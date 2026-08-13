#!/usr/bin/env python

import os
import platform
import shutil
import subprocess
import sys

from iciba import ICibaTranslate


def get_windows_user_dir() -> str:
    try:
        cmd = "cmd.exe /c echo %USERPROFILE%"
        raw_win_path = subprocess.check_output(
            cmd, shell=True, text=True, cwd="/mnt/c", stderr=subprocess.DEVNULL
        ).strip()

        wsl_path = subprocess.check_output(["wslpath", raw_win_path], text=True).strip()
        return wsl_path
    except Exception:
        return ""


def main():
    t = ICibaTranslate()
    argv = sys.argv
    w = ""
    if len(argv) == 1:
        if platform.uname().system == "Linux":
            if "microsoft" in platform.uname().release:
                w = subprocess.run(
                    [
                        get_windows_user_dir()
                        + "/scoop/apps/win32yank/current/win32yank.exe",
                        "-o",
                        "--lf",
                    ],
                    capture_output=True,
                    text=True,
                ).stdout
            elif shutil.which("xclip") is not None:
                w = subprocess.run(
                    ["xclip", "-selection", "clipboard", "-o"],
                    capture_output=True,
                    text=True,
                ).stdout
            else:
                w = subprocess.run(["wl-paste"], capture_output=True, text=True).stdout
        elif platform.uname().system == "Darwin":
            w = subprocess.run(
                ["pbpaste"], capture_output=True, text=True, check=True
            ).stdout
    elif len(argv) > 2:
        w = " ".join(argv[1:])
    else:
        w = argv[1]

    t.translate_print(w)


if __name__ == "__main__":
    main()
