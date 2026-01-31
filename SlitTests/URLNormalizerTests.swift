//
//  URLNormalizerTests.swift
//  SlitTests
//
//  Created by Timur Badretdinov on 29/01/2026.
//

@testable import Slit
import Testing

struct URLNormalizerTests {
    @Test func removesTrailingSlash() {
        let result = URLNormalizer.normalize("https://example.com/article/")
        #expect(result == "https://example.com/article")
    }

    @Test func preservesRootSlash() {
        let result = URLNormalizer.normalize("https://example.com/")
        #expect(result == "https://example.com/")
    }

    @Test func lowercasesHost() {
        let result = URLNormalizer.normalize("https://EXAMPLE.COM/article")
        #expect(result == "https://example.com/article")
    }

    @Test func lowercasesScheme() {
        let result = URLNormalizer.normalize("HTTPS://example.com/article")
        #expect(result == "https://example.com/article")
    }

    @Test func removesDefaultHttpPort() {
        let result = URLNormalizer.normalize("http://example.com:80/article")
        #expect(result == "http://example.com/article")
    }

    @Test func removesDefaultHttpsPort() {
        let result = URLNormalizer.normalize("https://example.com:443/article")
        #expect(result == "https://example.com/article")
    }

    @Test func preservesNonDefaultPort() {
        let result = URLNormalizer.normalize("https://example.com:8080/article")
        #expect(result == "https://example.com:8080/article")
    }

    @Test func removesFragment() {
        let result = URLNormalizer.normalize("https://example.com/article#section")
        #expect(result == "https://example.com/article")
    }

    @Test func preservesQueryParameters() {
        let result = URLNormalizer.normalize("https://example.com/article?id=123")
        #expect(result == "https://example.com/article?id=123")
    }

    @Test func preservesPath() {
        let result = URLNormalizer.normalize("https://example.com/path/to/article")
        #expect(result == "https://example.com/path/to/article")
    }

    @Test func matchesDuplicatesWithTrailingSlash() {
        let url1 = URLNormalizer.normalize("https://example.com/article")
        let url2 = URLNormalizer.normalize("https://example.com/article/")
        #expect(url1 == url2)
    }

    @Test func matchesDuplicatesWithDifferentCase() {
        let url1 = URLNormalizer.normalize("https://example.com/article")
        let url2 = URLNormalizer.normalize("https://EXAMPLE.COM/article")
        #expect(url1 == url2)
    }

    @Test func matchesDuplicatesWithFragment() {
        let url1 = URLNormalizer.normalize("https://example.com/article")
        let url2 = URLNormalizer.normalize("https://example.com/article#comments")
        #expect(url1 == url2)
    }

    @Test func returnsNilForInvalidUrl() {
        let result = URLNormalizer.normalize("")
        #expect(result == nil)
    }
}
