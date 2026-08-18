#!/bin/bash
# Builds Atmosphere inside the devkitPro MSYS2 shell.
# Invoked by build.bat in this same folder (and usable standalone from msys2):
#   bash build.sh [target] [jobs] [--dryrun]
#     target  nx_release (default) | nx_debug | nx_audit | dist-no-debug-nx_release | clean
#     jobs    parallel jobs, default 2

source /etc/profile.d/devkit-env.sh

PYTHON_WIN="/c/Users/nik/AppData/Local/Programs/Python/Python312"
export PATH="$PYTHON_WIN:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

TARGET="${1:-nx_release}"
JOBS="${2:-2}"
DRYRUN=""
[ "${3}" = "--dryrun" ] && DRYRUN="-n"

export PYTHON="$(command -v python)"
echo "PYTHON=$PYTHON"
echo "DEVKITPRO=$DEVKITPRO DEVKITARM=$DEVKITARM"
echo "Target=$TARGET Jobs=$JOBS DryRun=${DRYRUN:-no} CWD=$(pwd)"

if [ "$TARGET" = "clean" ]; then
    make clean
    exit $?
fi

make $DRYRUN -j"$JOBS" "$TARGET"
STATUS=$?

if [ $STATUS -eq 0 ] && [ -z "$DRYRUN" ]; then
    echo "== Build ok. Output in out/nintendo_nx_arm64_armv8a/release/ =="
    ls -la out/nintendo_nx_arm64_armv8a/release/ 2>/dev/null

    # dist-no-debug-nx_release already produces a correctly-nested SD-card zip
    # (its own recipe assembles atmosphere/ and switch/ directly under
    # DIST_DIR and zips relative to that -- no wrapper folder). Just copy it
    # into switch-cfw's _ZIPS_/ under our naming convention. See
    # PACKAGING.md at the switch-cfw root.
    case "$TARGET" in
        dist-no-debug*|dist)
            ZIP_SRC="$(find out -maxdepth 3 -iname 'atmosphere-*.zip' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)"
            if [ -n "$ZIP_SRC" ]; then
                ZIPS_DIR="$SCRIPT_DIR/../_ZIPS_"
                mkdir -p "$ZIPS_DIR"
                cp "$ZIP_SRC" "$ZIPS_DIR/atmosphere-release.zip"
                echo "== Packaged: $ZIPS_DIR/atmosphere-release.zip (from $ZIP_SRC) =="

                # Also extract into _SDCARD_/atmosphere/ so the real SD-card
                # layout for this project can be browsed/merged directly,
                # without unzipping. Mirrors _ZIPS_/ per PACKAGING.md.
                SDCARD_DIR="$SCRIPT_DIR/../_SDCARD_/atmosphere"
                rm -rf "$SDCARD_DIR"
                mkdir -p "$SDCARD_DIR"
                if unzip -oq "$ZIP_SRC" -d "$SDCARD_DIR"; then
                    echo "== Extracted: $SDCARD_DIR =="
                else
                    echo "== WARNING: extraction to $SDCARD_DIR failed (unzip not installed?) =="
                fi
            else
                echo "== WARNING: $TARGET reported success but no out/atmosphere-*.zip found =="
            fi
            ;;
    esac
fi

exit $STATUS
