# Hyppo
## Statement of Work (macOS)

## 1. Project summary
Hyppo is a native macOS application for tracking **investment research questions and scenarios**, not portfolio performance. Users track companies (assets), create research questions, formulate scenarios (e.g., base/bull/bear) to answer those questions, and append timestamped log entries with evidence links, short snippets, and local attachments. The result is a searchable, chronological record of what the user believed, when they believed it, and what information led them to reinforce, revise, or invalidate a scenario.

## 2. Objectives
- Make research question and scenario capture fast enough for daily use.
- Preserve a high-integrity audit trail of beliefs, evidence, and revisions.
- Support multiple scenarios per research question and enable lightweight comparison.
- Keep the UI clean even when entries carry rich metadata.
- Operate fully offline with robust local persistence and backups.
- Provide a premium upgrade path without bloating core workflows.

## 3. Target users and Pareto workflow
Target users are research-driven retail investors and semi-pro analysts who take notes, read filings/news, and revisit decisions.

The product must support this end-to-end workflow:
1) Choose/track a company (start research or ongoing coverage).
2) Formulate a research question (what do I need to understand about this investment?).
3) Create scenarios (bull/base/bear) exploring different possible outcomes.
4) Collect key evidence (article, filing, note, KPI, quote) via quick capture.
5) Write or update scenarios (what must be true; catalysts; risks; invalidation rules).
6) Revisit (scheduled review or prompted by new evidence) and decide: reinforce, revise, or invalidate.

## 4. Deliverables
- macOS application (universal build where feasible).
- Local data model and persistence layer.
- Core UI flows: Assets, Research Questions, Scenarios, Scenario Detail, Timeline, Global Search, Settings.
- Export (JSON, Markdown) and local backup mechanism.
- Test suite and release checklist.
- User documentation: onboarding, privacy statement, help.

## 5. Out of scope (initially)
- Brokerage integrations and live portfolio tracking.
- Automated trading, signals, or buy/sell recommendations.
- Multi-user collaboration or shared workspaces.
- Cross-platform clients (iOS/web) during initial phases.
- Always-on automated web scraping or news ingestion in MVP 1.

## 6. Non-negotiable constraints
- **Local-only operation:** all core functionality works entirely on-device; no required cloud services.
- **Privacy by default:** no data is shared anywhere; no telemetry by default; no background uploads; no remote sync unless later added as an explicit opt-in.
- External content is stored as links and short attributed snippets. The app must not store or reproduce full copyrighted articles.

## 7. Core design principles
- Calm by default: quiet layout with minimal visual noise.
- Progressive disclosure: show compact summaries first; reveal detail on demand.
- One primary action per screen: the next step is always obvious (Add Asset / Add Research Question / Add Scenario / Add Log).
- Fast capture: keyboard-first flows, minimal forms, autosaved drafts.
- Opinionated structure + flexible text: structured fields for drivers/invalidation; freeform notes for nuance.
- Strong hierarchy: typography and spacing carry meaning; color remains an accent.
- Consistency: repeat patterns across assets, theses, and logs.
- Reversibility: undo where practical; confirmations for destructive actions.
- Local resilience: export and backups are first-class features.
- Accessibility: keyboard navigation and readable defaults.

## 8. System overview

### 8.1 Core components
- **UI (SwiftUI):** Assets, Asset Detail, Research Question Detail, Scenario Detail, Add/Edit sheets, Timeline, Global Search, Settings/Export.
- **Domain layer:** models and business rules (integrity constraints, lifecycle transitions, validation).
- **Persistence:** SwiftData (or Core Data if advanced requirements emerge), local storage, optional encryption at rest.
- **Search/indexing:** local full-text search (SQLite FTS or Spotlight where appropriate) plus facets/filters.
- **Capture/attachments:** URL capture, snippet storage, optional local files (PDF/images) stored in the app sandbox.
- **Export/backup:** JSON export/import; Markdown exports; versioned backup folder.
- **Notifications (MVP 2):** local reminders for review cadence.

### 8.2 Core data model (conceptual)
- **Asset:** a tracked company/security.
- **Research Question:** an area of inquiry about an asset.
- **Scenario:** a hypothesis (bull/base/bear/custom) answering a research question.
- **Log Entry:** a point-in-time journal entry attached to a scenario.
- **Evidence:** a link/snippet/KPI/quote attached to a log entry.
- **Review Reminder:** local schedule metadata for scenario review.

### 8.3 End-to-end flows and required fields

#### 🟢 Flow 1 — Choose/track a company and formulate research question (start coverage)
*Status: Fully Specified & Implemented*

**User flow:** Open app → Add Asset → Create research question → Create scenario → Add first log → (optional) attach evidence → View timeline.

**Steps**
1) First launch: empty state with Add Asset.
2) Add Asset: ticker/name (optional tags) → Save.
3) Add Research Question: question text + context → Save.
4) Add Scenario: choose type (bull/base/bear) → complete structured scenario → Save.
5) Add Log Entry: title/body (optional tags/confidence/type) → Save.
6) Attach Evidence (optional): add URL (optional snippet/annotation) → Save.
7) View: timeline shows compact markers; expand to read; global search available.
8) Export/backup (optional): export JSON/Markdown; enable a backup folder.

**Fields required (UI + backend)**
- **Asset**
  - UI: ticker (required), name (required), exchange (optional), currency (optional), tags (optional).
  - Backend: assetId, tickerNormalized, createdAt, updatedAt, archivedAt (optional), tagIds.
- **Research Question**
  - UI: questionText (required), context (optional), priority (optional 1–5), status (default Open).
  - Backend: questionId, assetId, questionText, context, statusRaw, conclusion, priority, createdAt, updatedAt.
- **Scenario**
  - UI: scenarioType (bull/base/bear/custom), title, scenarioStatement (required), keyDrivers (required list), invalidationRules (required list), catalysts (optional), keyRisks (optional), preMortemText (optional), confidence (optional 1–5), status (default Active).
  - Backend: scenarioId, researchQuestionId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt (optional), status, statusChangedAt, confidenceCurrent, preMortemText, versionNumber.
- **Log Entry**
  - UI: occurredAt (default now), title (required), body (required), entryType (Observation/Update/Risk/Catalyst/Review), tags (optional), confidence (optional 1–5), indicators (evidence count, attachment count).
  - Backend: logEntryId, scenarioId, createdAt, updatedAt, occurredAt, entryType, tagIds, confidence, isSystemGenerated, isPinned (optional).
- **Evidence (when attached)**
  - UI: url (required), displayTitle (optional), evidenceType, snippetText (optional, limited), userAnnotation (optional).
  - Backend: evidenceId, logEntryId, capturedAt, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText, tagIds.

#### 🟡 Flow 2 — Collect key evidence (Quick Capture)
*Status: Fully Specified (see docs/QuickCapture_Wireframe.md) & Not Implemented*

**User flow:** Copy URL/snippet → Quick Capture → pick destination → Save → index → jump to entry.

**Steps**
1) Start capture: user copies URL/snippet from browser/PDF and triggers Quick Capture (menu bar or shortcut).
2) Choose destination: pick/create Asset; pick/create Research Question; pick/create Scenario; attach to a new log (default) or an existing log.
3) Describe evidence: URL (required), auto title (editable), evidence type, snippet/annotation, tags.
4) Save: write Evidence locally; link to log entry; update scenario lastUpdatedAt; index for search.
5) Confirm: lightweight confirmation with "Go to entry."

**Fields required (UI + backend)**
- **Quick Capture inputs**
  - UI: url (required), displayTitle (auto/editable), evidenceType (Article/Filing/KPI/Quote/Note), snippetText (optional, limited), userAnnotation (optional), tags (optional).
  - Backend: evidenceId, createdAt, updatedAt, capturedAt, evidenceType, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText, tagIds.
- **Destination context selector**
  - UI: Asset picker/search + inline create (ticker, name, tags); Research Question picker/search + inline create (question text, context); Scenario picker/search + inline create (type, title, minimal scenarioStatement); attachTo (new log by default vs existing log).
  - Backend: selectedAssetId, selectedResearchQuestionId, selectedScenarioId, selectedLogEntryId (or createNewLogEntry flag).
- **Auto-created Log Entry (when attachTo=new log)**
  - UI: log title preset (editable), entryType default Observation, occurredAt default now.
  - Backend: logEntryId, scenarioId, occurredAt, entryType, isSystemGenerated=false.
- **KPI evidence (only when evidenceType=KPI)**
  - UI: metricName (required), value (required), unit (optional), period (e.g., Q3 2025), optional comparison note.
  - Backend: metricName, metricValue, metricUnit, metricPeriod, metricNote (optional).
- **File attachments (MVP 2)**
  - UI: file picker, filename, note.
  - Backend: attachmentId, parentType (log/evidence), parentId, fileBookmark/pathReference, mimeType, fileSize.

#### 🟡 Flow 3 — Write or update scenario (structured hypothesis)
*Status: Fully Specified & Partially Implemented (Auto-logs active)*

**User flow:** Create scenario → later edit → app records revision as an audit log.

**Steps**
1) Create/open scenario: Asset → Research Question → Scenario list → select or Add Scenario.
2) Write scenario (first time): fill required structure → Save; optionally create an initial system log entry.
3) Update scenario: Edit Scenario → change fields → Save.
4) Record revision: app generates an Update log entry summarizing changes and confidence deltas; re-index.
5) View: current scenario displayed at the top; timeline shows the revision entry.

**Fields required (UI + backend)**
- **Scenario (structured content)**
  - UI (minimum): scenarioType, title, scenarioStatement, keyDrivers, invalidationRules.
  - UI (optional): catalysts, keyRisks, preMortemText, confidence (1–5), status.
  - UI (display-only): lastUpdatedAt, lastReviewedAt, versionNumber.
  - Backend: scenarioId, researchQuestionId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt, status, statusChangedAt, confidenceCurrent, preMortemText, versionNumber.
- **Revision inputs (when editing)**
  - UI: revisionNote (short "what/why changed"), effectiveDate (default now).
  - Backend: editedAt, editedFrom (manual vs review), changedFieldKeys, previousVersionNumber.
- **Automatic revision Log Entry (system generated)**
  - UI (display): entryType=Update, diffSummary, confidenceBefore/After (if changed), related evidence links.
  - Backend: logEntryId, scenarioId, occurredAt, entryType=Update, isSystemGenerated=true, diffSummaryText, confidenceBefore, confidenceAfter, relatedEvidenceIds.

#### 🟢 Flow 4 — Revisit (review and decide)
*Status: Fully Specified & Implemented*

**User flow:** Trigger review → see a compact snapshot → choose outcome → answer minimal prompts → commit a review log.

**Steps**
1) Trigger review: scheduled notification (MVP 2) or manual Review button; optionally "Review now" after evidence capture.
2) Review pack: scenario summary + recent logs + recent evidence + current status/confidence.
3) Decide: Reinforce / Revise / Invalidate.
4) Guided prompts: minimal structured answers for the chosen outcome.
5) Commit: create Review log entry; if revise, update scenario and increment version; if invalidate, set status and timestamp; update lastReviewedAt and next reminder.
6) Return: highlight the review entry on the timeline.

**Fields required (UI + backend)**
- **Review trigger and schedule (MVP 2)**
  - UI: reviewCadence, nextReviewDueAt, snooze, disable reminders.
  - Backend: reminderId, scenarioId, scheduleRule, nextReviewDueAt, lastNotifiedAt, isEnabled.
- **Review pack (snapshot)**
  - UI: scenarioSummary, currentStatus, currentConfidence, lastReviewedAt, recentLogsSinceLastReview, evidenceSinceLastReview.
  - Backend: derived from occurredAt/capturedAt + scenario.lastReviewedAt.
- **Decision outcome**
  - UI: outcome enum (Reinforce, Revise, Invalidate).
  - Backend: reviewOutcome, statusBefore/statusAfter, confidenceBefore/confidenceAfter.
- **Prompt answers (structured capture)**
  - Reinforce UI: whatStrengthened, supportingEvidenceNotes, confidenceAfter.
  - Revise UI: whatChanged, driverChanged (pick/freeform), riskOrCatalystMoved, inline scenario edits, confidenceAfter.
  - Invalidate UI: invalidationTriggered (pick/freeform), whatWasMissed, takeaways.
  - Backend: reviewAnswerPayload (structured JSON), invalidationRuleId or invalidationText, changedDriverKey (optional), lessonsLearnedText.
- **Review Log Entry (created on commit)**
  - UI (display): entryType=Review, outcome badge, short summary, evidence links.
  - Backend: logEntryId, scenarioId, occurredAt, entryType=Review, reviewOutcome, reviewAnswerPayload, relatedEvidenceIds.
- **Scenario updates resulting from review**
  - UI: updated status/confidence; updated scenario fields if revised.
  - Backend: scenario.lastReviewedAt, scenario.lastUpdatedAt, scenario.status/statusChangedAt (if changed), scenario.confidenceCurrent, scenario.versionNumber++ (if revised).

## 9. Architecture (macOS-first)
**Recommended baseline**
- UI: SwiftUI.
- Persistence: SwiftData (Core Data if advanced requirements emerge).
- Search: local full-text search via SQLite FTS or Spotlight indexing.
- App structure: MVVM (or TCA if state complexity grows).
- Import/export: JSON and Markdown; backups compatible with Time Machine.
- Optional later: CloudKit sync (opt-in), AI via Core ML (local) or remote API (explicit opt-in).

## 10. Product Phases (Roadmap)
The development of Hyppo is structured into four distinct phases, moving from core infrastructure to advanced analytical tools. For a detailed list of features and their current implementation status, see [roadmap.md](roadmap.md).

### 🟢 MVP 0: Foundations
**Goal:** Establish the core navigation shell, local persistence layer, and basic CRUD operations for all primary entities.
- Focus on macOS-native feel and robust data integrity.
- Establish the "Asset → Research Question → Scenario → Log" hierarchy.

### 🟢 MVP 1: Core Workflow
**Goal:** Enable the primary research journaling workflow, allowing users to track their investment logic over time.
- Focus on timeline visualization and data portability.
- Implement tagging systems and basic search to manage growing research sets.
- *Status: Complete — Global Search, Advanced Filters, and Markdown Export implemented.*

### 🟡 MVP 2: Workflow Support
**Goal:** Streamline the "Quick Capture" of evidence and formalize the "Review Loop" to ensure research stays current.
- Focus on reducing friction for daily use (Global shortcuts, snippets).
- Implement guided review wizards to help users update or invalidate their theses.
- *Status: Partial — Review Mode complete, Pre-Mortem complete, Quick Capture designed (see docs/QuickCapture_Wireframe.md).*

### ⚪️ MVP 3: Premium Features
**Goal:** Provide advanced analytical depth and AI-assisted insights for power users.
- Focus on local AI summaries and behavioral analytics.
- Enhanced export formats for professional-grade research memos.

## 11. Definition of Done
- Acceptance criteria met.
- Unit tests for persistence, integrity rules, and exports.
- Basic UI tests for create/edit flows.
- No P0 crashes; acceptable performance on large datasets.
- Release notes and help/privacy docs updated.

## 11.1 Success Metrics
To measure the effectiveness of Hyppo and validate the workflow improvements identified in the validation report, the following metrics should be tracked (where technically feasible):

### Quick Capture Friction (MVP 2)
- **Target:** Time from shortcut/keyboard trigger to save completion < 5 seconds
- **Measurement:** Track capture abandonment rate (started but not completed)
- **Goal:** < 20% abandonment rate for Quick Capture flows

### Evidence Collection Rate
- **Target:** Average evidence items per week per active user
- **Measurement:** Track evidence creation frequency over time
- **Goal:** Establish baseline in MVP 1, aim for 2x increase with Quick Capture in MVP 2

### Review Completion Rate
- **Target:** % of scheduled reviews that are completed (not just snoozed)
- **Measurement:** Track review reminders vs. completed reviews
- **Goal:** > 70% completion rate for scheduled reviews

### Search Effectiveness
- **Target:** Users can find relevant information within 3 search queries
- **Measurement:** Track search result click-through rate
- **Goal:** > 60% of searches result in user navigating to a result

### Data Retention
- **Target:** Users maintain active research (at least 1 log entry per month)
- **Measurement:** Track monthly active users with new log entries
- **Goal:** > 50% of users remain active after 3 months

**Note:** Metrics collection should respect privacy constraints. Consider opt-in analytics or local-only tracking that users can review.

## 12. Risks and Mitigations
- **Scope creep:** Lock MVP 1 to journaling + search + export.
- **Storage complexity:** Keep schema minimal; plan migrations early.
- **Copyright:** Store links and short snippets with attribution.
- **Premium AI:** Additive and opt-in; never required for core.

## 13. Parking Lot (Explicitly Deferred)
- Stock-specific news dashboard/feed (auto-ingested) tied to tracked theses.
- Continuous automated internet “scouring” / research collector.
- Large-scale sentiment analysis of external articles.
- Cross-device sync and an iPhone companion app.
- Web app and/or self-hosted server edition.
- Brokerage integrations and performance overlays.
- Social/community features.
- Multi-user teams/workspaces.

## 14. Next Steps
Convert MVP 1 into a sprint plan (Sprint 0 setup; Sprint 1 CRUD; Sprint 2 timeline; Sprint 3 search/export) and create wireframes for: Asset list, Research Question detail, Scenario detail, Add Log, Timeline (collapsed/expanded), and Global Search.

---

### 📝 AI Maintenance Instructions
**CRITICAL for all AI Assistants:**
- **Keep this document synchronized:** Whenever a feature is implemented or its specification changes, update the corresponding flow in **Section 8.3**.
- **Emoji Status Tracking:** 
  - Use 🟢 for Fully Specified & Implemented.
  - Use 🟡 for Partially Specified or In Progress.
  - Use ⚪️ for Not Started or Requires Clarification.
- **Roadmap Alignment:** Ensure the high-level phase statuses in **Section 10** match the granular progress in `roadmap.md`.
- **Thoroughness:** If you modify a data model or a UI flow, verify if it impacts the "Fields required" or "Steps" listed in this document.

