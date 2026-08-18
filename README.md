# Sakuin (索引)

Flutter personal finance tracker with Clean Architecture, Riverpod 2.x, Drift database, and local-first design. Inspired by PennywiseAI UI aesthetics, tailored for Indonesian financial habits.

---

## 🌟 Key Features

- **Dual Wallet System**:
  - **Physical Wallet**: Cash on hand management.
  - **Digital Wallet**: Sub-wallets per e-wallet provider (GoPay, OVO, DANA, ShopeePay, Bank accounts).
- **Smart Input System**:
  - Quick natural language text parser (Indonesian currency formats, shorthand like `25rb`, `1.5jt`, `500k`).
  - Manual keypad entry & AI correction sheet.
- **Local-First & Secure**:
  - Drift ORM SQLite local database.
  - Zero cloud dependency, no account registration required.
- **Modern PennywiseAI UI**:
  - Clean cards, smooth animations, warm cream/deep navy themes.
  - Bilingual localization (`easy_localization`: ID / EN).

---

## 🏗️ Architecture & Tech Stack

- **Framework**: Flutter 3.x / Dart 3.x
- **State Management**: Riverpod 2.x (`NotifierProvider`, `AsyncNotifierProvider`)
- **Database**: Drift ORM (DAO Pattern, Reactive Streams)
- **Localization**: `easy_localization`
- **Formatting**: `intl` (Indonesian Rupiah formatting)

---

## 📁 Project Structure

```text
lib/
├── core/                  # Design system, theme, database, utils, constants
├── features/
│   ├── dashboard/         # Overview, balance cards, recent transactions
│   ├── transactions/      # Transaction CRUD, history, parser
│   ├── wallets/           # Dual wallet hierarchy & management
│   ├── smart_input/       # AI & regex-based text input system
│   └── settings/          # Currency, locale, theme, backup
└── main.dart
```

---

## 📚 Documentation

Detailed specifications and architectural guides are available in `/docs`:
- [Architecture & Standards](docs/ARCHITECTURE.md)
- [Product Requirements (PRD)](docs/PRD.md)
- [Design Guidelines](docs/DESIGN.md)
- [Security & Privacy](docs/SECURITY.md)
- [Testing Guide](docs/TESTING.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

---

## 🚀 Getting Started

1. **Clone & setup dependencies**:
   ```bash
   flutter pub get
   ```

2. **Generate Drift Database code**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run the app**:
   ```bash
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```
