#!/bin/bash
source functions.sh
source colors.sh
source ./session.sh
export SESSION_DRIVER="${0##*/}"
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

run_level() {
    level=$1
    clear
    echo "$(tput setaf 2)$(tput bold)Level $level is being prepared...$(tput sgr0)"
    display_animation
    clear
    until bash rank04_exam_mode.sh rank04 level$level; do
        status=$?
        if (( status >= 128 )); then
            exit "$status"
        fi

        export SESSION_RESUME=1
        echo "$(tput setaf 1)Test failed. Try again.$(tput sgr0)"
        read -p "Press Enter to retry Level $level..." || exit 200
        clear
    done
    echo "$(tput setaf 2)✔️  Level $level passed!$(tput sgr0)"
    sleep 1
}

start_exam() {
    clear
    bash label.sh
    echo "$(tput setaf 2)$(tput bold)🧪 Welcome to the Rank04 Exam!$(tput sgr0)"
    echo "=================================================="
    sleep 1

    for level in 1 2; do
        if [[ ${SESSION_START_LEVEL:-} =~ ^level([0-3])$ ]] && (( level < ${BASH_REMATCH[1]} )); then
            continue
        fi
        mkdir -p ../../rendu 
        run_level $level
    done

    echo "=================================================="
    echo "$(tput setaf 2)$(tput bold)🎉 Congratulations! You passed the Rank04 exam!$(tput sgr0)"
    echo "=================================================="

    session_clear

    # Backup rendu folder
    if [ -d "../../rendu" ]; then
        timestamp=$(date +%Y%m%d_%H%M%S)
        mkdir -p ../../exam
        cp -r ../../rendu "../../exam/rendu_backup_$timestamp"
        echo -e "${CYAN}📁 rendu folder backed up to: exam/rendu_backup_$timestamp${RESET}"
        
        # Clean after backup
        rm -rf ../../rendu
        echo -e "${RED}🗑️  rendu folder has been cleared after successful exam.${RESET}"
    fi

    unset SESSION_START_LEVEL SESSION_RESUME

    # Ask to retry
    echo
    read -rp "$(echo -e ${YELLOW}${BOLD}"Do you want to retry the exam? (y/n): "${RESET})" retry
    case "$retry" in
        y|Y)
            echo -e "${YELLOW}🔄 Restarting the exam...${RESET}"
            sleep 1
            bash rank04.sh
            ;;
        *)
            echo -e "${GREEN}Goodbye!${RESET}"
            exit 0
            ;;
    esac
}

start_exam  # Call the function
