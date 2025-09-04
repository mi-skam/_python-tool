"""Database models for the application."""

from sqlalchemy import Column, DateTime, Integer, String, create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

Base = declarative_base()


class ExecutionLog(Base):
    """Model to store CLI execution metadata."""

    __tablename__ = "execution_logs"

    id = Column(Integer, primary_key=True)
    timestamp = Column(DateTime, nullable=False)
    command = Column(String(50), nullable=False)
    environment = Column(String(50), nullable=False)
    python_version = Column(String(100), nullable=False)
    service_name = Column(String(100))

    def to_dict(self):
        """Convert model to dictionary."""
        return {
            "id": self.id,
            "timestamp": self.timestamp.isoformat(),
            "command": self.command,
            "environment": self.environment,
            "python_version": self.python_version,
            "service_name": self.service_name,
        }


def get_db_session(database_url=None):
    """Create and return database session."""
    if not database_url:
        raise ValueError("Database URL must be provided")

    engine = create_engine(database_url)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    return Session()
