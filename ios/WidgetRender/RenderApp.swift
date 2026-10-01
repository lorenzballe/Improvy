import SwiftUI
import WidgetKit

// Draws the REAL widget views — ImprovyKit.swift and ImprovyWidgets.swift,
// compiled unchanged apart from the three patches in render.sh — with the
// payload the app really writes (test/widget_payload_test.dart), at the
// point sizes iOS gives each family, and saves them as PNGs.
//
// Not shipped: built only by .github/workflows/widgets.yml on a Mac.

/// iPhone 15/16 Pro sizes, in points.
enum Size {
    static let small = CGSize(width: 158, height: 158)
    static let medium = CGSize(width: 338, height: 158)
    static let large = CGSize(width: 338, height: 354)
}

struct Item {
    let name: String
    let size: CGSize
    let view: AnyView
}

@MainActor
enum Render {
    static func seed(_ state: String) {
        let d = UserDefaults(suiteName: Improvy.appGroupId)!
        for key in d.dictionaryRepresentation().keys { d.removeObject(forKey: key) }
        guard
            let url = Bundle.main.url(forResource: state, withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let map = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { fatalError("payload \(state) missing") }
        for (k, v) in map {
            if let n = v as? NSNumber {
                if CFGetTypeID(n) == CFBooleanGetTypeID() { d.set(n.boolValue, forKey: k) }
                else { d.set(n.intValue, forKey: k) }
            } else if let s = v as? String {
                d.set(s, forKey: k)
            }
        }
    }

    static func items() -> [Item] {
        let quiz = QuizProvider().entry(for: Date())
        return [
            Item(name: "01_question", size: Size.small, view: AnyView(QuizView(entry: quiz))),
            Item(name: "02_daily", size: Size.small, view: AnyView(DailyView(family: .systemSmall))),
            Item(name: "03_level", size: Size.small, view: AnyView(LevelView())),
            Item(name: "04_streak", size: Size.small, view: AnyView(StreakView())),
            Item(name: "05_weakest", size: Size.small, view: AnyView(WeakestView())),
            Item(name: "06_pocket", size: Size.small, view: AnyView(PocketView())),
            Item(name: "07_question_wide", size: Size.medium, view: AnyView(QuizView(entry: quiz, wide: true))),
            Item(name: "08_daily_wide", size: Size.medium, view: AnyView(DailyView(family: .systemMedium))),
            Item(name: "09_streak_wide", size: Size.medium, view: AnyView(StreakView(wide: true))),
            Item(name: "10_map", size: Size.medium, view: AnyView(MapView())),
            Item(name: "11_launcher", size: Size.medium, view: AnyView(LauncherView())),
            Item(name: "12_theory", size: Size.medium, view: AnyView(TheoryView())),
            Item(name: "13_map_large", size: Size.large, view: AnyView(MapView(tall: true))),
        ]
    }

    /// One widget as it sits on the home screen: the family's size, the
    /// system's continuous corner.
    static func card(_ item: Item) -> some View {
        item.view
            .frame(width: item.size.width, height: item.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .environment(\.colorScheme, .dark)
    }

    static func save<V: View>(_ view: V, _ path: URL, scale: CGFloat = 3) {
        let r = ImageRenderer(content: view)
        r.scale = scale
        guard let img = r.uiImage, let png = img.pngData() else {
            print("RENDER FAILED \(path.lastPathComponent)")
            return
        }
        try? png.write(to: path)
        print("wrote \(path.lastPathComponent) \(Int(img.size.width))x\(Int(img.size.height))")
    }

    /// The twelve on one page over a home-screen-like wallpaper, laid out as
    /// iOS would: smalls in pairs, mediums full width.
    static func sheet(_ items: [Item]) -> some View {
        let smalls = items.filter { $0.size == Size.small }
        let others = items.filter { $0.size != Size.small }
        return VStack(alignment: .leading, spacing: 22) {
            ForEach(Array(stride(from: 0, to: smalls.count, by: 2)), id: \.self) { i in
                HStack(spacing: 22) {
                    card(smalls[i])
                    if i + 1 < smalls.count { card(smalls[i + 1]) }
                }
            }
            ForEach(others.indices, id: \.self) { i in card(others[i]) }
        }
        .padding(28)
        .background(
            LinearGradient(
                colors: [Color(red: 0.20, green: 0.22, blue: 0.42),
                         Color(red: 0.45, green: 0.30, blue: 0.55),
                         Color(red: 0.85, green: 0.55, blue: 0.50)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    static func all() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for state in ["played", "unplayed"] {
            seed(state)
            let dir = docs.appendingPathComponent(state)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let list = items()
            for item in list {
                save(card(item), dir.appendingPathComponent("\(item.name).png"))
            }
            save(sheet(list), docs.appendingPathComponent("sheet_\(state).png"), scale: 2)
        }
        print("RENDER DONE")
    }
}

@main
struct RenderApp: App {
    init() {
        DispatchQueue.main.async {
            Render.all()
            exit(0)
        }
    }

    var body: some Scene {
        WindowGroup { Color.black }
    }
}
