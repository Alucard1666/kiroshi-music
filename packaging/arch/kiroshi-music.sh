#!/bin/sh

if command -v electron43 >/dev/null 2>&1; then
  ELECTRON=/usr/bin/electron43
elif command -v electron >/dev/null 2>&1; then
  ELECTRON=/usr/bin/electron
else
  ELECTRON=electron
fi

exec "$ELECTRON" /usr/lib/kiroshi-music "$@"
