/**
 ResearchWizardView provides a guided 2-step wizard for creating research
 following the McKinsey Mind framework.
 
 Steps:
 1. Frame the Problem - Define investment thesis, context, and key assumptions
 2. Review & Save - Confirm the structured research plan before saving
 */

import SwiftUI
import SwiftData

struct ResearchWizardView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Asset.ticker) private var allAssets: [Asset]
    @Query(sort: \Tag.name) private var allTags: [Tag]
    
    // MARK: - Properties
    
    let asset: Asset?
    let existingQuestion: ResearchQuestion?
    let onSave: (ResearchQuestion) -> Void
    
    // MARK: - State
    
    @State private var currentStep = 1
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    // Asset selection/creation state (only used when no asset is provided)
    @State private var selectedAsset: Asset?
    @State private var isCreatingNewAsset = false
    @State private var newAssetTicker: String = ""
    @State private var newAssetName: String = ""
    
    // Step 1: Frame the Problem
    /// Investment Thesis - the core belief being tested (maps to questionText for model compatibility)
    @State private var investmentThesis: String = ""
    /// Why This Matters - background context for the research
    @State private var whyThisMatters: String = ""
    @State private var drivers: [DriverDTO] = [
        DriverDTO(title: "")
    ]
    
    @State private var selectedDriverId: UUID?
    @State private var isDriverFieldFocused = false
    @State private var shouldFocusFirstDriver = false
    @State private var isAssetFieldFocused = false
    
    /// Confidence level for the research question (1-5 scale)
    @State private var confidence: Int? = nil
    
    /// Selected type for the research question
    @State private var selectedType: ResearchType? = nil
    
    /// Selected labels for the research question
    @State private var selectedLabels: [Tag] = []
    
    /// State for creating new labels
    @State private var showingLabelCreation = false
    @State private var newLabelName = ""
    @State private var newLabelColor: TagColor = .blue
    
    /// Focus state for tab navigation between text fields
    enum FocusedField: Hashable {
        case investmentThesis
        case whyThisMatters
    }
    @FocusState private var focusedField: FocusedField?
    
    // MARK: - Initialization
    
    init(asset: Asset?, existingQuestion: ResearchQuestion? = nil, onSave: @escaping (ResearchQuestion) -> Void) {
        self.asset = asset ?? existingQuestion?.asset
        self.existingQuestion = existingQuestion
        self.onSave = onSave
        
        // Pre-populate if editing
        if let question = existingQuestion {
            // Use thesisStatement if available, otherwise fall back to questionText for backwards compat
            _investmentThesis = State(initialValue: question.thesisStatement ?? question.questionText)
            _whyThisMatters = State(initialValue: question.context ?? "")
            _confidence = State(initialValue: question.confidenceCurrent)
            
            let dtos = (question.drivers ?? []).filter { $0.parentDriver == nil }.map { d in
                DriverDTO(
                    title: d.title,
                    description: d.driverDescription ?? "",
                    logic: d.logic ?? "",
                    subDrivers: (d.subDrivers ?? []).map { sd in
                        DriverDTO(
                            title: sd.title,
                            description: sd.driverDescription ?? "",
                            logic: sd.logic ?? "",
                            isSubDriver: true
                        )
                    }
                )
            }
            if !dtos.isEmpty {
                _drivers = State(initialValue: dtos)
            }
            
            // Pre-populate type + labels (fallback to legacy tags when needed)
            if question.researchType == nil,
               (question.labels ?? []).isEmpty,
               let legacyTags = question.tags,
               !legacyTags.isEmpty {
                let split = ResearchQuestion.splitLegacyTags(legacyTags)
                _selectedType = State(initialValue: split.type)
                _selectedLabels = State(initialValue: split.labels)
            } else {
                _selectedType = State(initialValue: question.researchType)
                _selectedLabels = State(initialValue: question.labels ?? question.tags ?? [])
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// The effective asset to use (provided, selected, or will be created)
    private var effectiveAsset: Asset? {
        asset ?? selectedAsset
    }
    
    /// Whether the user has a valid asset configuration (either selected or creating new)
    private var hasValidAssetConfig: Bool {
        if asset != nil || selectedAsset != nil {
            return true
        }
        if isCreatingNewAsset {
            let trimmedTicker = newAssetTicker.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = newAssetName.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedTicker.isEmpty && !trimmedName.isEmpty
        }
        return true // Allow creating research without an asset
    }
    
    private var isStep1Valid: Bool {
        let trimmedThesis = investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedThesis.isEmpty && hasValidAssetConfig
    }
    
    private var validDriversForDesign: [DriverDTO] {
        drivers.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    /// Groups drivers with their subdrivers based on the isSubDriver flag.
    /// Drivers marked with isSubDriver: true belong to the first non-subdriver above them in the list.
    private var driversWithGroupedSubDrivers: [(driver: DriverDTO, subDrivers: [DriverDTO])] {
        var result: [(driver: DriverDTO, subDrivers: [DriverDTO])] = []
        var currentDriver: DriverDTO? = nil
        var currentSubDrivers: [DriverDTO] = []
        
        for d in drivers {
            let trimmedTitle = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedTitle.isEmpty else { continue }
            
            if d.isSubDriver {
                // This is a subdriver - add to current parent's subdrivers
                currentSubDrivers.append(d)
            } else {
                // This is a parent driver
                // First, save the previous driver and its subdrivers
                if let prevDriver = currentDriver {
                    result.append((driver: prevDriver, subDrivers: currentSubDrivers))
                }
                // Start a new parent driver
                currentDriver = d
                // Include any nested subdrivers from the subDrivers array
                currentSubDrivers = d.subDrivers.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
        }
        
        // Don't forget the last driver
        if let lastDriver = currentDriver {
            result.append((driver: lastDriver, subDrivers: currentSubDrivers))
        }
        
        return result
    }
    
    /// Count of top-level drivers only (for validation display)
    private var validTopLevelDriversCount: Int {
        driversWithGroupedSubDrivers.count
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with Progress
            headerView
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch currentStep {
                    case 1: frameStep
                    case 2: reviewStep
                    default: EmptyView()
                    }
                }
                .padding(32)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 750, height: 800)
        .onKeyPress(.escape) {
            if focusedField != nil || isDriverFieldFocused || isAssetFieldFocused {
                focusedField = nil
                return .handled
            }
            return .ignored
        }
        .onKeyPress(.return) {
            guard focusedField == nil, !isDriverFieldFocused, !isAssetFieldFocused else {
                return .ignored
            }
            if currentStep < 2 {
                if validateCurrentStep() {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep += 1
                    }
                }
            } else {
                save()
            }
            return .handled
        }
        .alert("Validation Required", isPresented: $showValidationError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Research Wizard")
                        .font(.headline)
                    if let existingAsset = asset {
                        // Asset was provided externally
                        HStack(spacing: 4) {
                            Text("Creating research for")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(existingAsset.ticker)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    } else if let selected = selectedAsset {
                        // User selected an existing asset
                        HStack(spacing: 4) {
                            Text("Creating research for")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(selected.ticker)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    } else if isCreatingNewAsset && !newAssetTicker.isEmpty {
                        // User is creating a new asset
                        HStack(spacing: 4) {
                            Text("Creating research for new asset:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(newAssetTicker.uppercased())
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.accentColor)
                        }
                    } else {
                        Text("Creating new research question")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text("Step \(currentStep) of 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Step Indicators
            HStack(spacing: 0) {
                stepIndicator(step: 1, title: "Frame", icon: "lightbulb")
                stepConnector(completed: currentStep > 1)
                stepIndicator(step: 2, title: "Review", icon: "checkmark.circle")
            }
        }
        .padding()
    }
    
    private func stepIndicator(step: Int, title: String, icon: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(step <= currentStep ? Color.accentColor : Color.appBorder)
                    .frame(width: 36, height: 36)
                
                if step < currentStep {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(step == currentStep ? .white : .secondary)
                }
            }
            
            Text(title)
                .font(.caption2)
                .fontWeight(step == currentStep ? .semibold : .regular)
                .foregroundStyle(step <= currentStep ? .primary : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func stepConnector(completed: Bool) -> some View {
        Rectangle()
            .fill(completed ? Color.accentColor : Color.appBorder)
            .frame(height: 2)
            .frame(maxWidth: 60)
    }
    
    // MARK: - Step 1: Frame the Problem
    
    private var frameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "1.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Frame the Problem")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Define your investment thesis, why it matters, and the key assumptions that must be true.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Asset/Ticker Section (only show if no asset was provided)
            if asset == nil && existingQuestion == nil {
                assetSelectionSection
            }
            
            // Investment Thesis
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Investment Thesis")
                        .font(.headline)
                    Text("*")
                        .foregroundStyle(Color.statusInvalidated)
                }
                
                Text("What must be true for this investment to work?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $investmentThesis)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder))
                    .focused($focusedField, equals: .investmentThesis)
                    .interceptTab(
                        isActive: focusedField == .investmentThesis,
                        onTab: { focusedField = .whyThisMatters },
                        onShiftTab: { /* No previous field */ },
                        onEscape: { focusedField = nil }
                    )
            }
            
            // Why This Matters
            VStack(alignment: .leading, spacing: 8) {
                Text("Why This Matters")
                    .font(.headline)
                
                Text("What makes this worth investigating? What's the background?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $whyThisMatters)
                    .frame(minHeight: 60, maxHeight: 100)
                    .padding(8)
                    .background(Color.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.appBorder))
                    .focused($focusedField, equals: .whyThisMatters)
                    .interceptTab(
                        isActive: focusedField == .whyThisMatters,
                        onTab: {
                            focusedField = nil
                            shouldFocusFirstDriver = true
                        },
                        onShiftTab: { focusedField = .investmentThesis },
                        onEscape: { focusedField = nil }
                    )
            }
            
            // Key Assumptions (Drivers)
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Assumptions")
                    .font(.headline)
                
                DriverOutlineView(
                    drivers: $drivers,
                    prompt: "What assumptions must be true for this thesis to hold?",
                    isDriverFieldFocused: $isDriverFieldFocused,
                    shouldFocusFirstDriver: $shouldFocusFirstDriver,
                    onShiftTabAtFirstDriver: {
                        focusedField = .whyThisMatters
                    }
                )
                
                // Status hint - show count of top-level drivers and total subdrivers
                let topLevelCount = driversWithGroupedSubDrivers.count
                let subDriverCount = driversWithGroupedSubDrivers.reduce(0) { $0 + $1.subDrivers.count }
                if topLevelCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.statusActive)
                        if subDriverCount > 0 {
                            Text("\(topLevelCount) driver\(topLevelCount == 1 ? "" : "s"), \(subDriverCount) sub-driver\(subDriverCount == 1 ? "" : "s") defined")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(topLevelCount) assumption\(topLevelCount == 1 ? "" : "s") defined")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            
            // Confidence
            VStack(alignment: .leading, spacing: 8) {
                Text("Confidence")
                    .font(.headline)
                
                let confidenceSelection = Binding<Int?>(
                    get: { ConfidenceLevel.normalizedRawValue(confidence) },
                    set: { confidence = $0 }
                )
                
                Picker("Confidence", selection: confidenceSelection) {
                    Text("Not set").tag(nil as Int?)
                    ForEach(ConfidenceLevel.selectableCases) { level in
                        Text(level.displayName).tag(level.rawValue as Int?)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Type
            typeSection
            
            // Labels
            labelsSection
        }
    }

    // MARK: - Type Section
    
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Type")
                    .font(.headline)
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Choose a single type for meaningful filtering.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                FlowLayout(spacing: 6) {
                    ForEach(ResearchType.allCases.sorted(by: { $0.sortOrder < $1.sortOrder })) { type in
                        WizardTypeToggleChip(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            toggleType(type)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Labels Section
    
    private var labelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Labels")
                    .font(.headline)
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Add multiple labels to refine filtering.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                if allTags.isEmpty && selectedLabels.isEmpty {
                    HStack {
                        Text("No labels yet")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Button("Create label") {
                            showingLabelCreation = true
                        }
                        .font(.caption)
                    }
                } else {
                    FlowLayout(spacing: 6) {
                        ForEach(allTags) { tag in
                            WizardTagToggleChip(
                                tag: tag,
                                isSelected: selectedLabels.contains(where: { $0.tagId == tag.tagId })
                            ) {
                                toggleLabel(tag)
                            }
                        }
                        
                        // Add label button
                        Button {
                            showingLabelCreation = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.caption2)
                                Text("New")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color.surface)
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.appBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .popover(isPresented: $showingLabelCreation) {
                VStack(spacing: 12) {
                    Text("Create Label")
                        .font(.headline)
                    
                    TextField("Label name", text: $newLabelName)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Color", selection: $newLabelColor) {
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
                            newLabelName = ""
                            showingLabelCreation = false
                        }
                        
                        Spacer()
                        
                        Button("Create") {
                            createLabel()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(newLabelName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
                .frame(width: 250)
            }
        }
    }
    
    private func toggleType(_ type: ResearchType) {
        if selectedType == type {
            selectedType = nil
        } else {
            selectedType = type
        }
    }
    
    private func toggleLabel(_ label: Tag) {
        if let index = selectedLabels.firstIndex(where: { $0.tagId == label.tagId }) {
            selectedLabels.remove(at: index)
        } else {
            selectedLabels.append(label)
        }
    }
    
    private func createLabel() {
        let tag = Tag(name: newLabelName, colorName: newLabelColor.rawValue)
        modelContext.insert(tag)
        selectedLabels.append(tag)
        newLabelName = ""
        showingLabelCreation = false
    }
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return Color.accentColor
        }
        return color.color
    }
    
    // MARK: - Asset Selection Section
    
    /// Section for selecting an existing asset or creating a new one (Notion-style tag input)
    private var assetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Asset / Ticker")
                    .font(.headline)
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Type a ticker to search or create a new one.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            AssetTagField(
                allAssets: allAssets,
                selectedAsset: $selectedAsset,
                isCreatingNew: $isCreatingNewAsset,
                newTicker: $newAssetTicker,
                newName: $newAssetName,
                isFieldFocused: $isAssetFieldFocused
            )
            
            // Quick stats for selected asset
            if let selected = selectedAsset {
                HStack(spacing: 12) {
                    Label("\(selected.researchQuestionsCount) research questions", systemImage: "doc.text")
                    if let exchange = selected.exchange {
                        Label(exchange, systemImage: "building.columns")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
        }
    }
    
    // MARK: - Step 2: Review & Save
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "2.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.accentColor)
                    Text("Review Research Plan")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Text("Confirm your structured hypothesis before starting data collection.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Summary Card
            VStack(alignment: .leading, spacing: 20) {
                // Asset / Ticker (if applicable)
                if let existingAsset = asset {
                    reviewSection(icon: "chart.line.uptrend.xyaxis", title: "Asset", color: .purple) {
                        HStack(spacing: 8) {
                            Text(existingAsset.ticker)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(existingAsset.name)
                                .font(.subheadline)
                        }
                    }
                } else if let selected = selectedAsset {
                    reviewSection(icon: "chart.line.uptrend.xyaxis", title: "Asset", color: .purple) {
                        HStack(spacing: 8) {
                            Text(selected.ticker)
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(selected.name)
                                .font(.subheadline)
                        }
                    }
                } else if isCreatingNewAsset && !newAssetTicker.isEmpty && !newAssetName.isEmpty {
                    reviewSection(icon: "chart.line.uptrend.xyaxis", title: "New Asset (will be created)", color: Color.accentColor) {
                        HStack(spacing: 8) {
                            Text(newAssetTicker.uppercased())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(newAssetName)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Thesis & Context
                VStack(alignment: .leading, spacing: 12) {
                    reviewSection(icon: "lightbulb.fill", title: "Investment Thesis", color: Color.accentColor) {
                        Text(investmentThesis)
                            .font(.subheadline)
                    }
                    
                    if !whyThisMatters.isEmpty {
                        reviewSection(icon: "info.circle.fill", title: "Why This Matters", color: .secondary) {
                            Text(whyThisMatters)
                                .font(.subheadline)
                        }
                    }
                }
                
                Divider()
                
                // Assumptions
                if !driversWithGroupedSubDrivers.isEmpty {
                    reviewSection(icon: "target", title: "Key Assumptions (\(driversWithGroupedSubDrivers.count))", color: Color.statusActive) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(driversWithGroupedSubDrivers.enumerated()), id: \.offset) { index, item in
                                VStack(alignment: .leading, spacing: 4) {
                                    // Main driver with "Driver" pill
                                    HStack(spacing: 8) {
                                        Text("\(index + 1).")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.secondary)
                                        
                                        // Driver pill
                                        HStack(spacing: 4) {
                                            Image(systemName: "number")
                                                .font(.caption2)
                                            Text("Driver")
                                                .font(.caption)
                                        }
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.statusOnHold.opacity(0.12))
                                        .foregroundStyle(Color.statusOnHold)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                        
                                        Text(item.driver.title)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                    }
                                    
                                    // Logic if defined
                                    if !item.driver.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(item.driver.logic)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.leading, 12)
                                    }
                                    
                                    // Sub-drivers with "Sub" pill
                                    ForEach(item.subDrivers.filter { !$0.title.isEmpty }) { sub in
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 8) {
                                                Text("→")
                                                    .font(.caption)
                                                    .foregroundStyle(.tertiary)
                                                
                                                // Sub-driver pill
                                                HStack(spacing: 4) {
                                                    Image(systemName: "arrow.turn.down.right")
                                                        .font(.caption2)
                                                    Text("Sub")
                                                        .font(.caption)
                                                }
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.indigo.opacity(0.12))
                                                .foregroundStyle(.indigo)
                                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                                
                                                Text(sub.title)
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            .padding(.leading, 16)
                                            
                                            // Sub-driver logic if defined
                                            if !sub.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                Text(sub.logic)
                                                    .font(.caption2)
                                                    .foregroundStyle(.tertiary)
                                                    .padding(.leading, 40)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // Confidence
                if let conf = confidence, let level = ConfidenceLevel(rawValue: conf) {
                    reviewSection(icon: "gauge", title: "Confidence", color: Color.statusOnHold) {
                        Text(level.displayName)
                            .font(.subheadline)
                    }
                }
                
                // Type
                if let type = selectedType {
                    Divider()
                    
                    reviewSection(icon: type.iconName, title: "Type", color: .purple) {
                        HStack(spacing: 6) {
                            Image(systemName: type.iconName)
                                .font(.caption)
                            Text(type.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                    }
                }
                
                // Labels
                if !selectedLabels.isEmpty {
                    Divider()
                    
                    reviewSection(icon: "tag.fill", title: "Labels (\(selectedLabels.count))", color: .purple) {
                        FlowLayout(spacing: 6) {
                            ForEach(selectedLabels) { tag in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(tagColor(for: tag))
                                        .frame(width: 8, height: 8)
                                    Text(tag.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(tagColor(for: tag).opacity(0.15))
                                .foregroundStyle(tagColor(for: tag))
                                .clipShape(Capsule())
                            }
                        }
                    }
                }
                
            }
            .padding()
            .background(Color.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Readiness check
            readinessChecklist
        }
    }
    
    private func reviewSection<Content: View>(icon: String, title: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            
            content()
                .padding(.leading, 28)
        }
    }
    
    /// Count of drivers (including subdrivers) that have logic defined
    private var driversWithLogicCount: Int {
        driversWithGroupedSubDrivers.reduce(0) { count, item in
            var logicCount = 0
            if !item.driver.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                logicCount += 1
            }
            logicCount += item.subDrivers.filter { !$0.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            return count + logicCount
        }
    }
    
    /// Total count of all drivers and subdrivers
    private var totalDriversCount: Int {
        driversWithGroupedSubDrivers.reduce(0) { $0 + 1 + $1.subDrivers.count }
    }
    
    /// Whether an asset is configured (selected, provided, or being created)
    private var hasAssetConfigured: Bool {
        asset != nil || selectedAsset != nil || (isCreatingNewAsset && !newAssetTicker.isEmpty && !newAssetName.isEmpty)
    }
    
    private var readinessChecklist: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readiness Checklist")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                checklistItem(passed: hasAssetConfigured, text: "Asset/ticker linked")
                checklistItem(passed: !investmentThesis.isEmpty, text: "Investment thesis defined")
                checklistItem(passed: !driversWithGroupedSubDrivers.isEmpty, text: "Assumptions added")
                checklistItem(passed: driversWithLogicCount > 0, text: "Logic defined (\(driversWithLogicCount)/\(totalDriversCount))")
                checklistItem(passed: confidence != nil, text: "Confidence set")
            }
        }
        .padding()
        .background(Color.surface.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func checklistItem(passed: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: passed ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(passed ? .green : .secondary)
            Text(text)
                .font(.caption)
                .foregroundStyle(passed ? .primary : .secondary)
        }
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .keyboardShortcut(.escape, modifiers: [])
            
            Spacer()
            
            if currentStep > 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
            
            if currentStep < 2 {
                Button {
                    if validateCurrentStep() {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentStep += 1
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button {
                    save()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark")
                        Text("Save Research Plan")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Validation
    
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case 1:
            if investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                validationMessage = "Please enter your investment thesis."
                showValidationError = true
                return false
            }
            return true
            
        default:
            return true
        }
    }
    
    // MARK: - Save
    
    private func save() {
        let rq: ResearchQuestion
        let trimmedThesis = investmentThesis.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContext = whyThisMatters.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Determine the final asset to use
        var finalAsset: Asset? = asset ?? selectedAsset
        
        // Create new asset if needed
        if finalAsset == nil && isCreatingNewAsset {
            let trimmedTicker = newAssetTicker.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedName = newAssetName.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !trimmedTicker.isEmpty && !trimmedName.isEmpty {
                let newAsset = Asset(ticker: trimmedTicker, name: trimmedName)
                modelContext.insert(newAsset)
                finalAsset = newAsset
            }
        }
        
        if let existing = existingQuestion {
            // Update existing
            // Note: thesis maps to both questionText (for backwards compat/title) and thesisStatement
            existing.update(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis,
                confidence: confidence
            )
            
            // Clear existing drivers
            existing.drivers?.forEach { modelContext.delete($0) }
            
            // Update type + labels (sync legacy tags for compatibility)
            existing.researchType = selectedType
            existing.labels = selectedLabels.isEmpty ? nil : selectedLabels
            existing.tags = existing.labels
            
            rq = existing
        } else {
            // Create new
            // Note: thesis maps to both questionText (for backwards compat/title) and thesisStatement
            rq = ResearchQuestion(
                questionText: trimmedThesis,
                context: trimmedContext.isEmpty ? nil : trimmedContext,
                thesisStatement: trimmedThesis,
                confidence: confidence
            )
            // Assign the final asset (either provided, selected, or newly created)
            if let assetToAssign = finalAsset {
                rq.asset = assetToAssign
            }
            
            // Assign type + labels (sync legacy tags for compatibility)
            rq.researchType = selectedType
            rq.labels = selectedLabels.isEmpty ? nil : selectedLabels
            rq.tags = rq.labels
        }
        
        // Save drivers and sub-drivers using the grouped structure
        // This ensures drivers marked with isSubDriver: true are properly saved with parent relationships
        for (index, item) in driversWithGroupedSubDrivers.enumerated() {
            let trimmedTitle = item.driver.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLogic = item.driver.logic.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let driver = Driver(
                title: trimmedTitle,
                driverDescription: item.driver.description.isEmpty ? nil : item.driver.description,
                logic: trimmedLogic.isEmpty ? nil : trimmedLogic,
                position: index
            )
            driver.researchQuestion = rq
            
            // Save all subdrivers (both from subDrivers array and isSubDriver flag)
            for (subIndex, sd) in item.subDrivers.enumerated() {
                let trimmedSubTitle = sd.title.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSubTitle.isEmpty {
                    let trimmedSubLogic = sd.logic.trimmingCharacters(in: .whitespacesAndNewlines)
                    let subDriver = Driver(
                        title: trimmedSubTitle,
                        driverDescription: sd.description.isEmpty ? nil : sd.description,
                        logic: trimmedSubLogic.isEmpty ? nil : trimmedSubLogic,
                        position: subIndex,
                        parentDriver: driver
                    )
                    subDriver.researchQuestion = rq
                }
            }
        }
        
        onSave(rq)
        dismiss()
    }
}

// MARK: - Wizard Type Toggle Chip

/// A toggleable chip for research type selection in the wizard
private struct WizardTypeToggleChip: View {
    let type: ResearchType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.caption2)
                Text(type.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor.opacity(0.15) : Color.surface)
            .foregroundStyle(isSelected ? Color.accentColor : .secondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.accentColor : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wizard Tag Toggle Chip

/// A toggleable chip for tag selection in the wizard
private struct WizardTagToggleChip: View {
    let tag: Tag
    let isSelected: Bool
    let action: () -> Void
    
    private var tagColor: Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return Color.accentColor
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
            .background(isSelected ? tagColor.opacity(0.2) : Color.surface)
            .foregroundStyle(isSelected ? tagColor : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? tagColor : Color.appBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("New Research") {
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    return ResearchWizardView(asset: asset) { _ in }
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Tag.self], inMemory: true)
}
