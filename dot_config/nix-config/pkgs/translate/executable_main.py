#!/usr/bin/env python

import platform
import shutil
import subprocess
import sys

from iciba import ICibaTranslate


def main():
    t = ICibaTranslate()
    argv = sys.argv
    w = ""
    if len(argv) == 1:
        if platform.uname().system == "Linux":
            if shutil.which("xclip") is not None:
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
