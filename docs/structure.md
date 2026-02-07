# Repository structure

Generated from `/Users/ndelahou/Documents/Programming/apps/Hyppo`.

Notes:
- `.git` (and similar metadata/build folders) are intentionally excluded from this view to keep it readable.
- Last updated: February 2026 (Odoo-style navigation, Analytics, Decisions & Tasks modules)

```
Hyppo
├── Hyppo
│   ├── Assets.xcassets
│   │   ├── AccentColor.colorset
│   │   │   └── Contents.json
│   │   ├── AppIcon.appiconset
│   │   │   └── Contents.json
│   │   └── Contents.json
│   ├── Models
│   │   ├── Asset.swift
│   │   ├── Decision.swift              # 🆕 Decision journal entries
│   │   ├── Driver.swift                # McKinsey: Load-bearing assumptions
│   │   ├── Enums.swift                 # EvidenceSentiment, SourceType, etc.
│   │   ├── Evidence.swift              # Driver linkage, sentiment
│   │   ├── LogEntry.swift
│   │   ├── Outcome.swift               # 🆕 Decision outcome tracking
│   │   ├── ResearchQuestion.swift      # Driver/KillCriteria relationships
│   │   ├── ResearchTask.swift          # 🆕 Actionable research tasks
│   │   ├── ReviewReminder.swift
│   │   ├── Tag.swift
│   │   ├── TaskViewConfiguration.swift # 🆕 Task view display settings
│   │   └── ViewConfiguration.swift     # 🆕 Generic view configuration
│   ├── Services
│   │   ├── AnalyticsService.swift      # 🆕 Portfolio & research analytics
│   │   ├── ClipboardDetector.swift
│   │   ├── ExportService.swift
│   │   ├── NotificationService.swift
│   │   └── QuickCaptureService.swift   # Driver destination support
│   ├── Utilities
│   │   ├── AccessibilityHelper.swift   # 🆕 Accessibility utilities
│   │   ├── AppColors.swift             # 🆕 Centralized color palette
│   │   ├── DebugLogger.swift
│   │   ├── MigrationHelper.swift       # Data migration for schema changes
│   │   └── SwiftDataStoreReset.swift
│   ├── Views
│   │   ├── Analytics                           # 🆕 Full analytics module
│   │   │   ├── AnalyticsDashboardView.swift    # Top-level analytics dashboard
│   │   │   ├── DecisionAnalyticsView.swift     # Decision-specific metrics
│   │   │   ├── DriverAnalyticsView.swift       # Driver coverage analytics
│   │   │   ├── EvidenceAnalyticsView.swift     # Evidence breakdown analytics
│   │   │   ├── PortfolioHealthDashboardView.swift # Portfolio-wide health overview
│   │   │   ├── ReviewAnalyticsView.swift       # Review cadence analytics
│   │   │   ├── RiskAlertsDashboardView.swift   # Risk & blind-spot alerts
│   │   │   └── TaskAnalyticsView.swift         # Task completion analytics
│   │   ├── Components
│   │   │   ├── AssetTagField.swift             # 🆕 Reusable asset/tag input
│   │   │   └── EmptyStateView.swift
│   │   ├── Decisions                           # 🆕 Decision journal module
│   │   │   ├── DecisionDetailView.swift
│   │   │   ├── DecisionFormView.swift
│   │   │   ├── DecisionTimelineView.swift
│   │   │   └── OutcomeFormView.swift
│   │   ├── Evidence
│   │   │   └── EvidenceFormView.swift
│   │   ├── Export
│   │   │   └── ExportImportView.swift
│   │   ├── LogEntries
│   │   │   └── LogEntryFormView.swift
│   │   ├── Navigation
│   │   │   └── OdooStyleNavigationView.swift   # 🆕 Replaced MainNavigationView + SidebarView
│   │   ├── QuickCapture
│   │   │   ├── DestinationPicker.swift
│   │   │   └── QuickCaptureHUD.swift
│   │   ├── Records                             # 🆕 Generic record display module
│   │   │   ├── RecordCardGridView.swift
│   │   │   ├── RecordCardView.swift
│   │   │   ├── RecordKanbanView.swift
│   │   │   ├── RecordListView.swift
│   │   │   ├── RecordRowView.swift
│   │   │   └── RecordTableView.swift
│   │   ├── ResearchQuestions
│   │   │   ├── ConfidenceChartView.swift       # 🆕 Confidence over time chart
│   │   │   ├── ConvictionHealthView.swift      # Evidence balance dashboard
│   │   │   ├── DriverOutlineView.swift         # Collapsible driver hierarchy
│   │   │   ├── ResearchQuestionDetailView.swift
│   │   │   ├── ResearchQuestionFormView.swift
│   │   │   ├── ResearchTasksView.swift         # 🆕 Task list for a research question
│   │   │   └── ResearchWizardView.swift        # Guided Frame+Design wizard
│   │   ├── Reviews
│   │   │   ├── ReviewReminderView.swift
│   │   │   └── ReviewWizardView.swift
│   │   ├── Search
│   │   │   ├── GlobalSearchView.swift
│   │   │   └── SearchPopoverView.swift         # 🆕 Popover-based quick search
│   │   ├── Settings
│   │   │   └── SettingsView.swift
│   │   └── Tasks                               # 🆕 Task management module
│   │       ├── AllTasksListView.swift
│   │       ├── EditableTaskField.swift
│   │       ├── MentionPopover.swift
│   │       ├── QuickAddTaskPopover.swift
│   │       ├── TaskInputField.swift
│   │       └── TaskSearchPopoverView.swift
│   ├── HyppoApp.swift
│   └── Version.swift
├── Hyppo.xcodeproj
│   ├── project.xcworkspace
│   │   ├── xcshareddata
│   │   │   └── swiftpm
│   │   │       └── configuration
│   │   ├── xcuserdata
│   │   │   └── ndelahou.xcuserdatad
│   │   │       └── UserInterfaceState.xcuserstate
│   │   └── contents.xcworkspacedata
│   ├── xcuserdata
│   │   └── ndelahou.xcuserdatad
│   │       └── xcschemes
│   │           └── xcschememanagement.plist
│   └── project.pbxproj
└── docs
    ├── QuickCapture_Wireframe.md
    ├── investor_research_workflow_validation.md
    ├── output.md
    ├── project_scope.md              # Primary spec: McKinsey Mind 5-step workflow
    ├── roadmap.md                    # Feature tracking with status
    ├── structure.md                  # This file
    ├── user_testing.md
    └── reference
        ├── competition_analysis.md
        ├── cream_of_the_crop.md
        ├── enterprise_opportunities.md
        ├── extra_features_from_gemini.md
        └── fictional_nvda_research_question.md
```

## Key Architecture Changes (since MVP 2.5)

### New Models
- **Decision**: Decision journal entries with rationale, context, and linked assets
- **Outcome**: Tracks actual outcomes against prior decisions for post-mortem analysis
- **ResearchTask**: Actionable tasks tied to research questions/drivers
- **TaskViewConfiguration / ViewConfiguration**: Persisted display preferences (sort, filter, grouping)

### New Services
- **AnalyticsService**: Aggregates portfolio health, evidence coverage, task completion, and risk metrics

### New Utilities
- **AccessibilityHelper**: Centralised accessibility label and trait helpers
- **AppColors**: Shared color palette used across the app

### New View Modules
- **Analytics** (8 views): Full analytics dashboard covering decisions, drivers, evidence, portfolio health, reviews, risk alerts, and tasks
- **Decisions** (4 views): Decision journal with detail, form, timeline, and outcome recording
- **Records** (6 views): Generic multi-layout record display (list, table, card grid, kanban)
- **Tasks** (6 views): Task management with quick-add, inline editing, mentions, and search

### Navigation Overhaul
- **OdooStyleNavigationView** replaces the previous `MainNavigationView` + `SidebarView` with an Odoo-inspired app-bar navigation pattern

### Removed
- `ContentView.swift` (replaced by `OdooStyleNavigationView`)
- `Views/Assets/` (asset management folded into Records module)
- `Views/Scenarios/` (deprecated in favor of Drivers)
- `Views/Tags/TagManagementView.swift` (tags now managed inline via `AssetTagField`)
- `Models/KillCriteria.swift` (merged into Driver model)
- `Views/ResearchQuestions/ResearchPlanTableView.swift` (superseded by Records table view)

### Existing Models — Updated
- **Driver**: Now incorporates kill-criteria fields directly
- **ResearchQuestion**: Relationships to ResearchTask; driver/kill-criteria handling streamlined
- **Evidence**: Unchanged from MVP 2.5

### New Components
- **AssetTagField**: Reusable tag/asset autocomplete input component
- **SearchPopoverView**: Lightweight popover for quick global search
- **ConfidenceChartView**: Conviction confidence plotted over time
- **ResearchTasksView**: Per-question task checklist
