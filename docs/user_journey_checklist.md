# Asset & Research Setup

## JOURNEY: Create an asset record

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- Asset exists with normalized ticker and name.
- Asset is persisted in local store.
- Asset is available for linking to research questions.

Main path:
1. Provide ticker and company name.
2. Save the asset.
3. Use the asset as a destination for research.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Create a research question with drivers and tags

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- Research question is created with thesis/context.
- Drivers (and sub-drivers) are created and linked to the question.
- Tags are created (if new) and linked to the question.

Main path:
1. Draft a thesis and context.
2. Add drivers and optional sub-drivers.
3. Save the research plan.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Edit a research question and refresh drivers

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Question fields are updated and version increments.
- Prior drivers are removed and replaced by the new set.
- Updated timestamp reflects the change.

Main path:
1. Open an existing research question.
2. Modify thesis/context and driver structure.
3. Save changes.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Duplicate a research question

Actor: Researcher  
Preconditions: At least one research question exists.  
Success guarantees (must be true at the end):
- A new research question is created with "(Copy)" in the title.
- Asset, status, and tags are preserved on the duplicate.
- Original question remains unchanged.

Main path:
1. Select one or more research questions.
2. Duplicate the selection.
3. Confirm the new copies are created.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Delete a research question and cascade data

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- The research question is removed from the local store.
- Related drivers, tasks, log entries, decisions, and outcomes are removed.
- Recovery is only possible via a prior export/import.

Main path:
1. Select a research question.
2. Delete it.
3. Verify it no longer appears in any lists.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Create and apply a tag during research setup

Actor: Researcher  
Preconditions: Research question creation/edit in progress.  
Success guarantees (must be true at the end):
- Tag is created with normalized name and optional color.
- Tag is linked to the research question.
- Tag is reusable in future entries.

Main path:
1. Enter a new tag name.
2. Save the tag.
3. Finish saving the research question.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Research Question State & History

## JOURNEY: Change research question status with audit trail

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Status changes to the selected state.
- A system-generated log entry records the status change.
- Research question updated timestamp changes.

Main path:
1. Select a research question.
2. Change its status.
3. Confirm the status change appears in history.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Change research confidence with audit trail

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Confidence is updated to the new level.
- A system-generated log entry records the change.
- Research question updated timestamp changes.

Main path:
1. Select a research question.
2. Update confidence level.
3. Confirm the history entry is added.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Change asset assignment with audit trail

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Research question asset link is updated.
- A system-generated log entry records the assignment change.
- Research question updated timestamp changes.

Main path:
1. Select a research question.
2. Assign a different asset or remove the asset.
3. Confirm history reflects the change.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Log Entries & Evidence

## JOURNEY: Add a log entry to a research question

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Log entry is created and linked to the research question.
- Log entry appears in the research timeline.
- Research question updated timestamp changes.

Main path:
1. Draft a log entry with title and body.
2. Save the log entry.
3. Confirm it appears in the timeline.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Add a driver-linked log entry with auto evidence

Actor: Researcher  
Preconditions: A research question with drivers exists.  
Success guarantees (must be true at the end):
- Log entry is created and linked to the research question.
- An evidence item is auto-created and linked to the selected driver.
- Driver evidence list reflects the new evidence.

Main path:
1. Create a log entry and select a driver.
2. Save the log entry.
3. Confirm evidence appears under the driver.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Edit a log entry and keep evidence aligned

Actor: Researcher  
Preconditions: A log entry exists.  
Success guarantees (must be true at the end):
- Log entry content reflects edits.
- Evidence is updated or re-linked if driver changes.
- Evidence is removed if the driver link is cleared.

Main path:
1. Edit log entry title/body and driver link.
2. Save changes.
3. Confirm evidence links are correct.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Pin or unpin a log entry

Actor: Researcher  
Preconditions: A log entry exists.  
Success guarantees (must be true at the end):
- Log entry pin state toggles.
- Pinned status persists across views.
- Updated timestamp changes.

Main path:
1. Toggle the pin state.
2. Confirm pinned state is reflected.
3. Continue research.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Delete a log entry

Actor: Researcher  
Preconditions: A log entry exists.  
Success guarantees (must be true at the end):
- Log entry is removed from the research question.
- Related evidence is removed if attached.
- Recovery is only possible via prior export/import.

Main path:
1. Select a log entry.
2. Delete it.
3. Confirm it no longer appears in the timeline.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Add evidence directly to a driver

Actor: Researcher  
Preconditions: A research question with drivers exists.  
Success guarantees (must be true at the end):
- Evidence is created with sentiment/source metadata.
- Evidence is linked to the selected driver.
- Evidence appears in driver summaries and analytics.

Main path:
1. Select a driver to target.
2. Enter evidence details and save.
3. Confirm evidence appears under the driver.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Edit existing evidence

Actor: Researcher  
Preconditions: Evidence exists.  
Success guarantees (must be true at the end):
- Evidence fields reflect changes, including type and metadata.
- Evidence remains linked to the intended driver.
- Updated timestamp changes.

Main path:
1. Edit evidence fields.
2. Save changes.
3. Confirm evidence displays updated data.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Tasks

## JOURNEY: Create a task (inbox or assigned)

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- Task is created with the intended text.
- Task is linked to a research question and/or driver when provided.
- Inbox tasks remain unassigned.

Main path:
1. Enter a task description.
2. Optionally assign to a question or driver.
3. Save the task.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Toggle task completion

Actor: Researcher  
Preconditions: A task exists.  
Success guarantees (must be true at the end):
- Completion state toggles correctly.
- Completed timestamp is set or cleared.
- Task lists reflect the updated state.

Main path:
1. Mark the task complete or incomplete.
2. Confirm the state change persists.
3. Continue work.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Delete a task

Actor: Researcher  
Preconditions: A task exists.  
Success guarantees (must be true at the end):
- Task is removed from local store.
- Task is unlinked from its question and driver.
- Recovery is only possible via prior export/import.

Main path:
1. Select a task.
2. Delete it.
3. Confirm it no longer appears.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Reviews & Reminders

## JOURNEY: Enable review reminders with scheduling

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Reminder is created and linked to the question.
- Next review date is scheduled based on cadence.
- Notification is scheduled if permission is granted.

Main path:
1. Enable review reminders.
2. Choose cadence.
3. Confirm next review date is set.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Disable review reminders

Actor: Researcher  
Preconditions: A reminder exists.  
Success guarantees (must be true at the end):
- Reminder is disabled.
- Pending notification is canceled.
- Reminder remains linked for later re-enable.

Main path:
1. Disable the reminder.
2. Confirm notifications stop.
3. Optionally re-enable later.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Snooze a review reminder

Actor: Researcher  
Preconditions: A reminder exists and is enabled.  
Success guarantees (must be true at the end):
- Snooze date is set and snooze count increments.
- Notification is rescheduled.
- Reminder is not due during snooze period.

Main path:
1. Choose a snooze duration.
2. Apply snooze.
3. Confirm due date is postponed.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Quick-complete a review without the wizard

Actor: Researcher  
Preconditions: A reminder exists and is enabled.  
Success guarantees (must be true at the end):
- Reminder schedules the next review date.
- Research question last-reviewed timestamp updates.
- A system-generated review log entry is created.

Main path:
1. Trigger quick review completion.
2. Confirm reminder is rescheduled.
3. Confirm a review log entry exists.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Complete a structured review (decision + driver updates)

Actor: Researcher  
Preconditions: A research question with drivers exists.  
Success guarantees (must be true at the end):
- A decision is recorded with driver snapshot counts.
- Driver statuses update based on assessments.
- Confidence and last-reviewed timestamp update.

Main path:
1. Assess each driver and select review outcome.
2. Record a decision with rationale.
3. Complete the review and persist changes.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Decisions & Outcomes

## JOURNEY: Record an investment decision

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Decision is saved with a snapshot of driver counts.
- Decision fields capture expectations and rationale.
- Investment phase updates when required (buy/exit/abandon).

Main path:
1. Select a decision action for the current phase.
2. Provide rationale and optional fields.
3. Save the decision.

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
- Outcome is saved with assessments and narrative.
- Research question transitions to post-mortem phase.
- Outcome is linked to the research question.

Main path:
1. Enter actual results and assessments.
2. Save the outcome.
3. Confirm the thesis is marked complete.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Quick Capture

## JOURNEY: Capture evidence quickly into a destination

Actor: Researcher  
Preconditions: At least one asset and driver exist.  
Success guarantees (must be true at the end):
- Evidence is created and linked to the selected driver.
- A log entry is created and linked to the research question.
- Research question and asset updated timestamps refresh.

Main path:
1. Select an asset, question, and driver.
2. Capture evidence details.
3. Save the capture.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Quick-capture creates a default research question if missing

Actor: Researcher  
Preconditions: Asset exists, no research question selected.  
Success guarantees (must be true at the end):
- A default research question is created for the asset.
- Evidence and log entry are linked to the new question.
- The capture is persisted.

Main path:
1. Select an asset and driver.
2. Save the capture.
3. Confirm the new research question exists.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Quick-capture save-and-continue preserves destination

Actor: Researcher  
Preconditions: Quick capture is open with destination selected.  
Success guarantees (must be true at the end):
- Current capture is saved successfully.
- Input fields reset while destination selections persist.
- Next capture uses preserved destination.

Main path:
1. Save with continue mode.
2. Add next capture details.
3. Save again.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Export & Import

## JOURNEY: Export a research question to Markdown

Actor: Researcher  
Preconditions: A research question exists.  
Success guarantees (must be true at the end):
- Markdown export includes thesis, drivers, timeline, and decisions.
- Exported file is saved to user-selected location.
- Export does not modify local data.

Main path:
1. Choose a research question.
2. Export to Markdown.
3. Verify file content.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Export full data to JSON backup

Actor: Researcher  
Preconditions: None.  
Success guarantees (must be true at the end):
- JSON file contains assets, questions, drivers, evidence, logs, decisions, outcomes, and tags.
- Export is saved to user-selected location.
- Export does not modify local data.

Main path:
1. Start JSON export.
2. Save the file.
3. Confirm export completes.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Import JSON with merge mode

Actor: Researcher  
Preconditions: A valid export JSON file exists.  
Success guarantees (must be true at the end):
- New assets are imported; existing tickers are skipped.
- Related questions, drivers, evidence, and logs are imported for new assets.
- Tags are deduplicated by normalized name.

Main path:
1. Choose merge mode.
2. Import JSON file.
3. Review import summary.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

## JOURNEY: Import JSON with replace mode

Actor: Researcher  
Preconditions: A valid export JSON file exists.  
Success guarantees (must be true at the end):
- Existing assets with matching tickers are deleted and recreated.
- Imported assets include their related questions, drivers, logs, and evidence.
- Recovery is only possible via prior export/import.

Main path:
1. Choose replace mode.
2. Import JSON file.
3. Review import summary.

Edge cases worth verifying:
- cancel
- invalid
- interruption
- empty state
- duplication

# Data Integrity & Recovery

## JOURNEY: Migrate legacy data on app launch

Actor: Researcher  
Preconditions: Existing data from a prior schema version.  
Success guarantees (must be true at the end):
- Research questions without drivers receive a default driver.
- Orphaned evidence is linked to a driver.
- Investment phase is initialized where missing.

Main path:
1. Launch the app after update.
2. Allow migration to run.
3. Verify data integrity checks pass.

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

## ⚠️ Unclear contract – needs product clarification

- Review wizard claims to generate a review log entry, but no log entry is created in code.
- Notification actions for "review now" and "snooze" are posted, but no handler is registered.
- "Replace" import mode UI warns about deleting all data, but code only replaces matching tickers.

## Critical journeys (high risk if broken)

- Create a research question with drivers and tags
- Add a driver-linked log entry with auto evidence
- Complete a structured review (decision + driver updates)
- Record an investment decision
- Record an outcome after exit or abandon
- Quick-capture evidence into a destination
- Export full data to JSON backup
- Import JSON with merge or replace mode
- Recover from store load failure by reset

