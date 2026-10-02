#!/usr/bin/env bash
# Checkpoints are plain data, never sourced as shell code.
SESSION_MAIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SESSION_DIR="$SESSION_MAIN/../../.session"
SESSION_FILE="$SESSION_DIR/last_session"

session_load() {
    local item path
    saved=()
    [[ -f "$SESSION_FILE" ]] || return 1
    mapfile -t saved < "$SESSION_FILE"
    [[ ${#saved[@]} -ge 8 && ${saved[0]} == 1 ]] || return 1
    case ${saved[1]} in
        level_base.sh|rank06_level.sh|rank05_level_base.sh|rank0[2-6]_exam_mode.sh) ;;
        *) return 1 ;;
    esac
    case ${saved[2]} in
        -|rank02_real_mode.sh|rank03_real_mode.sh|rank04.sh|rank05.sh|rank06.sh) ;;
        *) return 1 ;;
    esac
    [[ ${saved[3]} =~ ^rank0[2-6]$ && ${saved[4]} =~ ^(-|level[0-3])$ ]] || return 1
    [[ ${saved[5]} =~ ^[0-9]{1,3}$ ]] || return 1
    (( 10#${saved[5]} < ${#saved[@]} - 7 )) || return 1
    [[ ${saved[6]} =~ ^[0-9]+$ ]] || return 1
    for item in "${saved[@]:7}"; do
        [[ $item =~ ^[a-z0-9_]+$ ]] || return 1
        path="$SESSION_MAIN/../${saved[3]}"
        [[ ${saved[4]} == - ]] || path+="/${saved[4]}"
        [[ -f "$path/$item/sub.txt" ]] || return 1
    done
}

session_clear() {
    rm -f -- "$SESSION_FILE"
}

session_init() {
    session_worker=${0##*/}
    session_order=()
    session_index=0
    if [[ ${SESSION_RESUME:-0} == 1 ]] && session_load &&
       [[ ${saved[1]} == "$session_worker" && ${saved[3]} == "$rank" && ${saved[4]} == "${level:--}" ]]; then
        session_order=("${saved[@]:7}")
        session_index=$((10#${saved[5]}))
    fi
    unset SESSION_RESUME
    trap 'session_pause 130' INT
    trap 'session_pause 143' TERM
    trap 'session_pause 129' HUP
}

session_save() {
    local index=$1 tmp old=''
    shift
    (( $# > index )) || return 1
    mkdir -p "$SESSION_DIR" || return 1
    tmp=$(mktemp "$SESSION_DIR/checkpoint.XXXXXX") || return 1
    # Rename atomically, so a killed process cannot leave a partial checkpoint.
    if ! printf '%s\n' 1 "$session_worker" "${SESSION_DRIVER:--}" "$rank" "${level:--}" "$index" "$(date +%s)" "$@" > "$tmp"; then
        rm -f -- "$tmp"
        return 1
    fi
    [[ ! -f "$SESSION_FILE" ]] || old=$(sed '7d' "$SESSION_FILE")
    if [[ $old != "$(sed '7d' "$tmp")" ]]; then
        local order=("$@")
        printf '%s\t%s\t%s\t%s\t%s\n' "$(date -u +%FT%TZ)" "$session_worker" "$rank" "${level:--}" "${order[$index]}" >> "$SESSION_DIR/history.log"
    fi
    mv -f -- "$tmp" "$SESSION_FILE" || return 1
}

session_checkpoint() {
    session_save "$@" || { echo 'Unable to save session; stopping to protect progress.' >&2; exit 200; }
}

session_pause() {
    # The latest exercise was saved before accepting input, even for SIGKILL.
    echo
    echo 'Session saved. Run ./exam.sh to resume. Your rendu files are preserved.'
    exit "${1:-200}"
}
