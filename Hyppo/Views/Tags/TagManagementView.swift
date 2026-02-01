/**
 TagManagementView provides UI for creating, editing, and deleting tags.
 
 Can be used as a standalone sheet for global tag management or
 embedded in forms for inline tag selection.
 */

import SwiftUI
import SwiftData

// MARK: - Tag Management Sheet

/// Sheet for managing all tags in the app
struct TagManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Tag.name) private var tags: [Tag]
    
    @State private var newTagName = ""
    @State private var newTagColor: TagColor = .blue
    @State private var editingTag: Tag?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Manage Tags")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // Add new tag
            HStack(spacing: 12) {
                TextField("New tag name", text: $newTagName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        addTag()
                    }
                
                Picker("", selection: $newTagColor) {
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
                .frame(width: 120)
                
                Button("Add") {
                    addTag()
                }
                .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            
            Divider()
            
            // Tag list
            if tags.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tag")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No tags yet")
                        .font(.headline)
                    Text("Create tags to organize your assets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(tags) { tag in
                        TagRowView(tag: tag, onEdit: { editingTag = tag })
                    }
                    .onDelete(perform: deleteTags)
                }
                .listStyle(.inset)
            }
        }
        .frame(width: 400, height: 450)
        .sheet(item: $editingTag) { tag in
            TagEditSheet(tag: tag)
        }
    }
    
    private func addTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let tag = Tag(name: trimmedName, colorName: newTagColor.rawValue)
        modelContext.insert(tag)
        
        newTagName = ""
        newTagColor = .blue
    }
    
    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(tags[index])
        }
    }
}

// MARK: - Tag Row View

/// Row view for a tag in the management list
struct TagRowView: View {
    let tag: Tag
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(tagColor)
                .frame(width: 12, height: 12)
            
            Text(tag.name)
                .font(.body)
            
            Spacer()
            
            // Usage count
            let assetCount = tag.assets?.count ?? 0
            if assetCount > 0 {
                Text("\(assetCount) asset\(assetCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.caption)
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 4)
    }
    
    private var tagColor: Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Tag Edit Sheet

/// Sheet for editing an existing tag
struct TagEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var tag: Tag
    
    @State private var name: String = ""
    @State private var selectedColor: TagColor = .blue
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Tag")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            Divider()
            
            Form {
                TextField("Name", text: $name)
                
                Picker("Color", selection: $selectedColor) {
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
            }
            .formStyle(.grouped)
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .frame(width: 350, height: 280)
        .onAppear {
            name = tag.name
            if let colorName = tag.colorName, let color = TagColor(rawValue: colorName) {
                selectedColor = color
            }
        }
    }
    
    private func save() {
        tag.updateName(name)
        tag.colorName = selectedColor.rawValue
        dismiss()
    }
}

// MARK: - Tag Picker View

/// Inline tag picker for asset forms
struct TagPickerView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Tag.name) private var allTags: [Tag]
    @Binding var selectedTags: [Tag]
    
    @State private var showingTagManagement = false
    @State private var newTagName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected tags
            if !selectedTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(selectedTags) { tag in
                        TagChip(tag: tag, isSelected: true) {
                            removeTag(tag)
                        }
                    }
                }
            }
            
            // Available tags
            HStack {
                Menu {
                    ForEach(availableTags) { tag in
                    Button {
                        addTag(tag)
                    } label: {
                        Label {
                            Text(tag.name)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.monochrome)
                                .foregroundStyle(colorFor(tag))
                        }
                    }
                    }
                    
                    if !availableTags.isEmpty {
                        Divider()
                    }
                    
                    Button {
                        showingTagManagement = true
                    } label: {
                        Label("Manage Tags...", systemImage: "gear")
                    }
                } label: {
                    Label("Add Tag", systemImage: "plus")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingTagManagement) {
            TagManagementSheet()
        }
    }
    
    private var availableTags: [Tag] {
        allTags.filter { tag in
            !selectedTags.contains { $0.tagId == tag.tagId }
        }
    }
    
    private func addTag(_ tag: Tag) {
        if !selectedTags.contains(where: { $0.tagId == tag.tagId }) {
            selectedTags.append(tag)
        }
    }
    
    private func removeTag(_ tag: Tag) {
        selectedTags.removeAll { $0.tagId == tag.tagId }
    }
    
    private func colorFor(_ tag: Tag) -> Color {
        guard let colorName = tag.colorName,
              let tagColor = TagColor(rawValue: colorName) else {
            return .blue
        }
        return tagColor.color
    }
}

// MARK: - Tag Chip

/// Small chip view for displaying a tag
struct TagChip: View {
    let tag: Tag
    var isSelected: Bool = false
    var onRemove: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(tagColor)
                .frame(width: 8, height: 8)
            
            Text(tag.name)
                .font(.caption)
            
            if let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tagColor.opacity(0.15))
        .foregroundStyle(tagColor)
        .clipShape(Capsule())
    }
    
    private var tagColor: Color {
        guard let colorName = tag.colorName,
              let color = TagColor(rawValue: colorName) else {
            return .blue
        }
        return color.color
    }
}

// MARK: - Flow Layout

/// Simple flow layout for wrapping tag chips
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }
        
        totalHeight = currentY + lineHeight
        
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
}

// MARK: - Preview

#Preview("Tag Management") {
    TagManagementSheet()
        .modelContainer(for: [Tag.self, Asset.self], inMemory: true)
}

#Preview("Tag Picker") {
    TagPickerView(selectedTags: .constant([]))
        .padding()
        .modelContainer(for: [Tag.self], inMemory: true)
}

