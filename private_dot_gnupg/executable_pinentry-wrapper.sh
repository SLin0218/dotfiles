#!/usr/bin/env bash
# ==============================================================================
# Pinentry Unified Wrapper
# 策略：尽量使用 GUI 弹窗，所有 GUI 方案均不可用时才回退到终端交互
# 1. JetBrains IDE (IntelliJ IDEA 等) 内置弹窗
# 2. macOS 原生 pinentry-mac / pinentry-touchid
# 3. WSL2 环境优先使用 PFW (Windows Hello) 或 Windows 原生 pinentry.exe
# 4. Linux 桌面 (Wayland/X11) pinentry-qt / pinentry-gtk-2
# 5. 终端保底回退 pinentry-curses / pinentry-tty
# ==============================================================================

# --- 1. 优先支持 JetBrains IDE (IntelliJ IDEA / CLion / PyCharm 等) 内置弹窗 ---
if [ -n "${PINENTRY_USER_DATA:-}" ]; then
  case "$PINENTRY_USER_DATA" in
    IJ_PINENTRY_ENTRYPOINT=*)
      entrypoint="${PINENTRY_USER_DATA#IJ_PINENTRY_ENTRYPOINT=}"
      entrypoint="${entrypoint%%:*}"
      if [ -x "$entrypoint" ]; then
        exec "$entrypoint" "$@"
      fi
      ;;
  esac
fi

# --- 2. macOS 原生 GUI 弹窗（优先 Touch ID，次选 pinentry-mac） ---
if [ "$(uname)" = "Darwin" ]; then
  for candidate in \
    "$(command -v pinentry-touchid 2>/dev/null)" \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/bin/pinentry-touchid" \
    "/usr/local/bin/pinentry-touchid" \
    "$(command -v pinentry-mac 2>/dev/null)" \
    "${HOMEBREW_PREFIX:-/opt/homebrew}/bin/pinentry-mac" \
    "/usr/local/bin/pinentry-mac"; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then
      exec "$candidate" "$@"
    fi
  done
fi

# --- 3. WSL2 环境 GUI 弹窗（优先 PFW Windows Hello，次选 Windows 原生 pinentry.exe） ---
if [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
  # 3.1 PFW (Pinentry for Windows) Relay，支持 Windows Hello 与 Windows 11 安全中心
  if [ -x "$HOME/.local/bin/pfw-relay-x64" ] && [ -f "$HOME/.config/PinentryForWindows/relay/broker.cer" ]; then
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1 exec "$HOME/.local/bin/pfw-relay-x64"
  fi

  # 3.2 PATH 中的 Windows pinentry.exe
  if command -v pinentry.exe >/dev/null 2>&1; then
    exec pinentry.exe "$@"
  fi

  # 3.3 动态解析 Windows 宿主用户主目录，定位 Scoop / Git / GPG 原生弹窗
  win_user=""
  if [ -n "${USERPROFILE:-}" ]; then
    win_user="$(wslpath -u "$USERPROFILE" 2>/dev/null || true)"
  fi
  if [ -z "$win_user" ]; then
    win_user="$(echo "$PATH" | grep -o -E '/mnt/[a-z]/Users/[^/:]+' | head -n 1)"
  fi
  if [ -z "$win_user" ] && command -v cmd.exe >/dev/null 2>&1 && command -v wslpath >/dev/null 2>&1; then
    raw_win_user="$(cmd.exe /c '<nul set /p=%USERPROFILE%' 2>/dev/null || true)"
    if [ -n "$raw_win_user" ]; then
      win_user="$(wslpath -u "$raw_win_user" 2>/dev/null || true)"
    fi
  fi

  for candidate in \
    ${win_user:+"$win_user/scoop/apps/git/current/usr/bin/pinentry.exe"} \
    ${win_user:+"$win_user/scoop/apps/gnupg/current/bin/pinentry-basic.exe"} \
    "/mnt/c/Program Files/Git/usr/bin/pinentry.exe" \
    "/mnt/c/Program Files/GnuPG/bin/pinentry.exe" \
    "/mnt/c/Program Files (x86)/GnuPG/bin/pinentry-basic.exe"; do
    if [ -x "$candidate" ]; then
      exec "$candidate" "$@"
    fi
  done
fi

# --- 4. 纯 Linux 图形环境 GUI 弹窗 (Wayland / X11) ---
if [ -n "${WAYLAND_DISPLAY:-}" ] || [ -n "${DISPLAY:-}" ]; then
  for candidate in pinentry-qt pinentry-gtk-2 pinentry-x11 pinentry-gui pinentry-gnome3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      exec "$candidate" "$@"
    fi
  done
fi

# --- 5. 终端回退方案（当所有 GUI 途径均不存在时保底） ---
for candidate in pinentry-curses pinentry-tty pinentry; do
  if command -v "$candidate" >/dev/null 2>&1; then
    exec "$candidate" "$@"
  fi
done

exec pinentry "$@"
