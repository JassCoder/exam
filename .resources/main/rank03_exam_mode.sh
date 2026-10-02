#!/bin/bash
source colors.sh

rank=$1
level=${2:-}

# Save base directory (where script was launched from)
base_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Persistent session checkpoint
source "$base_dir/session.sh"
session_init

# Define subject pool using case statement instead of associative array
get_subjects() {
    case "$level" in
        level1)
            echo "broken_gnl filter scanf"
            ;;
        level2)
            echo "n_queens permutations powerset rip tsp"
            ;;
        *)
            echo ""
            ;;
    esac
}

pick_new_subject() {
    subjects_list=$(get_subjects)
    IFS=' ' read -r -a qsub <<< "$subjects_list"
    count=${#qsub[@]}
    random_index=$(( RANDOM % count ))
    chosen="${qsub[$random_index]}"
    session_checkpoint 0 "$chosen"
}

prepare_subject() {
    mkdir -p "$base_dir/../../rendu/$chosen"
    
    # Create appropriate files based on subject requirements
    case $chosen in
        "broken_gnl")
            [ ! -f "$base_dir/../../rendu/$chosen/broken_gnl.c" ] && \
                cp "$base_dir/../$rank/$level/broken_gnl/broken_gnl.c" "$base_dir/../../rendu/$chosen/broken_gnl.c"
            touch "$base_dir/../../rendu/$chosen/get_next_line.c"
            touch "$base_dir/../../rendu/$chosen/get_next_line.h"
            ;;
        "filter")
            touch "$base_dir/../../rendu/$chosen/filter.c"
            ;;
        "scanf")
            touch "$base_dir/../../rendu/$chosen/ft_scanf.c"
            ;;
        "tsp")
        	[ ! -f "$base_dir/../../rendu/$chosen/tsp.c" ] && \
                	cp "$base_dir/../$rank/$level/tsp/tsp.c" "$base_dir/../../rendu/$chosen/tsp.c"
                touch "$base_dir/../../rendu/$chosen/tsp.h"
                ;;
        *)
            # For other subjects, create generic .c file
            touch "$base_dir/../../rendu/$chosen/$chosen.c"
            ;;
    esac

    cd "$base_dir/../$rank/$level/$chosen" || {
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
    echo -e "${GREEN}🎯 New subject chosen: $chosen${RESET}"
fi

session_checkpoint 0 "$chosen"
prepare_subject

# Interactive loop
while true; do
    echo -e "${MAGENTA}${BOLD}Enter command: ${RESET}"
    read -r command || session_pause

    case $command in
        test)
            if [ -f "tester.sh" ]; then
                echo -e "${BLUE}Running tester...${RESET}"
                bash tester.sh
                echo -e "${CYAN}Test completed. Continue working or type 'next' for a new subject.${RESET}"
            else
                echo -e "${YELLOW}No tester available for this subject. Please test manually.${RESET}"
            fi
            ;;
        next)
            pick_new_subject
                    echo -e "${GREEN}🎯 New subject chosen: $chosen${RESET}"
            prepare_subject
            ;;
        save|exit)
            session_pause
            ;;
        *)
            echo -e "${RED}Unknown command. Use 'test', 'next', or 'exit'.${RESET}"
            ;;
    esac
done
