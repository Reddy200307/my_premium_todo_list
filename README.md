# My Rememberings 📝

A premium, modern To-Do list application built for Windows using Flutter. 

Designed with a focus on aesthetics and native integration, this app features a glassmorphic UI (Acrylic effects), smooth animations, and a hierarchical group-task structure to keep your day organized.

![App Banner](screenshots/Screenshot1.png)

## ✨ Features

* **Modern Desktop UI:** Features Windows Acrylic transparency, custom gradients, and the **DM Sans** typeface for a clean, premium look.
* **Group Management:** Organize tasks into distinct groups (e.g., Work, Personal, Shopping).
* **Smart Due Dates:**
    * 📅 **Calendar Integration:** Pick due dates easily.
    * 🔴 **Overdue:** Highlights missed tasks in Red.
    * 🟠 **Today:** Highlights urgent tasks in Orange.
    * 🔵 **Upcoming:** Standard blue for future tasks.
* **Task Lifecycle:** Add, Edit, Toggle (Complete/Incomplete), and Delete tasks with animations.
* **Persistence:** Auto-saves all data locally using `SharedPreferences`. No internet required.
* **Split-View Interface:** Responsive sidebar for groups and a main area for tasks.

## 📸 Screenshots

| Dashboard View | Add Task / Edit |
|:---:|:---:|
| ![Dashboard](screenshots/Screenshot1.png) |
| *View your groups and tasks* | *Intuitive dialogs for management* |

## 🛠️ Tech Stack & Dependencies

This project is built using **Flutter 3.x** targeting **Windows Desktop**.

* **Language:** Dart
* **State Management:** `setState` (Optimized for local widget trees)
* **Persistence:** [`shared_preferences`](https://pub.dev/packages/shared_preferences) (JSON serialization)
* **Window Effects:** [`flutter_acrylic`](https://pub.dev/packages/flutter_acrylic) (For Windows 10/11 transparency)
* **Date Formatting:** [`intl`](https://pub.dev/packages/intl)
* **Typography:** Google Fonts (DM Sans)

## 🚀 Getting Started

### Prerequisites

* **Flutter SDK:** [Install Flutter](https://docs.flutter.dev/get-started/install/windows)
* **Visual Studio 2022:** With the "Desktop development with C++" workload installed.

### Installation

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/Reddy200307/my_premium_todo_list](https://github.com/Reddy200307/my_premium_todo_list)
    cd my_premium_todo_list
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the app:**
    ```bash
    flutter run -d windows
    ```

## 🏗️ Project Structure

```text
lib/
├── main.dart             # Entry point and Main UI Logic
└── fonts/                # Custom DM Sans font assets
windows/                  # Windows-specific runner code
screenshots/              # Images for README