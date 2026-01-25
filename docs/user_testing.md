## Testing Checklist
### 1. Global Search (⌘F)
*Access:*
[X] Press ⌘F from anywhere in the app → Global Search sheet opens
[X] Pressing a result navigates to it and dismisses the search sheet.
    - TODO: the search results are not browsable with keyboard arrows.
[ ] Menu: Edit → Global Search works
[X] "Done" button dismisses the sheet

**Search Functionality:**
[X] Type a ticker (e.g., "AAPL") → Assets with that ticker appear. 
[X] On home page in the search bar search recognizes the tickers and the given name.
[X] Type partial research question text → Questions appear
[X] Type scenario title text → Scenarios appear
[X] Type log entry content → Log entries appear
[X] Type evidence URL/snippet text → Evidence items appear
[X] No results shows "No results found" message

**Entity Type Filter:**
[X] Click entity type dropdown → Can select "All", "Assets", "Research Questions", etc.
[X] Selecting "Scenarios" only shows scenario results
[X] Selecting "All Types" shows results from all entity types

**Tag Filter:**
[X] Tags dropdown shows all existing tags
[X] Selecting a tag filters results to only items with that tag
[X] Works correctly for Assets, Scenarios, Log Entries, and Evidence

**Confidence Filter:**
[X] Confidence dropdown shows star levels (e.g., ★★★☆☆)
[X] Confidence levels are stars instead of "1/5" everywhere in the app
[X] Selecting a confidence level filters Scenarios and Log Entries
[X] Assets and Research Questions (which don't have confidence) are excluded when confidence filter is active

**Date Range Filter:**
[X] Click "Date Range" to expand advanced filters
[X] Setting start/end dates filters results
[X] "Clear" button resets date filters

**Results Display:**
[X] Results are grouped by entity type with headers
[X] Each result shows title and subtitle
[X] Result count shown in toolbar
### 2. Pre-Mortem Field

**Scenario Form (Add/Edit):**

TODO: The scenario form is wrong. The scenario form as it currently exists is what the research question should be. When I meant I wanted to create scenarios I was thinking of something simpler along the lines of the structure used for the key drivers and invalidation rules. 

Below invalidation rules we could have the following:
Scenario:
type :base/bull/bear:  title    (+) add item to add another case. 

TODO: the premortem field is unclear. How could that fit in the suggested way of working?
TODO: For every research question we only want one page. We don't want a list of all the scenarios. it becomes unmanageable. Each research question is like one report.


- [ ] Open "Add Scenario" → Expand "Optional Details" section
- [ ] Pre-Mortem field is visible with prompt text
- [ ] Can enter multi-line text
- [ ] Save scenario → Pre-Mortem text is saved

**Scenario Detail View:**
TODO: Remove all this
- [ ] View a scenario with Pre-Mortem text → "Pre-Mortem" section appears
- [ ] Section is collapsible (expand/collapse)
- [ ] "Expand All" / "Collapse All" includes Pre-Mortem section
- [ ] View a scenario without Pre-Mortem → Section does not appear

**Edit Existing:**
TODO: Remove all this
- [ ] Edit an existing scenario → Pre-Mortem text is pre-populated
- [ ] Modify and save → Changes persist
- [ ] Clear Pre-Mortem text → Section disappears from detail view

### 3. Markdown Export (Verify Still Working)
TODO: export button is broken.
**From Scenario Detail:**
- [ ] Click Export button (square with arrow) in toolbar
- [ ] File save dialog appears with .md extension
- [ ] Saved file contains scenario details, drivers, invalidation rules
- [ ] If Pre-Mortem text exists, it should be included in export

### 4. Review Wizard (Verify Still Working)

**Access:**
- [ ] From Scenario Detail → Click "Review" (wand icon) in toolbar
- [ ] Review wizard opens

**Flow:**
- [ ] Overview step shows scenario summary
- [ ] Key Drivers step allows marking drivers as valid/invalid
- [ ] Invalidation Rules step allows marking rules as triggered
- [ ] Outcome step suggests appropriate outcome based on assessments
- [ ] Summary step shows preview of review log
- [ ] Complete creates a review log entry

### 5. Edge Cases to Test

- [ ] Global Search with no data in app → Shows empty state gracefully
- [ ] Global Search with special characters in search text
- [ ] Pre-Mortem with very long text (500+ characters)
- [ ] Multiple scenarios with same title → Both appear in search
- [ ] Archived assets → Should they appear in Global Search? (Current: yes)

---

### Test Data Suggestion

If you don't have enough test data, create:
- 2–3 Assets with different tickers
- 1–2 Research Questions per asset
- Bull/Base/Bear scenarios for at least one question
- Some scenarios WITH Pre-Mortem text, some WITHOUT
- Log entries with varying confidence levels
- Tags applied to different entities
- Evidence items attached to log entries

---

**Let me know what feedback you have after testing, especially:**
- Any crashes or errors
- UX friction (things that feel awkward)
- Missing features you expected
- Performance issues with larger datasets