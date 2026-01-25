# Repository structure

Generated from `/Users/ndelahou/Documents/Programming/apps/Hyppo`.

Notes:
- `.git` (and similar metadata/build folders) are intentionally excluded from this view to keep it readable.
- Last updated: January 2026 (MVP 2.5 McKinsey Mind Framework views complete)

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
│   │   ├── Driver.swift              # 🆕 McKinsey: Load-bearing assumptions
│   │   ├── Enums.swift               # Updated: EvidenceSentiment, SourceType
│   │   ├── Evidence.swift            # Updated: Driver linkage, sentiment
│   │   ├── KillCriteria.swift        # 🆕 McKinsey: Falsifiability conditions
│   │   ├── LogEntry.swift
│   │   ├── ResearchQuestion.swift    # Updated: Driver/KillCriteria relationships
│   │   ├── ReviewReminder.swift
│   │   └── Tag.swift
│   ├── Services
│   │   ├── ClipboardDetector.swift
│   │   ├── ExportService.swift
│   │   ├── NotificationService.swift
│   │   └── QuickCaptureService.swift # Updated: Driver destination support
│   ├── Utilities
│   │   ├── DebugLogger.swift
│   │   ├── MigrationHelper.swift     # 🆕 Data migration for schema changes
│   │   └── SwiftDataStoreReset.swift
│   ├── Views
│   │   ├── Assets
│   │   │   ├── AssetDetailView.swift
│   │   │   └── AssetFormView.swift
│   │   ├── Components
│   │   │   └── EmptyStateView.swift
│   │   ├── Evidence
│   │   │   └── EvidenceFormView.swift
│   │   ├── Export
│   │   │   └── ExportImportView.swift
│   │   ├── LogEntries
│   │   │   └── LogEntryFormView.swift
│   │   ├── Navigation
│   │   │   ├── MainNavigationView.swift
│   │   │   └── SidebarView.swift
│   │   ├── QuickCapture
│   │   │   ├── DestinationPicker.swift
│   │   │   └── QuickCaptureHUD.swift
│   │   ├── ResearchQuestions
│   │   │   ├── ConvictionHealthView.swift      # 🆕 McKinsey: Evidence balance dashboard
│   │   │   ├── DriverOutlineView.swift         # 🆕 McKinsey: Collapsible driver hierarchy
│   │   │   ├── ResearchPlanTableView.swift     # 🆕 McKinsey: Flat research plan table
│   │   │   ├── ResearchQuestionDetailView.swift
│   │   │   ├── ResearchQuestionFormView.swift
│   │   │   └── ResearchWizardView.swift        # 🆕 McKinsey: Guided Frame+Design wizard
│   │   ├── Reviews
│   │   │   ├── ReviewReminderView.swift
│   │   │   └── ReviewWizardView.swift
│   │   ├── Scenarios
│   │   │   └── (empty - scenarios deprecated in favor of drivers)
│   │   ├── Search
│   │   │   └── GlobalSearchView.swift
│   │   ├── Settings
│   │   │   └── SettingsView.swift
│   │   └── Tags
│   │       └── TagManagementView.swift
│   ├── ContentView.swift
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

## Key Architecture Changes (MVP 2.5)

### New Models
- **Driver**: 2-level hierarchy of load-bearing assumptions with validation questions, data sources, and thresholds
- **KillCriteria**: Falsifiability conditions that would invalidate a thesis

### Updated Models
- **Evidence**: Now links to Driver (not just ResearchQuestion), includes sentiment and sourceType
- **ResearchQuestion**: Relationships to Drivers and KillCriteria; deprecated old keyDrivers/invalidationRules arrays

### New Views (Complete)
- **DriverOutlineView**: Collapsible outline editor with drag-and-drop reordering
- **ResearchWizardView**: 3-step guided wizard (Frame → Design → Review)
- **ResearchPlanTableView**: Flat tabular view with inline editing
- **ConvictionHealthView**: Evidence balance dashboard with blind spot alerts

