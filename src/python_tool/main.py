#!/usr/bin/env python3
"""Main CLI application entry point."""

import argparse
import json
import os
import sys
from datetime import datetime

from dotenv import dotenv_values

from .models import ExecutionLog, get_db_session


def get_system_info():
    """Get system information."""
    config = dotenv_values(".env")

    return {
        "python_version": sys.version,
        "environment": os.environ.get("PYTHON_ENV", "development"),
        "service_name": os.environ.get("SERVICE_NAME")
        or config.get("SERVICE_NAME", "python-tool"),
        "timestamp": datetime.now().isoformat(),
    }


def echo_command(text: str, reverse: bool = False) -> dict:
    """Echo text with optional transformations."""
    result = {
        "original": text,
        "length": len(text),
    }

    if reverse:
        result["reversed"] = text[::-1]

    return result


def status_command(save_to_db: bool = False) -> dict:
    """Get application status and optionally save to database."""
    status_info = get_system_info()

    if save_to_db:
        try:
            config = dotenv_values(".env")
            # Prefer environment variables over .env file for containers
            postgres_user = os.environ.get("POSTGRES_USER") or config.get(
                "POSTGRES_USER"
            )
            postgres_password = os.environ.get("POSTGRES_PASSWORD") or config.get(
                "POSTGRES_PASSWORD"
            )
            postgres_host = os.environ.get("POSTGRES_HOST") or config.get(
                "POSTGRES_HOST"
            )
            postgres_port = os.environ.get("POSTGRES_PORT") or config.get(
                "POSTGRES_PORT"
            )
            postgres_db = os.environ.get("POSTGRES_DB") or config.get("POSTGRES_DB")

            database_url = f"postgresql://{postgres_user}:{postgres_password}@{postgres_host}:{postgres_port}/{postgres_db}"
            session = get_db_session(database_url=database_url)

            # Store execution in database
            execution_log = ExecutionLog(
                timestamp=datetime.now(),
                command="status",
                environment=status_info["environment"],
                python_version=status_info["python_version"],
                service_name=status_info["service_name"],
            )
            session.add(execution_log)
            session.commit()

            # Get recent executions
            recent_executions = (
                session.query(ExecutionLog)
                .order_by(ExecutionLog.timestamp.desc())
                .limit(5)
                .all()
            )

            session.close()

            status_info["recent_executions"] = [
                exec.to_dict() for exec in recent_executions
            ]
            status_info["database_status"] = "connected"

        except Exception as e:
            status_info["database_status"] = "error"
            status_info["database_error"] = str(e)

    return status_info


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="Python CLI Tool Template", prog="python-tool"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Status command
    status_parser = subparsers.add_parser("status", help="Show application status")
    status_parser.add_argument(
        "--save-db", action="store_true", help="Save execution to database"
    )
    status_parser.add_argument(
        "--json", action="store_true", help="Output in JSON format"
    )

    # Echo command
    echo_parser = subparsers.add_parser("echo", help="Echo text with transformations")
    echo_parser.add_argument("text", help="Text to echo")
    echo_parser.add_argument(
        "--reverse", action="store_true", help="Also return reversed text"
    )
    echo_parser.add_argument(
        "--json", action="store_true", help="Output in JSON format"
    )

    # Health command
    subparsers.add_parser("health", help="Health check")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    try:
        if args.command == "status":
            result = status_command(save_to_db=args.save_db)
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                print(f"Service: {result['service_name']}")
                print(f"Environment: {result['environment']}")
                print(f"Python: {result['python_version'].split()[0]}")
                print(f"Timestamp: {result['timestamp']}")
                if "database_status" in result:
                    print(f"Database: {result['database_status']}")

        elif args.command == "echo":
            result = echo_command(args.text, reverse=args.reverse)
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                print(f"Original: {result['original']}")
                print(f"Length: {result['length']}")
                if "reversed" in result:
                    print(f"Reversed: {result['reversed']}")

        elif args.command == "health":
            print("OK")
            sys.exit(0)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
