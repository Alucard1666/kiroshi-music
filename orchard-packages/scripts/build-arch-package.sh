#!/bin/sh

set -eu

manager_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
repository_dir=$(CDPATH= cd -- "$manager_dir/.." && pwd)
exec sh "$repository_dir/scripts/build-arch-package.sh" "$@"
