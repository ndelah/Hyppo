# Quick Capture HUD - Wireframe & Design Specification

## Overview

Quick Capture is a low-friction evidence collection mechanism that allows users to capture URLs, snippets, and notes from anywhere in macOS without interrupting their workflow. This document outlines the wireframe and design specifications for MVP 2 implementation.

## Design Goals

Based on the validation report (Section 2.2.2), Quick Capture must:
- **Minimize friction**: Target < 5 seconds from trigger to save
- **Maintain flow state**: No context switching away from browser/terminal
- **One-action save**: Minimal clicks required
- **Invisible when not needed**: Summon on demand, dismiss quickly

## User Flow

```
User copies URL/snippet → Triggers Quick Capture (⌘⇧H) → HUD appears → 
Auto-detects clipboard → User selects destination → Saves → HUD dismisses
```

## Wireframe Structure

### 1. HUD Panel (NSPanel with .floating level)

```
┌─────────────────────────────────────────────────┐
│  Quick Capture                          [×]     │
├─────────────────────────────────────────────────┤
│                                                  │
│  📋 Clipboard Content                            │
│  ┌──────────────────────────────────────────┐   │
│  │ https://example.com/article              │   │
│  │ [Auto-detected URL]                      │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  Or paste text snippet:                         │
│  ┌──────────────────────────────────────────┐   │
│  │                                          │   │
│  │                                          │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  Destination:                                    │
│  ┌──────────────────────────────────────────┐   │
│  │ Asset: [AAPL - Apple Inc.        ▼]      │   │
│  │ Question: [Select question...     ▼]      │   │
│  │ Scenario: [Select scenario...     ▼]      │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  [+ Create New Asset]  [+ Create Question]      │
│                                                  │
│  Evidence Type:                                  │
│  ○ Article  ○ Filing  ○ KPI  ○ Quote  ○ Note     │
│                                                  │
│  [Cancel]                    [Save & Continue]  │
└─────────────────────────────────────────────────┘
```

### 2. Compact Mode (After initial save)

For rapid successive captures, show a minimal version:

```
┌─────────────────────────────────────┐
│  Quick Capture              [×]     │
├─────────────────────────────────────┤
│  📋 [Paste or type snippet...]      │
│                                      │
│  → AAPL • Growth Scenario            │
│                                      │
│  [Save]  [Save & New]               │
└─────────────────────────────────────┘
```

## Component Specifications

### HUD Panel Properties
- **Type**: `NSPanel` with `level: .floating`
- **Size**: 500px × 400px (initial), 400px × 200px (compact)
- **Position**: Center of screen (or last position)
- **Behavior**: 
  - Appears on global shortcut (⌘⇧H)
  - Auto-focuses search field
  - Dismisses on Escape or click outside
  - Remembers last destination for faster subsequent captures

### Clipboard Auto-Detection

**URL Detection:**
- Regex pattern: `https?://[^\s]+`
- If clipboard contains URL → Auto-fill URL field
- Attempt to fetch page title (async, non-blocking)

**Text Snippet Detection:**
- If clipboard contains text (not URL) → Auto-fill snippet field
- Limit to 500 characters (copyright compliance)
- Show character count

**Mixed Content:**
- If clipboard contains both URL and text → Prefer URL, show text as snippet option

### Destination Picker

**Hierarchical Selection:**
1. **Asset Picker** (Required first)
   - Searchable dropdown
   - Shows: "TICKER - Name"
   - Recent assets at top
   - "+ Create New" option (inline form)

2. **Research Question Picker** (Optional)
   - Filtered by selected asset
   - Shows: Question text (truncated)
   - "+ Create New" option (inline form)

3. **Scenario Picker** (Optional)
   - Filtered by selected question
   - Shows: "Type: Title"
   - "+ Create New" option (inline form)

**Smart Defaults:**
- If user has a scenario selected in main app → Pre-fill that scenario
- If user has a question selected → Pre-fill that question
- Remember last used destination per session

### Inline Create Forms

When user clicks "+ Create New", show inline form:

**Create Asset:**
```
┌─────────────────────────────────────┐
│  Create New Asset                   │
│  Ticker: [AAPL        ]              │
│  Name:   [Apple Inc.  ]              │
│  [Cancel]  [Create]                  │
└─────────────────────────────────────┘
```

**Create Question:**
```
┌─────────────────────────────────────┐
│  Create New Research Question        │
│  Question: [Can AAPL sustain...]     │
│  [Cancel]  [Create]                  │
└─────────────────────────────────────┘
```

**Create Scenario:**
```
┌─────────────────────────────────────┐
│  Create New Scenario                 │
│  Type: [Bull ▼]  Title: [Growth...] │
│  [Cancel]  [Create Minimal]         │
└─────────────────────────────────────┘
```

### Evidence Type Selection

Radio buttons for:
- **Article** (default for URLs)
- **Filing** (SEC filings, 10-K/Q)
- **KPI** (metric data)
- **Quote** (expert/executive quotes)
- **Note** (user's own notes)

### Action Buttons

- **Cancel** (Escape key) - Dismiss without saving
- **Save** (Enter key) - Save and dismiss
- **Save & Continue** (⌘Enter) - Save and keep HUD open for next capture

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open Quick Capture | ⌘⇧H |
| Save | Enter |
| Save & Continue | ⌘Enter |
| Cancel | Escape |
| Focus destination | Tab |
| Create new (inline) | ⌘N |

## State Management

### Session State
- Last selected Asset
- Last selected Question  
- Last selected Scenario
- Last evidence type
- Compact mode preference

### Clipboard State
- Last clipboard content (to detect changes)
- Auto-detection result (URL vs Text)

## Error Handling

**Invalid URL:**
- Show warning: "Invalid URL format"
- Allow manual correction
- Still allow save as "Note" type

**No Destination Selected:**
- Disable Save button
- Show hint: "Select an asset to continue"

**Network Error (title fetch):**
- Silently fail
- Use URL as title
- Allow user to edit

## Accessibility

- VoiceOver support for all controls
- Keyboard navigation throughout
- High contrast mode support
- Focus indicators visible

## Implementation Notes

### File Structure
```
Hyppo/Views/QuickCapture/
  ├── QuickCaptureHUD.swift          # Main HUD panel
  ├── ClipboardDetector.swift         # URL/text detection
  ├── DestinationPicker.swift        # Hierarchical picker
  ├── InlineCreateForms.swift        # Quick create modals
  └── QuickCaptureService.swift      # Business logic
```

### Integration Points

1. **Global Shortcut Registration** (in `HyppoApp.swift`)
   ```swift
   .commands {
       CommandGroup(after: .sidebar) {
           Button("Quick Capture") {
               QuickCaptureService.shared.showHUD()
           }
           .keyboardShortcut("h", modifiers: [.command, .shift])
       }
   }
   ```

2. **Menu Bar Option** (Alternative trigger)
   - Add to menu bar for users who prefer click
   - Same HUD, different trigger

3. **Browser Extension** (Future)
   - Right-click context menu: "Capture to Hyppo"
   - Sends URL + selected text to Quick Capture

## Success Metrics

Track these metrics to validate friction reduction:
- **Time to Save**: Average time from ⌘⇧H to save completion
- **Abandonment Rate**: % of HUD opens that don't result in save
- **Evidence Rate**: Evidence items per week per user (before/after Quick Capture)
- **Destination Reuse**: % of captures using "last destination" vs. new selection

## Future Enhancements (Post-MVP 2)

1. **Draft Support**: Save incomplete captures as drafts
2. **Batch Capture**: Capture multiple items in sequence
3. **Smart Suggestions**: AI-suggested destination based on content
4. **Browser Extension**: Native browser integration
5. **Snippet Highlighting**: Visual selection of text before capture

---

**Status**: Design Complete - Ready for MVP 2 Implementation
**Last Updated**: 2026-01-27

