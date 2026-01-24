# Footnote
## Statement of Work (macOS)

## 1. Project summary
Footnote is a native macOS application for tracking **investment research questions and scenarios**, not portfolio performance. Users track companies (assets), create research questions, formulate scenarios (e.g., base/bull/bear) to answer those questions, and append timestamped log entries with evidence links, short snippets, and local attachments. The result is a searchable, chronological record of what the user believed, when they believed it, and what information led them to reinforce, revise, or invalidate a scenario.

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

#### Flow 1 — Choose/track a company and formulate research question (start coverage)
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
  - UI: scenarioType (bull/base/bear/custom), title, scenarioStatement (required), keyDrivers (required list), invalidationRules (required list), catalysts (optional), keyRisks (optional), confidence (optional 1–5), status (default Active).
  - Backend: scenarioId, researchQuestionId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt (optional), status, statusChangedAt, confidenceCurrent, versionNumber.
- **Log Entry**
  - UI: occurredAt (default now), title (required), body (required), entryType (Observation/Update/Risk/Catalyst/Review), tags (optional), confidence (optional 1–5), indicators (evidence count, attachment count).
  - Backend: logEntryId, scenarioId, createdAt, updatedAt, occurredAt, entryType, tagIds, confidence, isSystemGenerated, isPinned (optional).
- **Evidence (when attached)**
  - UI: url (required), displayTitle (optional), evidenceType, snippetText (optional, limited), userAnnotation (optional).
  - Backend: evidenceId, logEntryId, capturedAt, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText, tagIds.

#### Flow 2 — Collect key evidence (Quick Capture)
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
  - UI: metricName, value, unit, period (e.g., Q3 2025), optional comparison note.
  - Backend: metricName, metricValue, metricUnit, metricPeriod, metricNote (optional).
- **File attachments (MVP 2)**
  - UI: file picker, filename, note.
  - Backend: attachmentId, parentType (log/evidence), parentId, fileBookmark/pathReference, mimeType, fileSize.

#### Flow 3 — Write or update scenario (structured hypothesis)
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
  - UI (optional): catalysts, keyRisks, confidence (1–5), status.
  - UI (display-only): lastUpdatedAt, lastReviewedAt, versionNumber.
  - Backend: scenarioId, researchQuestionId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt, status, statusChangedAt, confidenceCurrent, versionNumber.
- **Revision inputs (when editing)**
  - UI: revisionNote (short "what/why changed"), effectiveDate (default now).
  - Backend: editedAt, editedFrom (manual vs review), changedFieldKeys, previousVersionNumber.
- **Automatic revision Log Entry (system generated)**
  - UI (display): entryType=Update, diffSummary, confidenceBefore/After (if changed), related evidence links.
  - Backend: logEntryId, scenarioId, occurredAt, entryType=Update, isSystemGenerated=true, diffSummaryText, confidenceBefore, confidenceAfter, relatedEvidenceIds.

#### Flow 4 — Revisit (review and decide)
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
  - UI: outcome enum.
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
- **Review pack (snapshot)**
  - UI: scenarioSummary, currentStatus, currentConfidence, lastReviewedAt, recentLogsSinceLastReview, evidenceSinceLastReview.
  - Backend: derived from occurredAt/capturedAt + scenario.lastReviewedAt.
- **Decision outcome**
  - UI: outcome enum.
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

## 10. Product phases (MVP roadmap)
- **MVP 0 (Foundations):** navigation shell + persistence + CRUD.
- **MVP 1 (Core v1):** assets/theses/logs + timeline + tags/search + export/backup.
- **MVP 2 (Workflow support):** Quick Capture, snippets/attachments, reminders + review mode, scenario comparison.
- **MVP 3 (Premium):** analytics dashboard, AI summaries/critique prompts, polished memo exports.

### MVP 0 implementation status (as built in this repo)
- **Navigation shell (sidebar → asset → research question → scenario → timeline)**: **Done**
- **Local persistence (SwiftData)**: **Done**
- **CRUD for core entities**
  - Asset: **Done**
  - Research Question: **Done**
  - Scenario: **Done**
  - Log Entry: **Done**
  - Evidence: **Done**
- **Settings window**: **Done** (export/import/backup actions are UI placeholders only)
- **Review reminders entity**: **Done** (ReviewReminder model with cadence, scheduling, snooze)
- **Review reminders UI**: **Done** (cadence selector, due badge, snooze/complete actions)
- **macOS notifications**: **Done** (UNUserNotificationCenter integration with snooze action)

## 11. Feature backlog and Scrum ticketing
Epics (user stories + tickets) are organized by MVP phase.

### Epic A — App shell and navigation (MVP 0)
User flow: open app → assets → asset → research questions → scenarios → timeline.
- A1 (**Done**): SwiftUI shell (sidebar + detail) with Settings.
- A2 (**Done**): Routing/state management; robust empty states.

### Epic B — Local persistence and data model (MVP 0)
- B1 (**Done**): Define entities (Asset, Research Question, Scenario, Log Entry, Evidence, Review Reminder).
- B2 (**Done**): Implement persistence; cascading deletes; performance targets.
- B3 (**Done**): Integrity rules and validation.

### Epic C — Assets management (MVP 1)
- C1 (**Done**): Asset list view + search.
- C2 (**Done**): Add/edit/delete asset.
- C3 (**Done**): Asset tags + tag filtering. *(Tag management, assignment in forms, sidebar filtering)*

### Epic D — Research questions and scenarios per asset (MVP 1)
- D1 (**Done**): Research question list under asset.
- D2 (**Done**): Create/edit research question (question text, context, priority).
- D3 (**Done**): Scenario list under research question.
- D4 (**Done**): Create/edit scenario (structured fields).
- D5 (**Done**): Scenario lifecycle statuses + auto log on status change.

### Epic E — Log entries and timeline (MVP 1)
- E1 (**Done**): Timeline view (compact markers; expand/collapse).
- E2 (**Not done**): Fast log creation (shortcut; drafts). *(Basic add log exists; no drafts/shortcut wiring.)*
- E3 (**Not done**): Log metadata (tags, confidence, entry type). *(Confidence + entry type exist; tags missing.)*
- E4 (**Not done**): UI density control via progressive disclosure.

### Epic F — Evidence (MVP 1 → MVP 2)
- F1 (MVP 1) (**Done**): Attach URL to a log.
- F2 (MVP 2) (**Not done**): Snippet capture with attribution.
- F3 (MVP 2) (**Not done**): File attachments (PDF/images) stored locally.

### Epic G — Search and filters (MVP 1)
- G1 (**Not done**): Global search across assets/research questions/scenarios/logs/evidence.
- G2 (**Not done**): Filters (date, tags, confidence, entry type).

### Epic H — Export, backup, portability (MVP 1)
- H1 (**Not done**): Export/import JSON.
- H2 (**Not done**): Export Markdown per scenario.
- H3 (**Not done**): Automatic local backups (versioned folder).

### Epic I — Review loop and reminders (MVP 2)
- I1 (**Done**): Local reminder scheduling per scenario. *(Cadence selector, due indicators, macOS notifications)*
- I2 (**Not done**): Review mode wizard (reinforce/revise/invalidate).
- I3 (**Partial**): Structured review log generation. *(Auto-creates log on "Complete Review", but no full wizard)*

### Epic J — Scenario comparison (MVP 2)
- J1 (**Not done**): Scenario grouping (bull/base/bear) per research question.
- J2 (**Not done**): Compare view (drivers/invalidation side-by-side).
- J3 (**Not done**): "Which is playing out?" selector that creates a log.

### Epic K — Premium features (MVP 3)
- K1 (**Not done**): Behavioral analytics dashboard.
- K2 (**Not done**): AI-assisted scenario summaries (editable, non-destructive).
- K3 (**Not done**): AI critique prompts (Socratic questioning).
- K4 (**Not done**): Premium export templates (investor memo).

## 12. Definition of Done
- Acceptance criteria met.
- Unit tests for persistence, integrity rules, and exports.
- Basic UI tests for create/edit flows.
- No P0 crashes; acceptable performance on large datasets.
- Release notes and help/privacy docs updated.

## 13. Risks and mitigations
- Scope creep: lock MVP 1 to journaling + search + export.
- Storage complexity: keep schema minimal; plan migrations early.
- Copyright: store links and short snippets with attribution.
- Premium AI: additive and opt-in; never required for core.

## 14. Parking lot (explicitly deferred)
- Stock-specific news dashboard/feed (auto-ingested) tied to tracked theses.
- Continuous automated internet “scouring” / research collector.
- Large-scale sentiment analysis of external articles.
- Cross-device sync and an iPhone companion app.
- Web app and/or self-hosted server edition.
- Brokerage integrations and performance overlays.
- Social/community features.
- Multi-user teams/workspaces.

## 15. Next step
Convert MVP 1 into a sprint plan (Sprint 0 setup; Sprint 1 CRUD; Sprint 2 timeline; Sprint 3 search/export) and create wireframes for: Asset list, Research Question detail, Scenario detail, Add Log, Timeline (collapsed/expanded), and Global Search.

