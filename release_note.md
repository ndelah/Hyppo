# Footnote — Release Notes

## Version 1.0.0 (MVP 0) — 2026-01-13

Footnote is a native macOS app for tracking **investment theses** (the reasoning), not portfolio performance. This first release ships the core data model and navigation shell so you can start capturing assets, theses, logs, and evidence locally.

## Highlights

- **Assets (companies/securities)**: Create, edit, archive, and delete tracked assets (ticker + name, optional exchange/currency).
- **Theses per asset**: Create multiple scenario theses (Base/Bull/Bear/Custom) with structured fields:
  - Thesis statement
  - Key drivers
  - Invalidation rules
  - Optional catalysts and key risks
  - Optional confidence (1–5) and status (Active/On Hold/Invalidated/Archived)
- **Timeline logs**: Add timestamped log entries (Observation/Update/Risk/Catalyst/Review) with optional confidence.
- **Evidence**: Attach evidence to log entries (Article/Filing/KPI/Quote/Note) with URL + optional title, snippet, and annotations.
  - Snippets are **truncated to a short length** to support copyright-safe note taking.
- **Navigation shell (SwiftUI)**: Sidebar → Asset → Thesis detail layout with clean empty states and contextual actions.
- **Local persistence (SwiftData)**: Data is stored on-device using SwiftData with cascading deletes (e.g., deleting a thesis deletes its logs/evidence).
- **Settings**: Preferences UI for basic display toggles and placeholders for backup/export/import.

## Privacy & Data

- **Local-only by default**: All core functionality works entirely on-device.
- **No telemetry**: No tracking, analytics, or background uploads.
- **External content handling**: Evidence is stored as links and short snippets—Footnote is not intended to store or reproduce full copyrighted articles.

## System Requirements

- **macOS**: Requires a macOS version compatible with SwiftUI + SwiftData (Xcode 15+ era).
- **Storage**: Local app data only (no cloud account required).

## Known Limitations (Planned Next)

- **Global search**: Not implemented yet.
- **Export/import/backup**: Settings UI exists, but JSON/Markdown export + import + automated backups are not implemented yet.
- **Quick Capture workflow**: Not implemented yet (no menu bar capture / destination selector).
- **Attachments (PDF/images)**: Not implemented yet (planned for later MVP).
- **Tags UI**: Tag model exists; tag management/filtering UI is not included in this release.

## Keyboard Shortcuts

- **New Asset**: ⌘N
- **New Thesis**: ⌘⇧T
- **New Log Entry**: ⌘⇧L


