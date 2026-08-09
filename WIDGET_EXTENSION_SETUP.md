# Home-screen widget: setup steps

The editor already lets you design and preview at Small / Medium / Large. To make
the widget actually appear on the iOS home screen, add a Widget Extension target
and an App Group. These two steps must be done in Xcode (they add a target and an
entitlement, which shouldn't be hand-edited). All the code is already written.

## 1. Add the Widget Extension target

- File > New > Target > **Widget Extension**. Name it **WidgyWidget**.
- Uncheck "Include Live Activity" and "Include Configuration App Intent" for v1.
- When asked to activate the scheme, say yes.
- Delete the boilerplate `WidgyWidget.swift` Xcode generates, and instead add the
  one at `WidgyWidget/WidgyWidget.swift` (already in the repo) to the extension target.

## 2. Create an App Group (both targets)

- Select the **Widgy** app target > Signing & Capabilities > + Capability > **App Groups**.
  Add a group, e.g. `group.com.yourteam.Widgy`.
- Select the **WidgyWidget** target > add the **same** App Group.
- Put that id into `SharedWidgetStore.appGroupID` (currently `group.com.yourteam.Widgy`).

## 3. Share the rendering code with the extension

The widget draws with the same views as the editor, so add these files to the
**WidgyWidget** target membership (File inspector > Target Membership, tick WidgyWidget):

- `Core/Store/SharedWidgetStore.swift`
- `Core/Models/WidgetContent.swift`
- `Core/Models/WidgetSize.swift`
- `DesignSystem/Components/CustomWidgetView.swift`
- `DesignSystem/Color+Hex.swift`
- `DesignSystem/AppFont.swift`
- `DesignSystem/Theme.swift`
- The Fraunces `.ttf` files in `Resources/Fonts/` (so the widget uses the real font).

Keep them in the app target too — just add the extension as a second membership.

## 4. Run

- Build and run the app, open a widget in the editor, tweak it, tap **Save**.
  That writes the payload to the App Group and reloads the widget timeline.
- Long-press the home screen > + > search "Widgy" > add it, pick Small/Medium/Large.
  It renders exactly what you designed.

## How it works

- On Save, `SharedWidgetStore.save(...)` writes the `WidgetContent` + family to a
  JSON file in the App Group container, then calls
  `WidgetCenter.shared.reloadTimelines(ofKind: "WidgyWidget")`.
- `WidgyProvider` reads that payload; `WidgyWidgetEntryView` renders it with the
  shared `CustomWidgetView`, mapping WidgetKit's `systemSmall/Medium/Large` to our
  `WidgetSize`. Same colours and fonts as the in-app preview.

## v2 ideas
- Use `AppIntentConfiguration` so the user can pick *which* saved widget per
  placed instance (right now the extension shows the most recently saved one).
- Store each library widget separately in the App Group, keyed by id.
