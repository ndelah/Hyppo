# Smoke Test User Journeys

## JOURNEY: Create a research question with drivers

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- Research question is created with thesis and drivers.
- Drivers are linked to the research question.
- Research question appears in records.

Main path:
1. Draft a thesis and add drivers.
2. Save the research question.
3. Open the question to confirm drivers.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Add a driver-linked log entry with evidence

Actor: Researcher  
Preconditions: Research question with at least one driver exists.  
Success guarantees (must be true at the end):
- Log entry is created and linked to the question.
- Evidence is created and linked to the selected driver.
- Evidence is visible in the driver timeline.

Main path:
1. Create a log entry and select a driver.
2. Save the log entry.
3. Confirm evidence is attached to the driver.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Capture evidence via Quick Capture

Actor: Researcher  
Preconditions: Asset and driver exist.  
Success guarantees (must be true at the end):
- Evidence is created and linked to the driver.
- A log entry is created and linked to the research question.
- Research question updated timestamp changes.

Main path:
1. Select asset, question, and driver.
2. Capture evidence details.
3. Save the capture.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Complete a structured review

Actor: Researcher  
Preconditions: Research question with drivers exists.  
Success guarantees (must be true at the end):
- Decision is recorded with driver snapshot counts.
- Driver statuses update based on assessments.
- Research question confidence and last-reviewed timestamp update.

Main path:
1. Assess drivers and select a review outcome.
2. Record the decision.
3. Complete the review.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Record an investment decision

Actor: Researcher  
Preconditions: Research question exists.  
Success guarantees (must be true at the end):
- Decision is saved with rationale.
- Investment phase updates when required.
- Decision appears in the decision timeline.

Main path:
1. Select a decision action.
2. Provide rationale and save.
3. Confirm decision is listed.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Record an outcome after exit or abandon

Actor: Researcher  
Preconditions: Research question is in exited or abandoned phase.  
Success guarantees (must be true at the end):
- Outcome is recorded with assessments and narrative.
- Research question transitions to post-mortem phase.
- Outcome appears in the research history.

Main path:
1. Enter outcome details.
2. Save the outcome.
3. Confirm the thesis is marked complete.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Export full data to JSON

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- JSON export includes all data types.
- Export file is saved to the chosen location.
- Local data is unchanged.

Main path:
1. Start JSON export.
2. Save the file.
3. Verify export completes.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Import JSON with merge or replace

Actor: Researcher  
Preconditions: Valid export JSON exists.  
Success guarantees (must be true at the end):
- Data is imported according to the selected mode.
- Imported assets include related questions, drivers, and evidence.
- Import summary is shown.

Main path:
1. Choose merge or replace mode.
2. Import the JSON file.
3. Review the import summary.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Recover from store load failure by reset

Actor: Researcher  
Preconditions: Local store fails to load.  
Success guarantees (must be true at the end):
- Store files are deleted and recreated.
- App launches with a fresh empty store.
- Prior data is lost unless a backup exists.

Main path:
1. Launch the app with a corrupted store.
2. Allow automatic reset.
3. Confirm the app opens successfully.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication


