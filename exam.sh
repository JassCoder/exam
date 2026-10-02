#!/usr/bin/env bash
main_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.resources/main" && pwd)" || exit 1
cd "$main_dir" || exit 1
source ./session.sh
case "${1:-}" in
    --forget) session_clear; echo 'Saved checkpoint cleared. Your code and history are preserved.'; exit 0 ;;
    --fresh) session_clear ;;
    --history) [[ ! -f "$SESSION_DIR/history.log" ]] || cat "$SESSION_DIR/history.log"; exit 0 ;;
    --help|-h)
        echo 'Usage: ./exam.sh [--resume|--fresh|--forget|--history]'
        echo "At an exercise prompt: save (save and quit), or Ctrl+C."
        exit 0 ;;
    --resume|'') ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
if session_load; then
    index=$((10#${saved[5]}))
    echo "Saved session: ${saved[3]} / ${saved[4]} / ${saved[$((7+index))]}"
    answer=y
    if [[ ${1:-} != --resume ]]; then
        read -rp 'Resume? [Y/n] ' answer || exit 0
    fi
    case "$answer" in
        ''|y|Y|yes|YES)
            export SESSION_RESUME=1 SESSION_START_LEVEL="${saved[4]}"
            if [[ ${saved[2]} != - ]]; then
                exec bash "${saved[2]}"
            fi
            exec bash "${saved[1]}" "${saved[3]}" "${saved[4]/-/}"
            ;;
        *) session_clear ;;
    esac
elif [[ ${1:-} == --resume ]]; then
    echo 'No valid saved session.' >&2
    exit 1
fi
exec bash menu.sh
