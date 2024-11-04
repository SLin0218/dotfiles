#!/usr/bin/env bash

"$HOME"/.local/scripts/clash-subscribe/bin/python "$HOME"/.local/scripts/clash-subscribe/main.py

if [[ $(uname) = 'Linux' ]]; then
  systemctl --user restart clash
  systemctl --user status clash
fi
