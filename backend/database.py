from sqlalchemy import create_engine, Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
import datetime

DATABASE_URL = "sqlite:///./tasks.db"

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class TaskDB(Base):
    __tablename__ = "tasks"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    title = Column(String, nullable=False)
    description = Column(String, nullable=False, default="")
    due_date = Column(String, nullable=False)
    status = Column(String, nullable=False, default="To-Do")
    blocked_by = Column(Integer, ForeignKey("tasks.id", ondelete="SET NULL"), nullable=True)
    is_recurring = Column(String, nullable=True)  # "Daily", "Weekly", or null
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(String, nullable=False, default=lambda: datetime.datetime.utcnow().isoformat())
    updated_at = Column(String, nullable=False, default=lambda: datetime.datetime.utcnow().isoformat())

    blocker = relationship("TaskDB", remote_side=[id], foreign_keys=[blocked_by])


def create_tables():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
