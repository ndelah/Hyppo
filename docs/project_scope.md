# Hyppo
## Statement of Work (macOS)

## 1. Project summary
Hyppo is a native macOS application for **hypothesis-driven investment research**, not portfolio performance tracking. The app implements a structured research workflow inspired by the McKinsey Mind methodology, guiding users through: Framing the problem → Designing the analysis → Gathering data → Interpreting results → Presenting ideas.

Users track companies (assets), formulate research questions with explicit hypotheses, define **Drivers** (load-bearing assumptions that must be true), specify **Kill Criteria** (falsifiability conditions), and collect evidence linked directly to drivers. The result is a searchable, chronological record of what the user believed, why they believed it, what evidence supported or contradicted their thesis, and how their conviction evolved.

## 2. Objectives
- [x] **Fast Capture:** Make research question and evidence capture fast enough for daily use.
- [x] **Audit Trail:** Preserve a high-integrity audit trail of beliefs, evidence, and revisions (via timestamped Log Entries).
- [x] **Hypothesis-Driven Structure:** Force users to articulate specific, testable assumptions (Drivers) before gathering data.
- [x] **Falsifiability:** Require Kill Criteria that define what would prove the thesis wrong.
- [x] **Blind Spot Detection:** Link evidence to specific Drivers to reveal gaps in research coverage.
- [x] **Clean UI:** Keep the UI clean even when entries carry rich metadata (using display density and collapsible sections).
- [x] **Offline & Persistence:** Operate fully offline with robust local persistence (SwiftData) and backups (JSON export/import).
- [ ] **Premium Path:** Provide a premium upgrade path without bloating core workflows.

## 3. Target users and Pareto workflow
Target users are research-driven retail investors and semi-pro analysts who take notes, read filings/news, and revisit decisions.

### McKinsey Mind Investment Workflow (5 Steps)

**1. Framing the Problem** — Develop a hypothesis to structure the research.
- Define the research question (what do I need to understand about this investment?).
- Formulate an initial hypothesis (thesis statement).
- Identify key Drivers: "What assumptions must be true for this hypothesis to hold?"
- Define Kill Criteria: "What data would prove me wrong?"

**2. Designing the Analysis** — Create a research plan to prove/disprove the hypothesis.
- For each Driver, define:
  - Validation questions (what specific questions need answers?)
  - Data sources (filings, earnings calls, industry reports, etc.)
  - Thresholds (what values would validate or invalidate?)
- Prioritize drivers by importance and uncertainty.

**3. Gathering Data** — Collect evidence linked to specific Drivers.
- Use Quick Capture to log articles, filings, KPIs, quotes.
- Tag each piece of evidence with sentiment (Supporting, Contradicting, Neutral).
- Link evidence directly to the Driver it validates or challenges.

**4. Interpreting Results** — Assess conviction based on accumulated evidence.
- Review Conviction Health Dashboard per Driver.
- Identify blind spots (drivers with no evidence).
- Trigger structured reviews when evidence materially changes.

**5. Presenting Ideas** — Export structured research memos.
- Markdown/PDF exports with thesis, drivers, evidence, and conclusion.
- Timeline of conviction changes and key decision points.

## 4. Deliverables
- [x] **macOS App:** Native macOS application (SwiftUI/SwiftData).
- [x] **Persistence:** Local data model and persistence layer using SwiftData.
- [x] **Core UI Flows:** Assets, Research Questions, Drivers, Evidence, Timeline, Global Search, Settings.
- [x] **Export/Import:** Export (JSON, Markdown) and local backup mechanism (JSON import).
- [ ] **Test Suite:** Test suite and release checklist.
- [ ] **Documentation:** User documentation: onboarding, privacy statement, help.

## 5. Out of scope (initially)
- Brokerage integrations and live portfolio tracking.
- Automated trading, signals, or buy/sell recommendations.
- Multi-user collaboration or shared workspaces.
- Cross-platform clients (iOS/web) during initial phases.
- Always-on automated web scraping or news ingestion.
- Logic tree visualization (users can create externally if needed).

## 6. Non-negotiable constraints
- **Local-only operation:** all core functionality works entirely on-device; no required cloud services.
- **Privacy by default:** no data is shared anywhere; no telemetry by default; no background uploads; no remote sync unless later added as an explicit opt-in.
- External content is stored as links and short attributed snippets. The app must not store or reproduce full copyrighted articles.

## 7. Core design principles
- Calm by default: quiet layout with minimal visual noise.
- Progressive disclosure: show compact summaries first; reveal detail on demand.
- **Hypothesis-first:** Users must articulate assumptions before gathering data.
- **Falsifiable by design:** Kill Criteria ensure theses can be disproven.
- Fast capture: keyboard-first flows, minimal forms, autosaved drafts.
- Opinionated structure + flexible text: structured fields for drivers/invalidation; freeform notes for nuance.
- Strong hierarchy: typography and spacing carry meaning; color remains an accent.
- Consistency: repeat patterns across assets, research questions, and evidence.
- Reversibility: undo where practical; confirmations for destructive actions.
- Local resilience: export and backups are first-class features.
- Accessibility: keyboard navigation and readable defaults.

## 8. System overview

### 8.1 Core components
- **UI (SwiftUI):** Assets, Asset Detail, Research Question Detail, Driver Outline, Conviction Health, Evidence Timeline, Global Search, Settings/Export.
- **Domain layer:** models and business rules (integrity constraints, lifecycle transitions, validation).
- **Persistence:** SwiftData with relationships: Asset → ResearchQuestion → Driver → Evidence.
- **Search/indexing:** local full-text search (SQLite FTS or Spotlight where appropriate) plus facets/filters (Entity Type, Tag, Confidence, Date Range).
- **Capture/attachments:** URL capture, snippet storage, evidence sentiment and source type tracking.
- **Export/backup:** JSON export/import; Markdown exports; versioned backup folder.
- **Notifications:** local reminders for review cadence.

### 8.2 Core data model (conceptual)

```
Asset (1) ──────────────────────────> (N) ResearchQuestion
                                           │
                                           ├──> (N) Driver (2-level hierarchy)
                                           │         │
                                           │         └──> (N) Evidence
                                           │
                                           ├──> (N) KillCriteria
                                           │
                                           ├──> (N) LogEntry
                                           │
                                           └──> (N) ReviewReminder
```

- **Asset:** a tracked company/security.
- **ResearchQuestion:** an area of inquiry about an asset, containing a thesis statement.
- **Driver:** a load-bearing assumption that must be true for the thesis to hold. Supports 2-level hierarchy (parent driver → sub-drivers).
- **KillCriteria:** a specific condition that would invalidate the thesis.
- **Evidence:** a link/snippet/KPI/quote linked to a specific Driver with sentiment (Supporting/Contradicting/Neutral).
- **LogEntry:** a point-in-time journal entry for tracking research progress.
- **ReviewReminder:** local schedule metadata for periodic review.

### 8.3 End-to-end flows and required fields

#### 🟢 Flow 1 — Frame the Problem (Start Research)
*Status: Data Model Complete, Views In Progress*

**User flow:** Add Asset → Create Research Question → Define Hypothesis → Add Drivers → Add Kill Criteria.

**Steps**
1) First launch: empty state with Add Asset.
2) Add Asset: ticker/name (optional tags) → Save.
3) Add Research Question: question text + context → Save.
4) **Research Wizard Step 1 (Frame):**
   - Define thesis statement (initial hypothesis).
   - Prompt: "What assumptions must be true for this hypothesis to hold?"
   - Add 2-3 Drivers (minimum required).
   - Add 1+ Kill Criteria.
5) View: Research Question detail shows thesis, drivers, kill criteria.

**Fields required (UI + backend)**
- **ResearchQuestion**
  - UI: questionText (required), context (optional), thesisStatement (required), priority (optional 1–5), status (default Open).
  - Backend: questionId, assetId, questionText, context, thesisStatement, statusRaw, conclusion, priority, createdAt, updatedAt.
- **Driver**
  - UI: text (required), context (optional), validationQuestions (optional list), dataSources (optional list), thresholds (optional list).
  - Backend: driverId, researchQuestionId, parentDriverId (for sub-drivers), text, context, validationQuestionsData, dataSourcesData, thresholdsData, createdAt, updatedAt.
- **KillCriteria**
  - UI: text (required), context (optional), threshold (optional).
  - Backend: ruleId, researchQuestionId, text, context, threshold, createdAt, updatedAt.

#### 🟡 Flow 2 — Design the Analysis (Research Plan)
*Status: Data Model Complete, Views Pending*

**User flow:** For each Driver → Define validation questions → Identify data sources → Set thresholds.

**Steps**
1) Open Research Question → Navigate to Driver Outline or Research Plan Table.
2) For each Driver:
   - Add validation questions (what do I need to answer?).
   - Add potential data sources (10-K, earnings call, industry report, etc.).
   - Set thresholds (what values validate or invalidate?).
3) Prioritize drivers by importance (order in outline).
4) View: Research Plan Table shows all drivers with their planned analyses.

**Fields required (UI + backend)**
- **Driver (research plan fields)**
  - UI: validationQuestions (list of strings), dataSources (list of strings), thresholds (list of strings).
  - Backend: validationQuestionsData (JSON-encoded), dataSourcesData (JSON-encoded), thresholdsData (JSON-encoded).

#### 🟢 Flow 3 — Gather Data (Evidence Collection)
*Status: Data Model Complete, Views Partially Complete*

**User flow:** Copy URL/snippet → Quick Capture → Link to Driver → Set sentiment → Save.

**Steps**
1) Start capture: user copies URL/snippet from browser/PDF and triggers Quick Capture (⌘⇧H).
2) Choose destination: Asset → Research Question → **Driver** (new: link directly to driver).
3) Describe evidence: URL, title, evidence type, snippet, annotation.
4) **Set sentiment:** Supporting, Contradicting, or Neutral.
5) **Set source type:** Article, Filing, Earnings Call, Analyst Report, etc.
6) Save: write Evidence linked to Driver; update timestamps; index for search.
7) Confirm: lightweight confirmation with "Go to entry."

**Fields required (UI + backend)**
- **Evidence**
  - UI: url (required for non-notes), displayTitle (auto/editable), evidenceType, snippetText (optional), annotationText (optional), **sentiment** (required), **sourceType** (optional), **driver** (recommended).
  - Backend: evidenceId, driverId (nullable), researchQuestionId (fallback), sentimentRaw, sourceTypeRaw, createdAt, updatedAt, capturedAt, evidenceType, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText.

#### 🟡 Flow 4 — Interpret Results (Conviction Assessment)
*Status: Data Model Complete, Views Pending*

**User flow:** View Conviction Health Dashboard → Identify blind spots → Trigger review if needed.

**Steps**
1) Open Research Question → View Conviction Health Dashboard.
2) See per-driver breakdown:
   - Count of supporting evidence.
   - Count of contradicting evidence.
   - Neutral evidence noted separately.
3) Identify blind spots: Drivers with zero evidence flagged.
4) Review conviction: Overall balance suggests confidence level.
5) If evidence materially changes conviction, trigger Review Wizard.

**Fields required (UI + backend)**
- **Conviction Health (computed)**
  - Per Driver: supportingCount, contradictingCount, neutralCount.
  - Overall: totalSupporting, totalContradicting, driversWithNoEvidence.
  - Display: conviction meter, blind spot alerts.

#### 🟢 Flow 5 — Review and Decide
*Status: Fully Specified & Implemented (needs Conviction Health integration)*

**User flow:** Trigger review → See conviction health → Choose outcome → Commit review log.

**Steps**
1) Trigger review: scheduled notification or manual Review button.
2) **Review pack:** Research Question summary + **Conviction Health per Driver** + recent evidence.
3) Decide: Reinforce / Revise / Invalidate.
4) Guided prompts: minimal structured answers for the chosen outcome.
5) Commit: create Review log entry; update confidence and status as needed.

**Fields required (UI + backend)**
- Same as existing Review flow, plus:
- **Conviction Health integration:**
  - Display per-driver evidence balance in review pack.
  - Highlight drivers with new contradicting evidence.

#### 🟢 Flow 6 — Present Ideas (Export)
*Status: Partially Implemented*

**User flow:** Select Research Question → Export to Markdown/PDF.

**Steps**
1) Open Research Question → Export menu.
2) Choose format: Markdown, PDF, JSON.
3) Export includes: Thesis, Drivers (with sub-drivers), Kill Criteria, Evidence timeline, Conviction summary.

## 9. Architecture (macOS-first)
**Recommended baseline**
- UI: SwiftUI.
- Persistence: SwiftData with relationships (Asset → ResearchQuestion → Driver → Evidence).
- Search: local full-text search via SQLite FTS or Spotlight indexing.
- App structure: MVVM (or TCA if state complexity grows).
- Import/export: JSON and Markdown; backups compatible with Time Machine.
- Optional later: CloudKit sync (opt-in), AI via Core ML (local) or remote API (explicit opt-in).

## 10. Product Phases (Roadmap)
The development of Hyppo is structured into distinct phases, moving from core infrastructure to the McKinsey Mind framework to advanced analytical tools. For a detailed list of features and their current implementation status, see [roadmap.md](roadmap.md).

### 🟢 MVP 0: Foundations
**Goal:** Establish the core navigation shell, local persistence layer, and basic CRUD operations for all primary entities.
- Focus on macOS-native feel and robust data integrity.
- Establish the "Asset → Research Question" hierarchy.
- *Status: Complete.*

### 🟢 MVP 1: Core Workflow
**Goal:** Enable the primary research journaling workflow, allowing users to track their investment logic over time.
- Focus on timeline visualization and data portability.
- Implement tagging systems and basic search to manage growing research sets.
- *Status: Complete — Global Search, Advanced Filters, and Markdown Export implemented.*

### 🟢 MVP 2: Workflow Support
**Goal:** Streamline the "Quick Capture" of evidence and formalize the "Review Loop" to ensure research stays current.
- Focus on reducing friction for daily use (Global shortcuts, snippets).
- Implement guided review wizards to help users update or invalidate their theses.
- *Status: Complete — Review Mode, Pre-Mortem, and Quick Capture (⌘⇧H) implemented.*

### 🟡 MVP 2.5: McKinsey Mind Framework
**Goal:** Implement hypothesis-driven research workflow with Drivers, Kill Criteria, and evidence-to-driver linkage.
- Data Model: Driver (2-level hierarchy), KillCriteria, Evidence sentiment/sourceType — **Complete.**
- Views: Driver Outline, Research Wizard, Research Plan Table, Conviction Health — **In Progress.**
- Migration: Existing data transformation — **Pending.**
- *Status: In Progress — Data model complete, views in progress.*

### ⚪️ MVP 3: Premium Features
**Goal:** Provide advanced analytical depth and AI-assisted insights for power users.
- Focus on local AI summaries and behavioral analytics.
- Enhanced export formats for professional-grade research memos.
- *Status: Pending.*

## 11. Definition of Done
- Acceptance criteria met.
- Unit tests for persistence, integrity rules, and exports.
- Basic UI tests for create/edit flows.
- No P0 crashes; acceptable performance on large datasets.
- Release notes and help/privacy docs updated.

## 11.1 Success Metrics
To measure the effectiveness of Hyppo and validate the McKinsey Mind workflow:

### Hypothesis Quality
- **Target:** 100% of Research Questions have ≥2 Drivers and ≥1 Kill Criteria.
- **Measurement:** Track Research Questions created with/without complete structure.
- **Goal:** Enforce structured hypothesis articulation.

### Evidence Coverage (Blind Spot Detection)
- **Target:** < 20% of Drivers have zero evidence after 7 days.
- **Measurement:** Track drivers with evidenceCount = 0.
- **Goal:** Identify and alert on research blind spots.

### Evidence Balance
- **Target:** Balanced evidence (not >80% supporting or contradicting).
- **Measurement:** Track sentiment distribution per Research Question.
- **Goal:** Prevent confirmation bias.

### Quick Capture Friction
- **Target:** Time from shortcut to save < 5 seconds.
- **Measurement:** Track capture abandonment rate.
- **Goal:** < 20% abandonment rate.

### Review Completion Rate
- **Target:** > 70% of scheduled reviews completed.
- **Measurement:** Track review reminders vs. completed reviews.

**Note:** Metrics collection should respect privacy constraints. Consider opt-in analytics or local-only tracking.

## 12. Risks and Mitigations
- **Scope creep:** Lock McKinsey framework to core workflow; defer advanced analytics to MVP 3.
- **Complexity for new users:** Provide guided wizard; allow skipping optional fields.
- **Migration risk:** Test migration thoroughly; keep backup of old data format.
- **Storage complexity:** Keep schema minimal; plan migrations early.
- **Copyright:** Store links and short snippets with attribution.
- **Premium AI:** Additive and opt-in; never required for core.

## 13. Parking Lot (Explicitly Deferred)
- Logic tree visualization (external tools can be used).
- Stock-specific news dashboard/feed (auto-ingested) tied to tracked theses.
- Continuous automated internet "scouring" / research collector.
- Large-scale sentiment analysis of external articles.
- Cross-device sync and an iPhone companion app.
- Web app and/or self-hosted server edition.
- Brokerage integrations and performance overlays.
- Social/community features.
- Multi-user teams/workspaces.
- Multiple tickers per research question (many-to-many) — future enhancement.

## 14. Next Steps
1. **Complete Driver Outline Editor** — Collapsible 2-level hierarchy UI for managing Drivers.
2. **Build Research Wizard** — Guided multi-step flow for Framing and Design phases.
3. **Build Conviction Health Dashboard** — Visual summary of evidence per Driver.
4. **Update Quick Capture** — Add Driver destination picker.
5. **Update Review Wizard** — Integrate Conviction Health display.
6. **Write Migration Logic** — Transform existing keyDrivers/invalidationRules to new models.
7. **Update Export** — Include Drivers, Kill Criteria, and evidence sentiment in exports.

---

### 📝 AI Maintenance Instructions
**CRITICAL for all AI Assistants:**
- **Keep this document synchronized:** Whenever a feature is implemented or its specification changes, update the corresponding flow in **Section 8.3**.
- **Emoji Status Tracking:** 
  - Use 🟢 for Fully Specified & Implemented.
  - Use 🟡 for Partially Specified or In Progress.
  - Use ⚪️ for Not Started or Requires Clarification.
- **Roadmap Alignment:** Ensure the high-level phase statuses in **Section 10** match the granular progress in `roadmap.md`.
- **McKinsey Framework:** The 5-step workflow (Frame → Design → Gather → Interpret → Present) is the core abstraction. All features should support this flow.

