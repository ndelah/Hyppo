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
    
    /// Confidence level for the research question (1-5 scale)
    @State private var confidence: Int? = nil
    
    /// Selected tags for the research question
    @State private var selectedTags: [Tag] = []
    
    /// State for creating new tags
    @State private var showingTagCreation = false
    @State private var newTagName = ""
    @State private var newTagColor: TagColor = .blue
    
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
            
            // Pre-populate tags
            _selectedTags = State(initialValue: question.tags ?? [])
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
                                .foregroundStyle(.blue)
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
                    .fill(step <= currentStep ? Color.accentColor : Color(nsColor: .separatorColor))
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
            .fill(completed ? Color.accentColor : Color(nsColor: .separatorColor))
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
                        .foregroundStyle(.red)
                }
                
                Text("What must be true for this investment to work?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                TextEditor(text: $investmentThesis)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(8)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
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
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(nsColor: .separatorColor)))
            }
            
            // Key Assumptions (Drivers)
            VStack(alignment: .leading, spacing: 8) {
                Text("Key Assumptions")
                    .font(.headline)
                
                DriverOutlineView(
                    drivers: $drivers,
                    prompt: "What assumptions must be true for this thesis to hold?"
                )
                
                // Status hint
                let validCount = validDriversForDesign.count
                if validCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(validCount) assumption\(validCount == 1 ? "" : "s") defined")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Confidence Level
            VStack(alignment: .leading, spacing: 8) {
                Text("Confidence Level")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    ForEach(ConfidenceLevel.allCases, id: \.rawValue) { level in
                        Button {
                            if confidence == level.rawValue {
                                confidence = nil
                            } else {
                                confidence = level.rawValue
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: (confidence ?? 0) >= level.rawValue ? "star.fill" : "star")
                                    .font(.body)
                                Text(level.displayName)
                                    .font(.caption2)
                            }
                            .frame(width: 60, height: 44)
                            .background(confidence == level.rawValue ? Color.accentColor : Color(nsColor: .windowBackgroundColor))
                            .foregroundStyle(confidence == level.rawValue ? .white : ((confidence ?? 0) >= level.rawValue ? .orange : .primary))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Tags
            tagsSection
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Tags")
                    .font(.headline)
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Categorize this research for easy filtering later.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                if allTags.isEmpty && selectedTags.isEmpty {
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
                            WizardTagToggleChip(
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
                            .background(Color(nsColor: .windowBackgroundColor))
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
    
    private func tagColor(for tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return .blue
        }
        return color.color
    }
    
    // MARK: - Asset Selection Section
    
    /// Section for selecting an existing asset or creating a new one
    private var assetSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Asset / Ticker")
                    .font(.headline)
                Text("(optional)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Link this research to an asset or create a new one.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            // Toggle between select existing or create new
            Picker("", selection: $isCreatingNewAsset) {
                Text("Select Existing").tag(false)
                Text("Create New").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 240)
            
            if isCreatingNewAsset {
                // Create new asset form
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        // Ticker field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ticker")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("e.g. AAPL", text: $newAssetTicker)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .textCase(.uppercase)
                                .onChange(of: newAssetTicker) { _, newValue in
                                    newAssetTicker = newValue.uppercased()
                                }
                        }
                        
                        // Company name field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Company Name")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("e.g. Apple Inc.", text: $newAssetName)
                                .textFieldStyle(.roundedBorder)
                                .frame(minWidth: 200)
                        }
                    }
                    
                    // Show validation hint
                    if !newAssetTicker.isEmpty || !newAssetName.isEmpty {
                        if newAssetTicker.isEmpty || newAssetName.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundStyle(.orange)
                                Text("Both ticker and company name are required to create an asset")
                                    .foregroundStyle(.orange)
                            }
                            .font(.caption)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("New asset will be created: \(newAssetTicker.uppercased()) - \(newAssetName)")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                }
                .padding(12)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Select existing asset
                if allAssets.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("No existing assets found.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button {
                            isCreatingNewAsset = true
                        } label: {
                            Label("Create your first asset", systemImage: "plus.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.blue)
                    }
                    .padding(12)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Menu {
                            Button {
                                selectedAsset = nil
                            } label: {
                                Text("No asset (skip)")
                            }
                            
                            Divider()
                            
                            ForEach(allAssets) { assetOption in
                                Button {
                                    selectedAsset = assetOption
                                } label: {
                                    HStack {
                                        Text(assetOption.ticker)
                                            .fontWeight(.semibold)
                                        Text("- \(assetOption.name)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                if let selected = selectedAsset {
                                    HStack(spacing: 6) {
                                        Text(selected.ticker)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                        Text("- \(selected.name)")
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                                    Text("Select an asset...")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Color(nsColor: .textBackgroundColor))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                            )
                        }
                        .menuStyle(.borderlessButton)
                        
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
                        }
                    }
                }
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
                    reviewSection(icon: "chart.line.uptrend.xyaxis", title: "New Asset (will be created)", color: .blue) {
                        HStack(spacing: 8) {
                            Text(newAssetTicker.uppercased())
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text(newAssetName)
                                .font(.subheadline)
                        }
                    }
                }
                
                // Thesis & Context
                VStack(alignment: .leading, spacing: 12) {
                    reviewSection(icon: "lightbulb.fill", title: "Investment Thesis", color: .blue) {
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
                if !validDriversForDesign.isEmpty {
                    reviewSection(icon: "target", title: "Key Assumptions (\(validDriversForDesign.count))", color: .green) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(validDriversForDesign.enumerated()), id: \.element.id) { index, driver in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(index + 1). \(driver.title)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    // Logic if defined
                                    if !driver.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(driver.logic)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .padding(.leading, 12)
                                    }
                                    
                                    // Sub-drivers
                                    ForEach(driver.subDrivers.filter { !$0.title.isEmpty }) { sub in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("  → \(sub.title)")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                            
                                            // Sub-driver logic if defined
                                            if !sub.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                                Text(sub.logic)
                                                    .font(.caption2)
                                                    .foregroundStyle(.quaternary)
                                                    .padding(.leading, 24)
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
                    reviewSection(icon: "star.fill", title: "Confidence", color: .orange) {
                        Text(level.displayName)
                            .font(.subheadline)
                    }
                }
                
                // Tags
                if !selectedTags.isEmpty {
                    Divider()
                    
                    reviewSection(icon: "tag.fill", title: "Tags (\(selectedTags.count))", color: .purple) {
                        FlowLayout(spacing: 6) {
                            ForEach(selectedTags) { tag in
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
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
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
    
    /// Count of drivers that have logic defined
    private var driversWithLogicCount: Int {
        validDriversForDesign.filter { !$0.logic.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
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
                checklistItem(passed: !validDriversForDesign.isEmpty, text: "Assumptions added")
                checklistItem(passed: driversWithLogicCount > 0, text: "Logic defined (\(driversWithLogicCount)/\(validDriversForDesign.count))")
                checklistItem(passed: confidence != nil, text: "Confidence set")
            }
        }
        .padding()
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.3))
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
            
            // Update tags
            existing.tags = selectedTags.isEmpty ? nil : selectedTags
            
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
            
            // Assign tags
            rq.tags = selectedTags.isEmpty ? nil : selectedTags
        }
        
        // Save drivers and sub-drivers
        for (index, d) in drivers.enumerated() {
            let trimmedTitle = d.title.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedTitle.isEmpty {
                let trimmedLogic = d.logic.trimmingCharacters(in: .whitespacesAndNewlines)
                let driver = Driver(
                    title: trimmedTitle,
                    driverDescription: d.description.isEmpty ? nil : d.description,
                    logic: trimmedLogic.isEmpty ? nil : trimmedLogic,
                    position: index
                )
                driver.researchQuestion = rq
                
                for (subIndex, sd) in d.subDrivers.enumerated() {
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
        }
        
        onSave(rq)
        dismiss()
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
            .background(isSelected ? tagColor.opacity(0.2) : Color(nsColor: .windowBackgroundColor))
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

// MARK: - Preview

#Preview("New Research") {
    let asset = Asset(ticker: "NVDA", name: "NVIDIA Corporation")
    return ResearchWizardView(asset: asset) { _ in }
        .modelContainer(for: [Asset.self, ResearchQuestion.self, Driver.self, Tag.self], inMemory: true)
}
