#!/usr/bin/python3
"""Mirror supervised program output to container stdout and optional supervisor files."""

from __future__ import annotations

import os
import subprocess
import sys


def wants_file_logging() -> bool:
    value = os.environ.get("PDNS_SUPERVISOR_FILE_LOGGING", "")
    return value.strip().lower() in {"1", "true", "yes", "on"}


def stream_output(command: list[str], copy_to_supervisor_log: bool) -> int:
    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )
    assert process.stdout is not None

    # PID 1 is supervisord. Writing to its stdout keeps `docker logs` working
    # even when supervisord stores this program's own stdout in a file.
    with open("/proc/1/fd/1", "w", encoding="utf-8") as container_stdout:
        for line in process.stdout:
            container_stdout.write(line)
            container_stdout.flush()
            if copy_to_supervisor_log:
                sys.stdout.write(line)
                sys.stdout.flush()
    return process.wait()


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "usage: supervisor_tee.py <program-name> <command> [args...]",
            file=sys.stderr,
        )
        return 2

    program_name = sys.argv[1]
    command = sys.argv[2:]

    return stream_output(command, copy_to_supervisor_log=wants_file_logging())


if __name__ == "__main__":
    raise SystemExit(main())
