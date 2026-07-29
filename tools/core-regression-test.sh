#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
WORK_DIR=${WORK_DIR:-/tmp/fakesip-core-regression}
CC=${CC:-gcc}
CFLAGS=${CFLAGS:--std=c99 -pedantic -Wall -Wextra -Werror}

mkdir -p "$WORK_DIR"

build_test() {
    name=$1
    shift
    "$CC" $CFLAGS -I"$ROOT_DIR/include" "$ROOT_DIR/tests/$name.c" "$@" \
        -o "$WORK_DIR/$name"
    "$WORK_DIR/$name"
}

build_test test_payload \
    "$ROOT_DIR/src/payload.c" "$ROOT_DIR/src/globvar.c" \
    "$ROOT_DIR/src/logging.c"
build_test test_srcinfo \
    "$ROOT_DIR/src/srcinfo.c" "$ROOT_DIR/src/globvar.c" \
    "$ROOT_DIR/src/logging.c"
build_test test_process \
    "$ROOT_DIR/src/process.c" "$ROOT_DIR/src/globvar.c" \
    "$ROOT_DIR/src/logging.c"
build_test test_nfrules \
    "$ROOT_DIR/src/nfrules.c" "$ROOT_DIR/src/globvar.c" \
    "$ROOT_DIR/src/logging.c"

if [ "$(uname -s)" = Linux ]; then
    "$CC" $CFLAGS -ffunction-sections -fdata-sections \
        -I"$ROOT_DIR/include" "$ROOT_DIR/tests/test_rawsend.c" \
        "$ROOT_DIR/src/globvar.c" "$ROOT_DIR/src/logging.c" \
        -Wl,--gc-sections -lnetfilter_queue -lnfnetlink -lmnl \
        -o "$WORK_DIR/test_rawsend"
    "$WORK_DIR/test_rawsend"
fi

FAKESIP=${FAKESIP:-$ROOT_DIR/build/fakesip}
if [ -x "$FAKESIP" ]; then
    assert_invalid() {
        set +e
        output=$($FAKESIP -a -f "$@" 2>&1)
        status=$?
        set -e
        [ "$status" -ne 0 ] || {
            printf 'FAIL: accepted invalid option: %s\n' "$*" >&2
            exit 1
        }
        case $output in
            *"invalid value"*) ;;
            *)
                printf 'FAIL: wrong error for invalid option %s: %s\n' \
                    "$*" "$output" >&2
                exit 1
                ;;
        esac
    }

    assert_invalid -m 123junk
    assert_invalid -m 18446744073709551616
    assert_invalid -n 65536
    assert_invalid -r -1
    assert_invalid -t +3
    assert_invalid -x 0x10000junk
    assert_invalid -y " 50"

    set +e
    output=$($FAKESIP -a -f -n 018 -m invalid 2>&1)
    status=$?
    set -e
    [ "$status" -ne 0 ] || {
        printf 'FAIL: decimal leading-zero queue test unexpectedly started\n' >&2
        exit 1
    }
    case $output in
        *"invalid value for -m"*) ;;
        *)
            printf 'FAIL: leading-zero decimal was not fully parsed: %s\n' \
                "$output" >&2
            exit 1
            ;;
    esac
fi

printf 'Core regression tests passed.\n'
