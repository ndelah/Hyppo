/**
 DestinationPicker component for Quick Capture HUD.
 
 Provides hierarchical selection of Asset → Research Question
 with inline create forms for rapid workflow.
 */

import SwiftUI
import SwiftData

// MARK: - Destination Picker View

/**
 A hierarchical picker for selecting the capture destination.
 
 Features:
 - Searchable asset dropdown with recent items at top
 - Research question picker filtered by selected asset
 - Inline create forms for new assets and questions
 */
struct DestinationPicker: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Queries
    
    @Query(sort: \Asset.updatedAt, order: .reverse) private var allAssets: [Asset]
    
    // MARK: - Bindings
    
    @Binding var selectedAsset: Asset?
    @Binding var selectedResearchQuestion: ResearchQuestion?
    @Binding var showInlineAssetForm: Bool
    @Binding var showInlineQuestionForm: Bool
    
    // MARK: - Local State
    
    @State private var assetSearchText: String = ""
    @State private var questionSearchText: String = ""
    
    // MARK: - Computed Properties
    
    /// Filtered assets based on search text
    private var filteredAssets: [Asset] {
        let active = allAssets.filter { !$0.isArchived }
        
        if assetSearchText.isEmpty {
            return active
        }
        
        let search = assetSearchText.lowercased()
        return active.filter {
            $0.ticker.lowercased().contains(search) ||
            $0.name.lowercased().contains(search)
        }
    }
    
    /// Research questions for the selected asset
    private var availableQuestions: [ResearchQuestion] {
        guard let asset = selectedAsset else { return [] }
        
        let questions = asset.researchQuestions ?? []
        
        if questionSearchText.isEmpty {
            return questions.sorted { $0.updatedAt > $1.updatedAt }
        }
        
        let search = questionSearchText.lowercased()
        return questions
            .filter { $0.questionText.lowercased().contains(search) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Asset Picker Section
            assetPickerSection
            
            // Research Question Picker Section (only if asset selected)
            if selectedAsset != nil {
                questionPickerSection
            }
        }
    }
    
    // MARK: - Asset Picker Section
    
    @ViewBuilder
    private var assetPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Asset", systemImage: "building.2")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if showInlineAssetForm {
                InlineAssetForm(
                    isPresented: $showInlineAssetForm,
                    onSave: { asset in
                        selectedAsset = asset
                        selectedResearchQuestion = nil
                    }
                )
            } else {
                HStack(spacing: 8) {
                    // Asset Dropdown
                    Menu {
                        // Search field at top
                        TextField("Search assets...", text: $assetSearchText)
                        
                        Divider()
                        
                        // Asset list
                        ForEach(filteredAssets) { asset in
                            Button {
                                selectedAsset = asset
                                selectedResearchQuestion = nil
                                assetSearchText = ""
                            } label: {
                                HStack {
                                    Text(asset.displayTitle)
                                    if selectedAsset?.assetId == asset.assetId {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        if filteredAssets.isEmpty {
                            Text("No assets found")
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        // Create new option
                        Button {
                            showInlineAssetForm = true
                        } label: {
                            Label("Create New Asset", systemImage: "plus")
                        }
                    } label: {
                        HStack {
                            if let asset = selectedAsset {
                                Text(asset.displayTitle)
                                    .lineLimit(1)
                            } else {
                                Text("Select asset...")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    
                    // Quick create button
                    Button {
                        showInlineAssetForm = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Create new asset")
                }
            }
        }
    }
    
    // MARK: - Research Question Picker Section
    
    @ViewBuilder
    private var questionPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Research Question", systemImage: "questionmark.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if showInlineQuestionForm {
                InlineQuestionForm(
                    asset: selectedAsset!,
                    isPresented: $showInlineQuestionForm,
                    onSave: { question in
                        selectedResearchQuestion = question
                    }
                )
            } else {
                HStack(spacing: 8) {
                    // Question Dropdown
                    Menu {
                        // Optional - can skip question selection
                        Button {
                            selectedResearchQuestion = nil
                            questionSearchText = ""
                        } label: {
                            HStack {
                                Text("No specific question")
                                    .foregroundStyle(.secondary)
                                if selectedResearchQuestion == nil {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Question list
                        ForEach(availableQuestions) { question in
                            Button {
                                selectedResearchQuestion = question
                                questionSearchText = ""
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(question.questionText)
                                            .lineLimit(2)
                                        Text(question.status.displayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    if selectedResearchQuestion?.questionId == question.questionId {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                        
                        if availableQuestions.isEmpty {
                            Text("No research questions")
                                .foregroundStyle(.secondary)
                        }
                        
                        Divider()
                        
                        // Create new option
                        Button {
                            showInlineQuestionForm = true
                        } label: {
                            Label("Create New Question", systemImage: "plus")
                        }
                    } label: {
                        HStack {
                            if let question = selectedResearchQuestion {
                                Text(question.questionText)
                                    .lineLimit(1)
                            } else {
                                Text("Select question (optional)...")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color(.controlBackgroundColor))
                        .cornerRadius(6)
                    }
                    .menuStyle(.borderlessButton)
                    
                    // Quick create button
                    Button {
                        showInlineQuestionForm = true
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("Create new research question")
                }
            }
        }
    }
}

// MARK: - Inline Asset Form

/**
 Compact form for creating a new asset inline.
 */
struct InlineAssetForm: View {
    @Environment(\.modelContext) private var modelContext
    
    @Binding var isPresented: Bool
    var onSave: (Asset) -> Void
    
    @State private var ticker: String = ""
    @State private var name: String = ""
    @State private var validationError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("New Asset")
                    .font(.caption.bold())
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 8) {
                TextField("Ticker", text: $ticker)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .textCase(.uppercase)
                
                TextField("Company Name", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack {
                Spacer()
                Button("Create") {
                    createAsset()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(ticker.isEmpty || name.isEmpty)
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func createAsset() {
        let trimmedTicker = ticker.trimmingCharacters(in: .whitespaces).uppercased()
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedTicker.isEmpty else {
            validationError = "Ticker is required"
            return
        }
        
        guard !trimmedName.isEmpty else {
            validationError = "Name is required"
            return
        }
        
        let asset = Asset(ticker: trimmedTicker, name: trimmedName)
        modelContext.insert(asset)
        
        do {
            try modelContext.save()
            onSave(asset)
            isPresented = false
        } catch {
            validationError = "Failed to create asset"
        }
    }
}

// MARK: - Inline Question Form

/**
 Compact form for creating a new research question inline.
 */
struct InlineQuestionForm: View {
    @Environment(\.modelContext) private var modelContext
    
    let asset: Asset
    @Binding var isPresented: Bool
    var onSave: (ResearchQuestion) -> Void
    
    @State private var questionText: String = ""
    @State private var validationError: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("New Research Question")
                    .font(.caption.bold())
                Spacer()
                Button("Cancel") {
                    isPresented = false
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            
            TextField("What do you want to research about \(asset.ticker)?", text: $questionText)
                .textFieldStyle(.roundedBorder)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            
            HStack {
                Spacer()
                Button("Create") {
                    createQuestion()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(questionText.isEmpty)
            }
        }
        .padding(10)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func createQuestion() {
        let trimmedText = questionText.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedText.isEmpty else {
            validationError = "Question text is required"
            return
        }
        
        let question = ResearchQuestion(questionText: trimmedText)
        question.asset = asset
        modelContext.insert(question)
        
        // Update asset's relationship
        if asset.researchQuestions == nil {
            asset.researchQuestions = []
        }
        asset.researchQuestions?.append(question)
        
        do {
            try modelContext.save()
            onSave(question)
            isPresented = false
        } catch {
            validationError = "Failed to create question"
        }
    }
}

// MARK: - Compact Destination Display

/**
 Shows the selected destination in compact mode.
 */
struct CompactDestinationDisplay: View {
    let asset: Asset?
    let researchQuestion: ResearchQuestion?
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let asset = asset {
                    Text(asset.ticker)
                        .fontWeight(.medium)
                    
                    if let question = researchQuestion {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(question.questionText)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Select destination")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DestinationPicker(
        selectedAsset: .constant(nil),
        selectedResearchQuestion: .constant(nil),
        showInlineAssetForm: .constant(false),
        showInlineQuestionForm: .constant(false)
    )
    .padding()
    .frame(width: 400)
}

