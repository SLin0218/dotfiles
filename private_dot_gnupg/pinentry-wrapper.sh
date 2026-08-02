#!/bin/bash
# 1. If explicitly requesting curses mode in an interactive terminal
if [ "$PINENTRY_USER_DATA" = "USE_CURSES=1" ] && [ -t 0 ]; then
	if command -v pinentry-curses >/dev/null 2>&1; then
		exec pinentry-curses "$@"
	fi
fi

# 2. macOS: Use pinentry-mac
if [ "$(uname)" = "Darwin" ]; then
	if [ -n "$HOMEBREW_PREFIX" ] && [ -x "$HOMEBREW_PREFIX/bin/pinentry-mac" ]; then
		exec "$HOMEBREW_PREFIX/bin/pinentry-mac" "$@"
	elif command -v pinentry-mac >/dev/null 2>&1; then
		exec pinentry-mac "$@"
	fi
fi

# 3. Try GUI pinentry (GNOME/GTK / Qt) - ideal for WSLg and Linux GUI
if command -v pinentry-gnome3 >/dev/null 2>&1; then
	exec pinentry-gnome3 "$@"
elif command -v pinentry-qt >/dev/null 2>&1; then
	exec pinentry-qt "$@"
fi

# 4. Final Fallback
if command -v pinentry-curses >/dev/null 2>&1; then
	exec pinentry-curses "$@"
else
	exec pinentry "$@"
fi


