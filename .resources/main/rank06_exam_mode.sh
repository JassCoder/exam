#!/bin/bash
source colors.sh

rank=$1
level=${2:-}

# Save base directory (where script was launched from)
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Persistent session checkpoint
source "$base_dir/session.sh"
session_init

# Define subject pool (rank06 has two projects)
get_subjects() {
    echo "mini_db mini_serv"
}

# Pick a new random subject
pick_new_subject() {
    subjects_list=$(get_subjects)
    IFS=' ' read -r -a qsub <<< "$subjects_list"
    count=${#qsub[@]}
    random_index=$(( RANDOM % count ))
    chosen="${qsub[$random_index]}"
    session_checkpoint 0 "$chosen"
}

# Prepare the subject folder and files
prepare_subject() {
    mkdir -p "$base_dir/../../rendu/$chosen"

    # Create file stubs based on project type
    if [[ "$chosen" == "mini_db" ]]; then
        [ ! -f "$base_dir/../../rendu/$chosen/mini_db.cpp" ] && touch "$base_dir/../../rendu/$chosen/mini_db.cpp"
        [ ! -f "$base_dir/../../rendu/$chosen/mini_db.hpp" ] && touch "$base_dir/../../rendu/$chosen/mini_db.hpp"
    elif [[ "$chosen" == "mini_serv" ]]; then
        [ ! -f "$base_dir/../../rendu/$chosen/mini_serv.c" ] && touch "$base_dir/../../rendu/$chosen/mini_serv.c"
    fi

    # Go to the subject folder dynamically
    cd "$base_dir/../$rank/$chosen" || {
        echo -e "${RED}Subject folder not found.${RESET}"
        exit 1
    }

    clear
    echo -e "${CYAN}${BOLD}Your subject: $chosen${RESET}"
    echo "=================================================="
    cat sub.txt
    echo
    echo -e "=================================================="
    echo -e "${YELLOW}Type 'test' to test your code, 'next' for a new question, 'save' to save and quit, or 'exit' to quit.${RESET}"
}

# Initial subject selection
if (( ${#session_order[@]} )); then
    chosen=${session_order[$session_index]}
    echo -e "${BLUE}🔁 Resuming with previously chosen subject: $chosen${RESET}"
else
    pick_new_subject
fi

session_checkpoint 0 "$chosen"
prepare_subject

# Command loop
while true; do
    read -rp "/> " input || session_pause
    case "$input" in
        test)
            clear
            echo -e "${GREEN}Running tester.sh...${RESET}"
            if [ -f "./tester.sh" ]; then
                output=$(./tester.sh 2>&1)
                echo "$output" | tee tester_output.log

                if echo "$output" | grep -q -E "PASSED|SUCCESS"; then
                    echo -e "${GREEN}${BOLD}✔️  Passed!${RESET}"
                    [[ -n ${SESSION_DRIVER:-} ]] || session_clear
                    sleep 1
                    exit 0
                else
                    echo -e "${RED}${BOLD}❌  Failed.${RESET}"
                    sleep 1
                    exit 1
                fi
            else
                echo -e "${YELLOW}No tester available for this subject. Please test manually.${RESET}"
                sleep 1
            fi
            ;;
        next)
            echo -e "${BLUE}🔄 Picking a new subject...${RESET}"
            pick_new_subject
            prepare_subject
            ;;
        save|exit)
            session_pause
            ;;
        *)
            echo "Please type 'test' to test code, 'next' for next or 'exit' for exit."
            ;;
    esac
done
