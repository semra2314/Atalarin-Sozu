//
//  WidgyTests.swift
//  WidgyTests
//
//  Created by Z. Erden Dereli on 20.07.2026.
//

import Testing
import Foundation
@testable import Widgy

@Suite("Catalog repository")
struct CatalogRepositoryTests {

    private func makeRepository() -> MockWidgetRepository {
        MockWidgetRepository(artificialDelay: .zero)
    }

    @Test("Discover returns only non-empty sections")
    func discoverSectionsAreNonEmpty() async throws {
        let sections = try await makeRepository().discoverSections()
        #expect(!sections.isEmpty)
        #expect(sections.allSatisfy { !$0.templates.isEmpty })
    }

    @Test("Fetching a known template succeeds")
    func fetchKnownTemplate() async throws {
        let template = try await makeRepository().template(id: "t-aurora")
        #expect(template.name == "Aurora Clock")
    }

    @Test("Fetching an unknown template throws notFound")
    func fetchUnknownTemplate() async throws {
        await #expect(throws: RepositoryError.self) {
            _ = try await makeRepository().template(id: "does-not-exist")
        }
    }

    @Test("Empty query returns the whole catalog")
    func emptyQueryReturnsAll() async throws {
        let results = try await makeRepository().search(query: "", category: nil)
        #expect(results.count == SampleCatalog.templates.count)
    }

    @Test("Search matches name, tag and author")
    func searchMatchesFields() async throws {
        let repository = makeRepository()
        #expect(try await repository.search(query: "aurora", category: nil).count == 1)
        #expect(try await !repository.search(query: "gradient", category: nil).isEmpty)
        #expect(try await !repository.search(query: "Nova", category: nil).isEmpty)
    }

    @Test("Category filter narrows results", arguments: WidgetCategory.allCases)
    func categoryFilter(category: WidgetCategory) async throws {
        let results = try await makeRepository().templates(in: category)
        #expect(results.allSatisfy { $0.category == category })
    }
}

@Suite("Model formatting")
struct ModelFormattingTests {

    @Test("Install counts abbreviate correctly")
    func installCountText() {
        var template = SampleCatalog.templates[0]
        template.installCount = 950
        #expect(template.installCountText == "950")
        template.installCount = 12_400
        #expect(template.installCountText == "12.4K")
        template.installCount = 2_300_000
        #expect(template.installCountText == "2.3M")
    }

    @Test("Free price reports as free")
    func freePrice() {
        #expect(WidgetTemplate.Price.free.isFree)
        #expect(!WidgetTemplate.Price.paid(amount: 1.99, currencyCode: "USD").isFree)
    }

    @Test("Theme survives a JSON round trip")
    func themeRoundTrip() throws {
        let original = SampleCatalog.templates[0].theme
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(WidgetTheme.self, from: data)
        #expect(decoded == original)
    }

    @Test("Every template supports at least one size")
    func templatesHaveSizes() {
        #expect(SampleCatalog.templates.allSatisfy { !$0.supportedSizes.isEmpty })
    }
}
