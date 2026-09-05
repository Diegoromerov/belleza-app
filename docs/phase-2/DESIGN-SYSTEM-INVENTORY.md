# GLOWAPP PHASE 2 — DESIGN SYSTEM INVENTORY

## 1. Executive Summary
This document provides a comprehensive inventory of all UI components, tokens, typography rules, layout patterns, and interaction states across the GlowApp platform (`admin-dashboard`, `frontend` Flutter app, and `landing`).

---

## 2. Component Categorization Matrix

| Category | Component Name | Existing Location(s) | Status | Standardized Target Primitive |
| :--- | :--- | :--- | :--- | :--- |
| **Atoms** | Button / Primary | `admin-dashboard/src/components/ui/button.tsx`, Flutter `ElevatedButton` | Standardized | `src/components/ui/button.tsx` |
| **Atoms** | Button / Outline | `admin-dashboard/src/components/ui/button.tsx`, Flutter `OutlinedButton` | Standardized | `src/components/ui/button.tsx` (variant: outline) |
| **Atoms** | Input Text | `admin-dashboard/src/components/ui/input.tsx`, Flutter `TextField` | Standardized | `src/components/ui/input.tsx` |
| **Atoms** | Badge / Chip | `admin-dashboard/src/components/ui/badge.tsx`, Flutter custom `Container` | Standardized | `src/components/ui/badge.tsx` |
| **Atoms** | Avatar | `admin-dashboard/src/components/ui/avatar.tsx`, Flutter `CircleAvatar` | Standardized | `src/components/ui/avatar.tsx` |
| **Atoms** | Icon Wrapper | Lucide Icons (React), Flutter Icons | Standardized | Lucide React / Icon |
| **Molecules** | Stat Card | `admin-dashboard/src/app/(dashboard)/page.tsx` | Refactor needed | `src/components/ui/stat-card.tsx` |
| **Molecules** | Search Bar | `admin-dashboard/src/components/ui/search-bar.tsx` | Standardized | `src/components/ui/search-bar.tsx` |
| **Molecules** | Modal / Dialog | `admin-dashboard/src/components/ui/dialog.tsx`, Flutter `AlertDialog` | Standardized | `src/components/ui/dialog.tsx` |
| **Molecules** | Dropdown / Select | `admin-dashboard/src/components/ui/select.tsx` | Standardized | `src/components/ui/select.tsx` |
| **Molecules** | Toast Notification | `sonner` / `react-hot-toast`, Flutter `SnackBar` | Standardized | `src/components/ui/toast.tsx` |
| **Molecules** | Skeleton Loading | Inline pulsing divs, Flutter `Shimmer` | Refactor needed | `src/components/ui/skeleton.tsx` |
| **Organisms** | Header / Navbar | Dashboard header, Mobile AppBar | Standardized | `src/components/layout/header.tsx` |
| **Organisms** | Sidebar Navigation | Dashboard sidebar | Standardized | `src/components/layout/sidebar.tsx` |
| **Organisms** | Data Table | Dashboard tables | Refactor needed | `src/components/ui/data-table.tsx` |
| **Organisms** | Booking Flow Card | Mobile `booking_screen.dart` | Refactor needed | `src/features/booking/components/` |

---

## 3. Visual & Token Audit
- **Primary Accent:** `#F43F5E` (Rose 500)
- **Secondary Neutral Dark:** `#0F172A` (Slate 900)
- **Secondary Neutral Light:** `#F8FAFC` (Slate 50)
- **Success State:** `#10B981` (Emerald 500)
- **Warning State:** `#F59E0B` (Amber 500)
- **Error State:** `#EF4444` (Red 500)
- **Border Radius Standard:** `8px` (`rounded-md`), `12px` (`rounded-lg`), `16px` (`rounded-xl`)
- **Spacing Grid Base:** 4px (8px, 12px, 16px, 24px, 32px, 48px)
- **Typography Base:** System Sans-Serif / Inter / Geist
