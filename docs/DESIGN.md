# Sakuin (索引) — Design & UI/UX Specification

> PennywiseAI-inspired Warm Cream & Deep Slate design system with Material You 3 principles.

---

## 1. Design Philosophy

Sakuin balances **aesthetic warmth** with **high-density financial utility**:
1. **Flat Surface Aesthetics**: Cards use subtle tint differences and flat fill, avoiding harsh box-shadows.
2. **Warm Emotional Tone**: Light theme avoids sterile stark white in favor of warm ivory/cream (`#FFF8F0`), reducing eye fatigue.
3. **Zero-Friction Ergonomics**: Primary action (Smart Input Bar) is sticky at bottom of viewport, directly above thumb reach.
4. **Information Hierarchy**: Bold display amounts, muted secondary captions, prominent color badges for income/expense status.

---

## 2. Color Palette & Design Tokens

### Light Theme (Warm Cream)

| Token Name | Hex Code | Purpose |
|------------|----------|---------|
| `colorBackground` | `#FFF8F0` | Main scaffold background (Ivory/Cream) |
| `colorSurface` | `#FFF1E6` | Card background, bottom sheet fill |
| `colorPrimary` | `#6B5CE7` | Active nav indicator, primary CTA buttons |
| `colorPrimaryContainer` | `#EDE8FF` | Chip background, active badge tint |
| `colorSecondary` | `#3B82C4` | Wallet accents, secondary icons |
| `colorAccent` | `#E74C8B` | Urgent budget alerts, tags |
| `colorOnBackground` | `#1A1A2E` | Primary typography & high emphasis text |
| `colorOnSurface` | `#4A4A6A` | Body text & medium emphasis |
| `colorMuted` | `#9B9BB5` | Timestamps, placeholders, inactive icons |
| `colorIncome` | `#2ECC71` | Income indicators, positive balance |
| `colorExpense` | `#E74C3C` | Expense indicators, negative balance |

### Dark Theme (Deep Navy & Slate)

| Token Name | Hex Code | Purpose |
|------------|----------|---------|
| `colorBackground` | `#0D0D1A` | Main scaffold background (Deep Obsidian Navy) |
| `colorSurface` | `#1A1A2E` | Elevated cards, bottom sheets |
| `colorPrimary` | `#8B7CF7` | Bright indigo primary action |
| `colorPrimaryContainer` | `#2D2650` | Active selection surface |
| `colorSecondary` | `#5BA3E6` | Blue accents & wallet highlights |
| `colorOnBackground` | `#E8E8F0` | High emphasis primary text |
| `colorOnSurface` | `#B0B0CC` | Medium emphasis secondary text |
| `colorIncome` | `#4ADE80` | High-contrast income green |
| `colorExpense` | `#F87171` | High-contrast expense coral red |

---

## 3. Typography Hierarchy

Using **Plus Jakarta Sans** / **Inter**:

| Style Role | Font Size | Weight | Line Height | Tracking |
|------------|-----------|--------|-------------|----------|
| `Display Large` (Hero Balance) | 32sp | Bold (700) | 38sp | -0.5px |
| `Headline Medium` (Section Titles)| 20sp | SemiBold (600)| 26sp | -0.2px |
| `Title Medium` (Transaction Name)| 16sp | SemiBold (600)| 22sp | 0.0px |
| `Body Large` (Input Fields) | 15sp | Regular (400) | 20sp | 0.1px |
| `Body Medium` (Descriptions) | 14sp | Regular (400) | 18sp | 0.2px |
| `Label Small` (Badges & Dates) | 12sp | Medium (500) | 16sp | 0.4px |

---

## 4. Component Catalog & Layout Specifications

### 4.1 Sticky Smart Input Bar + Floating Action Button

```
┌────────────────────────────────────────────────────────┐
│                                                 ( + )  │ ← FAB (Indigo, 56dp)
│  ┌──────────────────────────────────────────────────┐  │
│  │ 💬  Type: beli kopi 25rb gopay...             🎤 │  │ ← Sticky Input Bar
│  └──────────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────────┤
│     [ 🏠 Home ]        [ 📊 Analytics ]     [ 💬 Chat ] │ ← Bottom Nav Bar
└────────────────────────────────────────────────────────┘
```

- **Height**: 54dp
- **Border Radius**: 28dp (full pill shape)
- **Background**: `colorSurface` with 4dp blur elevation shadow
- **Interaction**: Tap anywhere on bar → expand directly into structured bottom sheet

### 4.2 Expanded Bottom Sheet (AI Review & Numpad)

- **Border Radius Top**: 24dp
- **Height**: ~75% viewport height
- **Components**:
  1. Top Search/Prompt Bar with submit button
  2. Live Parsed Transaction Summary card (Amount, Category, Wallet, Title)
  3. Horizontal scroll Category Suggestion chips
  4. Horizontal scroll Wallet Selector pills
  5. Full-width Confirm button
  6. "Switch to Numpad" / "Switch to Text" toggle button

### 4.3 Activity Heatmap Grid

- **Layout**: 7 rows (Mon to Sun) × 12 to 24 columns (Weeks)
- **Cell Dimension**: 12dp × 12dp, 3dp border radius, 3dp spacing
- **Color Scale**: 4 levels of intensity based on daily spending volume relative to monthly average
