#!/usr/bin/env python3
"""Export the pinned iOS catalog and wire fixtures using its actual Swift Codable models.

Requires macOS/Xcode Swift and a local IOS checkout. It never fetches or changes Git.
Generated files are committed inputs; Android builds do not need Swift or this script.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import uuid

REVISION = "41a8fbc67d2992f144383ede02c2ecfd6a73a1a1"
ANCHOR = "2026-10-08T00:00:00Z"
EPOCH_SECONDS = 1791417600


def export(checkout: Path, output: Path):
    revision = subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True).strip()
    if revision != REVISION:
        raise SystemExit(f"Expected iOS {REVISION}, found {revision}. Review source before changing the pin.")
    sources = {}

    def read(relative):
        data = (checkout / relative).read_bytes()
        sources[relative] = hashlib.sha256(data).hexdigest()
        return data.decode()

    parts = []
    for name in ["Author", "WidgetCategory", "WidgetSize", "Review", "WidgetTemplate", "CatalogSection", "WidgetTheme", "WidgetContent"]:
        source = read(f"Widgy/Core/Models/{name}.swift")
        if name == "WidgetTheme":
            # Drop only computed SwiftUI rendering helpers, not fields/initializers/Codable.
            source = source.split("    var backgroundColors:")[0] + "}\n"
        if name == "WidgetContent":
            source = source.split("// MARK: - SwiftUI helpers")[0]
        parts.append(source)
    catalog = read("Widgy/Core/Models/SampleCatalog.swift")
    # Source dates are launch-relative metadata, not known publication dates.
    parts.append(catalog.replace(".now", f"Date(timeIntervalSince1970: {EPOCH_SECONDS})"))
    parts.append(read("Widgy/Core/Repositories/WidgetRepository.swift"))
    parts.append(read("Widgy/Core/Repositories/MockWidgetRepository.swift"))
    read("Widgy/Core/Repositories/FirebaseWidgetRepository.swift")
    subscription = read("Widgy/Core/Store/SubscriptionStore.swift")
    if "static let subscriptionsAreLive = true" not in subscription:
        raise SystemExit("The source purchase launch policy changed; review section behavior.")
    parts.append("enum SubscriptionStore { static let subscriptionsAreLive = true }")
    parts.append(r'''
struct SectionExport: Encodable {
    let id: String
    let title: String
    let subtitle: String?
    let style: String
    let templateIds: [String]
    init(_ section: CatalogSection) {
        id = section.id; title = section.title; subtitle = section.subtitle
        templateIds = section.templates.map(\.id)
        switch section.style {
        case .spotlight: style = "spotlight"
        case .carousel: style = "carousel"
        case .compactList: style = "compactList"
        }
    }
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
func json<T: Encodable>(_ value: T) throws -> Any {
    try JSONSerialization.jsonObject(with: encoder.encode(value), options: [.fragmentsAllowed])
}
let bytes = Data([0, 1, 254, 255])
let identity = UUID(uuidString: "12345678-1234-5678-9ABC-123456789ABC")!
let photoContent = WidgetContent(
    text: "legacy", fontStyle: .rounded, fontSize: 29, textColorHex: "12345678",
    alignment: .trailing, background: .photo(bytes),
    stickers: [.init(id: identity, symbolName: "heart.fill", emoji: "❤️", imageData: bytes,
                     x: 0.1, y: 0.9, scale: 1.8, colorHex: "ABCDEF", rotation: -30, opacity: 0.6)],
    photos: [.init(id: identity, imageData: bytes, x: 0.2, y: 0.8, scale: 0.6,
                  rotation: 45, cornerRadius: 17, opacity: 0.7)],
    texts: [.init(id: identity, text: "A\nB", fontStyle: .monospaced, fontWeight: .heavy,
                 fontSize: 31, colorHex: "FEDCBA", alignment: .leading, lineSpacing: 2,
                 x: 0.3, y: 0.7, rotation: 20, widthFraction: 0.65, hasBackground: true,
                 backgroundHex: "112233", backgroundOpacity: 0.4,
                 backgroundCornerRadius: 7, backgroundPadding: 6)],
    verticalAlign: .bottom, fontWeight: .semibold, gradientDirection: .topTrailing,
    textScrim: true, lineSpacing: 3)
let fixtureAuthor = Author(id: "fixture-author", displayName: "Fixture", handle: "@fixture",
                           avatarURL: URL(string: "https://example.com/avatar.jpg"), isVerified: true)
let fixtureReview = Review(id: "fixture-review", templateID: "t-focus", authorName: "Fixture",
                           authorID: "fixture-uid", stars: 4, text: "Useful",
                           createdAt: Date(timeIntervalSinceReferenceDate: -0.25))
let sections = try await MockWidgetRepository(artificialDelay: .zero).discoverSections()
let result: [String: Any] = [
    "templates": try json(SampleCatalog.templates),
    "sections": try json(sections.map(SectionExport.init)),
    "setupTemplateIds": SampleCatalog.setupTemplateIDs.sorted(),
    "liveKarePlusIds": SampleCatalog.liveKarePlusIDs,
    "fixtures": [
        "content": try json(photoContent),
        "theme": try json(WidgetTheme(backgroundHexes: ["010203", "040506"], foregroundHex: "111111",
                                      accentHex: "222222", cornerRadius: 19, usesGlassEffect: true)),
        "author": try json(fixtureAuthor),
        "review": try json(fixtureReview),
        "freePrice": try json(WidgetTemplate.Price.free),
        "paidPrice": try json(WidgetTemplate.Price.paid(amount: Decimal(199) / 100, currencyCode: "USD"))
    ]
]
let data = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys, .prettyPrinted])
print(String(decoding: data, as: UTF8.self))
''')
    with tempfile.TemporaryDirectory(prefix="kare-catalog-export-") as work:
        script = Path(work) / "export.swift"
        script.write_text("\n".join(parts))
        result = subprocess.check_output(["swift", "-module-cache-path", str(Path(work) / "cache"), str(script)], text=True)
    data = json.loads(result)
    fixtures = data.pop("fixtures")
    # Swift creates fresh UUIDs on each process launch. Freeze only those generated
    # element IDs, using deterministic valid UUIDs; retain every other payload value.
    for template in data["templates"]:
        content = template.get("content")
        if content:
            for kind in ["texts", "photos", "stickers"]:
                for index, element in enumerate(content[kind]):
                    element["id"] = str(uuid.uuid5(uuid.NAMESPACE_URL, f"kare:{template['id']}:{kind}:{index}")).upper()
    data.update(schemaVersion=1, sourceRevision=REVISION, publicationAnchor=ANCHOR,
                subscriptionsAreLive=True)
    files = {
        "app/src/main/resources/catalog/kare-catalog-v1.json": data,
        "app/src/test/resources/catalog/ios-wire-fixtures.json": fixtures,
        "app/src/test/resources/catalog/ios-source-manifest.json": {
            "sourceRevision": REVISION, "publicationAnchor": ANCHOR, "sha256": sources,
            "orderedTemplateIds": [t["id"] for t in data["templates"]],
        },
    }
    for name, value in files.items():
        path = output / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
        print(name)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ios_checkout", type=Path)
    parser.add_argument("--output-root", type=Path, default=Path(__file__).resolve().parents[1])
    args = parser.parse_args()
    export(args.ios_checkout.resolve(), args.output_root.resolve())
