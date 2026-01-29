//
//  SlitApp.swift
//  Slit
//
//  Created by Timur Badretdinov on 18/01/2026.
//

import SwiftUI
import SwiftData

@main
struct SlitApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Article.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    importPendingURLs()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                importPendingURLs()
            }
        }
    }

    @MainActor
    private func importPendingURLs() {
        let pendingURLs = SharedURLManager.getPendingURLs()
        guard !pendingURLs.isEmpty else { return }

        let context = sharedModelContainer.mainContext

        for url in pendingURLs {
            let article = Article(url: url, title: "Loading...")
            context.insert(article)
            SharedURLManager.removePendingURL(url)

            Task {
                await ArticleImporter.importContent(for: article, context: context)
            }
        }
    }
}
