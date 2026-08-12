//
//  CloudKitCatalogSeeder.swift
//  Widgy
//
//  One-off developer utility: pushes `SampleCatalog` into the CloudKit PUBLIC
//  database so there is something to browse while the real creator-upload flow
//  is being built. Run it once, then delete the call.
//
//  Usage (e.g. from a temporary button, or a #if DEBUG task in the app):
//      try await CloudKitCatalogSeeder(containerIdentifier: "iCloud.com.yourteam.Widgy").seed()
//
//  Requires the iCloud/CloudKit capability and that you are signed into iCloud
//  on the device/simulator.
//

import Foundation
import CloudKit

nonisolated struct CloudKitCatalogSeeder {
    let containerIdentifier: String

    private var publicDB: CKDatabase {
        CKContainer(identifier: containerIdentifier).publicCloudDatabase
    }

    typealias Key = CloudKitWidgetRepository.Key
    typealias RecordType = CloudKitWidgetRepository.RecordType

    /// Uploads every sample template plus a couple of curated sections.
    func seed() async throws {
        var records: [CKRecord] = []

        for template in SampleCatalog.templates {
            let record = CKRecord(
                recordType: RecordType.template,
                recordID: CKRecord.ID(recordName: template.id)
            )
            let json = try CatalogCoder.encoder.encode(template)
            record[Key.payload] = String(decoding: json, as: UTF8.self) as CKRecordValue
            record[Key.name] = template.name as CKRecordValue
            record[Key.category] = template.category.rawValue as CKRecordValue
            record[Key.installCount] = template.installCount as CKRecordValue
            record[Key.searchText] = searchText(for: template) as CKRecordValue
            records.append(record)
        }

        records.append(contentsOf: sampleSections())

        try await save(records)
    }

    private func sampleSections() -> [CKRecord] {
        let sorted = SampleCatalog.templates.sorted { $0.installCount > $1.installCount }
        let featured = Array(sorted.prefix(3)).map(\.id)
        let trending = Array(sorted.prefix(8)).map(\.id)

        func section(_ id: String, _ title: String, _ subtitle: String?, _ style: String, _ ids: [String], _ order: Int) -> CKRecord {
            let record = CKRecord(recordType: RecordType.section, recordID: CKRecord.ID(recordName: id))
            record[Key.title] = title as CKRecordValue
            if let subtitle { record[Key.subtitle] = subtitle as CKRecordValue }
            record[Key.style] = style as CKRecordValue
            record[Key.templateIds] = ids as CKRecordValue
            record[Key.order] = order as CKRecordValue
            return record
        }

        return [
            section("sec-featured", "Featured today", "Hand-picked by the Kare team", "spotlight", featured, 0),
            section("sec-trending", "Trending", "Most installed this week", "carousel", trending, 1)
        ]
    }

    private func searchText(for template: WidgetTemplate) -> String {
        ([template.name, template.summary, template.author.displayName] + template.tags)
            .joined(separator: " ")
            .lowercased()
    }

    /// Saves records, overwriting any existing ones with the same id.
    private func save(_ records: [CKRecord]) async throws {
        let result = try await publicDB.modifyRecords(saving: records, deleting: [], savePolicy: .allKeys)
        for (_, saveResult) in result.saveResults {
            if case let .failure(error) = saveResult { throw error }
        }
    }
}
