# Sakuin (索引) — Security & Privacy Specification

> Local-first, zero-knowledge financial data protection framework.

---

## 1. Threat Model & Privacy Principles

Sakuin is built under a **Strict Local-First Privacy Model**:
1. **Zero Cloud Ingestion**: Financial records, balances, and transaction notes are never transmitted across the network.
2. **No User Authentication Servers**: No third-party accounts, OAuth trackers, or session tokens exist.
3. **On-Device Inference**: All AI parsing, regex evaluation, and categorization happen entirely inside the application sandbox.

---

## 2. Data Storage & Encryption

### SQLite Database (Drift)
- Database file stored inside application-sandboxed directory (`app_flutter/sakuin.db`).
- Non-root Android devices restrict file read access strictly to the app UID.
- Future migration ready for SQLCipher encrypted database when biometric lock or PIN is enabled.

### Sensitive Key Storage
- Encryption keys, export passphrases, and critical user preferences are stored via `FlutterSecureStorage` (backed by Android KeyStore / Keystore AES-256).

### SharedPreferences Restrictions
- `SharedPreferences` is **strictly forbidden** from storing transaction records, account balances, or financial details. It is only permitted for UI theme selection (`light` / `dark`) and locale codes (`en` / `id`).

---

## 3. Data Integrity & Validation

1. **Amount Sanitization**:
   - Negative amount values blocked at entity construction.
   - Max single transaction cap (Rp 10.000.000.000) to prevent overflow/corrupt arithmetic.
2. **Atomic Transfers**:
   - Inter-wallet transfers run inside SQLite atomic transactions (`db.transaction(...)`), ensuring debit and credit operations either both succeed or both roll back.
3. **Database Migration Safety**:
   - Strict `schemaVersion` check with backup steps before executing structural table modifications.

---

## 4. Export & Backup Security

- Encrypted JSON / CSV exports supported.
- User can define a local export password using Argon2id / AES-GCM for encrypted file generation before sharing to external storage.
