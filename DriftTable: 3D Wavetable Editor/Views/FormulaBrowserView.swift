//
//  FormulaBrowserView.swift
//  DriftTable
//
//  Browser for formula library with save/load/manage capabilities
//

import SwiftUI

struct FormulaBrowserView: View {
    @StateObject private var library = FormulaLibraryManager()
    @State private var searchText = ""
    @State private var selectedCategory: String = "Favorites"
    @State private var showAddFormula = false
    @State private var editingFormula: FormulaEntry?
    @State private var isMultiFrame: Bool
    
    let onSelectFormula: (String) -> Void
    let onModeChanged: ((Bool) -> Void)?
    @Environment(\.dismiss) private var dismiss
    
    init(isMultiFrame: Bool, onSelectFormula: @escaping (String) -> Void, onModeChanged: ((Bool) -> Void)? = nil) {
        _isMultiFrame = State(initialValue: isMultiFrame)
        self.onSelectFormula = onSelectFormula
        self.onModeChanged = onModeChanged
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Compact search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.subheadline)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                // Compact category picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        CategoryButton(
                            title: "⭐",
                            icon: "",
                            isSelected: selectedCategory == "Favorites"
                        ) {
                            selectedCategory = "Favorites"
                        }
                        
                        CategoryButton(
                            title: "My",
                            icon: "",
                            isSelected: selectedCategory == "My Formulas"
                        ) {
                            selectedCategory = "My Formulas"
                        }
                        
                        ForEach(relevantCategories.prefix(8), id: \.id) { category in
                            CategoryButton(
                                title: category.displayName.prefix(8).description,
                                icon: "",
                                isSelected: selectedCategory == category.id
                            ) {
                                selectedCategory = category.id
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .padding(.vertical, 6)
                
                Divider()
                
                // Compact formula list - use ScrollView to prevent popover resizing
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(displayedFormulas) { formula in
                            FormulaRow(
                                formula: formula,
                                onTap: {
                                    onSelectFormula(formula.expression)
                                    dismiss()
                                },
                                onFavorite: {
                                    library.toggleFavorite(id: formula.id)
                                },
                                onEdit: formula.isUserCreated ? {
                                    editingFormula = formula
                                } : nil,
                                onDelete: formula.isUserCreated ? {
                                    library.deleteUserFormula(id: formula.id)
                                } : nil
                            )
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            Divider()
                        }
                    }
                }
            }
            .navigationTitle("Formulas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(.subheadline)
                }
                
                ToolbarItem(placement: .principal) {
                    Picker("Mode", selection: $isMultiFrame) {
                        Text("Single").tag(false)
                        Text("Multi").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    .onChange(of: isMultiFrame) { _, newValue in
                        onModeChanged?(newValue)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddFormula = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline)
                    }
                }
            }
            .sheet(isPresented: $showAddFormula) {
                AddFormulaView(library: library, isMultiFrame: isMultiFrame)
            }
            .sheet(item: $editingFormula) { formula in
                EditFormulaView(library: library, formula: formula)
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    // MARK: - Computed Properties
    
    private var relevantCategories: [FormulaCategory] {
        library.categories.filter { $0.isMultiFrame == isMultiFrame }
    }
    
    private var displayedFormulas: [FormulaEntry] {
        if !searchText.isEmpty {
            return library.searchFormulas(query: searchText, isMultiFrame: isMultiFrame)
        }
        
        switch selectedCategory {
        case "Favorites":
            return library.favoriteFormulas(isMultiFrame: isMultiFrame)
        case "My Formulas":
            return library.userFormulas.filter { formula in
                let engine = FormulaEngine()
                if let compiled = try? engine.compile(formula.expression) {
                    return engine.usesFrameVariables(compiled) == isMultiFrame
                }
                return false
            }
        default:
            return library.formulas(in: selectedCategory, isMultiFrame: isMultiFrame)
        }
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if !icon.isEmpty {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Formula Row

struct FormulaRow: View {
    let formula: FormulaEntry
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formula.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(formula.expression)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    if formula.isUserCreated {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.blue)
                            .font(.caption2)
                    }
                    
                    Button(action: onFavorite) {
                        Image(systemName: formula.isFavorite ? "star.fill" : "star")
                            .foregroundColor(formula.isFavorite ? .yellow : .gray)
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if onDelete != nil {
                Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .confirmationDialog("Delete Formula?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \"\(formula.name)\"?")
        }
    }
}

// MARK: - Add Formula View

struct AddFormulaView: View {
    @ObservedObject var library: FormulaLibraryManager
    let isMultiFrame: Bool
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var expression = ""
    @State private var category = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Formula Details") {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                        .autocapitalization(.words)
                }
                
                Section("Expression") {
                    TextEditor(text: $expression)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                }
                
                Section {
                    Text("Type: \(isMultiFrame ? "Multi-Frame" : "Single-Frame")")
                        .foregroundColor(.secondary)
                    Text("Use variables like x, w for single-frame, or y, z for multi-frame morphs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Formula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFormula()
                    }
                    .disabled(name.isEmpty || expression.isEmpty || category.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveFormula() {
        // Validate expression
        let engine = FormulaEngine()
        do {
            let compiled = try engine.compile(expression)
            let usesFrameVars = engine.usesFrameVariables(compiled)
            
            if usesFrameVars != isMultiFrame {
                errorMessage = isMultiFrame
                    ? "This expression doesn't use frame variables (y or z). Use the Single-Frame browser instead."
                    : "This expression uses frame variables (y or z). Use the Multi-Frame browser instead."
                showError = true
                return
            }
            
            library.addUserFormula(
                expression: expression,
                name: name,
                category: category,
                isMultiFrame: isMultiFrame
            )
            dismiss()
        } catch {
            errorMessage = "Invalid expression: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Edit Formula View

struct EditFormulaView: View {
    @ObservedObject var library: FormulaLibraryManager
    let formula: FormulaEntry
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var expression: String
    @State private var category: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    init(library: FormulaLibraryManager, formula: FormulaEntry) {
        self.library = library
        self.formula = formula
        _name = State(initialValue: formula.name)
        _expression = State(initialValue: formula.expression)
        _category = State(initialValue: formula.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Formula Details") {
                    TextField("Name", text: $name)
                    TextField("Category", text: $category)
                        .autocapitalization(.words)
                }
                
                Section("Expression") {
                    TextEditor(text: $expression)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Formula")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateFormula()
                    }
                    .disabled(name.isEmpty || expression.isEmpty || category.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func updateFormula() {
        // Validate expression
        let engine = FormulaEngine()
        do {
            _ = try engine.compile(expression)
            
            library.updateUserFormula(
                id: formula.id,
                expression: expression,
                name: name,
                category: category
            )
            dismiss()
        } catch {
            errorMessage = "Invalid expression: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    FormulaBrowserView(isMultiFrame: false) { expression in
        print("Selected: \(expression)")
    }
}

