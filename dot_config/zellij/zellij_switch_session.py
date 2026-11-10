#!/usr/bin/env python3
"""Cross-platform Zellij session switcher (Next / Previous session).

Compatible with Windows, Linux, and macOS.
"""

import os
import subprocess
import sys


def get_sessions():
    try:
        # zellij list-sessions -s -n outputs plain session names, one per line
        out = subprocess.check_output(
            ["zellij", "list-sessions", "-s", "-n"],
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return [line.strip() for line in out.splitlines() if line.strip()]
    except Exception:
        return []


def main():
    direction = "next"
    if len(sys.argv) > 1 and sys.argv[1].lower() in ("prev", "p", "-p", "previous"):
        direction = "prev"

    sessions = get_sessions()
    if len(sessions) <= 1:
        return

    cur_session = os.environ.get("ZELLIJ_SESSION_NAME", "")

    try:
        cur_idx = sessions.index(cur_session)
    except ValueError:
        cur_idx = 0

    if direction == "prev":
        target_idx = (cur_idx - 1 + len(sessions)) % len(sessions)
    else:
        target_idx = (cur_idx + 1) % len(sessions)

    target_session = sessions[target_idx]
    if target_session != cur_session:
        subprocess.call(["zellij", "action", "switch-session", target_session])


if __name__ == "__main__":
    main()
