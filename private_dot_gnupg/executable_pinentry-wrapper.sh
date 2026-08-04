#!/bin/bash

# 显式请求使用 gui 模式
if [ "$PINENTRY_GUI" = "1" ]; then
  # macOS 环境优先使用 pinentry-mac
  if [ "$(uname)" = "Darwin" ]; then
    if [ -n "$HOMEBREW_PREFIX" ] && [ -x "$HOMEBREW_PREFIX/bin/pinentry-mac" ]; then
      exec "$HOMEBREW_PREFIX/bin/pinentry-mac" "$@"
    elif command -v pinentry-mac >/dev/null 2>&1; then
      exec pinentry-mac "$@"
    fi
  fi

  if grep -qi microsoft /proc/version; then
    win_user=$(powershell.exe -Command '$env:UserName' | tr -d '\r')
    exec "/mnt/c/Users/${win_user}/scoop/apps/git/current/usr/bin/pinentry.exe" "$@"
  else
    # 仅在确实开启了图形界面（存在 DISPLAY 或 WAYLAND_DISPLAY）时才调用 GUI pinentry
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
      if command -v pinentry-gnome2 >/dev/null 2>&1; then
        exec pinentry-gnome3 "$@"
      elif command -v pinentry-qt >/dev/null 2>&1; then
        exec pinentry-qt "$@"
      fi
    fi
  fi
else
  # 默认使用终端
  if command -v pinentry-curses >/dev/null 2>&1; then
    exec pinentry-curses "$@"
  elif command -v pinentry-tty >/dev/null 2>&1; then
    exec pinentry-tty "$@"
  else
    exec pinentry "$@"
  fi

fi
