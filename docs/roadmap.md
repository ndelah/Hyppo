# Hyppo Roadmap

This document tracks the implementation status of features across different development phases.

## MVP 0: Foundations
*Goal: Establish the core navigation shell, persistence layer, and basic CRUD operations.*

- [x] **Navigation Shell**: SwiftUI sidebar and detail views with Settings window.
- [x] **Local Persistence**: SwiftData implementation with cascading deletes and integrity rules.
- [x] **Core CRUD**: Basic Create, Read, Update, and Delete for all primary entities.
    - [x] Asset
    - [x] Research Question
    - [x] Scenario
    - [x] Log Entry
    - [x] Evidence
- [x] **Settings Window**: Framework for app-wide configurations.

## MVP 1: Core Workflow
*Goal: Enable the primary research journaling workflow with tags, search, and basic export.*

- [x] **Asset Management**:
    - [x] Asset list with search.
    - [x] Asset tags and sidebar filtering.
- [x] **Research & Scenarios**:
    - [x] Scenario lifecycle statuses.
    - [x] Automatic log generation on status changes.
- [x] **Timeline & Logs**:
    - [x] Timeline view with compact markers.
    - [x] Log metadata (Confidence, Entry Type).
    - [x] Tag support for Log Entries.
- [x] **Data Portability**:
    - [x] JSON Export/Import.
- [x] **Search & Discovery**:
    - [x] Global search across all entities.
    - [x] Advanced filters (date, tags, confidence).
    - [x] Search results grouped by entity type with headers.
    - [x] Navigation to results from search sheet.
    - [x] Entity type filtering (Assets, Research Questions, etc.).
    - [x] Tag-based filtering for all entities.
    - [x] Confidence filtering with star-based UI.
    - [x] Date range filtering.
- [x] **Markdown Export**:

    - [x] Export individual scenarios or assets to Markdown.

## MVP 2: Workflow Support
*Goal: Streamline evidence collection and formalize the review process.*

- [x] **Review Reminders**:
    - [x] Local reminder scheduling per scenario.
    - [x] macOS notification integration with snooze/complete actions.
- [x] **Quick Capture**:
    - [x] Global shortcut (⌘⇧H) for fast evidence entry.
    - [x] Auto-detect clipboard content (URLs vs. text snippets).
    - [x] Hierarchical destination picker (Asset → Research Question).
    - [x] Inline create forms for new assets/questions.
    - [x] Evidence type selection (Article, Filing, KPI, Quote, Note).
    - [x] Compact mode for rapid successive captures.
    - [ ] Draft support for logs.
- [x] **Review Mode**:
    - [x] Guided review wizard (Reinforce / Revise / Invalidate).
    - [x] Structured review log generation.
- [x] **Pre-Mortem Field**:
    - [x] Optional pre-mortem text field in Scenario form.
    - [x] Display in scenario detail and review pack.
    - [x] Collapsible section in detail view with "Expand/Collapse All" support.
    - [x] Persistence and editing support for pre-mortem content.
- [ ] **Enhanced Evidence**:
    - [ ] Snippet capture with attribution.
    - [ ] Local file attachments (PDF/images).
- [ ] **Scenario Comparison**:
    - [ ] Side-by-side comparison of drivers and invalidation rules.

## MVP 3: Premium Features
*Goal: Add analytical depth and AI-assisted insights.*

- [ ] **Behavioral Analytics**:
    - [ ] Confirmation bias detector (flag one-sided evidence).
    - [ ] Thesis drift alerts (confidence changes without revision).
    - [ ] Review completion rate tracking.
- [ ] **AI Assistance**:
    - [ ] Local AI summaries (Core ML).
    - [ ] Socratic critique prompts.
- [ ] **Market Data Integration** (Opt-in Premium):
    - [ ] Manual price entry per Asset.
    - [ ] Price change alerts (trigger reviews on +/- X% moves).
    - [ ] External API option (Yahoo Finance/Alpha Vantage).
- [ ] **Polished Exports**: Premium investor memo templates.

