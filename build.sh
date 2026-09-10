#!/usr/bin/env bash
# Build firmware locally with the official ZMK Docker image.
#
#   ./build.sh                 build every entry in build.yaml
#   ./build.sh dongle right    build entries whose artifact-name contains any argument
#   ./build.sh --update        refresh the west workspace (after changing config/west.yml)
#
# Output: firmware/<artifact-name>.uf2
# The west workspace (ZMK + modules) is cached in .ws/ (gitignored).
set -euo pipefail

IMAGE="zmkfirmware/zmk-build-arm:stable"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WS="$ROOT/.ws"
UPDATE=0
FILTERS=()
for arg in "$@"; do
    case "$arg" in
        --update) UPDATE=1 ;;
        *) FILTERS+=("$arg") ;;
    esac
done

mkdir -p "$WS" "$ROOT/firmware"

# The manifest (config/west.yml) declares `self: path: config`, so the repo root must appear at
# <workspace>/config. Mount the cache dir as the workspace and the repo inside it.
docker run --rm -i \
    -v "$WS:/workspaces" \
    -v "$ROOT:/workspaces/config" \
    -w /workspaces \
    -e "UPDATE=$UPDATE" \
    -e "FILTERS=${FILTERS[*]:-}" \
    "$IMAGE" bash -euo pipefail <<'INNER'
if [ ! -d .west ]; then
    west init -l config --mf config/west.yml
    UPDATE=1
fi
if [ "$UPDATE" = "1" ]; then
    west update --narrow --fetch-opt=--depth=1
fi
# The container is throwaway, so the CMake package registration in ~/.cmake
# must be redone on every run (instant).
west zephyr-export >/dev/null

python3 - <<'PY' > /tmp/targets.txt
import os, yaml
filters = os.environ.get("FILTERS", "").split()
with open("config/build.yaml") as f:
    entries = yaml.safe_load(f)["include"]
for e in entries:
    name = e.get("artifact-name") or (e["board"] + "-" + e["shield"].replace(" ", "-"))
    if filters and not any(x in name for x in filters):
        continue
    # "|" rather than tab: bash's read collapses consecutive tabs, losing empty fields.
    print("|".join([name, e["board"], e.get("shield", ""), e.get("snippet", ""), e.get("cmake-args", "")]))
PY

if [ ! -s /tmp/targets.txt ]; then
    echo "no build.yaml entry matches: $FILTERS" >&2
    exit 1
fi

while IFS='|' read -r name board shield snippet cmake_args; do
    echo "=== $name (board=$board shield='$shield' snippet='$snippet' $cmake_args)"
    args=(-s zmk/app -d "build/$name" -b "$board")
    [ -n "$snippet" ] && args+=(-S "$snippet")
    west build --pristine=auto "${args[@]}" -- \
        -DZMK_CONFIG=/workspaces/config/config \
        -DZMK_EXTRA_MODULES=/workspaces/config \
        ${shield:+-DSHIELD="$shield"} \
        $cmake_args
    cp "build/$name/zephyr/zmk.uf2" "config/firmware/$name.uf2"
    echo "--> firmware/$name.uf2"
done < /tmp/targets.txt
INNER
