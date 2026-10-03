import SwiftUI
import WidgetKit
import Foundation
import UIKit

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
    ///
    /// Computed on every read, never cached. The first render on a fresh
    /// install comes before the app has written anything, and a `let` here
    /// held that empty map for the life of the extension process — English
    /// fallbacks long after the app had synced, and after a change of
    /// language.
    static var labels: [String: String] {
        guard
            let data = string("labels_json").data(using: .utf8),
            let map = (try? JSONSerialization.jsonObject(with: data)) as? [String: String]
        else { return [:] }
        return map
    }

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

    /// A widget's tap target, `improvy://<path>`.
    ///
    /// home_widget hands the app only URLs that carry a `homeWidget` query
    /// item (SwiftHomeWidgetPlugin.isWidgetUrl); any other URL opens the app
    /// and the tap is dropped — every widget then "just opens Improvy" instead
    /// of the challenge, the question or the key it shows.
    static func link(_ path: String) -> URL {
        let separator = path.contains("?") ? "&" : "?"
        return URL(string: "improvy://\(path)\(separator)homeWidget")!
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
    static let top = Color(red: 0.102, green: 0.078, blue: 0.141)     // #1A1424
    static let bottom = Color(red: 0.051, green: 0.039, blue: 0.078)  // #0D0A14
    static let gold = Color(red: 0.988, green: 0.827, blue: 0.302)    // #FCD34D
    static let amber = Color(red: 0.961, green: 0.620, blue: 0.043)   // #F59E0B
    static let indigo = Color(red: 0.388, green: 0.400, blue: 0.945)  // #6366F1
    static let violet = Color(red: 0.659, green: 0.333, blue: 0.969)  // #A855F7
    static let mint = Color(red: 0.204, green: 0.827, blue: 0.600)    // #34D399
    static let cyan = Color(red: 0.133, green: 0.827, blue: 0.933)    // #22D3EE
    static let ember = Color(red: 0.976, green: 0.451, blue: 0.086)   // #F97316
    static let rose = Color(red: 0.984, green: 0.443, blue: 0.522)    // #FB7185
    /// The ink that reads on a light key colour (the yellows and greens).
    static let dark = Color(red: 0.078, green: 0.059, blue: 0.110)    // #140F1C
    static let quiet = Color.white.opacity(0.48)
    static let faint = Color.white.opacity(0.08)
}

extension Color {
    /// Relative luminance, 0–1, for choosing dark or white ink on a fill.
    var luminance: Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return 0.2126 * Double(r) + 0.7152 * Double(g) + 0.0722 * Double(b)
    }

    /// White on deep colours, the dark ink on light ones — a yellow key tile
    /// with a white "D" on it is a key nobody can read.
    var onFill: Color { luminance > 0.62 ? Ink.dark : .white }
}

/// The surface every widget sits on: near-black with depth, a soft light in
/// the widget's own accent from the top-right corner, and a faint sheen along
/// the top edge. One accent per widget, so twelve of them on a home screen
/// read as a family rather than as twelve dark rectangles.
///
/// No border. The system already frames a widget; an outline drawn inside that
/// frame reads as a second, lit rectangle sitting in the middle of the home
/// screen rather than as the edge of the card.
struct Surface: ViewModifier {
    var accent: Color = Ink.gold
    /// Raised for the states worth interrupting someone for — an unplayed
    /// challenge, a streak about to break.
    var lit: Bool = false

    func body(content: Content) -> some View {
        content
            .containerBackgroundCompat {
                ZStack {
                    LinearGradient(
                        colors: [Ink.top, Ink.bottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    RadialGradient(
                        colors: [accent.opacity(lit ? 0.30 : 0.17), .clear],
                        center: .topTrailing,
                        startRadius: 0,
                        endRadius: 210
                    )
                    LinearGradient(
                        colors: [.white.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.35)
                    )
                }
            }
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
    /// The small header every widget wears.
    static func eyebrow(_ size: CGFloat = 10.5) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func display(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// A note or degree with its accidental set the way music sets it: smaller
/// and raised, so "D♭" reads as D-flat rather than as "Db" in a heavy font.
func music(_ s: String, size: CGFloat, weight: Font.Weight = .bold) -> Text {
    var out = Text("")
    for ch in s {
        if "♭♯𝄫𝄪".contains(ch) {
            out = out + Text(String(ch))
                .font(.system(size: size * 0.62, weight: weight, design: .rounded))
                .baselineOffset(size * 0.30)
        } else {
            out = out + Text(String(ch)).font(.system(size: size, weight: weight, design: .rounded))
        }
    }
    return out
}

/// Header line: an SF Symbol and a label in the accent, optionally with
/// something pinned to the right (a streak chip, a percentage).
struct Eyebrow<Trailing: View>: View {
    let text: String
    var symbol: String? = nil
    var accent: Color = Ink.gold
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(.eyebrow())
                .kerning(0.6)
                .fitted(0.7)
            Spacer(minLength: 4)
            trailing
        }
        .foregroundStyle(accent)
    }
}

extension Eyebrow where Trailing == EmptyView {
    init(_ text: String, symbol: String? = nil, accent: Color = Ink.gold) {
        self.init(text: text, symbol: symbol, accent: accent) { EmptyView() }
    }
}

// MARK: - Pieces

/// A key in its own colour, filled, with ink chosen so it can always be read.
struct KeyBadge: View {
    let key: String
    var colour: Color
    var size: CGFloat = 46

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(LinearGradient(colors: [colour, colour.opacity(0.78)],
                                     startPoint: .top, endPoint: .bottom))
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.22), .clear],
                                     startPoint: .top, endPoint: .center))
            music(key, size: size * 0.42)
                .foregroundStyle(colour.onFill)
                .fitted(0.5)
                .padding(.horizontal, 3)
        }
        .frame(width: size, height: size)
        .shadow(color: colour.opacity(0.35), radius: 8, y: 3)
    }
}

/// One key of the mastery map: the name, and under it a thin bar in the key's
/// colour as long as the key is known. A key never played shows no bar and a
/// quiet name — "not started" and "started badly" are different facts.
struct KeyCell: View {
    let key: String
    var colour: Color
    var pct: Int
    var played: Bool
    var large = false

    var body: some View {
        VStack(spacing: large ? 7 : 5) {
            music(key, size: large ? 21 : 15, weight: .semibold)
                .foregroundStyle(played ? Color.white : Color.white.opacity(0.32))
                .fitted(0.6)
            if large {
                Text(played ? "\(pct)%" : "—")
                    .font(.ui(10.5, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(played ? colour : Color.white.opacity(0.25))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08))
                    if played {
                        Capsule().fill(colour)
                            .frame(width: max(4, geo.size.width * CGFloat(min(max(pct, 0), 100)) / 100))
                    }
                }
            }
            .frame(height: 3)
            .padding(.horizontal, large ? 12 : 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: large ? 16 : 12, style: .continuous)
                .fill(Color.white.opacity(played ? 0.07 : 0.035))
        )
    }
}

/// The app's mastery bar: a quiet track with a rounded fill in the accent.
struct Bar: View {
    var value: Double            // 0–1
    var colour: Color
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.10))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [colour.opacity(0.7), colour],
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

/// The streak count as a small capsule: a drawn flame and the number.
struct StreakChip: View {
    let count: Int
    var dim = false

    var body: some View {
        HStack(spacing: 3) {
            Flame(size: 10)
                .opacity(dim ? 0.6 : 1)
            Text("\(count)")
                .font(.ui(11, .bold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(dim ? 0.6 : 0.95))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(Capsule().fill(Color.white.opacity(0.09)))
    }
}

/// The flame, drawn as a symbol with the app's orange-to-gold — not an emoji,
/// which looks like a sticker next to everything else here.
struct Flame: View {
    var size: CGFloat

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundStyle(LinearGradient(colors: [Ink.gold, Ink.ember],
                                            startPoint: .top, endPoint: .bottom))
    }
}

/// The last seven days, oldest first, today last: was the daily played.
/// With [letters], each dot carries its weekday initial beneath it.
struct WeekDots: View {
    var colour: Color
    var size: CGFloat = 9
    var letters = false

    var body: some View {
        let week = Improvy.week
        let initials = WeekDots.initials()
        HStack(spacing: letters ? size * 0.9 : size * 0.55) {
            ForEach(Array(week.enumerated()), id: \.offset) { i, done in
                VStack(spacing: 5) {
                    ZStack {
                        Circle()
                            .fill(done ? AnyShapeStyle(LinearGradient(colors: [Ink.gold, colour],
                                                                      startPoint: .top, endPoint: .bottom))
                                       : AnyShapeStyle(Color.white.opacity(0.10)))
                        if i == week.count - 1 && !done {
                            Circle().strokeBorder(colour.opacity(0.9), lineWidth: 1.3)
                        }
                    }
                    .frame(width: size, height: size)
                    if letters {
                        Text(initials[i])
                            .font(.ui(8.5, .semibold))
                            .foregroundStyle(.white.opacity(i == week.count - 1 ? 0.85 : 0.35))
                    }
                }
            }
        }
    }

    /// The weekday initials for the last seven days, ending today, in the
    /// phone's language.
    static func initials() -> [String] {
        let cal = Calendar.current
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let today = Date()
        return (0..<7).reversed().map { back in
            let d = cal.date(byAdding: .day, value: -back, to: today) ?? today
            return symbols[cal.component(.weekday, from: d) - 1]
        }
    }
}

/// The daily's answers as a row of short bars, right and wrong.
struct ResultBars: View {
    /// The grid the app writes: one 🟩 or 🟥 per question.
    let grid: String
    var height: CGFloat = 5

    var body: some View {
        let marks = grid.compactMap { ch -> Bool? in
            ch == "🟩" ? true : (ch == "🟥" ? false : nil)
        }
        HStack(spacing: 2.5) {
            ForEach(Array(marks.enumerated()), id: \.offset) { _, ok in
                Capsule().fill(ok ? Ink.mint : Ink.rose)
                    .frame(height: height)
            }
        }
    }
}

/// A round accent button — play on the Daily card, the eye on the question.
struct GlyphButton: View {
    let system: String
    var colour: Color
    var size: CGFloat = 38
    /// Filled for the one thing on the widget that is an action.
    var filled = false

    var body: some View {
        ZStack {
            if filled {
                Circle().fill(LinearGradient(colors: [colour, colour.opacity(0.8)],
                                             startPoint: .top, endPoint: .bottom))
                    .shadow(color: colour.opacity(0.45), radius: 10, y: 3)
            } else {
                Circle().fill(colour.opacity(0.16))
            }
            Image(systemName: system)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(filled ? colour.onFill : colour)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Level animals

/// The level's animal in the app's own line art (lib/widgets/animal_icon.dart),
/// in the level's colour — never an emoji, which drew a different, cartoon
/// animal from the one the app shows.
struct AnimalGlyph: View {
    let level: Int
    var colour: Color
    var size: CGFloat

    var body: some View {
        AnimalArt.outline(level: level)
            .applying(CGAffineTransform(scaleX: size / 24, y: size / 24))
            .stroke(colour, style: StrokeStyle(lineWidth: 2 * size / 24, lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

// BEGIN GENERATED ANIMALS (tool/gen_animal_swift.py)
// Do not edit by hand: regenerate from lib/widgets/animal_icon.dart.

/// The eight level animals as the app draws them, on a 24 x 24 grid.
enum AnimalArt {
    /// Level 1-8, clamped, so a payload from a newer app never breaks an older widget.
    static func outline(level: Int) -> Path {
        switch min(max(level, 1), 8) {
        case 1: return snail()
        case 2: return turtle()
        case 3: return penguin()
        case 4: return rabbit()
        case 5: return fox()
        case 6: return horse()
        case 7: return falcon()
        case 8: return cheetah()
        default: return snail()
        }
    }

    private static func snail() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 2.000, y: 13.000))
        p.addCurve(to: CGPoint(x: 14.000, y: 13.000), control1: CGPoint(x: 2.000, y: 19.928), control2: CGPoint(x: 14.000, y: 19.928))
        p.addCurve(to: CGPoint(x: 6.000, y: 13.000), control1: CGPoint(x: 14.000, y: 8.381), control2: CGPoint(x: 6.000, y: 8.381))
        p.addCurve(to: CGPoint(x: 10.000, y: 13.000), control1: CGPoint(x: 6.000, y: 15.309), control2: CGPoint(x: 10.000, y: 15.309))
        p.move(to: CGPoint(x: 2.000, y: 13.000))
        p.addCurve(to: CGPoint(x: 18.000, y: 13.000), control1: CGPoint(x: 2.000, y: 22.238), control2: CGPoint(x: 18.000, y: 22.238))
        p.addCurve(to: CGPoint(x: 2.000, y: 13.000), control1: CGPoint(x: 18.000, y: 3.762), control2: CGPoint(x: 2.000, y: 3.762))
        p.move(to: CGPoint(x: 2.000, y: 21.000))
        p.addLine(to: CGPoint(x: 14.000, y: 21.000))
        p.addCurve(to: CGPoint(x: 22.000, y: 13.000), control1: CGPoint(x: 18.400, y: 21.000), control2: CGPoint(x: 22.000, y: 17.400))
        p.addLine(to: CGPoint(x: 22.000, y: 7.000))
        p.addCurve(to: CGPoint(x: 18.000, y: 7.000), control1: CGPoint(x: 22.000, y: 4.691), control2: CGPoint(x: 18.000, y: 4.691))
        p.addLine(to: CGPoint(x: 18.000, y: 13.000))
        p.move(to: CGPoint(x: 18.000, y: 3.000))
        p.addLine(to: CGPoint(x: 19.100, y: 5.200))
        p.move(to: CGPoint(x: 22.000, y: 3.000))
        p.addLine(to: CGPoint(x: 20.900, y: 5.200))
        return p
    }

    private static func turtle() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 12.000, y: 10.000))
        p.addLine(to: CGPoint(x: 14.000, y: 14.000))
        p.addLine(to: CGPoint(x: 14.000, y: 17.000))
        p.addCurve(to: CGPoint(x: 15.000, y: 18.000), control1: CGPoint(x: 14.000, y: 17.549), control2: CGPoint(x: 14.451, y: 18.000))
        p.addLine(to: CGPoint(x: 17.000, y: 18.000))
        p.addCurve(to: CGPoint(x: 18.000, y: 17.000), control1: CGPoint(x: 17.549, y: 18.000), control2: CGPoint(x: 18.000, y: 17.549))
        p.addLine(to: CGPoint(x: 18.000, y: 14.000))
        p.addCurve(to: CGPoint(x: 2.000, y: 14.000), control1: CGPoint(x: 18.000, y: 4.762), control2: CGPoint(x: 2.000, y: 4.762))
        p.addLine(to: CGPoint(x: 2.000, y: 17.000))
        p.addCurve(to: CGPoint(x: 3.000, y: 18.000), control1: CGPoint(x: 2.000, y: 17.549), control2: CGPoint(x: 2.451, y: 18.000))
        p.addLine(to: CGPoint(x: 5.000, y: 18.000))
        p.addCurve(to: CGPoint(x: 6.000, y: 17.000), control1: CGPoint(x: 5.549, y: 18.000), control2: CGPoint(x: 6.000, y: 17.549))
        p.addLine(to: CGPoint(x: 6.000, y: 14.000))
        p.addLine(to: CGPoint(x: 8.000, y: 10.000))
        p.addLine(to: CGPoint(x: 12.000, y: 10.000))
        p.closeSubpath()
        p.move(to: CGPoint(x: 4.820, y: 7.900))
        p.addLine(to: CGPoint(x: 8.000, y: 10.000))
        p.move(to: CGPoint(x: 15.180, y: 7.900))
        p.addLine(to: CGPoint(x: 12.000, y: 10.000))
        p.move(to: CGPoint(x: 16.930, y: 10.000))
        p.addLine(to: CGPoint(x: 20.000, y: 10.000))
        p.addCurve(to: CGPoint(x: 20.000, y: 14.000), control1: CGPoint(x: 22.309, y: 10.000), control2: CGPoint(x: 22.309, y: 14.000))
        p.addLine(to: CGPoint(x: 2.000, y: 14.000))
        return p
    }

    private static func penguin() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 12.000, y: 2.000))
        p.addCurve(to: CGPoint(x: 6.000, y: 8.000), control1: CGPoint(x: 8.700, y: 2.000), control2: CGPoint(x: 6.000, y: 4.700))
        p.addLine(to: CGPoint(x: 6.000, y: 16.000))
        p.addCurve(to: CGPoint(x: 18.000, y: 16.000), control1: CGPoint(x: 6.000, y: 22.928), control2: CGPoint(x: 18.000, y: 22.928))
        p.addLine(to: CGPoint(x: 18.000, y: 8.000))
        p.addCurve(to: CGPoint(x: 12.000, y: 2.000), control1: CGPoint(x: 18.000, y: 4.700), control2: CGPoint(x: 15.300, y: 2.000))
        p.closeSubpath()
        p.move(to: CGPoint(x: 9.000, y: 10.000))
        p.addLine(to: CGPoint(x: 9.010, y: 10.000))
        p.move(to: CGPoint(x: 15.000, y: 10.000))
        p.addLine(to: CGPoint(x: 15.010, y: 10.000))
        p.move(to: CGPoint(x: 12.000, y: 13.000))
        p.addLine(to: CGPoint(x: 11.000, y: 12.000))
        p.addLine(to: CGPoint(x: 13.000, y: 12.000))
        p.addLine(to: CGPoint(x: 12.000, y: 13.000))
        p.closeSubpath()
        p.move(to: CGPoint(x: 6.000, y: 12.000))
        p.addLine(to: CGPoint(x: 4.000, y: 14.000))
        p.addLine(to: CGPoint(x: 5.000, y: 17.000))
        p.move(to: CGPoint(x: 18.000, y: 12.000))
        p.addLine(to: CGPoint(x: 20.000, y: 14.000))
        p.addLine(to: CGPoint(x: 19.000, y: 17.000))
        p.move(to: CGPoint(x: 9.000, y: 22.000))
        p.addLine(to: CGPoint(x: 9.000, y: 20.000))
        p.move(to: CGPoint(x: 15.000, y: 22.000))
        p.addLine(to: CGPoint(x: 15.000, y: 20.000))
        return p
    }

    private static func rabbit() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 13.000, y: 16.000))
        p.addCurve(to: CGPoint(x: 15.240, y: 21.000), control1: CGPoint(x: 15.505, y: 15.997), control2: CGPoint(x: 16.910, y: 19.133))
        p.move(to: CGPoint(x: 18.000, y: 12.000))
        p.addLine(to: CGPoint(x: 18.010, y: 12.000))
        p.move(to: CGPoint(x: 18.000, y: 21.000))
        p.addLine(to: CGPoint(x: 10.000, y: 21.000))
        p.addCurve(to: CGPoint(x: 6.000, y: 17.000), control1: CGPoint(x: 7.806, y: 21.000), control2: CGPoint(x: 6.000, y: 19.194))
        p.addCurve(to: CGPoint(x: 13.000, y: 10.000), control1: CGPoint(x: 6.000, y: 13.160), control2: CGPoint(x: 9.160, y: 10.000))
        p.addLine(to: CGPoint(x: 13.200, y: 10.000))
        p.addLine(to: CGPoint(x: 9.600, y: 6.400))
        p.addCurve(to: CGPoint(x: 12.400, y: 3.600), control1: CGPoint(x: 7.983, y: 4.783), control2: CGPoint(x: 10.783, y: 1.983))
        p.addLine(to: CGPoint(x: 15.800, y: 7.000))
        p.addLine(to: CGPoint(x: 16.000, y: 7.000))
        p.addCurve(to: CGPoint(x: 22.000, y: 13.000), control1: CGPoint(x: 19.300, y: 7.000), control2: CGPoint(x: 22.000, y: 9.700))
        p.addLine(to: CGPoint(x: 22.000, y: 14.000))
        p.addCurve(to: CGPoint(x: 20.000, y: 16.000), control1: CGPoint(x: 22.000, y: 15.097), control2: CGPoint(x: 21.097, y: 16.000))
        p.addLine(to: CGPoint(x: 19.000, y: 16.000))
        p.addCurve(to: CGPoint(x: 16.000, y: 19.000), control1: CGPoint(x: 17.354, y: 16.000), control2: CGPoint(x: 16.000, y: 17.354))
        p.move(to: CGPoint(x: 20.000, y: 8.540))
        p.addLine(to: CGPoint(x: 20.000, y: 4.000))
        p.addCurve(to: CGPoint(x: 16.000, y: 4.000), control1: CGPoint(x: 20.000, y: 1.691), control2: CGPoint(x: 16.000, y: 1.691))
        p.addLine(to: CGPoint(x: 16.000, y: 7.000))
        p.move(to: CGPoint(x: 7.612, y: 12.524))
        p.addCurve(to: CGPoint(x: 6.012, y: 16.824), control1: CGPoint(x: 8.518, y: 14.127), control2: CGPoint(x: 7.745, y: 16.203))
        return p
    }

    private static func fox() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 3.000, y: 3.000))
        p.addLine(to: CGPoint(x: 6.000, y: 10.000))
        p.move(to: CGPoint(x: 21.000, y: 3.000))
        p.addLine(to: CGPoint(x: 18.000, y: 10.000))
        p.move(to: CGPoint(x: 6.000, y: 10.000))
        p.addLine(to: CGPoint(x: 12.000, y: 19.000))
        p.addLine(to: CGPoint(x: 18.000, y: 10.000))
        p.addLine(to: CGPoint(x: 12.000, y: 6.000))
        p.addLine(to: CGPoint(x: 6.000, y: 10.000))
        p.closeSubpath()
        p.move(to: CGPoint(x: 9.000, y: 12.000))
        p.addLine(to: CGPoint(x: 9.010, y: 12.000))
        p.move(to: CGPoint(x: 15.000, y: 12.000))
        p.addLine(to: CGPoint(x: 15.010, y: 12.000))
        p.move(to: CGPoint(x: 12.000, y: 17.000))
        p.addLine(to: CGPoint(x: 12.010, y: 17.000))
        return p
    }

    private static func horse() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 8.000, y: 20.000))
        p.addLine(to: CGPoint(x: 16.000, y: 20.000))
        p.move(to: CGPoint(x: 10.000, y: 20.000))
        p.addLine(to: CGPoint(x: 10.000, y: 14.000))
        p.addLine(to: CGPoint(x: 6.000, y: 12.000))
        p.addLine(to: CGPoint(x: 7.000, y: 8.000))
        p.addLine(to: CGPoint(x: 10.000, y: 7.000))
        p.addLine(to: CGPoint(x: 10.000, y: 4.000))
        p.addLine(to: CGPoint(x: 13.000, y: 5.000))
        p.addLine(to: CGPoint(x: 16.000, y: 9.000))
        p.addLine(to: CGPoint(x: 16.000, y: 14.000))
        p.addLine(to: CGPoint(x: 14.000, y: 16.000))
        p.addLine(to: CGPoint(x: 14.000, y: 20.000))
        p.move(to: CGPoint(x: 14.000, y: 4.000))
        p.addLine(to: CGPoint(x: 15.000, y: 2.000))
        p.addLine(to: CGPoint(x: 17.000, y: 3.000))
        p.move(to: CGPoint(x: 10.000, y: 10.000))
        p.addLine(to: CGPoint(x: 10.010, y: 10.000))
        return p
    }

    private static func falcon() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 16.000, y: 7.000))
        p.addLine(to: CGPoint(x: 16.010, y: 7.000))
        p.move(to: CGPoint(x: 3.400, y: 18.000))
        p.addLine(to: CGPoint(x: 12.000, y: 18.000))
        p.addCurve(to: CGPoint(x: 20.000, y: 10.000), control1: CGPoint(x: 16.389, y: 18.000), control2: CGPoint(x: 20.000, y: 14.389))
        p.addLine(to: CGPoint(x: 20.000, y: 7.000))
        p.addCurve(to: CGPoint(x: 12.720, y: 4.700), control1: CGPoint(x: 20.010, y: 3.287), control2: CGPoint(x: 14.845, y: 1.656))
        p.addLine(to: CGPoint(x: 2.000, y: 20.000))
        p.move(to: CGPoint(x: 20.000, y: 7.000))
        p.addLine(to: CGPoint(x: 22.000, y: 7.500))
        p.addLine(to: CGPoint(x: 20.000, y: 8.000))
        p.move(to: CGPoint(x: 10.000, y: 18.000))
        p.addLine(to: CGPoint(x: 10.000, y: 21.000))
        p.move(to: CGPoint(x: 14.000, y: 17.750))
        p.addLine(to: CGPoint(x: 14.000, y: 21.000))
        p.move(to: CGPoint(x: 7.000, y: 18.000))
        p.addCurve(to: CGPoint(x: 10.840, y: 7.390), control1: CGPoint(x: 12.359, y: 18.000), control2: CGPoint(x: 14.957, y: 10.820))
        return p
    }

    private static func cheetah() -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 12.000, y: 5.000))
        p.addCurve(to: CGPoint(x: 14.000, y: 5.260), control1: CGPoint(x: 12.670, y: 5.000), control2: CGPoint(x: 13.350, y: 5.090))
        p.addCurve(to: CGPoint(x: 20.420, y: 3.000), control1: CGPoint(x: 15.780, y: 3.260), control2: CGPoint(x: 19.030, y: 2.420))
        p.addCurve(to: CGPoint(x: 20.000, y: 10.000), control1: CGPoint(x: 21.820, y: 3.580), control2: CGPoint(x: 20.000, y: 10.000))
        p.addCurve(to: CGPoint(x: 21.000, y: 13.440), control1: CGPoint(x: 20.570, y: 11.070), control2: CGPoint(x: 21.000, y: 12.240))
        p.addCurve(to: CGPoint(x: 12.000, y: 21.000), control1: CGPoint(x: 21.000, y: 17.900), control2: CGPoint(x: 16.970, y: 21.000))
        p.addCurve(to: CGPoint(x: 3.000, y: 13.440), control1: CGPoint(x: 7.030, y: 21.000), control2: CGPoint(x: 3.000, y: 18.000))
        p.addCurve(to: CGPoint(x: 4.000, y: 10.000), control1: CGPoint(x: 3.000, y: 12.190), control2: CGPoint(x: 3.500, y: 11.040))
        p.addCurve(to: CGPoint(x: 3.500, y: 3.000), control1: CGPoint(x: 4.000, y: 10.000), control2: CGPoint(x: 2.110, y: 3.580))
        p.addCurve(to: CGPoint(x: 10.000, y: 5.230), control1: CGPoint(x: 4.890, y: 2.420), control2: CGPoint(x: 8.220, y: 3.230))
        p.addCurve(to: CGPoint(x: 12.000, y: 5.000), control1: CGPoint(x: 10.656, y: 5.079), control2: CGPoint(x: 11.327, y: 5.002))
        p.closeSubpath()
        p.move(to: CGPoint(x: 8.000, y: 14.000))
        p.addLine(to: CGPoint(x: 8.000, y: 14.500))
        p.move(to: CGPoint(x: 16.000, y: 14.000))
        p.addLine(to: CGPoint(x: 16.000, y: 14.500))
        p.move(to: CGPoint(x: 11.250, y: 16.250))
        p.addLine(to: CGPoint(x: 12.750, y: 16.250))
        p.addLine(to: CGPoint(x: 12.000, y: 17.000))
        p.addLine(to: CGPoint(x: 11.250, y: 16.250))
        p.closeSubpath()
        return p
    }
}
// END GENERATED ANIMALS
