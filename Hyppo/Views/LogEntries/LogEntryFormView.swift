/**
 LogEntryFormView provides a form for creating or editing a log entry.
 
 Supports quick capture with minimal required fields while allowing
 optional metadata like confidence level, entry type, and tags.
 
 When a Driver is selected, the log entry becomes linked to the McKinsey
 framework and automatically creates Evidence that updates conviction scores.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum LogEntryFormMode {
    case add(researchQuestion: ResearchQuestion)
    case edit(LogEntry)
    
    var title: String {
        switch self {
        case .add: return "Add Log Entry"
        case .edit: return "Edit Log Entry"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
    
    /// Returns the research question for this mode
    var researchQuestion: ResearchQuestion? {
        switch self {
        case .add(let rq): return rq
        case .edit(let logEntry): return logEntry.researchQuestion
        }
    }
}

/// Result of saving a log entry, includes any created Evidence
struct LogEntrySaveResult {
    let logEntry: LogEntry
    let evidence: Evidence?
}

/// Form for creating or editing a log entry
struct LogEntryFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let mode: LogEntryFormMode
    let onSave: (LogEntry) -> Void
    
    // MARK: - State (Core Log Entry)
    
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var entryType: LogEntryType = .observation
    @State private var occurredAt: Date = Date()
    @State private var selectedTags: [Tag] = []
    @State private var validationErrors: [String] = []
    
    // MARK: - State (McKinsey Framework - Evidence Linkage)
    
    @State private var selectedDriver: Driver? = nil
    @State private var sentiment: EvidenceSentiment = .neutral
    @State private var sourceType: SourceType = .other
    @State private var sourceUrl: String = ""
    
    // MARK: - Initialization
    
    init(mode: LogEntryFormMode, onSave: @escaping (LogEntry) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let logEntry) = mode {
            _title = State(initialValue: logEntry.title)
            _bodyText = State(initialValue: logEntry.body)
            _entryType = State(initialValue: logEntry.entryType)
            _occurredAt = State(initialValue: logEntry.occurredAt)
            _selectedTags = State(initialValue: logEntry.tags ?? [])
            _selectedDriver = State(initialValue: logEntry.driver)
            _sentiment = State(initialValue: logEntry.sentiment ?? .neutral)
            _sourceType = State(initialValue: logEntry.sourceType ?? .other)
            _sourceUrl = State(initialValue: logEntry.sourceUrl ?? "")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var questionTitle: String {
        switch mode {
        case .add(let researchQuestion):
            return researchQuestion.questionText
        case .edit(let logEntry):
            return logEntry.researchQuestion?.questionText ?? "Unknown Research Question"
        }
    }
    
    /// Available top-level drivers from the research question
    private var availableDrivers: [Driver] {
        mode.researchQuestion?.topLevelDrivers ?? []
    }
    
    /// Whether driver linkage section should be shown
    private var showDriverSection: Bool {
        !availableDrivers.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Research question reference
                    HStack {
                        Text("Research Question:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(questionTitle)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                    
                    // Entry type and date row
                    HStack(spacing: 16) {
                        // Entry type picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Type")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Picker("Type", selection: $entryType) {
                                ForEach(LogEntryType.allCases) { type in
                                    Label(type.displayName, systemImage: type.iconName)
                                        .tag(type)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(minWidth: 130)
                        }
                        
                        // Date picker
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date & Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            DatePicker("", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                        }
                        
                        Spacer()
                    }
                    
                    // Title field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Title")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("Brief summary of this entry", text: $title)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Body field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextEditor(text: $bodyText)
                            .font(.body)
                            .frame(minHeight: 100)
                            .padding(4)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                    }
                    
                    // McKinsey Framework Section - Driver Linkage
                    if showDriverSection {
                        driverLinkageSection
                    }
                    
                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TagPickerView(selectedTags: $selectedTags)
                    }
                    
                    // Validation errors
                    if !validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(validationErrors, id: \.self) { error in
                                Label(error, systemImage: "exclamationmark.circle")
                                    .foregroundStyle(.red)
                                    .font(.caption)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 500, height: 700)
    }
    
    // MARK: - Driver Linkage Section (McKinsey Framework)
    
    private var driverLinkageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "target")
                    .foregroundStyle(.blue)
                Text("Link to Assumption (Optional)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if selectedDriver != nil {
                    Button {
                        selectedDriver = nil
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.caption2)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Text("Link this log to an assumption to update conviction scores.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            // Driver picker
            LogDriverPicker(selectedDriver: $selectedDriver, drivers: availableDrivers)
            
            // Show sentiment and source type only when driver is selected
            if selectedDriver != nil {
                VStack(alignment: .leading, spacing: 12) {
                    // Sentiment and Source Type Row
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sentiment")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Picker("Sentiment", selection: $sentiment) {
                                ForEach(EvidenceSentiment.allCases) { s in
                                    Label(s.rawValue, systemImage: s.iconName).tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Source Type")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Picker("Source", selection: $sourceType) {
                                ForEach(SourceType.allCases) { s in
                                    Label(s.displayName, systemImage: s.iconName).tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                    
                    // Source URL
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Source URL (Optional)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        TextField("https://...", text: $sourceUrl)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            Text(mode.title)
                .font(.headline)
            Spacer()
        }
        .padding()
    }
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            // Show indicator when driver is linked
            if selectedDriver != nil {
                HStack(spacing: 4) {
                    Image(systemName: "link.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Will update conviction")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Button(mode.saveButtonTitle) {
                save()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
            .disabled(!isValid)
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func validate() -> Bool {
        validationErrors = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Title is required")
        }
        
        if bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Details are required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        switch mode {
        case .add:
            let newLogEntry = LogEntry(
                title: title,
                body: bodyText,
                entryType: entryType,
                occurredAt: occurredAt,
                isSystemGenerated: false
            )
            newLogEntry.tags = selectedTags.isEmpty ? nil : selectedTags
            
            // Set McKinsey framework fields
            newLogEntry.driver = selectedDriver
            newLogEntry.sentiment = selectedDriver != nil ? sentiment : nil
            newLogEntry.sourceType = selectedDriver != nil ? sourceType : nil
            newLogEntry.sourceUrl = sourceUrl.isEmpty ? nil : sourceUrl
            
            // If linked to a driver, create Evidence automatically
            if let driver = selectedDriver {
                let evidence = createEvidenceFromLogEntry(newLogEntry, driver: driver)
                modelContext.insert(evidence)
                
                // Update driver's evidence relationship
                if driver.evidence == nil {
                    driver.evidence = []
                }
                driver.evidence?.append(evidence)
            }
            
            onSave(newLogEntry)
            
        case .edit(let logEntry):
            logEntry.update(
                title: title,
                body: bodyText,
                entryType: entryType,
                occurredAt: occurredAt
            )
            logEntry.tags = selectedTags.isEmpty ? nil : selectedTags
            
            // Update McKinsey framework fields
            let previousDriver = logEntry.driver
            logEntry.driver = selectedDriver
            logEntry.sentiment = selectedDriver != nil ? sentiment : nil
            logEntry.sourceType = selectedDriver != nil ? sourceType : nil
            logEntry.sourceUrl = sourceUrl.isEmpty ? nil : sourceUrl
            
            // Handle Evidence updates
            if let driver = selectedDriver {
                // Find existing evidence linked to this log entry or create new
                if let existingEvidence = logEntry.evidenceItems?.first {
                    // Update existing evidence
                    existingEvidence.driver = driver
                    existingEvidence.sentiment = sentiment
                    existingEvidence.sourceType = sourceType
                    existingEvidence.update(
                        url: sourceUrl.isEmpty ? nil : sourceUrl,
                        displayTitle: title,
                        snippetText: String(bodyText.prefix(Evidence.maxSnippetLength)),
                        annotationText: nil
                    )
                    
                    // Update driver relationships if changed
                    if previousDriver !== driver {
                        previousDriver?.evidence?.removeAll { $0 === existingEvidence }
                        if driver.evidence == nil {
                            driver.evidence = []
                        }
                        driver.evidence?.append(existingEvidence)
                    }
                } else {
                    // Create new evidence
                    let evidence = createEvidenceFromLogEntry(logEntry, driver: driver)
                    modelContext.insert(evidence)
                    
                    if driver.evidence == nil {
                        driver.evidence = []
                    }
                    driver.evidence?.append(evidence)
                }
            } else if previousDriver != nil {
                // Driver was removed, delete associated evidence
                if let existingEvidence = logEntry.evidenceItems?.first {
                    previousDriver?.evidence?.removeAll { $0 === existingEvidence }
                    modelContext.delete(existingEvidence)
                }
            }
            
            onSave(logEntry)
        }
        
        dismiss()
    }
    
    /// Creates Evidence from LogEntry data
    private func createEvidenceFromLogEntry(_ logEntry: LogEntry, driver: Driver) -> Evidence {
        let evidence = Evidence(
            url: sourceUrl.isEmpty ? nil : sourceUrl,
            evidenceType: .note,
            sentiment: sentiment,
            sourceType: sourceType,
            displayTitle: title,
            snippetText: String(bodyText.prefix(Evidence.maxSnippetLength)),
            annotationText: nil
        )
        evidence.driver = driver
        evidence.logEntry = logEntry
        return evidence
    }
}

// MARK: - Tag Picker View

/// A view for selecting tags from available tags
struct TagPickerView: View {
    @Binding var selectedTags: [Tag]
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @State private var showingTagCreation = false
    @State private var newTagName = ""
    @State private var newTagColor: TagColor = .blue
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if allTags.isEmpty {
                HStack {
                    Text("No tags yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Button("Create tag") {
                        showingTagCreation = true
                    }
                    .font(.caption)
                }
            } else {
                FlowLayout(spacing: 6) {
                    ForEach(allTags) { tag in
                        TagToggleChip(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.tagId == tag.tagId })
                        ) {
                            toggleTag(tag)
                        }
                    }
                    
                    // Add tag button
                    Button {
                        showingTagCreation = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.caption2)
                            Text("New")
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .foregroundStyle(.secondary)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .popover(isPresented: $showingTagCreation) {
            VStack(spacing: 12) {
                Text("Create Tag")
                    .font(.headline)
                
                TextField("Tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Color", selection: $newTagColor) {
                    ForEach(TagColor.allCases) { color in
                        HStack {
                            Circle()
                                .fill(color.color)
                                .frame(width: 12, height: 12)
                            Text(color.displayName)
                        }
                        .tag(color)
                    }
                }
                .pickerStyle(.menu)
                
                HStack {
                    Button("Cancel") {
                        newTagName = ""
                        showingTagCreation = false
                    }
                    
                    Spacer()
                    
                    Button("Create") {
                        createTag()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding()
            .frame(width: 250)
        }
    }
    
    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.tagId == tag.tagId }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
    
    private func createTag() {
        let tag = Tag(name: newTagName, colorName: newTagColor.rawValue)
        modelContext.insert(tag)
        selectedTags.append(tag)
        newTagName = ""
        showingTagCreation = false
    }
}

/// A toggleable chip for tag selection
private struct TagToggleChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    private var tagColor: Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return .blue
        }
        return color.color
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Circle()
                    .fill(tagColor)
                    .frame(width: 8, height: 8)
                Text(tag.name)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isSelected ? tagColor.opacity(0.2) : Color(nsColor: .controlBackgroundColor))
            .foregroundStyle(isSelected ? tagColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? tagColor : Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Log Driver Picker

/**
 A picker for selecting a Driver from the research question's drivers.
 Supports 2-level hierarchy (parent drivers and sub-drivers).
 */
struct LogDriverPicker: View {
    @Binding var selectedDriver: Driver?
    let drivers: [Driver]
    
    var body: some View {
        Menu {
            Button {
                selectedDriver = nil
            } label: {
                Text("None (Journal only)")
            }
            
            Divider()
            
            ForEach(drivers.sorted(by: { $0.position < $1.position })) { driver in
                driverMenuSection(driver)
            }
        } label: {
            HStack {
                if let selected = selectedDriver {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .foregroundStyle(.blue)
                        Text(selected.title)
                            .fontWeight(.medium)
                    }
                } else {
                    Text("Select Assumption (optional)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(10)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .menuStyle(.borderlessButton)
    }
    
    @ViewBuilder
    private func driverMenuSection(_ driver: Driver) -> some View {
        Button {
            selectedDriver = driver
        } label: {
            HStack {
                Text(driver.title)
                if selectedDriver?.driverId == driver.driverId {
                    Image(systemName: "checkmark")
                }
            }
        }
        
        if let subs = driver.subDrivers, !subs.isEmpty {
            ForEach(subs.sorted(by: { $0.position < $1.position })) { sub in
                Button {
                    selectedDriver = sub
                } label: {
                    HStack {
                        Text("  → \(sub.title)")
                        if selectedDriver?.driverId == sub.driverId {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let question = ResearchQuestion(
        questionText: "Can AAPL sustain services revenue growth?",
        context: "Services now represent 20% of revenue"
    )
    
    return LogEntryFormView(mode: .add(researchQuestion: question)) { _ in }
        .modelContainer(for: [ResearchQuestion.self, LogEntry.self, Tag.self, Driver.self, Evidence.self], inMemory: true)
}
