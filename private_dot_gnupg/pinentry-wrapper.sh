#!/bin/bash

# 1. 显式请求使用终端 curses 模式
# （注：去掉了 [ -t 0 ]，因为 gpg-agent 调用 pinentry 时 fd 0 始终是管道）
if [ "$PINENTRY_USER_DATA" = "USE_CURSES=1" ]; then
	if command -v pinentry-curses >/dev/null 2>&1; then
		exec pinentry-curses "$@"
	fi
fi

# 2. macOS 环境优先使用 pinentry-mac
if [ "$(uname)" = "Darwin" ]; then
	if [ -n "$HOMEBREW_PREFIX" ] && [ -x "$HOMEBREW_PREFIX/bin/pinentry-mac" ]; then
		exec "$HOMEBREW_PREFIX/bin/pinentry-mac" "$@"
	elif command -v pinentry-mac >/dev/null 2>&1; then
		exec pinentry-mac "$@"
	fi
fi

# 3. 仅在确实开启了图形界面（存在 DISPLAY 或 WAYLAND_DISPLAY）时才调用 GUI pinentry
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
	if command -v pinentry-gnome3 >/dev/null 2>&1; then
		exec pinentry-gnome3 "$@"
	elif command -v pinentry-qt >/dev/null 2>&1; then
		exec pinentry-qt "$@"
	fi
fi

# 4. 终端环境 / SSH / 纯命令行 / 无 GUI 时的降级回退方案
if command -v pinentry-curses >/dev/null 2>&1; then
	exec pinentry-curses "$@"
elif command -v pinentry-tty >/dev/null 2>&1; then
	exec pinentry-tty "$@"
else
	exec pinentry "$@"
fi
