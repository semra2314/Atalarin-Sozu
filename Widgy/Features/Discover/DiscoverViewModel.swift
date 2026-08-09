//
//  DiscoverViewModel.swift
//  Widgy
//

import Foundation
import Observation

@MainActor
@Observable
final class DiscoverViewModel {
    enum State {
        case idle
        case loading
        case loaded([CatalogSection])
        case failed(String)
    }

    private(set) var state: State = .idle
    private let repository: WidgetRepository

    init(repository: WidgetRepository) {
        self.repository = repository
    }

    func loadIfNeeded() async {
        if case .loaded = state { return }
        await load()
    }

    func load() async {
        state = .loading
        do {
            state = .loaded(try await repository.discoverSections())
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
