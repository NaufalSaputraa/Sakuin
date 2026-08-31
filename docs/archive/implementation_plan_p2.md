# Sakuin P2 — Implementation Plan (PLANNING ONLY)

> Mode: **GEMINI Plan Mode (4-phase)**. Dokumen ini PLANNING ONLY — tidak ada code implementasi.
> Baseline: P1 DONE & PUSHED (`421ac08`) — analyze 0 error, 24 tests pass, 544 nodes.
> Keempat fitur **offline 100%** (on-device), tanpa cloud fallback.

---

## HEADER — Tujuan, Scope, Dependencies

### Tujuan
1. **OCR Receipt Full Flow** — kamera → crop → ML Kit → `ParsedTransaction` → auto-fill sheet.
2. **Voice Input** — STT on-device → `ParsedTransaction` (reuse text parser pipeline).
3. **AI Chat LLM Full (Qwen 1.5B Pennywise P2, swappable Gemma 4 E2B)** — LiteRT `.litertlm` lokal mengganti stub rule-based di `AiChatScreen`.
4. **Multi-currency** — currency per wallet/transaction + offline rates + migrasi Drift v2→v3.

### Scope IN
- Camera capture + crop + OCR pipeline (1). On-device STT + permission (2).
- Real LiteRT inference Qwen 1.5B (Pennywise) + UI model-status (3).
- Currency column di Transactions + tabel `currency_rates` offline + converter + UI picker (4).

### Scope OUT
- Cloud LLM/STT/OCR (dilarang). Live camera preview custom (cukup native via image_picker).
- Realtime FX internet (rates offline statis / user-set). iOS target (fokus Android; iOS dicatat risiko).

### Dependencies Baru (pubspec.yaml)
| Package | Versi | Fungsi | Fitur |
|---------|-------|--------|-------|
| `image_cropper` (atau `crop_your_image`) | latest | Crop receipt | 1 |
| `speech_to_text` | ^7.x | On-device STT | 2 |
| `litertlm` | latest | Load/run `.litertlm` model via LiteRT `Engine.fromFile(modelPath)` (Qwen 1.5B Pennywise P2; swappable ke Gemma 4 E2B) | 3 |
| `flutter_downloader` (atau `background_downloader`) | latest | Download model terpisah (pattern DownloadManager) ke `getExternalFilesDir("models")` + progress/retry | 3 |
| `flutter_tts` (OPSIONAL) | ^4.x | On-device TTS output | 3 |
| `google_mlkit_text_recognition` | 0.14.0 (SUDAH ADA) | OCR latin | 1 |

> `camera` package tidak wajib — `image_picker` sudah cover capture. Tambah hanya jika butuh live preview.
> **Model LLM TIDAK dibundle di `assets/`** (hindari APK >1GB). Model diunduh terpisah saat runtime via DownloadManager-style. Metadata unduhan (URL, version, SHA-256, size) **di-pin di `Constants.ModelDownload`** (`lib/core/constants/model_download.dart`), destinasi `getExternalFilesDir("models")`. App tetap fungsional tanpa AI sampai model READY (inspirasi PennywiseAI).
>
> **Model utama P2 = Qwen2.5-1.5B-Instruct-q8-ekv4096.litertlm** (dari R2 Pennywise): URL `https://pub-fcfb3ffddb184540a758a7fe68249908.r2.dev/models/v1/Qwen2.5-1.5B-Instruct-q8-ekv4096.litertlm`, SHA-256 **di-pin dari Pennywise Constants**, size **~1.5GB**.
> **Swappable design**: cukup ganti `Constants.ModelDownload.URL` + `SHA256` + `size` ke Gemma 4 E2B (~2.4GB) tanpa ubah code — karena keduanya `.litertlm` + LiteRT `Engine.fromFile`. Tidak perlu rebuild APK logic.

### Android Permissions (AndroidManifest.xml — BELUM ADA)
- `android.permission.CAMERA` (1). `android.permission.RECORD_AUDIO` (2). Scoped storage handling untuk crop (1).

---

## PHASE 1 — ANALYSIS (Research Current State)

### 1. OCR Receipt Full
- **State**: `lib/services/ocr/receipt_scanner_service.dart` ada. `ImagePicker` + `TextRecognizer(latin)`. `parseReceiptText()` ekstrak merchant, total (regex `total|jumlah|...`), max-amount fallback → `ParsedTransaction`.
- **Gap**: (a) tidak ada crop; (b) tidak ada UI sheet consumer; (c) permission CAMERA belum di-declare; (d) belum diuji device; (e) tidak ada preview sebelum parse.
- **Blast radius**: Service layer (aman). Tambah `camera_service`/crop wrapper + provider + sheet + permission gate. Tidak sentuh DB.

### 2. Voice Input
- **State**: Tidak ada STT dep. `text_parser_service.parseBatchText` sudah map free-text → `ParsedTransaction`. `ParsedTransaction` punya `walletProvider`, `categoryKey`, `amount`.
- **Gap**: (a) `speech_to_text` belum ada; (b) permission mic; (c) streaming transcript → debounce → parse; (d) UI sheet voice.
- **Blast radius**: Service baru + provider + sheet. Reuse `textParserServiceProvider` & `transactionRepositoryProvider`. Risiko DB rendah.

### 3. AI Chat Gemma LLM Full
- **State**: `gemma_llm_service.dart` = **stub** (`generateResponse` hardcoded, `status`/`downloadProgress` hardcode). `AiChatScreen._handleSend` **tidak memanggil** service — pakai if/else rule-based. `formatPrompt()` sudah benar (Gemma turn + inject saldo/income/expense/budget).
- **Inspirasi PennywiseAI** (research @librarian): model Qwen 2.5-1.5B-Instruct (~1.5GB) disimpan di Cloudflare R2, diunduh terpisah via `DownloadManager.enqueue` ke `getExternalFilesDir(DOWNLOADS)`, progress via `DownloadManager.Query` (downloadedMB/totalMB), verifikasi **SHA-256** (`ModelRepository.verifyModelIntegrity()`), space guard 2x model size (~3GB), `StateFlow` NOT_DOWNLOADED→DOWNLOADING→LOADING→READY/ERROR, UI di SettingsScreen, `LlmRepository` gates pada `isModelDownloaded()`.
- **Gap**: (a) `litertlm` (LiteRT) belum ada; (b) model `.litertlm` Qwen 1.5B (~1.5GB) **belum dibundle — harus diunduh terpisah** (Constants.ModelDownload + DownloadManager); (c) `generateResponse` harus async inference nyata dari file eksternal (bukan asset); (d) wiring ke `AiChatScreen`; (e) UI status/indikator download + load progress; (f) `ModelRepository` (state flow, verify SHA-256, finalize) + gate `LlmRepository.isModelDownloaded()`.
- **Blast radius**: Service (ganti impl), `chat_providers`, `ai_chat_screen` (branch conversational), **baru: `model_repository`, `settings_view_model`, SettingsScreen download UI**. DB chat aman. App tetap jalan tanpa AI (fallback rule-based) jika model belum READY.

### 4. Multi-currency
- **State**: `Wallets.currency` (default `'IDR'`) & `WalletModel.currency` SUDAH ada. **`Transactions` table TIDAK punya currency** — amount diasumsi IDR. `schemaVersion=2`, `onUpgrade` hanya `from<2`. `RupiahFormatter` hardcode IDR.
- **Gap**: (a) Transactions butuh `currency` + `amountBase` (ekuivalen IDR saat tx); (b) tabel `currency_rates` offline; (c) converter service; (d) UI picker + wallet currency selector + settings; (e) `CurrencyFormatter` generik; (f) migrasi v2→v3.
- **Blast radius**: TINGGI — tables.dart, app_database (migration), transaction_dao, transaction_model, wallet UI, formatter, semua provider total balance. Audit semua `RupiahFormatter.format`.

### Open Questions (SUDAH DIJAWAB)
- Urutan → **1→2→3→4**. Offline 100% → Ya, tapi **APK tetap kecil (<100MB)**; model LLM (Qwen 1.5B Pennywise) sebagai unduhan terpisah (bukan bundle), swappable ke Gemma 4 E2B. TTS → Opsional (3).

## PHASE 2 — PLANNING (Task Breakdown + File Path + Estimasi)

### Fitur 1: OCR Receipt Full
| Task | File Path | Est |
|------|-----------|-----|
| `image_cropper` + permission CAMERA | `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml` | S |
| `camera_service.dart` (wrap picker + crop) | `lib/services/ocr/camera_service.dart` | M |
| Extend `receipt_scanner_service.dart` (terima path crop → `ParsedTransaction` + previewPath) | `lib/services/ocr/receipt_scanner_service.dart` | M |
| `ReceiptScanNotifier` + state (loading, previewPath, parsed, error) | `lib/features/transactions/providers/receipt_scan_provider.dart` | M |
| `ReceiptScanSheet` UI (kamera→preview→crop→auto-fill `quick_entry_sheet`) | `lib/features/transactions/presentation/receipt_scan_sheet.dart` | L |
| l10n `ocr_*` | `assets/translations/en.json`, `id.json` | S |
| Test `parseReceiptText` sample struk (mock) | `test/services/ocr/receipt_scanner_test.dart` | M |

### Fitur 2: Voice Input
| Task | File Path | Est |
|------|-----------|-----|
| `speech_to_text` + permission RECORD_AUDIO | `pubspec.yaml`, `AndroidManifest.xml` | S |
| `speech_service.dart` (init, listen streaming, stop, permission) | `lib/services/voice/speech_service.dart` | M |
| `VoiceInputNotifier` + state (listening, transcript, parsed, confidence) | `lib/features/transactions/providers/voice_input_provider.dart` | M |
| `VoiceInputSheet` UI (waveform/state) | `lib/features/transactions/presentation/voice_input_sheet.dart` | L |
| l10n `voice_*` | `assets/translations/en.json`, `id.json` | S |
| Test mapping transcript→`ParsedTransaction` (mock STT) | `test/services/voice/speech_service_test.dart` | M |

### Fitur 3: AI Chat Gemma LLM Full (Model = Unduhan Terpisah, bukan bundle)
| Task | File Path | Est |
|------|-----------|-----|
| `Constants.ModelDownload` (URL, version, SHA256, size) + `flutter_downloader` | `lib/core/constants/model_download.dart`, `pubspec.yaml` | S |
| `ModelRepository` (isModelDownloaded, verifyIntegrity/SHA-256, finalizeDownload, `modelState` flow: NOT_DOWNLOADED→DOWNLOADING→LOADING→READY/ERROR, space guard 2x size) | `lib/features/chat/data/model_repository.dart` | L |
| `SettingsViewModel`/Notifier (start/cancel/monitor download via DownloadManager, retry, insufficient-space message) | `lib/features/settings/providers/settings_view_model.dart` | M |
| UI Settings download progress (button Download, progress bar MB/total, retry, pesan insufficient space) | `lib/features/settings/presentation/settings_screen.dart` | M |
| `LlmRepository` gate `isModelDownloaded()` — chat disabled sampai READY | `lib/features/chat/data/llm_repository.dart` | S |
| Ganti `gemma_llm_service.dart` (load via `Interpreter.fromFile(modelPath)`, async `generateResponse`, status/progress nyata) | `lib/services/ml/gemma_llm_service.dart` | L |
| `GemmaChatNotifier` (load model dari external file, infer, streaming token, observe ModelState) | `lib/features/chat/providers/gemma_chat_provider.dart` | M |
| Wire `AiChatScreen` (branch conversational → Gemma; keep action-intent ke text parser; disable input jika !READY) | `lib/features/chat/presentation/ai_chat_screen.dart` | L |
| UI model-status badge + load/progress dialog + fallback hint "download model" | `ai_chat_screen.dart` / widget | M |
| l10n `gemma_*`, `model_download_*` | `assets/translations/en.json`, `id.json` | S |
| Test `formatPrompt` + mock inference + `verifyIntegrity` (hash match/mismatch) | `test/services/ml/gemma_llm_test.dart`, `test/features/chat/model_repository_test.dart` | M |

### Fitur 4: Multi-currency
| Task | File Path | Est |
|------|-----------|-----|
| Tabel `CurrencyRates` + alter `Transactions` (currency, amountBase) | `lib/core/database/tables.dart` | M |
| Migration v2→v3 (`onUpgrade` addColumn + createTable) | `lib/core/database/app_database.dart` | M |
| `CurrencyModel` + `currency_rates_repository` (DAO) | `lib/features/currency/domain`, `data` | M |
| `currency_converter_service.dart` (offline rate → IDR) | `lib/services/currency/currency_converter_service.dart` | M |
| `CurrencyFormatter` (ganti/extend `RupiahFormatter`) | `lib/core/utils/currency_formatter.dart` | M |
| Provider: list currency, rates, convert | `lib/features/currency/providers/currency_providers.dart` | M |
| UI: currency picker di `quick_entry_sheet` + wallet currency selector + settings | `lib/features/transactions/presentation/quick_entry_sheet.dart`, `wallets_screen.dart`, `settings_screen.dart` | L |
| l10n `currency_*` | `assets/translations/en.json`, `id.json` | S |
| Test converter + migration (dummy data) | `test/services/currency`, `test/core/database` | L |

---

## PHASE 3 — SOLUTIONING (Arsitektur, Dependency Graph, Risiko)

### Arsitektur per Fitur
**1. OCR**: `CameraService` (image_picker + `image_cropper`) → file path → `ReceiptScannerService.scanReceipt` (ML Kit `TextRecognizer`) → `parseReceiptText` → `ParsedTransaction` → `ReceiptScanNotifier` → `ReceiptScanSheet` auto-fill `QuickEntrySheet`. Structured type `ParsedTransaction` dijaga (AGENTS.md).

**2. Voice**: `SpeechService` (speech_to_text, streaming) → transcript → debounce → `TextParserService.parseBatchText` → `ParsedTransaction` → `VoiceInputNotifier` → `VoiceInputSheet` → commit via `TransactionRepository`. Reuse pipeline P1 (zero duplikasi ML).

**3. Qwen 1.5B (Pennywise) — LLM Unduhan Terpisah (interface sama untuk Gemma 4 E2B nanti)**: `DownloadManager`/`flutter_downloader` → file di `getExternalFilesDir("models")` → **SHA-256 check** (`ModelRepository.verifyIntegrity`) → `QwenLlmService` (LiteRT `Engine.fromFile(modelPath)` untuk `.litertlm`, **bukan `fromAsset`**, load lazy) → `GemmaChatNotifier` → `AiChatScreen`. `ModelState` flow (`NotifierProvider<ModelNotifier, ModelState>`: NOT_DOWNLOADED→DOWNLOADING→LOADING→READY/ERROR) dipancarkan `ModelRepository`. **Chat disabled sampai READY** (gate `LlmRepository.isModelDownloaded()`); jika model belum diunduh/error, app tetap jalan dengan fallback rule-based (tanpa AI). Error handling: insufficient space (guard 2x model size), hash mismatch (reject + retry). `formatPrompt` sudah inject data riil (saldo/income/expense/budget). **EngineConfig backend cpu/gpu tetap sama** untuk Qwen maupun Gemma 4 E2B — hanya ganti asset URL/model file, tidak ubah inference code.

**4. Multi-currency**: `CurrencyRates` table (code, name, rateToIdr, isBase, updatedAt). `Transactions.currency` + `amountBase` (snapshot ekuivalen IDR). `CurrencyConverterService.convert(amount, from, to)`. Semua aggregator balance pakai `amountBase` untuk total IDR; UI tampil per-currency via `CurrencyFormatter`. Migrasi v2→v3: `m.alterTable(addColumn)` currency/amountBase (default 'IDR'/0) + `m.createTable(currencyRates)` + seed default rates (USD, SGD, EUR, dst, statis).

### Dependency Graph
- Fitur 1 & 2 **independen** — bisa parallel lane.
- Fitur 3 butuh Fitur 2 selesai? Tidak wajib, tapi `AiChatScreen` action-intent reuse `TextParserService` (sudah ada). 3 paralel dengan 1&2 aman.
- Fitur 4 **paling bawah** (dependency tinggi ke formatter & aggregator) — kerjakan terakhir. Urutan eksekusi: **1 → 2 → 3 → 4** (user), tapi 1&2 parallelizable.

### Risiko & Mitigasi
| Risiko | Fitur | Mitigasi |
|--------|-------|----------|
| APK size | 3 | **Bukan lagi 1.4GB** — APK tetap **<100MB** (model di luar bundle). Risiko bergeser ke: (a) user belum download model → chat disabled (fallback rule-based aktif); (b) storage penuh → space guard 2x size + pesan insufficient space; (c) network metered/lambat → progress + cancel/retry; (d) SHA-256 mismatch (corrupt/interupsi) → reject + retry. Mitigasi: UI Settings download jelas, retry, dan pesan error spesifik. |
| Permission CAMERA/RECORD_AUDIO ditolak | 1,2 | Permission gate + fallback gallery/keyboard; UI explainer `.tr()`. |
| LiteRT `.litertlm` model load & memory | 3 | Lazy load via `Engine.fromFile`, unload saat exit, cek `gpuDelegate` opsional; test di device low-RAM. |
| OCR akurasi struk non-standard | 1 | Confidence score di `ParsedTransaction`; user selalu bisa koreksi di sheet (auto-fill, bukan auto-commit). |
| Migrasi v2→v3 corrupt data | 4 | Backup WAJIB sebelum `alterTable` (AGENTS.md); addColumn pakai default aman; test migrasi dengan DB seeded. |
| `RupiahFormatter` tersebar | 4 | Introduce `CurrencyFormatter` + sedikit demi sedikit replace; jangan ubah behavior IDR. |

### Rekomendasi Adaptasi Download Model (Sakuin)
- **Pilihan mekanisme download**: **Gunakan `flutter_downloader`** (wrapper Android `DownloadManager` native + iOS `NSURLSession`, dengan progress/cancel/retry bawaan). Alternatif `background_downloader` jika butuh kontrol lebih (resume, concurrency). **Hindari** `dio`+manual stream untuk background download — `DownloadManager` lebih andal saat app ditutup & otomatis handle notification progress. WorkManager **tidak wajib** untuk download sendiri (DownloadManager sudah persistent); gunakan WorkManager hanya jika perlu trigger post-download verify di luar lifecycle (opsional).
- **Destinasi**: `getExternalFilesDir("models")` (atau `getApplicationDocumentsDirectory` via path_provider di iOS) — otomatis terhapus saat uninstall, tidak masuk backup cloud, tidak bloat APK.
- **Keamanan integritas**: **Pin SHA-256 di `Constants.ModelDownload`**; `ModelRepository.verifyIntegrity()` hitung hash file setelah download selesai, tolak + hapus jika mismatch. Version field untuk force re-download saat update model.
- **Gate**: `LlmRepository.isModelDownloaded()` mengembalikan `bool` dari `ModelState == READY`; `AiChatScreen` disable input + tampilkan CTA "Download Model" jika `NOT_DOWNLOADED`/`ERROR`.
- **UX**: SettingsScreen jadi single source of truth download (button, progress bar MB/total, retry, insufficient-space). AiChatScreen hanya consume state, tidak memulai download.
- **Fallback**: Jika model tidak READY, `AiChatScreen` tetap bisa jawab via rule-based stub P1 (app fungsional 100% tanpa AI).

### Swappable Model Strategy (Qwen 1.5B ↔ Gemma 4 E2B)
- **Abstraksi `ModelDownloadConfig`**: `{ url, sha256, size, displayName }` — semua metadata model (Qwen maupun Gemma) disimpan sebagai data config, BUKAN hardcode di service.
- **`ModelRepository` tidak hardcode Qwen**: repo hanya consume `ModelDownloadConfig` (download → verify SHA-256 → finalize). Untuk ganti ke Gemma 4 E2B, cukup **inject config baru** (`url` Gemma, `sha256` Gemma, `size` ~2.4GB, `displayName`) — tanpa ubah logic repo/UI/service.
- **Inference-agnostic**: karena Qwen & Gemma 4 E2B sama-sama `.litertlm` + LiteRT `Engine.fromFile`, `EngineConfig` backend (cpu/gpu delegate) identik. Swap = ganti asset URL + constants, **tidak perlu rebuild APK logic** (APK tetap kecil; model tetap unduhan terpisah).
- **Future-proofing**: `Constants.ModelDownload` jadi single source of truth; ganti 3 field (URL/SHA256/size) + `displayName` untuk release model berbeda.

### Verification Strategy
- `flutter analyze` 0 error; `build_runner build` jika schema berubah (fitur 4).
- Unit test: `parseReceiptText`, mapping STT→Parsed, `formatPrompt`, `CurrencyConverter`, migrasi DB.
- Widget test: sheet open/auto-fill (mock service). Device test wajib untuk OCR/Voice/Gemma (emulator tidak cukup untuk kamera/mic/TFLite).
- Checklist AGENTS.md (lihat Phase 4).

## PHASE 4 — IMPLEMENTATION (Urutan, Lanes, DoD, Rollout, Checklist)

### Urutan Eksekusi (sesuai user: 1→2→3→4)
1. **OCR Receipt Full** — branch `feat/ocr-receipt`.
2. **Voice Input** — branch `feat/voice-input` (parallel lane dgn #1 aman).
3. **AI Chat Gemma LLM** — branch `feat/gemma-llm` (parallel lane dgn #1/#2 aman).
4. **Multi-currency** — branch `feat/multi-currency` (setelah 1-3 stabil; sentuh formatter & aggregator).

> Parallel lanes: Fitur 1, 2, 3 tidak saling block (service terisolasi). Fitur 4 sequential terakhir karena dampak luas.

### Definition of Done (DoD) per Fitur
- **OCR**: Kamera→crop→OCR→`ParsedTransaction` muncul di sheet dgn field terisi; user koreksi & simpan; `analyze` 0 error; test `parseReceiptText` pass; device-tested.
- **Voice**: Mic→STT→`ParsedTransaction` di sheet; permission gate; test mapping pass; device-tested.
- **Gemma/Qwen LLM**: Model **Qwen 1.5B ter-download** ke external files, **ter-verifikasi SHA-256** (READY), `generateResponse` inference nyata offline (bukan stub) setelah download; `AiChatScreen` conversational via Qwen, chat **disabled sampai READY** dengan CTA download; action-intent tetap deterministic; **progress UI + retry + pesan insufficient space** ada di Settings; fallback rule-based aktif jika model belum READY; test `formatPrompt`+mock+`verifyIntegrity` pass; device-tested. **Future swap ke Gemma 4 E2B hanya ganti constants** (URL/SHA256/size) — tanpa ubah code.
- **Multi-currency**: Tx punya currency + amountBase; total balance pakai amountBase; converter offline; picker di UI; migrasi v2→v3 verified + backup; `analyze` 0 error; test converter+migrasi pass.

### Rollout per Fitur
- Branch per fitur dari `main` (P1 = `421ac08`). PR terpisah, review, merge ke `main`.
- Fitur 3 (model **Qwen 1.5B ~1.5GB** unduhan terpisah via LiteRT `.litertlm`, APK tetap <100MB; swappable ke Gemma 4 E2B ~2.4GB cukup ganti constants) → note di changelog: "AI model diunduh terpisah via Settings"; tidak perlu release tag terpisah untuk APK.
- Fitur 4 migrasi → merge diikuti pengujian fresh-install + upgrade-install (rollback plan: restore DB backup).

### Checklist AGENTS.md (sebelum "Done")
- [ ] `flutter analyze` passes (0 error, no `print()` → `debugPrint`).
- [ ] `build_runner build` jika schema berubah (fitur 4).
- [ ] No hardcoded colors (pakai `Theme.of(context).colorScheme`).
- [ ] All strings `.tr()` (en.json + id.json).
- [ ] Repositories implement abstract interfaces (CurrencyRepositoryInterface, dll).
- [ ] No `StateNotifierProvider`/`ChangeNotifierProvider` (pakai `NotifierProvider`/`AsyncNotifierProvider`).
- [ ] Services return structured types (`ParsedTransaction`, `CurrencyModel`), BUKAN `Map`.
- [ ] Currency pakai formatter generik (`CurrencyFormatter`), bukan hardcode.
- [ ] Result pattern untuk failure yang diharapkan (OCR gagal, STT denied, model load error).
- [ ] Drift DAO pattern; migration `schemaVersion` + `onUpgrade` guard `if (from < N)`.
- [ ] Tests pass untuk critical paths (OCR parse, STT map, Gemma prompt, converter, migrasi).

---
*Plan selesai — PLANNING ONLY, no implementation code. Lanjut ke `/create` per fitur saat eksekusi.*
