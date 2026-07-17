# TaskFlow

A simple yet powerful task manager app built with Flutter, following clean architecture principles.

## Features

- **Create, Read, Update, Delete Tasks** — Full CRUD operations
- **Mark Tasks Complete** — Toggle completion with checkbox
- **Filter Tasks** — All / Active / Completed
- **Sort Tasks** — By due date or priority
- **Search Tasks** — Filter by title
- **Dark Mode** — Toggle between light and dark themes
- **Local Notifications** — Reminders for upcoming tasks
- **Undo Delete** — SnackBar with undo action
- **Empty States** — Contextual messages when no tasks exist
- **Local Persistence** — Tasks saved in SQLite, survive app restart

## Architecture

```
lib/
├── main.dart                    # App entry, theme, providers
├── models/
│   └── task.dart                # Task model with fromMap/toMap/copyWith
├── database/
│   └── database_helper.dart     # SQLite database operations
├── repository/
│   └── task_repository.dart     # Repository pattern layer
├── providers/
│   └── task_provider.dart       # Riverpod state management
├── screens/
│   ├── home_screen.dart         # Task list with filters/sort
│   └── add_task_screen.dart     # Add/Edit task form
├── widgets/
│   ├── task_tile.dart           # Reusable task item widget
│   └── empty_widget.dart        # Empty state widget
└── utils/
    ├── constants.dart           # App constants
    └── notification_service.dart # Local notifications
```

## Data Flow

```
User → Screen → Riverpod Notifier → Repository → DatabaseHelper → SQLite
```

## Tech Stack

| Component | Package |
|-----------|---------|
| State Management | flutter_riverpod |
| Database | sqflite |
| Notifications | flutter_local_notifications |
| Date Formatting | intl |
| Timezone | timezone |

## Setup

### Prerequisites

- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / VS Code

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/taskflow.git

# Navigate to project
cd taskflow

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## Getting Started

1. Launch the app
2. Tap **+** to add your first task
3. Enter title, description, select due date and priority
4. Tap **Save**
5. Use filter chips to switch between All/Active/Done
6. Tap sort icon to sort by due date or priority
7. Swipe left to delete a task
8. Tap checkbox to mark complete
9. Tap task to edit
10. Use search icon to find tasks by title

## Requirements Checklist

- [x] Task List
- [x] Add Task
- [x] Edit Task
- [x] Delete Task (swipe-to-delete)
- [x] Complete Task (checkbox toggle)
- [x] Local Database (SQLite)
- [x] Riverpod (state management)
- [x] Repository Pattern
- [x] Filtering (All / Active / Completed)
- [x] Sorting (Due Date / Priority)
- [x] Dark Mode
- [x] Search
- [x] Notifications
- [x] Undo Delete
- [x] Testing
- [x] README
