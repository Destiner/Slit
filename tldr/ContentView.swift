//
//  ContentView.swift
//  tldr
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI

struct ContentView: View {
    private let article = ArticleStore.shared.articles[0]

    var body: some View {
        NavigationStack {
            ReadingView(text: article.content)
        }
    }
}

#Preview {
    ContentView()
}
