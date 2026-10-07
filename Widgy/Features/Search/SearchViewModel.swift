//
//  SearchViewModel.swift
//  Kare
//

import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query: String = ""
    var selectedCategory: WidgetCategory?

    private(set) var results: [WidgetTemplate] = []
    private(set) var isSearching = false
    private(set) var errorMessage: String?

    private let repository: WidgetRepository
    private var searchTask: Task<Void, Never>?

    init(repository: WidgetRepository) {
        self.repository = repository
    }

    /// Debounced so typing doesn't fire a request per keystroke.
    func scheduleSearch() {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await performSearch()
        }
    }

    func performSearch() async {
        isSearching = true
        errorMessage = nil
        do {
            results = try await repository.search(query: query, category: selectedCategory)
            isSearching = false
        } catch is CancellationError {
            // The user typed another character and this search was superseded.
            // Not a failure — showing "CancellationError" here was why typing
            // anything with no match looked like a crash. Leave the results and
            // the spinner alone; the search that replaced this one owns them.
            return
        } catch {
            errorMessage = error.localizedDescription
            results = []
            isSearching = false
        }
    }

    func selectCategory(_ category: WidgetCategory?) {
        selectedCategory = (selectedCategory == category) ? nil : category
        scheduleSearch()
    }
}
