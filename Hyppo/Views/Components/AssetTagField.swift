/**
 AssetTagField provides a Notion-like tag input for asset/ticker selection.
 
 Features:
 - Click to focus and type
 - Auto-suggests existing assets as you type
 - Press enter to create new ticker if it doesn't exist
 - Shows selected asset as a removable chip
 */

import SwiftUI
import SwiftData

struct AssetTagField: View {
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    
    // MARK: - Properties
    
    let allAssets: [Asset]
    @Binding var selectedAsset: Asset?
    @Binding var isCreatingNew: Bool
    @Binding var newTicker: String
    @Binding var newName: String
    /// Reports whether the asset text field currently has focus
    @Binding var isFieldFocused: Bool
    
    // MARK: - State
    
    @State private var searchText: String = ""
    @State private var isFocused: Bool = false
    @State private var showSuggestions: Bool = false
    @State private var highlightedIndex: Int = 0
    @FocusState private var textFieldFocused: Bool
    
    // MARK: - Computed Properties
    
    /// Filtered assets based on search text
    private var filteredAssets: [Asset] {
        guard !searchText.isEmpty else { return allAssets }
        
        let query = searchText.uppercased()
        return allAssets.filter { asset in
            asset.ticker.uppercased().contains(query) ||
            asset.name.uppercased().contains(query)
        }
    }
    
    /// Check if the typed ticker already exists
    private var tickerExists: Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return allAssets.contains { $0.ticker.uppercased() == query }
    }
    
    /// The existing asset that matches the typed ticker exactly
    private var matchingAsset: Asset? {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        return allAssets.first { $0.ticker.uppercased() == query }
    }
    
    /// Whether we can create a new ticker (non-empty and doesn't exist)
    private var canCreateNew: Bool {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !tickerExists
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main input area
            ZStack(alignment: .leading) {
                // Background tap area
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? Color.accentColor : Color.appBorder, lineWidth: isFocused ? 2 : 1)
                    )
                
                HStack(spacing: 8) {
                    // Selected asset chip (if any)
                    if let asset = selectedAsset {
                        selectedAssetChip(asset)
                    } else if isCreatingNew && !newTicker.isEmpty {
                        newAssetChip
                    } else {
                        // Text input
                        TextField("Type ticker (e.g. AAPL)...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($textFieldFocused)
                            .textCase(.uppercase)
                            .onChange(of: searchText) { _, newValue in
                                searchText = newValue.uppercased()
                                showSuggestions = !newValue.isEmpty
                                highlightedIndex = 0
                            }
                            .onSubmit {
                                handleSubmitWithHighlight()
                            }
                            .onKeyPress(.downArrow) {
                                moveSelection(by: 1)
                                return .handled
                            }
                            .onKeyPress(.upArrow) {
                                moveSelection(by: -1)
                                return .handled
                            }
                            .onKeyPress(.tab) {
                                // Tab confirms the highlighted selection (same as Enter)
                                if showSuggestions && totalSelectableItems > 0 {
                                    handleSubmitWithHighlight()
                                    return .handled
                                }
                                return .ignored
                            }
                    }
                    
                    Spacer()
                    
                    // Clear button when there's a selection
                    if selectedAsset != nil || (isCreatingNew && !newTicker.isEmpty) {
                        Button {
                            clearSelection()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .frame(height: 44)
            .onTapGesture {
                if selectedAsset == nil && !(isCreatingNew && !newTicker.isEmpty) {
                    textFieldFocused = true
                }
            }
            .onChange(of: textFieldFocused) { _, focused in
                isFocused = focused
                isFieldFocused = focused
                if !focused {
                    // Delay hiding suggestions to allow click
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        showSuggestions = false
                    }
                }
            }
            
            // Suggestions dropdown
            if showSuggestions && selectedAsset == nil && !isCreatingNew {
                suggestionsDropdown
            }
            
            // Company name field when creating new
            if isCreatingNew && !newTicker.isEmpty {
                companyNameField
            }
        }
    }
    
    // MARK: - Selected Asset Chip
    
    private func selectedAssetChip(_ asset: Asset) -> some View {
        HStack(spacing: 6) {
            Text(asset.ticker)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text("·")
                .foregroundStyle(.secondary)
            
            Text(asset.name)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.purple.opacity(0.15))
        .foregroundStyle(Color.purple)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - New Asset Chip
    
    private var newAssetChip: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle.fill")
                .font(.caption)
            
            Text(newTicker)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if !newName.isEmpty {
                Text("·")
                    .foregroundStyle(.secondary)
                
                Text(newName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            } else {
                Text("(new)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.assetBackgroundColor)
        .foregroundStyle(Color.assetColor)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    // MARK: - Suggestions Dropdown
    
    private var suggestionsDropdown: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Existing assets
            if !filteredAssets.isEmpty {
                ForEach(Array(filteredAssets.prefix(5).enumerated()), id: \.element.assetId) { index, asset in
                    Button {
                        selectAsset(asset)
                    } label: {
                        HStack(spacing: 8) {
                            Text(asset.ticker)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            
                            Text(asset.name)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(asset.researchQuestionsCount) questions")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(highlightedIndex == index ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    
                    if index < filteredAssets.prefix(5).count - 1 || canCreateNew {
                        Divider()
                            .padding(.leading, 12)
                    }
                }
            }
            
            // Create new option
            if canCreateNew {
                Button {
                    createNewAsset()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(Color.assetColor)
                        
                        Text("Create")
                            .foregroundStyle(.primary)
                        
                        Text(searchText.uppercased())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.assetColor)
                        
                        Spacer()
                        
                        Text("↵")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appBorder.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(highlightedIndex == filteredAssets.prefix(5).count ? Color.accentColor.opacity(0.1) : Color.clear)
                }
                .buttonStyle(.plain)
            }
            
            // Empty state
            if filteredAssets.isEmpty && !canCreateNew && !searchText.isEmpty {
                HStack {
                    Text("No matching assets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appBorder, lineWidth: 1)
        )
    }
    
    // MARK: - Company Name Field
    
    private var companyNameField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Company Name")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("e.g. Apple Inc.", text: $newName)
                .textFieldStyle(.roundedBorder)
            
            // Validation hint
            if newName.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Color.statusOnHold)
                    Text("Enter company name to create the asset")
                        .foregroundStyle(Color.statusOnHold)
                }
                .font(.caption)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.statusActive)
                    Text("New asset will be created: \(newTicker) - \(newName)")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            }
        }
        .padding(12)
        .background(Color.assetColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // MARK: - Computed Properties for Navigation
    
    /// Total number of selectable items (filtered assets + create new option if available)
    private var totalSelectableItems: Int {
        let assetCount = min(filteredAssets.count, 5)
        return canCreateNew ? assetCount + 1 : assetCount
    }
    
    // MARK: - Actions
    
    /// Moves the highlighted selection by the given delta
    private func moveSelection(by delta: Int) {
        guard showSuggestions && totalSelectableItems > 0 else { return }
        
        let newIndex = highlightedIndex + delta
        if newIndex >= 0 && newIndex < totalSelectableItems {
            highlightedIndex = newIndex
        }
    }
    
    /// Handles submit when user presses Enter, using the highlighted selection
    private func handleSubmitWithHighlight() {
        guard showSuggestions else {
            handleSubmit()
            return
        }
        
        let visibleAssets = Array(filteredAssets.prefix(5))
        
        // If highlighting an asset, select it
        if highlightedIndex < visibleAssets.count {
            selectAsset(visibleAssets[highlightedIndex])
            return
        }
        
        // If highlighting the "Create new" option, create it
        if canCreateNew && highlightedIndex == visibleAssets.count {
            createNewAsset()
            return
        }
        
        // Fallback to default submit behavior
        handleSubmit()
    }
    
    private func selectAsset(_ asset: Asset) {
        selectedAsset = asset
        isCreatingNew = false
        newTicker = ""
        newName = ""
        searchText = ""
        showSuggestions = false
        textFieldFocused = false
    }
    
    private func createNewAsset() {
        let ticker = searchText.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Check if there's an exact match (user may have typed full ticker)
        if let existing = matchingAsset {
            selectAsset(existing)
            return
        }
        
        // Start creating new
        newTicker = ticker
        isCreatingNew = true
        selectedAsset = nil
        searchText = ""
        showSuggestions = false
        textFieldFocused = false
    }
    
    private func handleSubmit() {
        // If there's an exact match, select it
        if let existing = matchingAsset {
            selectAsset(existing)
            return
        }
        
        // If only one result, select it
        if filteredAssets.count == 1 {
            selectAsset(filteredAssets[0])
            return
        }
        
        // Otherwise, create new
        if canCreateNew {
            createNewAsset()
        }
    }
    
    private func clearSelection() {
        selectedAsset = nil
        isCreatingNew = false
        newTicker = ""
        newName = ""
        searchText = ""
        // Focus the text field after clearing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            textFieldFocused = true
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedAsset: Asset?
        @State private var isCreatingNew = false
        @State private var newTicker = ""
        @State private var newName = ""
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                Text("Asset / Ticker")
                    .font(.headline)
                
                AssetTagField(
                    allAssets: [
                        Asset(ticker: "AAPL", name: "Apple Inc."),
                        Asset(ticker: "NVDA", name: "NVIDIA Corporation"),
                        Asset(ticker: "MSFT", name: "Microsoft Corporation"),
                        Asset(ticker: "GOOGL", name: "Alphabet Inc.")
                    ],
                    selectedAsset: $selectedAsset,
                    isCreatingNew: $isCreatingNew,
                    newTicker: $newTicker,
                    newName: $newName,
                    isFieldFocused: .constant(false)
                )
                
                Spacer()
            }
            .padding()
            .frame(width: 400, height: 400)
        }
    }
    
    return PreviewWrapper()
}

