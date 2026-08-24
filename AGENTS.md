# Sakuin (索引) — Agent Instruction File

Flutter personal finance tracker with Clean Architecture, Riverpod 2.x, Drift database, and local-first design.
Dual wallet system (Physical + Digital with sub-wallets per e-wallet provider). PennywiseAI-inspired UI.

---

## Commands

### Core Workflow
```bash
# Get dependencies
flutter pub get

# Generate Drift DB code (REQUIRED after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test

# Lint (print() is ERROR-level)
flutter analyze
```

### Order Matters
1. Schema changes → `build_runner build` → restart app
2. Drift generates `.g.dart` files — never edit manually

---

## Architecture

### Feature Structure (MANDATORY)
```
lib/features/<feature>/
├── data/          # Repositories (Drift DB ops ONLY)
├── domain/        # Entities, repository interfaces, use cases
├── presentation/  # Screens, widgets (UI only)
├── providers/     # Riverpod providers
└── services/      # External API calls, non-DB logic
```

### Dependency Rules
- **Presentation** → never imports `data/` directly (use `providers/`)
- **Domain** → pure Dart, no Flutter/external packages
- **Repositories** → Drift DB operations ONLY
- **Services** → API calls, AI, parsing (NOT DB queries)

### Service vs Repository
| Layer | Handles | Does NOT Handle |
|-------|---------|-----------------| 
| **Service** | Text parsing, ML inference, OCR, orchestration | Database queries |
| **Repository** | Drift CRUD, local DB queries | API calls |

**CRITICAL:** Services WAJIB return **structured data types** (class/model), BUKAN raw `Map<String, dynamic>` atau JSON maps.

```dart
// ✅ Correct — structured type
class TextParserService {
  Future<ParsedTransaction?> parseTransactionText({
    required String inputText,
    required List<WalletInfo> wallets,
  }) async {
    // ML pipeline: TFLite → Naive Bayes → Regex
    return ParsedTransaction(amount: parsedAmount, category: parsedCategory);
  }
}

// ❌ Wrong — raw map
Future<Map<String, dynamic>> parseTransaction(String text) async {
  return jsonDecode(response.text); // Not type-safe!
}
```

---

## Riverpod Patterns

### Provider Types (Use Correct One)
```dart
// ✅ Sync state with mutations
NotifierProvider<WalletNotifier, WalletState>

// ✅ Async state with mutations (load + mutate)
AsyncNotifierProvider<TransactionNotifier, List<Transaction>>

// ✅ Read-only async data
FutureProvider.autoDispose<List<Transaction>>

// ✅ Realtime streams
StreamProvider.autoDispose<double>

// ✅ Simple primitives only
StateProvider<int>
```

### BANNED Providers
- ❌ `StateNotifierProvider` — deprecated in Riverpod 2.x (use `NotifierProvider`)
- ❌ `ChangeNotifierProvider` — incompatible with Riverpod immutability

### Migration Pattern (StateNotifier → Notifier)
```dart
// ❌ OLD (deprecated)
class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;
  WalletNotifier(this._repo) : super(WalletState.initial());
}

// ✅ NEW (Riverpod 2.x)
class WalletNotifier extends Notifier<WalletState> {
  @override
  WalletState build() {
    return WalletState.initial();
  }
  
  Future<void> loadWallets() async {
    final repo = ref.read(walletRepositoryProvider);
    // ...
  }
}

final walletNotifierProvider = NotifierProvider<WalletNotifier, WalletState>(() {
  return WalletNotifier();
});
```

### Rules
- Use `ref.watch` in `build()`, `ref.read` in callbacks
- Never `ref.watch` inside `onPressed` or async functions
- Use `.autoDispose` for non-global providers
- Family providers for parameterized queries

---

## Drift Database

### DAO Pattern (MANDATORY)
```dart
@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Stream<List<Transaction>> watchRecent(int limit) {
    return (select(transactions)..limit(limit)).watch();
  }

  Future<List<Transaction>> getByWallet(int walletId) {
    return (select(transactions)..where((t) => t.walletId.equals(walletId))).get();
  }
}
```

### Schema Migrations
- Increment `schemaVersion` for every schema change
- Add migration step in `onUpgrade` with `if (from < N)` guard
- Never modify existing migration steps (add new ones only)
- Backup data WAJIB before destructive migrations (drop table/column)

### After Schema Changes
```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## Domain Layer Interfaces

### Abstract Repository Pattern (MANDATORY)
```dart
// domain/wallet_repository_interface.dart
abstract class WalletRepositoryInterface {
  Future<List<WalletModel>> getWallets();
  Future<void> createWallet(WalletModel wallet);
  Stream<List<WalletModel>> watchWallets();
}

// data/wallet_repository.dart
class WalletRepository implements WalletRepositoryInterface {
  final AppDatabase _db;
  WalletRepository(this._db);

  @override
  Future<List<WalletModel>> getWallets() => _db.walletDao.getAll();
}

// Provider MUST use abstract interface type
final walletRepositoryProvider = Provider<WalletRepositoryInterface>((ref) {
  final db = ref.watch(databaseProvider);
  return WalletRepository(db);
});
```

---

## Error Handling

### Result Pattern (MANDATORY for expected failures)
```dart
sealed class Result<T, E> {
  const Result();
}
final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}
final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}
```

| Situation | Action |
|-----------|--------|
| Not found, validation error, parse failure | `return Failure(...)` |
| Out of memory, corrupted DB, null assertion | `rethrow` (bug) |

---

## Sakuin Domain — Dual Wallet System

### Wallet Hierarchy
```
Wallets
├── Physical (root, wallet_type: 'physical')
│   └── [balance = cash on hand]
└── Digital (root, wallet_type: 'digital')
    ├── GoPay (sub-wallet, provider: 'gopay')
    ├── OVO (sub-wallet, provider: 'ovo')
    ├── Dana (sub-wallet, provider: 'dana')
    └── ShopeePay (sub-wallet, provider: 'shopeepay')
```

### Rules
- Two root wallets created on first launch: Physical + Digital
- Sub-wallets have `parent_id` pointing to Digital root
- Physical wallet has no sub-wallets (always 1 root)
- Transfer between wallets = 2 transactions (debit + credit)

### Indonesian Financial Infrastructure
- **Currency format**: `Rp 50.000` (titik pemisah ribuan, tanpa desimal)
- **Shorthand parsing**: `"25rb"` → 25000, `"1.5jt"` → 1500000, `"500k"` → 500000
- **Default categories**: Indonesian context (Pulsa, Ojol, Warung, Kos, BBM)

---

## Theming (PennywiseAI-inspired)

### Rules
- Always use `Theme.of(context).colorScheme` (never hardcode colors)
- Cards use flat fill, NO elevation/shadows (except Smart Input Bar)
- Border radius: 16-20dp for cards
- AppBar: transparent, no elevation

### Key Colors
- Light background: `#FFF8F0` (warm cream), surface: `#FFF1E6`, primary: `#6B5CE7`
- Dark background: `#0D0D1A` (deep navy), surface: `#1A1A2E`, primary: `#8B7CF7`
- Income: green, Expense: red (universal convention)

---

## Smart Input System

### Three Entry Points
1. **Smart Input Bar** (sticky above bottom nav) → AI text parsing path
2. **FAB "+"** (floating above input bar) → manual numpad path
3. **Correction** → edit AI-parsed fields in expanded sheet

### Text Parser Pipeline
```
User text → TFLite NLP (Level 3)
           → Naive Bayes (Level 2, fallback)
           → Indonesian Regex (Level 1, fallback)
           → ParsedTransaction
```

---

## Animation
- Duration: **200-400ms**, curve: `Curves.easeOutCubic`
- Loading: **Shimmer**, not generic spinner
- Lottie for complex animations (empty states, celebrations)
- `flutter_animate` for micro-interactions and list stagger

---

## Security
- Financial data in Drift ONLY (not SharedPreferences)
- No logging of sensitive data (amounts, account numbers)
- Validate input amounts (no negative, max limit)
- No auth — fully local, no accounts

---

## Localization
- ALL strings use `.tr()` from easy_localization
- English PRIMARY, Indonesian secondary
- Files: `assets/translations/en.json`, `assets/translations/id.json`
- Never hardcode strings in any language

---

## Code Style

### Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (NOT SCREAMING_CASE)
- Providers: `camelCase` + `Provider` suffix

### Widget Rules
- Prefer `const` constructors
- Extract widgets > 80 lines to separate file
- Use `ConsumerWidget` / `ConsumerStatefulWidget`
- Never nest > 5 levels

---

## Quirks & Gotchas
- `print()` is ERROR — use `debugPrint()`
- Generated `.g.dart` files — never edit manually
- Deep link scheme: `sakuin://`

---

## Performance
- `const` widgets, `ListView.builder`, `.autoDispose` providers
- Use `select` to avoid full rebuilds

---

## AG Kit Workflows

Symlink: `.agent/ → D:\Coding\AG-Kit\.agent` (Junction active)

- `/plan` — Project planning
- `/verify` — Validate code changes
- `/create` — Scaffold components
- `/debug` — Systematic debugging
- `/status` — Current status
- `/enhance` — Update features
- `/orchestrate` — Multi-agent coordination
- `/remember` — Persist to memory

---

## Verification Checklist (Before "Done")

- [ ] `flutter analyze` passes
- [ ] `build_runner build` if schema changed
- [ ] No `print()` (use `debugPrint`)
- [ ] No hardcoded colors (use `Theme.of(context)`)
- [ ] All strings use `.tr()`
- [ ] Repositories implement abstract interfaces
- [ ] No `StateNotifierProvider` or `ChangeNotifierProvider`
- [ ] Services return structured types
- [ ] Currency uses `RupiahFormatter`
- [ ] Tests pass for critical paths

---

## Agent skills

### Issue tracker

Issues live as GitHub issues via `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles with default strings (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context layout (one `CONTEXT.md` + `docs/adr/` at root). See `docs/agents/domain.md`.
