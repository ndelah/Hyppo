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

## MVP 2.5: McKinsey Mind Framework 🆕
*Goal: Implement hypothesis-driven research workflow inspired by the McKinsey Mind 5-step process.*

### Data Model (Complete)
- [x] **Driver Model**: 2-level hierarchy (Drivers and Sub-drivers) with research plan fields.
    - [x] Parent-child relationships for hierarchical structure.
    - [x] Validation questions, data sources, and thresholds per driver.
    - [x] Relationship to ResearchQuestion.
- [x] **KillCriteria Model**: Falsifiability conditions that would invalidate a thesis.
    - [x] Threshold and context fields.
    - [x] Relationship to ResearchQuestion.
- [x] **Evidence Enhancements**:
    - [x] `EvidenceSentiment` enum (Supporting, Contradicting, Neutral).
    - [x] `SourceType` enum (Article, Filing, Earnings Call, Analyst Report, etc.).
    - [x] Direct linkage from Evidence to Driver (for blind spot detection).
- [x] **ResearchQuestion Updates**:
    - [x] Relationships to Drivers and KillCriteria.
    - [x] Removed deprecated fields (old keyDrivers/invalidationRules arrays).

### Views (In Progress)
- [ ] **Driver Outline Editor**: Collapsible outline for 2-level Driver hierarchy.
    - [ ] Add/edit/delete drivers and sub-drivers inline.
    - [ ] Drag-and-drop reordering.
    - [ ] Expand/collapse controls.
- [ ] **Research Wizard**: Guided multi-step wizard for McKinsey workflow.
    - [ ] Step 1 (Framing): Thesis statement, initial hypothesis, prompt for assumptions.
    - [ ] Step 2 (Design): Define drivers with validation questions, sources, thresholds.
    - [ ] Step 3 (Summary): Review research plan before execution.
- [ ] **Research Plan Table**: Flat tabular view of the issue tree.
    - [ ] Columns: Driver, Validation Questions, Data Sources, Thresholds, Status.
    - [ ] Inline editing of cells.
- [ ] **Conviction Health Dashboard**: Visual summary of evidence balance per driver.
    - [ ] Supporting vs. contradicting evidence count per driver.
    - [ ] Blind spot alerts (drivers with zero evidence).
    - [ ] Overall conviction meter.
- [ ] **Evidence Form Updates**: Driver picker, sentiment, source type.
- [ ] **Quick Capture Updates**: Driver destination picker.
- [ ] **Review Wizard Integration**: Conviction health in review flow.

### Migration
- [ ] **Data Migration**: Transform existing data to new schema.
    - [ ] Migrate old keyDrivers strings to Driver objects.
    - [ ] Migrate old invalidationRules to KillCriteria objects.

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

---

## Current Sprint: McKinsey Mind Views

| Task | Status | Notes |
|------|--------|-------|
| Driver Outline Editor | 🟡 In Progress | Collapsible 2-level hierarchy UI |
| Research Wizard | ⚪️ Pending | Frame + Design steps |
| Research Plan Table | ⚪️ Pending | Flat alternative to outline |
| Conviction Health Dashboard | ⚪️ Pending | Evidence roll-up per driver |
| Evidence Form Updates | ⚪️ Pending | Driver picker, sentiment, sourceType |
| Quick Capture Driver Picker | ⚪️ Pending | Link evidence directly to driver |
| Review Wizard Integration | ⚪️ Pending | Show conviction health |
| Migration Logic | ⚪️ Pending | Existing data transformation |

