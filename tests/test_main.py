import json
import os
import subprocess
import sys
from unittest.mock import MagicMock, patch

from src.python_tool.main import echo_command, get_system_info, status_command


def test_get_system_info():
    """Test system info retrieval."""
    info = get_system_info()
    assert "python_version" in info
    assert "environment" in info
    assert "service_name" in info
    assert "timestamp" in info


def test_echo_command():
    """Test the echo command functionality."""
    # Test basic echo
    result = echo_command("hello")
    assert result["original"] == "hello"
    assert result["length"] == 5
    assert "reversed" not in result

    # Test echo with reverse
    result = echo_command("hello", reverse=True)
    assert result["original"] == "hello"
    assert result["length"] == 5
    assert result["reversed"] == "olleh"


def test_echo_command_empty_string():
    """Test echo command with empty string."""
    result = echo_command("")
    assert result["original"] == ""
    assert result["length"] == 0


def test_echo_command_special_characters():
    """Test echo command with special characters."""
    test_text = "hello-world_123"
    result = echo_command(test_text, reverse=True)
    assert result["original"] == test_text
    assert result["reversed"] == test_text[::-1]
    assert result["length"] == len(test_text)


def test_status_command_without_db():
    """Test status command without database."""
    result = status_command(save_to_db=False)
    assert "python_version" in result
    assert "environment" in result
    assert "service_name" in result
    assert "timestamp" in result
    assert "database_status" not in result


@patch("src.python_tool.main.get_db_session")
def test_status_command_with_database(mock_db_session):
    """Test status command with mocked database."""
    # Mock database session and query
    mock_session = MagicMock()
    mock_db_session.return_value = mock_session

    # Mock query results (empty list of recent executions)
    mock_query = MagicMock()
    mock_session.query.return_value = mock_query
    mock_query.order_by.return_value = mock_query
    mock_query.limit.return_value = mock_query
    mock_query.all.return_value = []

    result = status_command(save_to_db=True)

    # Check expected fields are present
    assert "python_version" in result
    assert "environment" in result
    assert "service_name" in result
    assert "timestamp" in result
    assert "recent_executions" in result
    assert "database_status" in result
    assert result["database_status"] == "connected"
    assert result["recent_executions"] == []

    # Verify database operations were called
    mock_session.add.assert_called_once()
    mock_session.commit.assert_called_once()
    mock_session.close.assert_called_once()


@patch("src.python_tool.main.get_db_session")
def test_status_command_database_error(mock_db_session):
    """Test status command handles database errors gracefully."""
    # Mock database session to raise an exception
    mock_db_session.side_effect = Exception("Database connection failed")

    result = status_command(save_to_db=True)
    assert "database_status" in result
    assert result["database_status"] == "error"
    assert "database_error" in result
    assert "Database connection failed" in result["database_error"]


def test_cli_health_command():
    """Test CLI health command via subprocess."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [sys.executable, "-m", "src.python_tool.main", "health"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0
    assert result.stdout.strip() == "OK"


def test_cli_echo_command():
    """Test CLI echo command via subprocess."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [sys.executable, "-m", "src.python_tool.main", "echo", "test", "--json"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0

    output = json.loads(result.stdout)
    assert output["original"] == "test"
    assert output["length"] == 4


def test_cli_echo_command_with_reverse():
    """Test CLI echo command with reverse option."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "src.python_tool.main",
            "echo",
            "hello",
            "--reverse",
            "--json",
        ],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0

    output = json.loads(result.stdout)
    assert output["original"] == "hello"
    assert output["reversed"] == "olleh"
    assert output["length"] == 5


def test_cli_status_command():
    """Test CLI status command via subprocess."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [sys.executable, "-m", "src.python_tool.main", "status", "--json"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 0

    output = json.loads(result.stdout)
    assert "python_version" in output
    assert "environment" in output
    assert "service_name" in output
    assert "timestamp" in output


def test_cli_no_command():
    """Test CLI with no command shows help."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [sys.executable, "-m", "src.python_tool.main"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode == 1
    assert "usage:" in result.stderr.lower() or "usage:" in result.stdout.lower()


def test_cli_invalid_command():
    """Test CLI with invalid command."""
    # Set required environment variable
    env = os.environ.copy()
    env["SERVICE_NAME"] = "python-tool"

    result = subprocess.run(
        [sys.executable, "-m", "src.python_tool.main", "invalid"],
        capture_output=True,
        text=True,
        env=env,
    )
    assert result.returncode != 0
