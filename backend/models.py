from pydantic import BaseModel
from typing import Optional


class TaskCreate(BaseModel):
    title: str
    description: str = ""
    due_date: str
    status: str = "To-Do"
    blocked_by: Optional[int] = None
    is_recurring: Optional[str] = None  # "Daily", "Weekly", or null


class TaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    due_date: Optional[str] = None
    status: Optional[str] = None
    blocked_by: Optional[int] = None
    is_recurring: Optional[str] = None


class TaskResponse(BaseModel):
    id: int
    title: str
    description: str
    due_date: str
    status: str
    blocked_by: Optional[int] = None
    is_recurring: Optional[str] = None
    sort_order: int
    created_at: str
    updated_at: str
    is_blocked: bool = False  # computed field: True if blocker exists and is not "Done"
    blocker_title: Optional[str] = None

    class Config:
        from_attributes = True


class ReorderRequest(BaseModel):
    task_ids: list[int]  # ordered list of task IDs
