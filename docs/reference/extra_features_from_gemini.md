Here is the functional specification designed for the engineering team. This translates Sarah’s user story into actionable technical requirements, grouped by the four loops of the Hyppo architecture.

// TODO:

### Feature Specification: Hyppo v1.0

#### 1. The Setup Loop (Thesis Initialization)

**Objective:** Enable the user to create a structured, falsifiable research framework before data collection begins.

| Feature ID | Feature Name | User Story Reference | Functional Requirement | UI/UX Elements | Dev Notes / Constraints |
| --- | --- | --- | --- | --- | --- |
| **S-01** | **Thesis Document Container** | Sarah creates a new notebook for `$GRID`. | Create a persistent object for a specific asset (Ticker) that holds text, metadata, and history. | Main view. "Clean Slate" text editor. Auto-fetch current Asset Price/Name via API upon ticker entry. | Local-first storage (SQLite/CoreData). Support Markdown syntax. |
| **S-02** | **Scenario Matrix** | Sarah inputs Bull/Base/Bear targets. | 3-Column input form requiring: 1. Price Target (Float), 2. Probability (%), 3. Narrative Summary (String). | Fixed table layout (cannot be deleted). Validation: Probabilities do not need to sum to 100% (independent scenarios). | Fields must be queryable later for the "Audit" comparison. |
| **S-03** | **Critical Question Builder** | Sarah types Q1 and Q2 regarding debt/batteries. | Dynamic list builder. Users can add/remove questions *only* during the Draft phase. | "Add Question" button. Drag-and-drop reordering. | These entries become unique `ID` tags for the Capture Loop. |
| **S-04** | **Conviction Slider** | Sarah sets confidence to 60%. | Input mechanism to set an integer value (0-100) representing subjective confidence. | Horizontal slider or draggable gauge. Color gradient (Red 0% -> Green 100%). | Store value with timestamp. Must be linked to the specific Thesis Version. |
| **S-05** | **Version Commit (Lock)** | Sarah clicks "Lock V1.0". | Freezes the current state of S-01 through S-04. Transitions status from "Draft" to "Active." | "Commit Thesis" button. Visual lock icon appears. | Triggers creation of `Thesis_Version_1.0` in the database. |

---

#### 2. The Capture Loop (Evidence Ingestion)

**Objective:** Reduce friction for data entry while enforcing structure (tagging evidence to questions).

| Feature ID | Feature Name | User Story Reference | Functional Requirement | UI/UX Elements | Dev Notes / Constraints |
| --- | --- | --- | --- | --- | --- |
| **C-01** | **Global Quick-Capture** | Sarah hits `Cmd+Shift+H` over Excel. | System-wide floating window that accepts text/links without focusing the main app window. | macOS Menu Bar app / Spotlight-style modal. Transparency effects. | Must listen for global hotkeys even when app is in background. |
| **C-02** | **Evidence Context Linker** | Sarah pastes CFO quote. | Auto-detect content type (URL vs. Text). If URL, fetch metadata (Title/Favicon). | Text area with auto-formatting. "Paste" support. | Async fetching of URL metadata to avoid UI blocking. |
| **C-03** | **Question Bucketing** | Sarah tags "Q1 Debt Refinancing". | Dropdown list populated *only* by the Active Thesis's "Critical Questions" (from S-03). | Autocomplete dropdown. | Filter logic: Only show questions for the currently selected Ticker/Thesis. |
| **C-04** | **Sentiment Tagger** | Sarah marks quote as "Bearish". | Assign a directional value (-1, 0, +1) to the evidence snippet. | 3-State Toggle Switch (Red Down Arrow / Gray Dash / Green Up Arrow). | Default to "Neutral" if untouched. |

---

#### 3. The Update Loop (Synthesis & Revision)

**Objective:** Facilitate thesis evolution and track changes in rationale (Thesis Drift).

| Feature ID | Feature Name | User Story Reference | Functional Requirement | UI/UX Elements | Dev Notes / Constraints |
| --- | --- | --- | --- | --- | --- |
| **U-01** | **Split-Screen Workbench** | Sarah reviews Thesis vs. Evidence. | Dual-pane view. Left: Thesis Text (Editable). Right: Evidence Feed (Read-only, filtered by Question). | Resizable split panes. Sync scrolling optional. | The "Right Pane" queries the Evidence table for all items captured since last Commit. |
| **U-02** | **Semantic Diff Engine** | Sarah changes rationale text. | Track character-level insertions/deletions between V_current and V_new. | Highlight additions in Green, deletions in Red (standard diff UI). | Use standard Diff algorithm. Store only the "Delta" to save space? Or full snapshots (easier)? |
| **U-03** | **Drift Guardrail Logic** | Sarah tries to save without changing score. | Logic Check: If `Sentiment_Sum` of new evidence is significantly negative BUT `Conviction_Score` is unchanged -> Trigger Alert. | Modal Popup: "Significant Bearish Evidence detected. Update Conviction?" | Requires a weighting algorithm for sentiment (e.g., 3 Bearish notes > Threshold). |
| **U-04** | **Re-Commit Workflow** | Sarah saves V1.1. | Saves new snapshot. Archives V1.0. Updates the "Current Active" pointer. | "Save New Version" button. | Must force a comment or "Reason for Update" entry. |

---

#### 4. The Audit Loop (Retrospective Analysis)

**Objective:** Visualize the correlation between decision process and investment outcome.

| Feature ID | Feature Name | User Story Reference | Functional Requirement | UI/UX Elements | Dev Notes / Constraints |
| --- | --- | --- | --- | --- | --- |
| **A-01** | **Conviction vs. Price Plot** | Sarah views the timeline graph. | X-Axis: Time. Y1-Axis: Stock Price (API). Y2-Axis: Conviction Score (User Data). | Interactive Line Chart using library (e.g., D3, Swift Charts). | Price data needs to be cached so it works offline. |
| **A-02** | **Decision Node Expansion** | Sarah clicks "Update V1.1" dot. | Interactivity: Clicking a timestamp on the graph reveals the Thesis Snapshot and Evidence from that specific moment. | Pop-over or "Inspector" side panel showing historical state. | Read-only view of the database at time `t`. |
| **A-03** | **Outcome Categorization** | Sarah tags "Right Process/Good Outcome". | Final state logging. Input 4-quadrant logic: Good/Bad Process vs. Win/Loss Result. | Matrix selection tool or tagging field. | This data feeds the global dashboard/stats page. |

---

### Technical Architecture Overview

* **Platform:** Native macOS (Swift/SwiftUI).
* **Local Database:** CoreData or Realm (Critical for offline "Deep Work" and privacy).
* **External APIs:** Financial Data Provider (e.g., IEX Cloud, Alpha Vantage) for fetching Stock Price history for the Audit loop.
* **Sync (Optional for V2):** CloudKit for syncing between Mac and iPad, but V1 should focus on local-first speed.

**Would you like me to outline the specific "Drift Guardrail" algorithm logic in pseudocode?**