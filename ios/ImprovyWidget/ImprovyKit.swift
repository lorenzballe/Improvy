import SwiftUI
import WidgetKit
import Foundation

// MARK: - Shared data
//
// These widgets only ever *render*. Every string arrives already formatted from
// `lib/services/widget_service.dart`, which owns notation (C-D-E vs Do-Re-Mi),
// accidental spelling and wording — re-deriving any of it here would let the
// widget and the app drift apart.
//
// The payload crosses over through the App Group shared with the app
// (home_widget writes into `UserDefaults(suiteName:)`). The group ID must match
// `WidgetService.iOSAppGroupId` in Dart and the App Groups capability on BOTH
// targets — without it the widgets build fine and show placeholders forever.

enum Improvy {
    static let appGroupId = "group.com.improvy.app.widget"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

    static func string(_ key: String, _ fallback: String = "") -> String {
        let v = defaults?.string(forKey: key) ?? ""
        return v.isEmpty ? fallback : v
    }

    static func int(_ key: String, _ fallback: Int = 0) -> Int {
        guard let d = defaults, d.object(forKey: key) != nil else { return fallback }
        return d.integer(forKey: key)
    }

    static func bool(_ key: String) -> Bool { defaults?.bool(forKey: key) ?? false }

    /// The widgets' own labels, in the device's language, written by the app
    /// (`WidgetService._labels`). Falling back to the English literal means a
    /// widget is never blank because a string is missing — it is only ever
    /// less translated than it could be.
    static let labels: [String: String] = {
        guard
            let data = string("labels_json").data(using: .utf8),
            let map = (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
        else { return [:] }
        return map
    }()

    static func label(_ name: String, _ fallback: String) -> String {
        let v = labels[name] ?? ""
        return v.isEmpty ? fallback : v
    }

    /// The last seven days, oldest first, ending today: was the daily played.
    /// An empty or malformed payload reads as a quiet week rather than as a
    /// week of failures.
    static var week: [Bool] {
        guard
            let data = string("week_json").data(using: .utf8),
            let list = (try? JSONSerialization.jsonObject(with: data)) as? [Bool],
            list.count == 7
        else { return Array(repeating: false, count: 7) }
        return list
    }

    /// A `#rrggbb` the app wrote, or [fallback] if it is missing or malformed.
    static func colour(_ key: String, _ fallback: Color) -> Color {
        Color(hex: defaults?.string(forKey: key) ?? "") ?? fallback
    }

    /// Days since 1970-01-01 for a local calendar date.
    ///
    /// Built as a **UTC** instant from the local Y/M/D on purpose: using local
    /// midnight would land on the previous day east of Greenwich. Dart
    /// (`DateTime.utc(y, m, d)`) and Kotlin do the identical construction —
    /// they must agree, or the widget reads the wrong hour of the rotation.
    static func localEpochDay(_ date: Date) -> Int {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let c = local.dateComponents([.year, .month, .day], from: date)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var parts = DateComponents()
        parts.year = c.year
        parts.month = c.month
        parts.day = c.day
        guard let midnight = utc.date(from: parts) else { return 0 }
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }

    /// Absolute hour slot — hours since the epoch, in local calendar terms.
    static func slot(for date: Date) -> Int {
        localEpochDay(date) * 24 + Calendar.current.component(.hour, from: date)
    }

    /// The next N hours, on the hour — the shape almost every timeline here
    /// wants. Starting at *this* hour rather than now keeps a widget added at
    /// 10:59 from sitting on a stale question for one minute.
    static func hourlyDates(_ count: Int, from now: Date = Date()) -> [Date] {
        let cal = Calendar.current
        let top = cal.date(bySetting: .minute, value: 0, of: now).map {
            $0 > now ? cal.date(byAdding: .hour, value: -1, to: $0)! : $0
        } ?? now
        return (0..<count).compactMap { cal.date(byAdding: .hour, value: $0, to: top) }
    }
}

extension Color {
    /// `#rrggbb`, the format `WidgetService._keyHex` writes.
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else { return nil }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

// MARK: - Design tokens
//
// Lifted from the app's own surfaces so a widget looks like a piece of Improvy
// sitting on the home screen, not like a notification from it.

enum Ink {
    static let top = Color(red: 0.106, green: 0.078, blue: 0.157)     // #1B1428
    static let bottom = Color(red: 0.055, green: 0.039, blue: 0.094)  // #0E0A18
    static let gold = Color(red: 0.988, green: 0.827, blue: 0.302)    // #FCD34D
    static let indigo = Color(red: 0.388, green: 0.400, blue: 0.945)  // #6366F1
    static let violet = Color(red: 0.659, green: 0.333, blue: 0.969)  // #A855F7
    static let mint = Color(red: 0.204, green: 0.827, blue: 0.600)    // #34D399
    static let cyan = Color(red: 0.133, green: 0.827, blue: 0.933)    // #22D3EE
    static let ember = Color(red: 0.984, green: 0.573, blue: 0.235)   // #FB923C
    static let rose = Color(red: 0.957, green: 0.247, blue: 0.369)    // #F43F5E
}

/// The surface every widget sits on: a soft vertical ink gradient with a glow
/// in the widget's own accent bleeding in from the top-left corner, and a
/// hairline edge. The glow is what stops twelve dark rectangles from reading as
/// one undifferentiated block on a busy home screen.
struct Surface: ViewModifier {
    var accent: Color = Ink.gold
    /// Raised for the states worth interrupting someone for — an unplayed
    /// challenge, a streak about to break.
    var lit: Bool = false

    func body(content: Content) -> some View {
        content
            .containerBackgroundCompat {
                ZStack(alignment: .topLeading) {
                    LinearGradient(
                        colors: [Ink.top, Ink.bottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(
                        colors: [accent.opacity(lit ? 0.34 : 0.18), .clear],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 190
                    )
                }
            }
            .overlay(
                ContainerRelativeShape()
                    .strokeBorder(
                        accent.opacity(lit ? 0.55 : 0.16),
                        lineWidth: lit ? 1.4 : 1
                    )
            )
    }
}

extension View {
    func surface(_ accent: Color = Ink.gold, lit: Bool = false) -> some View {
        modifier(Surface(accent: accent, lit: lit))
    }

    /// iOS 17 moved widget backgrounds behind `containerBackground`, and a
    /// widget that does not adopt it is letterboxed in the new layouts. 16
    /// still needs a plain background.
    @ViewBuilder
    func containerBackgroundCompat<B: View>(@ViewBuilder _ background: () -> B) -> some View {
        if #available(iOS 17.0, *) {
            self.containerBackground(for: .widget) { background() }
        } else {
            self.background(background())
        }
    }

    /// Widgets are read at arm's length in a glance: one line, shrink before
    /// you ever truncate.
    func fitted(_ minimum: CGFloat = 0.55) -> some View {
        self.lineLimit(1).minimumScaleFactor(minimum)
    }
}

// MARK: - Type

extension Font {
    /// The small tracked-out caps every widget wears as a header.
    static func eyebrow(_ size: CGFloat = 9) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Header line: a tracked-out label in the accent, optionally with something
/// pinned to the right (a streak chip, a percentage).
struct Eyebrow<Trailing: View>: View {
    let text: String
    var accent: Color = Ink.gold
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.eyebrow())
                .kerning(1.7)
                .foregroundStyle(accent)
                .fitted(0.7)
            Spacer(minLength: 4)
            trailing
        }
    }
}

extension Eyebrow where Trailing == EmptyView {
    init(_ text: String, accent: Color = Ink.gold) {
        self.init(text: text, accent: accent) { EmptyView() }
    }
}

// MARK: - Pieces

/// A key in its own colour, in the same rounded square the app puts it in.
struct KeyTile: View {
    let key: String
    var colour: Color
    var size: CGFloat = 46
    /// 0–1. Fills the tile from the bottom, so the twelve of the map read as a
    /// bar chart at a glance without a single number on them.
    var fill: Double? = nil

    var body: some View {
        let radius = size * 0.30
        ZStack {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(colour.opacity(0.16))
            if let fill, fill > 0 {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: radius * 0.7, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [colour.opacity(0.95), colour.opacity(0.55)],
                                    startPoint: .bottom, endPoint: .top
                                )
                            )
                            .frame(height: max(3, geo.size.height * CGFloat(fill)))
                    }
                }
                .padding(2)
            }
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(colour.opacity(fill == nil ? 0.45 : 0.30), lineWidth: 1)
            Text(key)
                .font(.system(size: size * 0.40, weight: .black, design: .rounded))
                .foregroundStyle((fill ?? 0) < 0.55 ? colour : Color.white)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                .fitted(0.5)
                .padding(.horizontal, 2)
        }
        .frame(width: size, height: size)
    }
}

/// The app's mastery bar: a quiet track with a rounded fill in the accent.
struct Bar: View {
    var value: Double            // 0–1
    var colour: Color
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [colour.opacity(0.75), colour],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .frame(width: max(value <= 0 ? 0 : height,
                                     geo.size.width * CGFloat(min(max(value, 0), 1))))
            }
        }
        .frame(height: height)
    }
}

/// The small outlined capsule used for streaks and counts.
struct Chip: View {
    let text: String
    var colour: Color = Ink.gold

    var body: some View {
        Text(text)
            .font(.ui(10, .black))
            .foregroundStyle(colour)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule().fill(colour.opacity(0.12))
                    .overlay(Capsule().strokeBorder(colour.opacity(0.30), lineWidth: 1))
            )
            .fitted(0.8)
    }
}

/// The last seven days as dots, oldest first, today last and ringed. The
/// number says how long the run is; the dots say what it looks like.
struct WeekDots: View {
    var colour: Color
    var size: CGFloat = 9

    var body: some View {
        let week = Improvy.week
        HStack(spacing: size * 0.62) {
            ForEach(Array(week.enumerated()), id: \.offset) { i, done in
                Circle()
                    .fill(done ? colour : Color.white.opacity(0.12))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle().strokeBorder(
                            i == week.count - 1 ? colour.opacity(0.85) : .clear,
                            lineWidth: 1.5
                        )
                        .padding(-2.5)
                    )
            }
        }
    }
}

/// A round accent button — the play glyph on the Daily card, the mode buttons
/// on the launcher.
struct GlyphButton: View {
    let system: String
    var colour: Color
    var size: CGFloat = 38

    var body: some View {
        ZStack {
            Circle().fill(colour.opacity(0.16))
            Circle().strokeBorder(colour.opacity(0.42), lineWidth: 1)
            Image(systemName: system)
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(colour)
        }
        .frame(width: size, height: size)
    }
}
