//
//  CloudKitWidgetRepository.swift
//  Kare
//
//  Production catalog backed by CloudKit's PUBLIC database (Apple-native, free,
//  iCloud auth for creators). The iOS marketplace is its own catalog, separate
//  from Android, so an Apple-only store is the natural fit.
//
//  To activate:
//    1. Target > Signing & Capabilities > add "iCloud" > check CloudKit,
//       create/select a container (e.g. iCloud.com.yourteam.Widgy).
//    2. Put that container id in `AppEnvironment.cloudKit(...)`.
//    3. Run `CloudKitCatalogSeeder` once (see that file) to populate the public
//       database with the sample catalog, or add records in the CloudKit dashboard.
//    4. In `AppEnvironment.live`, return `.cloudKit(...)` instead of the mock.
//
//  The whole `WidgetTemplate` is stored as JSON text in the `payload` field, so
//  nested types (Author, theme, price) round-trip without per-field mapping.
//  A few flat fields (name, category, installCount) are kept for querying/sorting.
//

import Foundation
import CloudKit

nonisolated struct CloudKitWidgetRepository: WidgetRepository {
    let containerIdentifier: String

    init(containerIdentifier: String) {
        self.containerIdentifier = containerIdentifier
    }

    private var publicDB: CKDatabase {
        CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    // MARK: Record schema

    enum RecordType {
        static let template = "WidgetTemplate"
        static let section = "CatalogSection"
        static let review = "Review"
    }

    enum Key {
        static let payload = "payload"           // JSON text of the model
        static let name = "name"
        static let category = "category"
        static let installCount = "installCount"
        static let searchText = "searchText"
        // section-only
        static let title = "title"
        static let subtitle = "subtitle"
        static let style = "style"
        static let templateIds = "templateIds"
        static let order = "order"
        // review-only
        static let templateID = "templateID"
        static let authorName = "authorName"
        static let stars = "stars"
        static let text = "text"
        static let createdAt = "createdAt"
    }

    // MARK: WidgetRepository

    func discoverSections() async throws -> [CatalogSection] {
        let templates = try await fetchAllTemplates()
        let byID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })

        let sectionRecords = (try? await fetchAll(RecordType.section)) ?? []

        // If the backend has curated sections, use them. Otherwise fall back to
        // a sensible default curation built from the templates themselves.
        if !sectionRecords.isEmpty {
            let sections = sectionRecords
                .sorted { ($0[Key.order] as? Int ?? 0) < ($1[Key.order] as? Int ?? 0) }
                .compactMap { record -> CatalogSection? in
                    guard let title = record[Key.title] as? String,
                          let styleRaw = record[Key.style] as? String else { return nil }
                    let ids = record[Key.templateIds] as? [String] ?? []
                    let items = ids.compactMap { byID[$0] }
                    guard !items.isEmpty else { return nil }
                    return CatalogSection(
                        id: record.recordID.recordName,
                        title: title,
                        subtitle: record[Key.subtitle] as? String,
                        style: style(from: styleRaw),
                        templates: items
                    )
                }
            if !sections.isEmpty { return sections }
        }

        return defaultSections(from: templates)
    }

    func template(id: String) async throws -> WidgetTemplate {
        do {
            let record = try await publicDB.record(for: CKRecord.ID(recordName: id))
            return try decodeTemplate(record)
        } catch let error as CKError where error.code == .unknownItem {
            throw RepositoryError.notFound
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
    }

    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate] {
        let templates = try await fetchAllTemplates()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return templates.filter { template in
            let matchesCategory = category == nil || template.category == category
            guard matchesCategory else { return false }
            guard !trimmed.isEmpty else { return true }
            return template.name.lowercased().contains(trimmed)
                || template.summary.lowercased().contains(trimmed)
                || template.tags.contains { $0.lowercased().contains(trimmed) }
                || template.author.displayName.lowercased().contains(trimmed)
        }
    }

    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate] {
        let templates = try await fetchAllTemplates()
        return templates.filter { $0.category == category }
    }

    func reviews(for templateID: String) async throws -> [Review] {
        let predicate = NSPredicate(format: "%K == %@", Key.templateID, templateID)
        let query = CKQuery(recordType: RecordType.review, predicate: predicate)
        let records: [CKRecord]
        do {
            let response = try await publicDB.records(matching: query)
            records = response.matchResults.compactMap { try? $0.1.get() }
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
        return records
            .compactMap(decodeReview)
            .sorted { $0.createdAt > $1.createdAt }
    }

    func submitReview(_ review: Review) async throws {
        let record = CKRecord(recordType: RecordType.review,
                              recordID: CKRecord.ID(recordName: review.id))
        record[Key.templateID] = review.templateID as CKRecordValue
        record[Key.authorName] = review.authorName as CKRecordValue
        record[Key.stars] = review.stars as CKRecordValue
        record[Key.text] = review.text as CKRecordValue
        record[Key.createdAt] = review.createdAt as CKRecordValue
        do {
            _ = try await publicDB.modifyRecords(saving: [record], deleting: [], savePolicy: .allKeys)
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
    }

    private func decodeReview(_ record: CKRecord) -> Review? {
        guard let templateID = record[Key.templateID] as? String,
              let author = record[Key.authorName] as? String,
              let stars = record[Key.stars] as? Int,
              let text = record[Key.text] as? String else { return nil }
        let created = record[Key.createdAt] as? Date ?? .now
        return Review(id: record.recordID.recordName, templateID: templateID,
                      authorName: author, stars: stars, text: text, createdAt: created)
    }

    // MARK: Fetch helpers

    private func fetchAllTemplates() async throws -> [WidgetTemplate] {
        let records = try await fetchAll(RecordType.template)
        return records.compactMap { try? decodeTemplate($0) }
    }

    private func fetchAll(_ recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        var records: [CKRecord] = []
        do {
            var response = try await publicDB.records(matching: query)
            records += response.matchResults.compactMap { try? $0.1.get() }
            while let cursor = response.queryCursor {
                response = try await publicDB.records(continuingMatchFrom: cursor)
                records += response.matchResults.compactMap { try? $0.1.get() }
            }
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
        return records
    }

    // MARK: Mapping

    private func decodeTemplate(_ record: CKRecord) throws -> WidgetTemplate {
        guard let json = record[Key.payload] as? String,
              let data = json.data(using: .utf8) else {
            throw RepositoryError.notFound
        }
        do {
            return try CatalogCoder.decoder.decode(WidgetTemplate.self, from: data)
        } catch {
            throw RepositoryError.transport(underlying: error)
        }
    }

    private func style(from raw: String) -> CatalogSection.Style {
        switch raw {
        case "spotlight": .spotlight
        case "compactList": .compactList
        default: .carousel
        }
    }

    // MARK: Default curation (used until curated sections exist)

    private func defaultSections(from templates: [WidgetTemplate]) -> [CatalogSection] {
        let sorted = templates.sorted { $0.installCount > $1.installCount }
        return [
            CatalogSection(id: "spotlight", title: "Featured today",
                           subtitle: "Hand-picked by the Kare team",
                           style: .spotlight, templates: Array(sorted.prefix(3))),
            CatalogSection(id: "trending", title: "All widgets",
                           subtitle: "Everything that ships with Kare",
                           style: .carousel, templates: Array(sorted.prefix(8))),
            CatalogSection(id: "minimal", title: "Quietly minimal", subtitle: nil,
                           style: .carousel, templates: templates.filter { $0.category == .minimal }),
            CatalogSection(id: "free", title: "Great and free", subtitle: nil,
                           style: .compactList, templates: templates.filter { $0.price.isFree })
        ].filter { !$0.templates.isEmpty }
    }
}

/// Shared JSON coders so encode (seeder) and decode (repository) always agree.
nonisolated enum CatalogCoder {
    static var encoder: JSONEncoder { JSONEncoder() }
    static var decoder: JSONDecoder { JSONDecoder() }
}
