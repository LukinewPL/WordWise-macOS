# 📚 WordWise

[![Build Status](https://github.com/lukinew/WordWise/actions/workflows/build.yml/badge.svg)](https://github.com/lukinew/WordWise/actions/workflows/build.yml) 
![Swift 6](https://img.shields.io/badge/Swift-6.0-orange) 
![macOS 15+](https://img.shields.io/badge/macOS-15+-blue) 
![License](https://img.shields.io/badge/License-BSL--1.1-red)

**Learn languages naturally using spaced repetition.**  
**Ucz się języków w naturalny sposób, wykorzystując system powtórek w odstępach.**

---

## 📸 Screenshots

*(Animated GIF placeholder: App gameplay showing glassmorphism and liquid animations)*

---

## ✨ Features

- 🔥 **SM-2 Spaced Repetition**: Intelligent algorithm that maximizes long-term memory retention.
- ⚡ **Multiple Study Modes**:
  - **Standard Study**: Classic flashcard input for steady learning.
  - **Speed Round**: Test your reflexes and knowledge under pressure.
  - **Test Mode**: Simulates a real test environment with multiple choice and written answers.
- 📥 **XLSX & TXT Import**: Seamlessly import your word sets from Excel spreadsheets or plain text files.
- 🧪 **Liquid Glass UI**: Beautiful, modern "glassmorphism" design with smooth liquid animations.
- 📅 **Streak Tracking**: Maintain your daily learning habit with visual progress indicators.
- 🗺️ **Activity Heatmap**: Visualize your progress over the last year.
- 🌐 **Multilingual**: Professionally localized in English and Polish with support for easy expansion.

---

## 🔥 How Streaks Work

WordWise is designed to help you build a consistent learning habit:

1. **Daily Goal**: Complete at least one study session every day to increment your streak.
2. **Persistence**: Your streak increases by 1 for each consecutive day you use the app.
3. **Reset**: If you skip a day, the fire icon 🔥 resets to 0. Use it as motivation to keep going!
4. **Heatmap**: The activity section shows exactly when you studied, with darker cells representing more intense study days.

---

## 🛠 Architecture

- **`WordWiseApp.swift`**: Main entry point and environment injection.
- **`Models/`**: SwiftData models for `Word`, `WordSet`, and `StudySession`.
- **`Engine/`**: Core logic for SM-2 (`SM2Engine`) and data import (`ImportEngine`).
- **`Utilities/`**: Design tokens, glass effects, and `LanguageManager`.
- **`Views/`**: All UI components organized by feature.
- **`Resources/`**: Assets and localization JSON files.

---

## 🚀 How to Build & Run

1. **Clone the repository**:
   ```bash
   git clone https://github.com/lukinew/WordWise.git
   ```
2. **Open the project**: Open `WordWise.xcodeproj` in Xcode 16+.
3. **Select Destination**: Choose "My Mac" as the target.
4. **Run**: Press `Cmd + R` to build and run the application.

---

## 🌍 How to Add a New Language

1. Create a new JSON file in `WordWise/Resources/Languages/` (e.g., `de.json`).
2. Follow the existing structure (see `en.json`).
3. Add the file to the **WordWise** target in Xcode.
4. Ensure it's included in the "Copy Bundle Resources" build phase.
5. The language will appear automatically in the app settings!

---

## ⚖️ License

WordWise is licensed under the **Business Source License 1.1 (BSL-1.1)** until **January 1, 2029**.

- **You MAY**: Use the compiled application for free for personal use.
- **You MAY NOT**: Copy, modify, redistribute, or use the source code for commercial purposes.
- **Future Change**: On 2029-01-01, the license converts to **MIT**, making it fully open-source.

---

## 🤝 Contributing

Bug reports and feature suggestions are welcome via GitHub Issues. Pull requests are currently not being accepted due to the BSL license restrictions.
