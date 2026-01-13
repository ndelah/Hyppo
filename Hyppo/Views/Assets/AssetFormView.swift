/**
 AssetFormView provides a form for creating or editing an asset.
 
 Supports both add and edit modes with validation and appropriate
 save/cancel actions.
 */

import SwiftUI
import SwiftData

/// Form mode for add vs edit
enum AssetFormMode {
    case add
    case edit(Asset)
    
    var title: String {
        switch self {
        case .add: return "Add Asset"
        case .edit: return "Edit Asset"
        }
    }
    
    var saveButtonTitle: String {
        switch self {
        case .add: return "Add"
        case .edit: return "Save"
        }
    }
}

/// Form for creating or editing an asset
struct AssetFormView: View {
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties
    
    let mode: AssetFormMode
    let onSave: (Asset) -> Void
    
    // MARK: - State
    
    @State private var ticker: String = ""
    @State private var name: String = ""
    @State private var exchange: String = ""
    @State private var currency: String = ""
    @State private var selectedTags: [Tag] = []
    @State private var validationErrors: [String] = []
    
    // MARK: - Initialization
    
    init(mode: AssetFormMode, onSave: @escaping (Asset) -> Void) {
        self.mode = mode
        self.onSave = onSave
        
        // Pre-populate for edit mode
        if case .edit(let asset) = mode {
            _ticker = State(initialValue: asset.ticker)
            _name = State(initialValue: asset.name)
            _exchange = State(initialValue: asset.exchange ?? "")
            _currency = State(initialValue: asset.currency ?? "")
            _selectedTags = State(initialValue: asset.tags ?? [])
        }
    }
    
    // MARK: - Computed Properties
    
    private var isValid: Bool {
        !ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Form content
            Form {
                Section {
                    TextField("Ticker", text: $ticker, prompt: Text("e.g., AAPL"))
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Company Name", text: $name, prompt: Text("e.g., Apple Inc."))
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Required")
                }
                
                Section {
                    TextField("Exchange", text: $exchange, prompt: Text("e.g., NASDAQ"))
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Currency", text: $currency, prompt: Text("e.g., USD"))
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Optional")
                }
                
                Section {
                    TagPickerView(selectedTags: $selectedTags)
                } header: {
                    Text("Tags")
                }
                
                // Validation errors
                if !validationErrors.isEmpty {
                    Section {
                        ForEach(validationErrors, id: \.self) { error in
                            Label(error, systemImage: "exclamationmark.circle")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer with buttons
            footerView
        }
        .frame(width: 400, height: 450)
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
        
        if ticker.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Ticker is required")
        }
        
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Company name is required")
        }
        
        return validationErrors.isEmpty
    }
    
    private func save() {
        guard validate() else { return }
        
        let trimmedExchange = exchange.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch mode {
        case .add:
            let newAsset = Asset(
                ticker: ticker,
                name: name,
                exchange: trimmedExchange.isEmpty ? nil : trimmedExchange,
                currency: trimmedCurrency.isEmpty ? nil : trimmedCurrency
            )
            newAsset.tags = selectedTags.isEmpty ? nil : selectedTags
            onSave(newAsset)
            
        case .edit(let asset):
            asset.update(
                ticker: ticker,
                name: name,
                exchange: trimmedExchange.isEmpty ? nil : trimmedExchange,
                currency: trimmedCurrency.isEmpty ? nil : trimmedCurrency
            )
            asset.tags = selectedTags.isEmpty ? nil : selectedTags
            onSave(asset)
        }
        
        dismiss()
    }
}

// MARK: - Preview

#Preview("Add") {
    AssetFormView(mode: .add) { _ in }
        .modelContainer(for: [Asset.self, Tag.self], inMemory: true)
}

