# Implementation Plan — Sakuin P1 (4 Fitur Berurutan)

> **Mode:** PLANNING ONLY (no code). Strategic advisor: @oracle.
> **Target:** `D:\Coding\Sakuin` — Flutter + Clean Architecture + Riverpod 2.x + Drift.
> **Convention:** GEMINI Plan Mode (Phase 1 ANALYSIS → 2 PLANNING → 3 SOLUTIONING → 4 IMPLEMENTATION).

---

## HEADER

### Tujuan
Lanjutkan dari MVP (P0 = 100% done) dengan 4 fitur P1 yang berjalan **berurutan** sesuai prioritas USER:
1. **Smart Rules Engine** — Auto + Manual (belajar dari history Naive Bayes + custom rule if-merchant-then-category)
2. **Export/Import** — CSV + JSON full backup/restore (transaksi, wallet, budget, kategori, + smart_rules)
3. **Activity Heatmap** — GitHub-style transaction density grid (perluas skeleton existing)
4. **Subscription Detection** — deteksi langganan berulang (tagihan bulanan)

### Scope (IN)
- Smart Rules: tabel `SmartRules` sudah ada di `tables.dart` (belum ada DAO/repo/UI) → tambah DAO + model + repo + evaluator service + learning service + UI.
- Export/Import: service + repo baru, full serialize/deserialize, file picker.
- Heatmap: perbaiki bug skeleton (pakai `recentTransactionsProvider` limit 20 untuk grid 98 hari) → provider dedicated + grid 52 minggu + tooltip.
- Subscription: tabel baru `Subscriptions` (schemaVersion 1→2) + detector service + UI.

### Scope (OUT / Non-Goals)
- Tidak ubah dual-wallet core, tidak ubah parser NLP 3-tier (hanya *hook* evaluator ke pipeline).
- Tidak ada auth/cloud sync (tetap local-first). Export hanya ke file lokal.
- Tidak ada recurring auto-transaction scheduler (P1 hanya deteksi + konfirmasi, bukan auto-create tx).
- Tidak ada perubahan schema untuk fitur selain `Subscriptions`.

### Dependencies
- `drift`, `drift_flutter` (sudah ada) — butuh `build_runner build` tiap kali DAO/table berubah.
- **Baru:** `file_picker` (untuk Export/Import file). Tambah ke `pubspec.yaml`.
- `easy_localization` (sudah ada) — tambah key `en.json` + `id.json`.
- `intl` (sudah ada) — `RupiahFormatter` untuk tooltip heatmap & subscription amount.
- `flutter_riverpod` 2.x (sudah ada) — NotifierProvider / AsyncNotifierProvider / StreamProvider.

---

## PHASE 1 — ANALYSIS

### Research & Current State (hasil recon)
- `lib/core/database/tables.dart:75-85` — tabel `SmartRules` SUDAH ADA (`conditions` JSON, `actionType` 'categorize'|'tag'|'wallet', `actionValue` JSON, `priority`). **Tidak masuk `daos:` list** (`app_database.dart:16`) → butuh tambah `SmartRuleDao` + `build_runner`.
- `lib/features/home/presentation/widgets/activity_heatmap_widget.dart` — skeleton 14 minggu, tapi `ref.watch(recentTransactionsProvider)` (limit 20, `transaction_providers.dart:14`) → **BUG**: grid 98 hari tapi data cuma 20 tx terbaru. Perlu provider dedicated.
- `lib/services/ml/naive_bayes_classifier.dart` — NB sudah trained; bisa di-reuse untuk auto-learning (frekuensi merchant→category).
- `lib/services/ml/text_parser_service.dart` — titik hook evaluator (Level 4, setelah NB).
- `lib/core/database/daos/transaction_dao.dart` — punya `getByDateRange`/`watchByDateRange` (cocok untuk heatmap & subscription scan).
- `lib/core/utils/result.dart` — `Result<T,E>` + `AppError` (database/validation/parse) sudah siap pakai.
- `lib/core/utils/currency_formatter.dart:73` — `RupiahFormatter.format/compact` tersedia.
- `schemaVersion = 1` (`app_database.dart:22`) — naik ke 2 hanya untuk tabel `Subscriptions`.

### Open Questions (sudah dijawab di Socratic Gate)
- Auto + Manual rule? → **YA** (auto-learn dari history + user custom).
- CSV + JSON full? → **YA** (full backup restore, bukan partial).
- Urutan? → **4 berurutan** (Smart Rules → Export → Heatmap → Subscription).

### Blast Radius per Fitur
| Fitur | File disentuh | Risiko schema | Risiko runtime |
|-------|---------------|---------------|----------------|
| Smart Rules | `app_database.dart` (daos list), `daos/smart_rule_dao.dart` (baru), `features/smart_rules/*` (baru), `text_parser_service.dart` (hook), `app_router.dart` (route) | Rendah (tabel sudah ada) | Sedang (evaluator di pipeline parse) |
| Export/Import | `services/export/*` (baru), `features/settings` (UI), `pubspec.yaml` | None | Sedang (restore overwrite) |
| Heatmap | `widgets/activity_heatmap_widget.dart` (edit), `transaction_providers.dart` (provider baru), `daos/transaction_dao.dart` (query baru) | None | Rendah |
| Subscription | `tables.dart` (tabel baru), `app_database.dart` (schemaVersion 2 + onUpgrade), `daos/subscription_dao.dart` (baru), `features/subscriptions/*` (baru), `app_router.dart` | Tinggi (migrasi v1→v2) | Sedang |

---

## PHASE 2 — PLANNING (Task Breakdown + Estimasi)

### Fitur 1: Smart Rules Engine
**Task & File:**
- T1. `lib/features/smart_rules/domain/smart_rule_model.dart` — `SmartRuleModel`, `RuleCondition` (field/op/value), `RuleAction` (type/value). Kondisi JSON ↔ model (serialize/deserialize).
- T2. `lib/core/database/daos/smart_rule_dao.dart` — `SmartRuleDao`: `watchAll()`, `getActive()`, `getById()`, `insertRule()`, `updateRule()`, `deleteRule()`, `getByPriority()`. Daftarkan di `app_database.dart:16` → **build_runner**.
- T3. `lib/features/smart_rules/domain/smart_rule_repository_interface.dart` + `lib/features/smart_rules/data/smart_rule_repository.dart` — Drift ONLY.
- T4. `lib/services/ml/smart_rule_evaluator_service.dart` — `evaluate(TransactionLike)` → `RuleAction?` (pure logic, structured type). Evaluasi aktif by priority.
- T5. `lib/services/ml/smart_rule_learning_service.dart` — scan tx history → frekuensi merchant→category → generate rule auto di atas threshold (simpan via repo).
- T6. `lib/features/smart_rules/providers/smart_rule_providers.dart` — `smartRulesNotifierProvider` (NotifierProvider: CRUD + toggle), `smartRuleEvaluationProvider` (family, panggil evaluator).
- T7. Hook evaluator ke `text_parser_service.dart` (Level 4) + `quick_entry_sheet.dart` (sebelum insert).
- T8. `lib/features/smart_rules/presentation/smart_rules_screen.dart` + `rule_editor_sheet.dart` — list + add/edit rule (condition builder + action picker).
- T9. Route `/smart-rules` di `app_router.dart`; entry dari Settings.
- **Estimasi:** 3–4 hari.

### Fitur 2: Export / Import
**Task & File:**
- T1. `pubspec.yaml` — tambah `file_picker`.
- T2. `lib/services/export/export_model.dart` — `ExportBundle` (wallets, categories, transactions, budgets, smartRules), `ImportResult`.
- T3. `lib/services/export/export_service.dart` — `toCsv()`, `toJson()` → `ExportBundle` (structured, bukan Map mentah).
- T4. `lib/services/export/import_service.dart` — `parseCsv()`, `parseJson()` → `ImportBundle` + validasi (Result pattern). Deteksi duplikat/id collision.
- T5. `lib/features/settings/domain/backup_repository_interface.dart` + `data/backup_repository.dart` — `exportAll()`, `importAll(ExportBundle)` dalam 1 transaction Drift; full restore = replace (dengan konfirmasi UI).
- T6. `lib/features/settings/providers/export_import_provider.dart` — `exportImportNotifierProvider` (NotifierProvider: pick file, export, import, progress state).
- T7. UI di `settings_screen.dart` — tombol Export CSV / Export JSON / Import + dialog konfirmasi overwrite + progress (Shimmer).
- **Estimasi:** 2.5–3.5 hari.

### Fitur 3: Activity Heatmap
**Task & File:**
- T1. `lib/features/transactions/providers/transaction_providers.dart` — `heatmapTransactionsProvider` (StreamProvider.autoDispose) query `getByDateRange(now-52w, now)`.
- T2. `lib/features/home/providers/heatmap_data_provider.dart` (atau di transaction_providers) — agregasi `Map<DateTime, HeatmapDay>` (date, totalAmount, count, intensity 0–4). Pure function `aggregateHeatmap()`.
- T3. Edit `activity_heatmap_widget.dart` — perluas ke **52 minggu**, tambah baris label bulan, label hari (S S R K J S M), tap → tooltip (`RupiahFormatter.format` + count + tanggal). Warna via `colorScheme.primary` alpha bucket. Extract `_HeatmapCell` (sudah ada) + `_HeatmapTooltip`.
- T4. Jika >80 baris → pindah ke `lib/features/home/presentation/widgets/activity_heatmap/`.
- **Estimasi:** 1.5–2 hari.

### Fitur 4: Subscription Detection
**Task & File:**
- T1. `lib/core/database/tables.dart` — tabel `Subscriptions` (id, merchant, normalizedKey, amount, period, categoryId nullable, firstSeen, lastSeen, occurrenceCount, confidence, isActive, isConfirmed, createdAt).
- T2. `lib/core/database/app_database.dart` — `schemaVersion = 2`, `onUpgrade` `if (from < 2)` create table `subscriptions` (additive, aman tanpa backup destructive). Daftarkan di `tables:` + `daos:`. **build_runner**.
- T3. `lib/core/database/daos/subscription_dao.dart` — `watchAll()`, `insertSubscription()`, `updateSubscription()`, `upsertByKey()`.
- T4. `lib/services/subscription_detector_service.dart` — scan tx: normalize merchant, tolerance amount ±5%, interval ~30 hari → `List<DetectedSubscription>` (structured). Hitung `nextChargeEstimate`, `confidence`.
- T5. `lib/features/subscriptions/domain/subscription_repository_interface.dart` + `data/subscription_repository.dart`.
- T6. `lib/features/subscriptions/providers/subscription_providers.dart` — `subscriptionsNotifierProvider` (AsyncNotifierProvider: detect + list + confirm/ignore), `detectedSubscriptionsProvider` (FutureProvider).
- T7. `lib/features/subscriptions/presentation/subscriptions_screen.dart` — list detected, konfirmasi/ignore, estimasi tagihan berikutnya.
- T8. Route `/subscriptions` di `app_router.dart`; entry dari Home/Analytics.
- **Estimasi:** 3–4 hari.

---

## PHASE 3 — SOLUTIONING (Arsitektur per Fitur)

### 3.1 Smart Rules Engine
- **Domain model:** `SmartRuleModel { id, name, isActive, List<RuleCondition> conditions, RuleAction action, int priority, DateTime createdAt }`. `RuleCondition { field:'merchant'|'title'|'amount'|'category', op:'contains'|'equals'|'gt'|'lt', String value }`. `RuleAction { type:'categorize'|'tag'|'wallet', String value }`.
- **Repo interface:** `SmartRuleRepositoryInterface { Stream<List<SmartRuleModel>> watchRules(); Future<void> save(SmartRuleModel); Future<void> delete(int id); Future<void> toggle(int id, bool active); }`.
- **DAO methods:** `watchAll`, `getActive`, `getById`, `insertRule(Companion)`, `updateRule`, `deleteRule`, `getByPriority`.
- **Service:** `SmartRuleEvaluatorService.evaluate(TransactionLike input)` → iterasi `getActive()` by priority, match semua condition (AND), return `RuleAction?`. `SmartRuleLearningService.generateFromHistory()` → pakai `NaiveBayesClassifier`-style frequency count di repo tx → insert rule auto (`isActive=true`, `priority` rendah). **Service return structured type, BUKAN Map.**
- **Provider:** `smartRulesNotifierProvider` (NotifierProvider) untuk CRUD UI; `smartRuleEvaluationProvider` (family) dipanggil di parser pipeline.
- **UI:** `smart_rules_screen.dart` (list + toggle) + `rule_editor_sheet.dart` (builder kondisi + action picker kategori/wallet).
- **Localization:** `smartRules.list.title`, `smartRules.add`, `smartRules.condition.merchant`, `smartRules.action.categorize`, `smartRules.autoGenerated`, `smartRules.empty`.
- **Test:** evaluator unit (match/no-match/priority), learning service (frekuensi → rule), repository insert/get.

### 3.2 Export / Import
- **Domain model:** `ExportBundle { List<WalletEntry> wallets; List<CategoryEntry> categories; List<TransactionEntry> transactions; List<BudgetEntry> budgets; List<SmartRuleEntry> smartRules; DateTime exportedAt }`. `ImportResult { int inserted; List<String> warnings; }`.
- **Repo interface:** `BackupRepositoryInterface { Future<ExportBundle> exportAll(); Future<Result<ImportResult, AppError>> importAll(ExportBundle bundle); }`.
- **Service:** `ExportService.toJson(ExportBundle)` / `toCsv(...)`; `ImportService.parseJson(String)` / `parseCsv(String)` → `ImportBundle` + validasi (amount > 0, category/wallet ref valid) → `Result`.
- **Provider:** `exportImportNotifierProvider` (NotifierProvider) — state: idle/exporting/importing/success/error + progress %.
- **UI:** Settings: 3 tombol (Export CSV, Export JSON, Import) + `AlertDialog` konfirmasi overwrite + Shimmer progress. Pakai `file_picker` untuk pilih path (mobile) / `file_selector` fallback.
- **Localization:** `exportImport.exportCsv`, `exportImport.exportJson`, `exportImport.import`, `exportImport.confirmOverwrite`, `exportImport.success`, `exportImport.errorParse`.
- **Test:** CSV round-trip (export→import→equal), JSON round-trip, validasi import rusak.

### 3.3 Activity Heatmap
- **Provider:** `heatmapTransactionsProvider` (StreamProvider.autoDispose) → `repo.getByDateRange(now-364d, now)`. `heatmapDataProvider` (StreamProvider.autoDispose) → `aggregateHeatmap(txList, weeks:52)` → `Map<DateTime, HeatmapDay>`. `HeatmapDay { DateTime date; double total; int count; int intensity; }` intensity bucket: 0=null,1:<50rb,2:<150rb,3:<500rb,4:≥500rb (pakai `RupiahFormatter` untuk label).
- **Widget:** perluas skeleton ke 52 kolom (minggu) × 7 baris (hari), baris label bulan di atas, tap cell → `Tooltip`/`Overlay` showing `RupiahFormatter.format(total)` + `count` + tanggal. Warna: `colorScheme.primary.withValues(alpha: bucket/4)` untuk non-null, `onSurface.withValues(alpha:0.06)` untuk null. **Gunakan `Theme.of(context)`, border radius 16, const constructor.**
- **Localization:** `heatmap.title`, `heatmap.rangeYear`, `heatmap.less`, `heatmap.more`, `heatmap.emptyDay`.
- **Test:** `aggregateHeatmap` pure function (bucket boundary, date bucketing, count).

### 3.4 Subscription Detection
- **Domain model:** `DetectedSubscription { String merchant; String normalizedKey; double amount; String period; int occurrenceCount; DateTime firstSeen; DateTime lastSeen; double confidence; int? categoryId; DateTime nextChargeEstimate }`. `SubscriptionModel` (persisted) mirror tabel.
- **Repo interface:** `SubscriptionRepositoryInterface { Stream<List<SubscriptionModel>> watchSubscriptions(); Future<void> upsert(SubscriptionModel); Future<void> setConfirmed(int id, bool confirmed); }`.
- **DAO:** `watchAll`, `insertSubscription`, `updateSubscription`, `upsertByKey(normalizedKey,...)`.
- **Service:** `SubscriptionDetectorService.detect(List<TransactionModel>)` → group by `normalizedKey` (lowercase, strip non-alnum), filter amount tolerance ±5%, hitung interval median ~30 (±5) hari → `List<DetectedSubscription>`. Confidence dari occurrenceCount + regularity. **Structured type.**
- **Provider:** `subscriptionsNotifierProvider` (AsyncNotifierProvider) — `detect()` scan via repo tx → upsert confirmed ke table; `detectedSubscriptionsProvider` (FutureProvider) untuk list.
- **UI:** `subscriptions_screen.dart` — list detected (merchant, amount `RupiahFormatter`, period, next charge, confidence badge), aksi Confirm/Ignore (Ignore → jangan simpan / set isActive=false).
- **Localization:** `subscription.list.title`, `subscription.detected`, `subscription.confirm`, `subscription.ignore`, `subscription.nextCharge`, `subscription.empty`, `subscription.monthly`.
- **Test:** detector grouping (interval detection, tolerance, false-positive filter), nextChargeEstimate.

### Dependency Graph
```
Smart Rules (DAO + model + repo + evaluator + learning)
   └─> Export/Import (baca SmartRules via SmartRuleDao)   [lane A]
Heatmap (tx only)                                          [lane B, paralel]
Subscription (tx + categories + tabel baru)                [lane B, paralel]
```
- Lane A harus urut: Smart Rules → Export (Export butuh SmartRuleDao).
- Lane B (Heatmap, Subscription) tidak bergantung Smart Rules → bisa paralel dengan Lane A setelah DAO tx existing dipakai.
- Subscription butuh migrasi v2 → lakukan terakhir di lane B (risiko tertinggi).

### Risiko & Mitigasi
| Risiko | Mitigasi |
|--------|----------|
| Evaluator di pipeline parse melambat UI | Jalankan async, cache `getActive()` di provider, short-circuit bila tidak ada rule aktif |
| Import overwrite data user | Dialog konfirmasi wajib + opsi "backup dulu" (export otomatis sebelum import) |
| Migrasi v1→v2 gagal di device lama | `onUpgrade` hanya additive (create table), tidak drop; test di fresh + existing DB |
| Heatmap 52 minggu berat | Stream + agregasi di provider (bukan rebuild widget), `const` cell, `.autoDispose` |
| False-positive subscription (1x belanja) | Threshold occurrenceCount ≥ 2 + interval regular + confidence gate sebelum tampil |
| `print()` lolos | Gunakan `debugPrint`; `flutter analyze` jadikan ERROR gate |

### Verification Strategy
- `flutter analyze` → 0 error (print = error).
- `dart run build_runner build --delete-conflicting-outputs` setelah tiap perubahan DAO/table.
- `flutter test` → coverage tiap fitur (lihat Test per fitur di atas).
- Manual: restore CSV↔JSON round-trip; heatmap tap tooltip; subscription confirm/ignore persist.

---

## PHASE 4 — IMPLEMENTATION (Urutan Eksekusi)

### Suggested Sequence (USER: 4 berurutan)
1. **Smart Rules Engine** — fondasi (DAO, evaluator, learning, UI).
2. **Export / Import** — manfaatkan SmartRuleDao dari step 1.
3. **Activity Heatmap** — perbaiki bug skeleton + provider dedicated.
4. **Subscription Detection** — tabel baru + migrasi v2 + detector + UI.

### Parallelizable Lanes (optimasi, optional)
- **Lane A:** Step 1 → Step 2 (sequential, Export butuh SmartRuleDao).
- **Lane B:** Step 3 (Heatmap) + Step 4 (Subscription) bisa dikerjakan paralel dengan Lane A karena hanya butuh `TransactionDao` existing. Subscription (step 4) ditutup terakhir karena migrasi.

### Definition of Done per Phase
- **Smart Rules:** rule manual CRUD jalan; auto-learn generate rule dari history; evaluator ter-hook di parser & quick-entry; `flutter analyze` clean; 3 test lolos.
- **Export/Import:** Export CSV + JSON menghasilkan file valid; Import restore identik; konfirmasi overwrite; 3 test round-trip lolos.
- **Heatmap:** grid 52 minggu realtime dari `heatmapDataProvider`; tooltip tap benar; tidak pakai `recentTransactionsProvider`; 1 test agregasi lolos.
- **Subscription:** deteksi jalan; confirm/ignore persist (tabel v2); next charge tampil; migrasi v1→v2 aman; 2 test lolos.

### Rollout Plan
- Branch per fitur (`feat/smart-rules`, `feat/export-import`, `feat/heatmap`, `feat/subscription`).
- Setelah masing-masing DoD: `build_runner` + `flutter analyze` + `flutter test` → merge ke `develop`.
- Sebelum rilis: regression test restore backup + migrasi dari APK lama (v1 DB).
- **JANGAN** edit `.g.dart` manual; selalu `build_runner`.

---

## VERIFICATION CHECKLIST (AGENTS.md)
- [ ] `flutter analyze` passes (0 error, print = error)
- [ ] `build_runner build` dijalankan jika schema/DAO berubah
- [ ] Tidak ada `print()` (pakai `debugPrint`)
- [ ] Tidak ada hardcoded color (pakai `Theme.of(context).colorScheme`)
- [ ] Semua string pakai `.tr()` (tambah ke `en.json` + `id.json`)
- [ ] Repository implement abstract interface (`*RepositoryInterface`)
- [ ] Tidak ada `StateNotifierProvider` / `ChangeNotifierProvider` (pakai Notifier/AsyncNotifier)
- [ ] Service return structured type (bukan `Map<String,dynamic>`)
- [ ] Currency pakai `RupiahFormatter`
- [ ] Tests pass untuk critical path tiap fitur
- [ ] Migration `onUpgrade` pakai guard `if (from < N)` (khusus Subscription v2)
