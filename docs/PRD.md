# Sakuin (索引) — Product Requirements Document

> Indonesian personal finance tracker. Local-first, dual-wallet, AI-powered input.

---

## 1. Product Overview

**Sakuin** is a privacy-first personal finance tracking app for Indonesian users. It combines on-device AI for smart transaction parsing with a dual wallet system (physical cash + digital e-wallets). All data stays on-device — no cloud, no accounts, no tracking.

### Vision
Become the go-to financial indexing tool for Indonesian millennials and Gen-Z who manage money across cash and multiple e-wallets (GoPay, OVO, Dana, ShopeePay).

### Core Value Proposition
- **Zero-friction input**: Type "beli kopi 25rb gopay" and AI parses everything
- **Dual wallet clarity**: See physical cash and digital balances in one view
- **Local-first privacy**: No server, no account, no data leaves your phone
- **Indonesian-native**: Rupiah formatting, shorthand parsing ("rb", "jt"), local categories

---

## 2. Target Users

### Primary Persona: "Rina" — Urban Young Professional
- **Age**: 22-30
- **Context**: Works in Jakarta, paid monthly via bank transfer
- **Pain**: Loses track of spending across GoPay, OVO, and cash
- **Behavior**: Buys coffee, ojol, and lunch daily; wants quick logging
- **Goal**: Know where money goes without tedious manual entry

### Secondary Persona: "Budi" — University Student
- **Age**: 18-24
- **Context**: Gets monthly allowance, budgets tightly
- **Pain**: Overspends on food/entertainment without realizing
- **Behavior**: Uses ShopeePay and cash; no credit card
- **Goal**: Stay within monthly budget, track kos/kontrakan rent

### Tertiary Persona: "Dewi" — Freelancer
- **Age**: 25-35
- **Context**: Irregular income from multiple clients
- **Pain**: Difficult to plan with variable cash flow
- **Behavior**: Income arrives in multiple wallets at different times
- **Goal**: Track income vs expense trends, set savings targets

---

## 3. MVP Scope (Phase 1)

### Must Have (P0)
| Feature | Description |
|---------|-------------|
| Dual Wallet System | Physical + Digital root wallets, sub-wallets per e-wallet provider |
| Smart Input Bar | Sticky text input for AI-powered transaction parsing |
| FAB Manual Input | Traditional numpad entry as fallback |
| Indonesian Categories | 16 preset categories (Food, Transport, Pulsa, Ojol, Warung, BBM...) |
| Rupiah Formatting | Native Rp format with shorthand parsing (25rb, 1.5jt, 500k) |
| Basic Analytics | Pie chart, trend line, monthly summary |
| Budget Tracking | 3 types: Limit, Target, Expected. Per-category or per-wallet |
| Bilingual | English (primary) + Indonesian |
| Dark/Light Theme | PennywiseAI-inspired warm cream light + deep navy dark |

### Should Have (P1 — Phase 2)
| Feature | Description |
|---------|-------------|
| Smart Rules Engine | Auto-categorize based on merchant/amount/time patterns |
| Subscription Detection | Auto-detect recurring payments |
| Activity Heatmap | GitHub-style contribution grid for spending patterns |
| Export/Import | CSV, Excel backup and restore |

### Could Have (P2 — Phase 3+)
| Feature | Description |
|---------|-------------|
| OCR Receipt Scanner | Photo receipt → extract amount + merchant |
| Voice Input | "belanja indomaret 50 ribu" via speech |
| AI Chat Assistant | On-device Qwen model for Q&A about finances |
| Multi-currency | IDR + USD + others |
| Home Widget | Android widget for quick balance view |

---

## 4. User Stories

### Wallet Management
- **US-01**: As a user, I want two default wallets (Physical + Digital) created on first launch so I can start tracking immediately.
- **US-02**: As a user, I want to add sub-wallets under Digital (GoPay, OVO, Dana, ShopeePay) so I can track each e-wallet separately.
- **US-03**: As a user, I want to see total balance across all wallets on the home screen.
- **US-04**: As a user, I want to transfer money between wallets (e.g., cash withdrawal = Physical↑ Digital↓).

### Transaction Input
- **US-05**: As a user, I want to type "beli kopi 25rb gopay" in the smart input bar and have the app auto-parse amount (25000), category (Food), and wallet (GoPay).
- **US-06**: As a user, I want to tap the FAB "+" to open a manual entry form with numpad when I prefer traditional input.
- **US-07**: As a user, I want to edit any AI-parsed field before confirming the transaction.
- **US-08**: As a user, I want Indonesian shorthand (25rb, 1.5jt, 500k) to be auto-resolved in any amount field.

### Analytics
- **US-09**: As a user, I want to see a monthly spending breakdown by category (pie chart).
- **US-10**: As a user, I want to compare income vs expense trends over time.
- **US-11**: As a user, I want to filter analytics by time period (This Month, Last Month, This Year, All Time).

### Budget
- **US-12**: As a user, I want to set a monthly spending limit (e.g., "Makan max Rp 2.000.000/bulan").
- **US-13**: As a user, I want to see a circular progress widget on the home screen showing budget usage.
- **US-14**: As a user, I want to be alerted when I'm approaching or exceeding my budget limit.

---

## 5. Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| **Privacy** | 100% on-device. No network calls except optional model download |
| **Performance** | App launch < 2 seconds. Transaction save < 200ms |
| **Storage** | < 50MB app size (excl. ML model). DB efficient for 10K+ transactions |
| **Platforms** | Android 8.0+ (API 26) initially |
| **Localization** | English primary, Bahasa Indonesia secondary |
| **Accessibility** | Material 3 contrast ratios, screen reader labels |

---

## 6. Success Metrics

| Metric | Target |
|--------|--------|
| Daily Active Usage | User logs ≥1 transaction/day |
| Smart Input Accuracy | ≥80% correct parse on first try |
| Time to Log | < 5 seconds from app open to transaction saved |
| Retention | 60% D7 retention |
