//
//  URLNormalizer.swift
//  Slit
//
//  Created by Timur Badretdinov on 29/01/2026.
//

import Foundation

enum URLNormalizer {
    static func normalize(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return url.absoluteString
        }

        // Lowercase the scheme and host
        if let scheme = components.scheme {
            components.scheme = scheme.lowercased()
        }
        if let host = components.host {
            components.host = host.lowercased()
        }

        // Remove trailing slash from path
        if components.path.hasSuffix("/"), components.path != "/" {
            components.path.removeLast()
        }

        // Remove default ports
        if let scheme = components.scheme, let port = components.port {
            if (scheme == "http" && port == 80) || (scheme == "https" && port == 443) {
                components.port = nil
            }
        }

        // Remove fragment
        components.fragment = nil

        return components.string ?? url.absoluteString
    }

    static func normalize(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        return normalize(url)
    }
}
