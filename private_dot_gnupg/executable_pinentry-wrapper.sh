#!/bin/bash

# 默认优先使用 GUI 模式输入密码；如需强制终端模式，可设置 PINENTRY_GUI=0 或 PINENTRY_TERMINAL=1
USE_GUI=1
if [ "$PINENTRY_GUI" = "0" ] || [ "$PINENTRY_NO_GUI" = "1" ] || [ "$PINENTRY_TERMINAL" = "1" ] || [ "$PINENTRY_USER_DATA" = "curses" ]; then
  USE_GUI=0
fi

if [ "$USE_GUI" = "1" ]; then
  # 1. macOS 环境：优先使用 pinentry-mac 或 pinentry-touchid
  if [ "$(uname)" = "Darwin" ]; then
    for candidate in \
      "$(command -v pinentry-mac 2>/dev/null)" \
      "${HOMEBREW_PREFIX:+$HOMEBREW_PREFIX/bin/pinentry-mac}" \
      "/opt/homebrew/bin/pinentry-mac" \
      "/usr/local/bin/pinentry-mac" \
      "$(command -v pinentry-touchid 2>/dev/null)"; do
      if [ -n "$candidate" ] && [ -x "$candidate" ]; then
        exec "$candidate" "$@"
      fi
    done
  fi

  # 2. WSL 环境：优先调用 Windows 原生 pinentry.exe 弹窗（比 Linux GUI 弹窗更稳定且无需依赖 WSLg/GCR）
  if [ -n "$WSL_DISTRO_NAME" ] || [ -n "$WSL_INTEROP" ] || grep -qi microsoft /proc/version 2>/dev/null; then
    # 优先在 PATH 中查找 pinentry.exe
    if command -v pinentry.exe >/dev/null 2>&1; then
      exec pinentry.exe "$@"
    fi

    # 常见 Windows Scoop / Git / GPG 安装路径（使用通配符匹配，避免调用耗时的 powershell.exe）
    for candidate in \
      /mnt/c/Users/*/scoop/apps/git/current/usr/bin/pinentry.exe \
      "/mnt/c/Program Files/Git/usr/bin/pinentry.exe" \
      /mnt/c/Users/*/scoop/apps/gnupg/current/bin/pinentry-basic.exe \
      "/mnt/c/Program Files/GnuPG/bin/pinentry.exe" \
      "/mnt/c/Program Files (x86)/GnuPG/bin/pinentry-basic.exe"; do
      if [ -x "$candidate" ]; then
        exec "$candidate" "$@"
      fi
    done
  fi

  # 3. Linux / WSLg 图形环境（存在 DISPLAY 或 WAYLAND_DISPLAY）
  if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
    for candidate in pinentry-qt pinentry-gnome3 pinentry-gtk-2 pinentry-x11 pinentry-gui; do
      if command -v "$candidate" >/dev/null 2>&1; then
        exec "$candidate" "$@"
      fi
    done
  fi
fi

# 4. 终端回退方案（当显式禁用 GUI、无图形环境或未找到 GUI 程序时使用）
for candidate in pinentry-curses pinentry-tty pinentry; do
  if command -v "$candidate" >/dev/null 2>&1; then
    exec "$candidate" "$@"
  fi
done

exec pinentry "$@"
