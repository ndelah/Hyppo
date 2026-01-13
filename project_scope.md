# Footnote
## Statement of Work (macOS)

## 1. Project summary
Footnote is a native macOS application for tracking **investment theses** (the reasoning), not portfolio performance. Users track companies (assets), create one or more theses per asset (e.g., base/bull/bear), and append timestamped log entries with evidence links, short snippets, and local attachments. The result is a searchable, chronological record of what the user believed, when they believed it, and what information led them to reinforce, revise, or invalidate a thesis.

## 2. Objectives
- Make thesis capture fast enough for daily use.
- Preserve a high-integrity audit trail of beliefs, evidence, and revisions.
- Support multiple scenario theses per asset and enable lightweight comparison.
- Keep the UI clean even when entries carry rich metadata.
- Operate fully offline with robust local persistence and backups.
- Provide a premium upgrade path without bloating core workflows.

## 3. Target users and Pareto workflow
Target users are research-driven retail investors and semi-pro analysts who take notes, read filings/news, and revisit decisions.

The product must support this end-to-end workflow:
1) Choose/track a company (start research or ongoing coverage).
2) Collect key evidence (article, filing, note, KPI, quote) via quick capture.
3) Write or update a thesis (what must be true; catalysts; risks; invalidation rules).
4) Revisit (scheduled review or prompted by new evidence) and decide: reinforce, revise, or invalidate.

## 4. Deliverables
- macOS application (universal build where feasible).
- Local data model and persistence layer.
- Core UI flows: Assets, Theses, Thesis Detail, Timeline, Global Search, Settings.
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
- One primary action per screen: the next step is always obvious (Add Asset / Add Thesis / Add Log).
- Fast capture: keyboard-first flows, minimal forms, autosaved drafts.
- Opinionated structure + flexible text: structured fields for drivers/invalidation; freeform notes for nuance.
- Strong hierarchy: typography and spacing carry meaning; color remains an accent.
- Consistency: repeat patterns across assets, theses, and logs.
- Reversibility: undo where practical; confirmations for destructive actions.
- Local resilience: export and backups are first-class features.
- Accessibility: keyboard navigation and readable defaults.

## 8. System overview

### 8.1 Core components
- **UI (SwiftUI):** Assets, Asset Detail, Thesis Detail, Add/Edit sheets, Timeline, Global Search, Settings/Export.
- **Domain layer:** models and business rules (integrity constraints, lifecycle transitions, validation).
- **Persistence:** SwiftData (or Core Data if advanced requirements emerge), local storage, optional encryption at rest.
- **Search/indexing:** local full-text search (SQLite FTS or Spotlight where appropriate) plus facets/filters.
- **Capture/attachments:** URL capture, snippet storage, optional local files (PDF/images) stored in the app sandbox.
- **Export/backup:** JSON export/import; Markdown exports; versioned backup folder.
- **Notifications (MVP 2):** local reminders for review cadence.

### 8.2 Core data model (conceptual)
- **Asset:** a tracked company/security.
- **Thesis:** a hypothesis thread under an asset (base/bull/bear/custom).
- **Log Entry:** a point-in-time journal entry attached to a thesis.
- **Evidence:** a link/snippet/KPI/quote attached to a log entry.
- **Review Reminder:** local schedule metadata for thesis review.

### 8.3 End-to-end flows and required fields

#### Flow 1 — Choose/track a company (start coverage)
**User flow:** Open app → Add Asset → Create first thesis → Add first log → (optional) attach evidence → View timeline.

**Steps**
1) First launch: empty state with Add Asset.
2) Add Asset: ticker/name (optional tags) → Save.
3) Add Thesis: choose type → complete structured thesis → Save.
4) Add Log Entry: title/body (optional tags/confidence/type) → Save.
5) Attach Evidence (optional): add URL (optional snippet/annotation) → Save.
6) View: timeline shows compact markers; expand to read; global search available.
7) Export/backup (optional): export JSON/Markdown; enable a backup folder.

**Fields required (UI + backend)**
- **Asset**
  - UI: ticker (required), name (required), exchange (optional), currency (optional), tags (optional).
  - Backend: assetId, tickerNormalized, createdAt, updatedAt, archivedAt (optional), tagIds.
- **Thesis**
  - UI: thesisType, title, thesisStatement (required), keyDrivers (required list), invalidationRules (required list), catalysts (optional), keyRisks (optional), confidence (optional 1–5), status (default Active).
  - Backend: thesisId, assetId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt (optional), status, statusChangedAt, confidenceCurrent, versionNumber.
- **Log Entry**
  - UI: occurredAt (default now), title (required), body (required), entryType (Observation/Update/Risk/Catalyst/Review), tags (optional), confidence (optional 1–5), indicators (evidence count, attachment count).
  - Backend: logEntryId, thesisId, createdAt, updatedAt, occurredAt, entryType, tagIds, confidence, isSystemGenerated, isPinned (optional).
- **Evidence (when attached)**
  - UI: url (required), displayTitle (optional), evidenceType, snippetText (optional, limited), userAnnotation (optional).
  - Backend: evidenceId, logEntryId, capturedAt, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText, tagIds.

#### Flow 2 — Collect key evidence (Quick Capture)
**User flow:** Copy URL/snippet → Quick Capture → pick destination → Save → index → jump to entry.

**Steps**
1) Start capture: user copies URL/snippet from browser/PDF and triggers Quick Capture (menu bar or shortcut).
2) Choose destination: pick/create Asset; pick/create Thesis; attach to a new log (default) or an existing log.
3) Describe evidence: URL (required), auto title (editable), evidence type, snippet/annotation, tags.
4) Save: write Evidence locally; link to log entry; update thesis lastUpdatedAt; index for search.
5) Confirm: lightweight confirmation with “Go to entry.”

**Fields required (UI + backend)**
- **Quick Capture inputs**
  - UI: url (required), displayTitle (auto/editable), evidenceType (Article/Filing/KPI/Quote/Note), snippetText (optional, limited), userAnnotation (optional), tags (optional).
  - Backend: evidenceId, createdAt, updatedAt, capturedAt, evidenceType, urlRaw, urlNormalized, domain, sourceTitle, snippetText, annotationText, tagIds.
- **Destination context selector**
  - UI: Asset picker/search + inline create (ticker, name, tags); Thesis picker/search + inline create (type, title, minimal thesisStatement); attachTo (new log by default vs existing log).
  - Backend: selectedAssetId, selectedThesisId, selectedLogEntryId (or createNewLogEntry flag).
- **Auto-created Log Entry (when attachTo=new log)**
  - UI: log title preset (editable), entryType default Observation, occurredAt default now.
  - Backend: logEntryId, thesisId, occurredAt, entryType, isSystemGenerated=false.
- **KPI evidence (only when evidenceType=KPI)**
  - UI: metricName, value, unit, period (e.g., Q3 2025), optional comparison note.
  - Backend: metricName, metricValue, metricUnit, metricPeriod, metricNote (optional).
- **File attachments (MVP 2)**
  - UI: file picker, filename, note.
  - Backend: attachmentId, parentType (log/evidence), parentId, fileBookmark/pathReference, mimeType, fileSize.

#### Flow 3 — Write or update thesis (structured hypothesis)
**User flow:** Create thesis → later edit → app records revision as an audit log.

**Steps**
1) Create/open thesis: Asset → Thesis list → select or Add Thesis.
2) Write thesis (first time): fill required structure → Save; optionally create an initial system log entry.
3) Update thesis: Edit Thesis → change fields → Save.
4) Record revision: app generates an Update log entry summarizing changes and confidence deltas; re-index.
5) View: current thesis displayed at the top; timeline shows the revision entry.

**Fields required (UI + backend)**
- **Thesis (structured content)**
  - UI (minimum): thesisType, title, thesisStatement, keyDrivers, invalidationRules.
  - UI (optional): catalysts, keyRisks, confidence (1–5), status.
  - UI (display-only): lastUpdatedAt, lastReviewedAt, versionNumber.
  - Backend: thesisId, assetId, createdAt, updatedAt, lastUpdatedAt, lastReviewedAt, status, statusChangedAt, confidenceCurrent, versionNumber.
- **Revision inputs (when editing)**
  - UI: revisionNote (short “what/why changed”), effectiveDate (default now).
  - Backend: editedAt, editedFrom (manual vs review), changedFieldKeys, previousVersionNumber.
- **Automatic revision Log Entry (system generated)**
  - UI (display): entryType=Update, diffSummary, confidenceBefore/After (if changed), related evidence links.
  - Backend: logEntryId, thesisId, occurredAt, entryType=Update, isSystemGenerated=true, diffSummaryText, confidenceBefore, confidenceAfter, relatedEvidenceIds.

#### Flow 4 — Revisit (review and decide)
**User flow:** Trigger review → see a compact snapshot → choose outcome → answer minimal prompts → commit a review log.

**Steps**
1) Trigger review: scheduled notification (MVP 2) or manual Review button; optionally “Review now” after evidence capture.
2) Review pack: thesis summary + recent logs + recent evidence + current status/confidence.
3) Decide: Reinforce / Revise / Invalidate.
4) Guided prompts: minimal structured answers for the chosen outcome.
5) Commit: create Review log entry; if revise, update thesis and increment version; if invalidate, set status and timestamp; update lastReviewedAt and next reminder.
6) Return: highlight the review entry on the timeline.

**Fields required (UI + backend)**
- **Review trigger and schedule (MVP 2)**
  - UI: reviewCadence, nextReviewDueAt, snooze, disable reminders.
  - Backend: reminderId, thesisId, scheduleRule, nextReviewDueAt, lastNotifiedAt, isEnabled.
- **Review pack (snapshot)**
  - UI: thesisSummary, currentStatus, currentConfidence, lastReviewedAt, recentLogsSinceLastReview, evidenceSinceLastReview.
  - Backend: derived from occurredAt/capturedAt + thesis.lastReviewedAt.
- **Decision outcome**
  - UI: outcome enum.
  - Backend: reviewOutcome, statusBefore/statusAfter, confidenceBefore/confidenceAfter.
- **Prompt answers (structured capture)**
  - Reinforce UI: whatStrengthened, supportingEvidenceNotes, confidenceAfter.
  - Revise UI: whatChanged, driverChanged (pick/freeform), riskOrCatalystMoved, inline thesis edits, confidenceAfter.
  - Invalidate UI: invalidationTriggered (pick/freeform), whatWasMissed, takeaways.
  - Backend: reviewAnswerPayload (structured JSON), invalidationRuleId or invalidationText, changedDriverKey (optional), lessonsLearnedText.
- **Review Log Entry (created on commit)**
  - UI (display): entryType=Review, outcome badge, short summary, evidence links.
  - Backend: logEntryId, thesisId, occurredAt, entryType=Review, reviewOutcome, reviewAnswerPayload, relatedEvidenceIds.
- **Thesis updates resulting from review**
  - UI: updated status/confidence; updated thesis fields if revised.
  - Backend: thesis.lastReviewedAt, thesis.lastUpdatedAt, thesis.status/statusChangedAt (if changed), thesis.confidenceCurrent, thesis.versionNumber++ (if revised).

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
- **Navigation shell (sidebar → asset → thesis → timeline)**: **Done**
- **Local persistence (SwiftData)**: **Done**
- **CRUD for core entities**
  - Asset: **Done**
  - Thesis: **Done**
  - Log Entry: **Done**
  - Evidence: **Done**
- **Settings window**: **Done** (export/import/backup actions are UI placeholders only)
- **Review reminders entity**: **Done** (ReviewReminder model with cadence, scheduling, snooze)
- **Review reminders workflow/UI**: **Not done** (MVP 2)

## 11. Feature backlog and Scrum ticketing
Epics (user stories + tickets) are organized by MVP phase.

### Epic A — App shell and navigation (MVP 0)
User flow: open app → assets → asset → theses → thesis → timeline.
- A1 (**Done**): SwiftUI shell (sidebar + detail) with Settings.
- A2 (**Done**): Routing/state management; robust empty states.

### Epic B — Local persistence and data model (MVP 0)
- B1 (**Done**): Define entities (Asset, Thesis, Log Entry, Evidence, Review Reminder).
- B2 (**Done**): Implement persistence; cascading deletes; performance targets.
- B3 (**Done**): Integrity rules and validation.

### Epic C — Assets management (MVP 1)
- C1 (**Done**): Asset list view + search.
- C2 (**Done**): Add/edit/delete asset.
- C3 (**Not done**): Asset tags + tag filtering.

### Epic D — Thesis threads per asset (MVP 1)
- D1 (**Done**): Thesis list under asset.
- D2 (**Done**): Create/edit thesis (structured fields).
- D3 (**Not done**): Thesis lifecycle statuses + auto log on status change. *(Statuses exist; no auto-log on change.)*

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
- G1 (**Not done**): Global search across assets/theses/logs/evidence.
- G2 (**Not done**): Filters (date, tags, confidence, entry type).

### Epic H — Export, backup, portability (MVP 1)
- H1 (**Not done**): Export/import JSON.
- H2 (**Not done**): Export Markdown per thesis.
- H3 (**Not done**): Automatic local backups (versioned folder).

### Epic I — Review loop and reminders (MVP 2)
- I1 (**Not done**): Local reminder scheduling per thesis.
- I2 (**Not done**): Review mode wizard (reinforce/revise/invalidate).
- I3 (**Not done**): Structured review log generation.

### Epic J — Scenario comparison (MVP 2)
- J1 (**Not done**): Scenario grouping (bull/base/bear) per asset.
- J2 (**Not done**): Compare view (drivers/invalidation side-by-side).
- J3 (**Not done**): “Which is playing out?” selector that creates a log.

### Epic K — Premium features (MVP 3)
- K1 (**Not done**): Behavioral analytics dashboard.
- K2 (**Not done**): AI-assisted thesis summaries (editable, non-destructive).
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
Convert MVP 1 into a sprint plan (Sprint 0 setup; Sprint 1 CRUD; Sprint 2 timeline; Sprint 3 search/export) and create wireframes for: Asset list, Thesis detail, Add Log, Timeline (collapsed/expanded), and Global Search.

