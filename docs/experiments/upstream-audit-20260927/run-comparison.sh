#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 4 ]; then
    echo 'Usage: run-comparison.sh <upstream> <fork> <test-source-root> <output>'
    exit 2
fi
upstream=$(realpath "$1")
fork=$(realpath "$2")
tests=$(realpath "$3")
out=$(realpath -m "$4")
here=$(cd -- "$(dirname -- "$0")" && pwd)
mkdir -p "$out"
for version in upstream fork; do
    source=$upstream
    [ "$version" != fork ] || source=$fork
    flags=(-std=c99 -Wall -Wextra -g -O1 '-fsanitize=address,undefined'
           -fno-sanitize-recover=all -I"$source/include")
    gcc "${flags[@]}" "$here/packet-contracts.c" \
        "$source/src/ipv4pkt.c" "$source/src/ipv6pkt.c" \
        "$source/src/globvar.c" "$source/src/logging.c" \
        -lnetfilter_queue -lnfnetlink -lmnl -o "$out/$version-packet-contracts"
    "$out/$version-packet-contracts" >"$out/$version-packet-contracts.log" 2>&1
    printf '%s packet contracts:\n' "$version"
    cat "$out/$version-packet-contracts.log"
    gcc "${flags[@]}" "$tests/tests/test_process.c" "$source/src/process.c" \
        "$source/src/globvar.c" "$source/src/logging.c" \
        -o "$out/$version-process"
    status=0
    timeout --kill-after=2 8 "$out/$version-process" >"$out/$version-process.log" 2>&1 || status=$?
    printf '%s process regression exit=%s\n' "$version" "$status"
    cat "$out/$version-process.log"
    if [ "$version" = fork ]; then
        [ "$status" = 0 ]
    else
        [ "$status" = 1 ]
    fi
done
