import asyncio
from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from typing import Optional

from database import create_tables, get_db, TaskDB
from models import TaskCreate, TaskUpdate, TaskResponse, ReorderRequest
from crud import get_all_tasks, get_task, create_task, update_task, delete_task, reorder_tasks

app = FastAPI(title="Flodo Task Manager API", version="1.0.0")

# CORS — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    create_tables()


def _enrich_task(task: TaskDB, db: Session) -> TaskResponse:
    """Add computed fields to task response."""
    is_blocked = False
    blocker_title = None

    if task.blocked_by:
        blocker = get_task(db, task.blocked_by)
        if blocker:
            blocker_title = blocker.title
            if blocker.status != "Done":
                is_blocked = True

    return TaskResponse(
        id=task.id,
        title=task.title,
        description=task.description,
        due_date=task.due_date,
        status=task.status,
        blocked_by=task.blocked_by,
        is_recurring=task.is_recurring,
        sort_order=task.sort_order,
        created_at=task.created_at,
        updated_at=task.updated_at,
        is_blocked=is_blocked,
        blocker_title=blocker_title,
    )


@app.get("/tasks", response_model=list[TaskResponse])
def list_tasks(
    search: Optional[str] = Query(None),
    status: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    tasks = get_all_tasks(db, search=search, status=status)
    return [_enrich_task(t, db) for t in tasks]


@app.get("/tasks/{task_id}", response_model=TaskResponse)
def read_task(task_id: int, db: Session = Depends(get_db)):
    task = get_task(db, task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return _enrich_task(task, db)


@app.post("/tasks", response_model=TaskResponse)
async def create_task_endpoint(task: TaskCreate, db: Session = Depends(get_db)):
    # Simulate 2-second delay
    await asyncio.sleep(2)
    created = create_task(db, task)
    return _enrich_task(created, db)


@app.put("/tasks/{task_id}", response_model=TaskResponse)
async def update_task_endpoint(task_id: int, task: TaskUpdate, db: Session = Depends(get_db)):
    # Simulate 2-second delay
    await asyncio.sleep(2)
    updated = update_task(db, task_id, task)
    if not updated:
        raise HTTPException(status_code=404, detail="Task not found")
    return _enrich_task(updated, db)


@app.delete("/tasks/{task_id}")
def delete_task_endpoint(task_id: int, db: Session = Depends(get_db)):
    success = delete_task(db, task_id)
    if not success:
        raise HTTPException(status_code=404, detail="Task not found")
    return {"message": "Task deleted successfully"}


@app.put("/tasks/reorder")
def reorder_tasks_endpoint(request: ReorderRequest, db: Session = Depends(get_db)):
    reorder_tasks(db, request.task_ids)
    return {"message": "Tasks reordered successfully"}
