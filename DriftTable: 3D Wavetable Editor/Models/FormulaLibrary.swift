//
//  FormulaLibrary.swift
//  DriftTable
//
//  Formula library management and persistence
//

import Foundation
import Combine

// MARK: - Formula Entry

struct FormulaEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var expression: String
    var name: String
    var category: String
    var isFavorite: Bool
    var isUserCreated: Bool
    let dateCreated: Date
    var dateModified: Date
    
    init(expression: String, name: String, category: String, isFavorite: Bool = false, isUserCreated: Bool = false) {
        self.id = UUID()
        self.expression = expression
        self.name = name
        self.category = category
        self.isFavorite = isFavorite
        self.isUserCreated = isUserCreated
        self.dateCreated = Date()
        self.dateModified = Date()
    }
}

// MARK: - Formula Category

struct FormulaCategory: Identifiable, Equatable {
    let id: String
    let name: String
    let isMultiFrame: Bool
    
    var displayName: String {
        return name.replacingOccurrences(of: "[x]", with: "")
            .replacingOccurrences(of: "---", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Formula Library Manager

class FormulaLibraryManager: ObservableObject {
    @Published var singleFrameFormulas: [FormulaEntry] = []
    @Published var multiFrameFormulas: [FormulaEntry] = []
    @Published var userFormulas: [FormulaEntry] = []
    @Published var categories: [FormulaCategory] = []
    
    private let userFormulasKey = "userFormulas"
    private let favoritesKey = "favoriteFormulas"
    
    init() {
        loadBundledFormulas()
        loadUserFormulas()
    }
    
    // MARK: - Load Bundled Formulas
    
    func loadBundledFormulas() {
        // Load singles
        if let singlesURL = Bundle.main.url(forResource: "FormulaUserSingles", withExtension: "txt") {
            singleFrameFormulas = parseFormulaFile(url: singlesURL, isMultiFrame: false)
        }
        
        // Load multis
        if let multisURL = Bundle.main.url(forResource: "FormulaUserMultis", withExtension: "txt") {
            multiFrameFormulas = parseFormulaFile(url: multisURL, isMultiFrame: true)
        }
        
        // Extract categories
        extractCategories()
        
        // Load favorites
        loadFavorites()
    }
    
    private func parseFormulaFile(url: URL, isMultiFrame: Bool) -> [FormulaEntry] {
        var formulas: [FormulaEntry] = []
        var currentCategory = isMultiFrame ? "Multi-Frame" : "Single-Frame"
        
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return formulas
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }
            
            // Check if it's a category header
            if trimmed.hasPrefix("[x][") && trimmed.hasSuffix("]") {
                // Extract category name
                let categoryText = trimmed
                    .replacingOccurrences(of: "[x][", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .trimmingCharacters(in: .whitespaces)
                
                if !categoryText.isEmpty && categoryText != " " {
                    currentCategory = categoryText
                }
                continue
            }
            
            // Check if it's a formula entry
            if trimmed.hasPrefix("[") && trimmed.contains("][") {
                // Parse formula: [expression][name]
                let components = parseFormulaLine(trimmed)
                if let expression = components.expression, let name = components.name {
                    let formula = FormulaEntry(
                        expression: expression,
                        name: name,
                        category: currentCategory,
                        isUserCreated: false
                    )
                    formulas.append(formula)
                }
            }
        }
        
        return formulas
    }
    
    private func parseFormulaLine(_ line: String) -> (expression: String?, name: String?) {
        // Format: [expression][name]
        guard line.hasPrefix("[") else { return (nil, nil) }
        
        var expression: String?
        var name: String?
        
        // Find the first closing bracket
        if let firstClose = line.firstIndex(of: "]"),
           firstClose != line.startIndex {
            let expressionStart = line.index(after: line.startIndex)
            expression = String(line[expressionStart..<firstClose])
            
            // Find the second opening bracket
            if let secondOpen = line[line.index(after: firstClose)...].firstIndex(of: "["),
               let secondClose = line[line.index(after: secondOpen)...].firstIndex(of: "]") {
                let nameStart = line.index(after: secondOpen)
                name = String(line[nameStart..<secondClose])
            }
        }
        
        return (expression, name)
    }
    
    private func extractCategories() {
        var categorySet = Set<String>()
        
        for formula in singleFrameFormulas {
            categorySet.insert(formula.category)
        }
        
        for formula in multiFrameFormulas {
            categorySet.insert(formula.category)
        }
        
        for formula in userFormulas {
            categorySet.insert(formula.category)
        }
        
        categories = categorySet.sorted().map { categoryName in
            let isMulti = multiFrameFormulas.contains { $0.category == categoryName }
            return FormulaCategory(id: categoryName, name: categoryName, isMultiFrame: isMulti)
        }
    }
    
    // MARK: - User Formulas
    
    func loadUserFormulas() {
        if let data = UserDefaults.standard.data(forKey: userFormulasKey),
           let formulas = try? JSONDecoder().decode([FormulaEntry].self, from: data) {
            userFormulas = formulas
        }
    }
    
    func saveUserFormulas() {
        if let data = try? JSONEncoder().encode(userFormulas) {
            UserDefaults.standard.set(data, forKey: userFormulasKey)
        }
        extractCategories()
    }
    
    func addUserFormula(expression: String, name: String, category: String, isMultiFrame: Bool) {
        let formula = FormulaEntry(
            expression: expression,
            name: name,
            category: category,
            isUserCreated: true
        )
        userFormulas.append(formula)
        saveUserFormulas()
    }
    
    func updateUserFormula(id: UUID, expression: String, name: String, category: String) {
        if let index = userFormulas.firstIndex(where: { $0.id == id }) {
            userFormulas[index].expression = expression
            userFormulas[index].name = name
            userFormulas[index].category = category
            userFormulas[index].dateModified = Date()
            saveUserFormulas()
        }
    }
    
    func deleteUserFormula(id: UUID) {
        userFormulas.removeAll { $0.id == id }
        saveUserFormulas()
    }
    
    // MARK: - Favorites
    
    func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let favoriteIds = try? JSONDecoder().decode(Set<UUID>.self, from: data) {
            
            // Mark favorites in single frame formulas
            for index in singleFrameFormulas.indices {
                if favoriteIds.contains(singleFrameFormulas[index].id) {
                    singleFrameFormulas[index].isFavorite = true
                }
            }
            
            // Mark favorites in multi frame formulas
            for index in multiFrameFormulas.indices {
                if favoriteIds.contains(multiFrameFormulas[index].id) {
                    multiFrameFormulas[index].isFavorite = true
                }
            }
            
            // Mark favorites in user formulas
            for index in userFormulas.indices {
                if favoriteIds.contains(userFormulas[index].id) {
                    userFormulas[index].isFavorite = true
                }
            }
        }
    }
    
    func saveFavorites() {
        var favoriteIds = Set<UUID>()
        
        for formula in singleFrameFormulas where formula.isFavorite {
            favoriteIds.insert(formula.id)
        }
        for formula in multiFrameFormulas where formula.isFavorite {
            favoriteIds.insert(formula.id)
        }
        for formula in userFormulas where formula.isFavorite {
            favoriteIds.insert(formula.id)
        }
        
        if let data = try? JSONEncoder().encode(favoriteIds) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    func toggleFavorite(id: UUID) {
        // Check single frame
        if let index = singleFrameFormulas.firstIndex(where: { $0.id == id }) {
            singleFrameFormulas[index].isFavorite.toggle()
            saveFavorites()
            return
        }
        
        // Check multi frame
        if let index = multiFrameFormulas.firstIndex(where: { $0.id == id }) {
            multiFrameFormulas[index].isFavorite.toggle()
            saveFavorites()
            return
        }
        
        // Check user formulas
        if let index = userFormulas.firstIndex(where: { $0.id == id }) {
            userFormulas[index].isFavorite.toggle()
            saveUserFormulas()
            saveFavorites()
            return
        }
    }
    
    // MARK: - Query
    
    func allFormulas(isMultiFrame: Bool) -> [FormulaEntry] {
        let bundled = isMultiFrame ? multiFrameFormulas : singleFrameFormulas
        let user = userFormulas.filter { formula in
            let engine = FormulaEngine()
            if let compiled = try? engine.compile(formula.expression) {
                return engine.usesFrameVariables(compiled) == isMultiFrame
            }
            return false
        }
        return bundled + user
    }
    
    func formulas(in category: String, isMultiFrame: Bool) -> [FormulaEntry] {
        return allFormulas(isMultiFrame: isMultiFrame).filter { $0.category == category }
    }
    
    func favoriteFormulas(isMultiFrame: Bool) -> [FormulaEntry] {
        return allFormulas(isMultiFrame: isMultiFrame).filter { $0.isFavorite }
    }
    
    func searchFormulas(query: String, isMultiFrame: Bool) -> [FormulaEntry] {
        let lowercased = query.lowercased()
        return allFormulas(isMultiFrame: isMultiFrame).filter {
            $0.name.lowercased().contains(lowercased) ||
            $0.expression.lowercased().contains(lowercased) ||
            $0.category.lowercased().contains(lowercased)
        }
    }
}

