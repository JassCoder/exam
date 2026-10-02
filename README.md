# 42 Exam Practice Shell

⚡ An interactive practice environment for 42 School exams (Ranks 02-06) ⚡

## 📋 Overview

This project provides a comprehensive practice shell for 42 School examinations, offering interactive menus and practice exercises for different exam ranks. The shell simulates the actual exam environment and helps students prepare effectively.

## 🚀 Features

- **Interactive Menu System**: Clean, colorful terminal interface
- **Multiple Exam Ranks**: Support for Ranks 02, 03, 04, 05 and 06
- **Practice Environment**: Dedicated workspace (`rendu` folder) for submissions
- **Command Practice**: Built-in command reference and practice
- **Easy Navigation**: Simple numbered menu system

## 📁 Project Structure

```
.
├── exam.sh           # Main entry point
├── Makefile          # Build configuration
├── README.md         # This file
└── .resources/       # Practice materials
    ├── main/         # Main menu and interface
    ├── rank02/       # Rank 02 exam exercises
    ├── rank03/       # Rank 03 exam exercises
    ├── rank04/       # Rank 04 exam exercises
    ├── rank05/       # Rank 05 exam exercises
    └── rank06/       # Rank 06 exam exercises
```

## 🔧 Installation & Usage

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/terminal-42s/42_examshell
   cd 42_examshell

2. **Run the exam shell**:
   ```bash
   make
   ```
   
   Or directly:
   ```bash
   bash exam.sh
   ```

### Menu Options

The main menu provides the following options:

- **🔄 1. Commands**: Access command reference and practice
- **🚀 2. Exam Rank 02**: Practice exercises for Rank 02 exam
- **📋 3. Exam Rank 03**: Practice exercises for Rank 03 exam  
- **📄 4. Exam Rank 04**: Practice exercises for Rank 04 exam
- **📄 5. Exam Rank 05**: Practice exercises for Rank 05 exam
- **📄 6. Exam Rank 06**: Practice exercises for Rank 06 exam
- **📁 7. Open Rendu Folder**: Access your submission workspace
- **🔄 8. Update Shell**: Keep your exam shell up-to-date with latest features

## 💡 How to Use

1. Launch the application using `make` or `bash exam.sh`
2. Select your desired exam rank or practice option
3. Follow the on-screen instructions
4. Complete exercises in the automatically created `rendu` folder
5. Use the practice environment to simulate real exam conditions

## 📝 Workspace

The shell automatically creates a `rendu` folder where you can:
- Write your solutions
- Test your code
- Practice exam submissions

## 🔄 Staying Up-to-Date

The exam shell includes an automatic update mechanism:

```bash
# From the main menu, select option 8: Update Shell
# Or manually run:
bash update.sh
```

The update script will:
- ✅ Check for latest changes from the repository
- ✅ Display available updates before pulling
- ✅ Download and apply all updates automatically
- ✅ Update file permissions for test scripts
- ✅ Return you to the main menu when complete

Stay tuned for new exam ranks, improved testers, and additional features!

## 🎯 Target Audience

This tool is designed for:
- 42 School students preparing for exams
- Anyone practicing C programming and system administration
- Students wanting to simulate exam conditions

## ⚙️ Requirements

- Bash shell
- Unix-like operating system (Linux/macOS)
- Terminal with color support (recommended)

## 🔄 Updates

The project includes update mechanisms to keep practice materials current with the latest exam requirements.

## 📚 Exam Ranks Covered

- **Rank 02**: Fundamental C programming concepts
- **Rank 03**: Advanced C programming and system calls
- **Rank 04**: Complex algorithms and data structures
- **Rank 05**: Advanced C++ programming and object-oriented design
- **Rank 06**: Advanced system programming (mini_db, mini_serv)

## 🤝 Contributing

This is a practice tool for 42 School students. Contributions and improvements are welcome to enhance the learning experience.

## 📧 Support

For issues or questions regarding the practice environment, please refer to your 42 School resources or community.

---

**Good luck with your exams! 🍀**

*Made for 42 School students by 42 School students*

## Saving and resuming

Progress is saved automatically before each exercise in every rank and mode.
Run `./exam.sh` (or `make`) again and accept the resume prompt to return to the
same exercise, practice question order, and exam level. `./resume.sh` is an alias.

- Type `save` at an exercise prompt to save and quit. `exit` also preserves progress.
- Ctrl+C, terminal closure, and termination preserve the last checkpoint. Even
  `kill -9` can recover it because saving happens before you start working.
- `./exam.sh --resume` resumes without asking.
- `./exam.sh --history` shows the timestamped exercise history.
- `./exam.sh --fresh` opens the menu without the old checkpoint.
- `./exam.sh --forget` removes the checkpoint without deleting code or history.

State lives in `.session/` inside this checkout and is ignored by Git. One active
session per checkout is supported. Files already saved in `rendu/` are preserved
when pausing and reopening an exercise; unsaved editor buffers and running tests
cannot be restored. Tests must be rerun after interruption. Existing completed-exam
backup behavior remains in place. The old `.orig` wrapper backups are no longer used.
