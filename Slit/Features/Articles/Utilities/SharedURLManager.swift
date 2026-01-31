//
//  SharedURLManager.swift
//  Slit
//
//  Created by Timur Badretdinov on 29/01/2026.
//

import Foundation

enum SharedURLManager {
    static let appGroupIdentifier = "group.DestinerLabs.Slit"
    private static let pendingURLsKey = "pendingSharedURLs"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    static func addPendingURL(_ url: URL) {
        guard let defaults = sharedDefaults else { return }
        var urls = getPendingURLs()
        urls.append(url)
        let urlStrings = urls.map { $0.absoluteString }
        defaults.set(urlStrings, forKey: pendingURLsKey)
    }

    static func getPendingURLs() -> [URL] {
        guard let defaults = sharedDefaults,
              let urlStrings = defaults.stringArray(forKey: pendingURLsKey)
        else {
            return []
        }
        return urlStrings.compactMap { URL(string: $0) }
    }

    static func clearPendingURLs() {
        sharedDefaults?.removeObject(forKey: pendingURLsKey)
    }

    static func removePendingURL(_ url: URL) {
        guard let defaults = sharedDefaults else { return }
        var urls = getPendingURLs()
        urls.removeAll { $0 == url }
        let urlStrings = urls.map { $0.absoluteString }
        defaults.set(urlStrings, forKey: pendingURLsKey)
    }
}
