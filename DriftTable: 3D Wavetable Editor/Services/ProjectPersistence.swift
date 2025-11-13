//
//  ProjectPersistence.swift
//  DriftTable
//
//  Created by Mitchell Cohen on 11/12/25.
//

import Foundation

struct ProjectPersistence {
    static func save(project: WavetableProject, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(project)
        try data.write(to: url)
    }
    
    static func load(from url: URL) throws -> WavetableProject {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(WavetableProject.self, from: data)
    }
}
