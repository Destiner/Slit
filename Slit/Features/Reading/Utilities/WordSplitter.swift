//
//  WordSplitter.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation

enum WordSplitter {
    static func split(_ text: String) -> [String] {
        // Split by whitespace (spaces, tabs, newlines) and filter empty strings
        return text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
    }
}
