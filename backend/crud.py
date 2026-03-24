from sqlalchemy.orm import Session
from database import TaskDB
from models import TaskCreate, TaskUpdate
import datetime
from dateutil.relativedelta import relativedelta


def get_all_tasks(db: Session, search: str = None, status: str = None):
    query = db.query(TaskDB)

    if search:
        query = query.filter(TaskDB.title.ilike(f"%{search}%"))

    if status and status != "All":
        query = query.filter(TaskDB.status == status)

    tasks = query.order_by(TaskDB.sort_order.asc(), TaskDB.created_at.desc()).all()
    return tasks


def get_task(db: Session, task_id: int):
    return db.query(TaskDB).filter(TaskDB.id == task_id).first()


def create_task(db: Session, task: TaskCreate):
    # Get max sort_order
    max_order = db.query(TaskDB.sort_order).order_by(TaskDB.sort_order.desc()).first()
    next_order = (max_order[0] + 1) if max_order else 0

    now = datetime.datetime.utcnow().isoformat()
    db_task = TaskDB(
        title=task.title,
        description=task.description,
        due_date=task.due_date,
        status=task.status,
        blocked_by=task.blocked_by,
        is_recurring=task.is_recurring,
        sort_order=next_order,
        created_at=now,
        updated_at=now,
    )
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task


def update_task(db: Session, task_id: int, task: TaskUpdate):
    db_task = db.query(TaskDB).filter(TaskDB.id == task_id).first()
    if not db_task:
        return None

    old_status = db_task.status
    update_data = task.model_dump(exclude_unset=True)
    # Handle explicit null for blocked_by
    if "blocked_by" in update_data:
        db_task.blocked_by = update_data["blocked_by"]

    for key, value in update_data.items():
        setattr(db_task, key, value)

    db_task.updated_at = datetime.datetime.utcnow().isoformat()
    db.commit()
    db.refresh(db_task)

    # Handle recurring task logic
    new_status = db_task.status
    if old_status != "Done" and new_status == "Done" and db_task.is_recurring:
        _create_next_recurring_task(db, db_task)

    return db_task


def _create_next_recurring_task(db: Session, completed_task: TaskDB):
    """Create the next occurrence of a recurring task."""
    try:
        due_date = datetime.datetime.fromisoformat(completed_task.due_date)
    except ValueError:
        due_date = datetime.datetime.strptime(completed_task.due_date, "%Y-%m-%d")

    if completed_task.is_recurring == "Daily":
        next_due = due_date + datetime.timedelta(days=1)
    elif completed_task.is_recurring == "Weekly":
        next_due = due_date + datetime.timedelta(weeks=1)
    else:
        return

    max_order = db.query(TaskDB.sort_order).order_by(TaskDB.sort_order.desc()).first()
    next_order = (max_order[0] + 1) if max_order else 0
    now = datetime.datetime.utcnow().isoformat()

    new_task = TaskDB(
        title=completed_task.title,
        description=completed_task.description,
        due_date=next_due.strftime("%Y-%m-%d"),
        status="To-Do",
        blocked_by=None,
        is_recurring=completed_task.is_recurring,
        sort_order=next_order,
        created_at=now,
        updated_at=now,
    )
    db.add(new_task)
    db.commit()


def delete_task(db: Session, task_id: int):
    db_task = db.query(TaskDB).filter(TaskDB.id == task_id).first()
    if not db_task:
        return False

    # Clear blocked_by references pointing to this task
    db.query(TaskDB).filter(TaskDB.blocked_by == task_id).update(
        {"blocked_by": None}, synchronize_session="fetch"
    )

    db.delete(db_task)
    db.commit()
    return True


def reorder_tasks(db: Session, task_ids: list[int]):
    for index, task_id in enumerate(task_ids):
        db.query(TaskDB).filter(TaskDB.id == task_id).update(
            {"sort_order": index}, synchronize_session="fetch"
        )
    db.commit()
    return True
