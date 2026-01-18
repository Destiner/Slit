//
//  Article.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import Foundation

struct Article: Identifiable {
    let id: UUID
    let title: String
    let content: String

    init(id: UUID = UUID(), title: String, content: String) {
        self.id = id
        self.title = title
        self.content = content
    }
}
