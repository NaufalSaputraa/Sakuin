# Sakuin (索引) — Testing Strategy & Quality Assurance

> Test pyramid, test coverage standards, and automated validation suite.

---

## 1. Testing Pyramid

```
                ▲
               / \
              /   \
             / E2E \       <-- Integration Tests (critical journeys)
            /-------\
           / Widget  \     <-- Presentation & BottomSheet UI tests
          /-----------\
         /  Unit Tests \   <-- Parsers, Domain Entities, Repositories, DAOs
        /---------------\
```

---

## 2. Test Suites by Layer

### 2.1 Unit Testing (Priority 1)
- **Indonesian Currency & Shorthand Parsing**:
  - Test `IndonesianAmountParser` across `25rb` (25000), `1.5jt` (1500000), `500k` (500000), `Rp 50.000` (50000).
- **Text Parser Pipeline**:
  - Test multi-intent sentences: `"beli kopi 25rb gopay"`, `"transfer 100k ke fisik"`, `"gaji freelance 2jt"`.
- **Drift DAOs (In-Memory SQLite)**:
  - Test CRUD operations, balance calculation queries, and stream emissions with `NativeDatabase.memory()`.

### 2.2 Widget & Presentation Testing (Priority 2)
- **Smart Input Bar**: Tap interaction, text change triggers, mic icon rendering.
- **Quick Entry Bottom Sheet**: Numpad key taps, category chip selection, wallet pill active states.
- **Theme Consistency**: Verification that colors match active `ColorScheme` without hardcoded leaks.

### 2.3 Integration Tests (Priority 3)
- Complete transaction lifecycle: Open app → Type shorthand in smart bar → Confirm → Verify balance deduction and transaction list update.

---

## 3. Automated Validation Commands

```bash
# 1. Lint and Static Analysis
flutter analyze

# 2. Run All Unit & Widget Tests
flutter test

# 3. Drift Code Generation Verification
dart run build_runner build --delete-conflicting-outputs

# 4. AG-Kit Core Validation Script
python .agent/scripts/checklist.py .
```
