import SwiftUI
import WidgetKit

// The twelve home-screen widgets, one file, one design language. Every one of
// them draws strings the app has already formatted — see ImprovyKit.swift for
// how the payload crosses the App Group, and for the tokens and pieces shared
// between them.
//
// Each `kind:` string here must match the iOS name in `WidgetService._widgets`
// (Dart) exactly, or the app's refresh sweep silently updates nothing.

// MARK: - Timelines
//
// Two shapes cover everything: a rotation that changes on the hour, and state
// that only changes when the app writes (refreshed hourly, plus just after
// midnight, when an unplayed challenge becomes a new one).

struct HourEntry: TimelineEntry {
    let date: Date
    /// The absolute slot actually shown — handed back on tap so the app can
    /// rebuild exactly this question.
    let slot: Int
    let degree: String
    let key: String
}

struct QuizProvider: TimelineProvider {
    func placeholder(in context: Context) -> HourEntry {
        HourEntry(date: Date(), slot: 0, degree: "♭3", key: "E♭")
    }

    func getSnapshot(in context: Context, completion: @escaping (HourEntry) -> Void) {
        completion(entry(for: Date()))
    }

    /// A day of entries. The rotation itself is written a week ahead by the
    /// app, so a phone that never opens it keeps turning over regardless.
    func getTimeline(in context: Context, completion: @escaping (Timeline<HourEntry>) -> Void) {
        let entries = Improvy.hourlyDates(24).map(entry(for:))
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> HourEntry {
        let slot = Improvy.slot(for: date)
        guard
            let data = Improvy.string("quiz_json").data(using: .utf8),
            let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: String]],
            !list.isEmpty
        else {
            return HourEntry(date: date, slot: slot, degree: "♭3", key: "E♭")
        }
        let base = Improvy.int("quiz_base_slot")
        // Past the end of the written week the rotation wraps rather than going
        // blank; the next app launch rewrites it anyway.
        let index = (((slot - base) % list.count) + list.count) % list.count
        let question = list[index]["q"] ?? ""
        // The degree is the headline and the key the quiet line under it, so
        // the one string has to be split. " of " is what widget_service writes.
        let parts = question.components(separatedBy: " of ")
        return HourEntry(
            date: date,
            // The slot actually shown, not the wall clock — after a wrap they
            // differ, and the app must reveal what was on screen.
            slot: base + index,
            degree: parts.first ?? question,
            key: parts.count > 1 ? parts[1] : ""
        )
    }
}

/// Everything that only moves when the app writes: scores, streaks, mastery.
struct StateEntry: TimelineEntry {
    let date: Date
}

struct StateProvider: TimelineProvider {
    func placeholder(in context: Context) -> StateEntry { StateEntry(date: Date()) }

    func getSnapshot(in context: Context, completion: @escaping (StateEntry) -> Void) {
        completion(StateEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StateEntry>) -> Void) {
        var dates = Improvy.hourlyDates(12)
        if let midnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) {
            dates.append(midnight)
        }
        completion(Timeline(entries: dates.map(StateEntry.init(date:)), policy: .atEnd))
    }
}

// MARK: - ① Question
//
// The answer is withheld on purpose: the unresolved question is what makes the
// widget worth keeping on a home screen, and the tap that resolves it opens
// the app on the reveal.

struct QuizView: View {
    var entry: HourEntry
    var wide = false

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(wide ? "TODAY'S QUESTION" : "QUESTION")
                Spacer(minLength: 6)
                Text(entry.degree)
                    .font(.display(wide ? 46 : 40))
                    .foregroundStyle(Ink.gold)
                    .shadow(color: Ink.gold.opacity(0.35), radius: 14)
                    .fitted()
                if !entry.key.isEmpty {
                    Text("of \(entry.key)")
                        .font(.ui(wide ? 15 : 13, .medium))
                        .foregroundStyle(.white.opacity(0.55))
                        .fitted(0.7)
                        .padding(.top, 1)
                }
                Spacer(minLength: 6)
                Text("Tap to reveal")
                    .font(.ui(10, .medium))
                    .foregroundStyle(.white.opacity(0.42))
                    .fitted(0.8)
            }
            if wide {
                Spacer(minLength: 0)
                GlyphButton(system: "eye.fill", colour: Ink.gold, size: 54)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(wide ? 4 : 0)
        .surface(Ink.gold)
        .widgetURL(URL(string: "improvy://quiz?s=\(entry.slot)"))
    }
}

struct ImprovyQuizWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyQuizWidget", provider: QuizProvider()) {
            QuizView(entry: $0)
        }
        .configurationDisplayName("Improvy · Question")
        .description("A scale degree to answer, new every hour. Tap to reveal it.")
        .supportedFamilies([.systemSmall])
    }
}

struct ImprovyQuizWideWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyQuizWideWidget", provider: QuizProvider()) {
            QuizView(entry: $0, wide: true)
        }
        .configurationDisplayName("Improvy · Question (wide)")
        .description("The same hourly question, with room to breathe.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - ② Daily Challenge

struct DailyView: View {
    var family: WidgetFamily

    private var played: Bool { Improvy.bool("daily_played") }
    private var key: String { Improvy.string("daily_key") }
    private var colour: Color { Improvy.colour("daily_key_color", Ink.gold) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: family == .systemSmall ? "DAILY" : "DAILY CHALLENGE", accent: played ? .white.opacity(0.45) : Ink.gold) {
                Chip(text: "🔥 \(Improvy.int("daily_streak"))",
                     colour: played ? .white.opacity(0.55) : Ink.gold)
            }
            Spacer(minLength: 8)
            HStack(spacing: 12) {
                KeyTile(key: key.isEmpty ? "?" : key, colour: colour,
                        size: family == .systemSmall ? 42 : 52)
                VStack(alignment: .leading, spacing: 3) {
                    Text(played
                         ? (Improvy.string("daily_score", "Done"))
                         : (key.isEmpty ? "Daily Challenge" : "Key of \(key)"))
                        .font(.display(family == .systemSmall ? 19 : 23))
                        .foregroundStyle(.white)
                        .fitted(0.6)
                    Text(played
                         ? Improvy.string("daily_grid", "Next one tomorrow")
                         : Improvy.string("daily_sub", "10 questions"))
                        .font(.ui(11, .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .fitted(0.7)
                    if family != .systemSmall, !played {
                        Text(Improvy.string("daily_mode"))
                            .font(.ui(10, .bold))
                            .foregroundStyle(colour.opacity(0.9))
                            .fitted(0.7)
                    }
                }
                if family != .systemSmall {
                    Spacer(minLength: 0)
                    if !played { GlyphButton(system: "play.fill", colour: Ink.gold, size: 46) }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // The gold frame only while there is still something to do today.
        .surface(played ? Ink.violet : Ink.gold, lit: !played)
        .widgetURL(URL(string: "improvy://daily"))
    }
}

struct ImprovyDailyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyDailyWidget", provider: StateProvider()) { _ in
            FamilyReader { DailyView(family: $0) }
        }
        .configurationDisplayName("Improvy · Daily Challenge")
        .description("The key of the day, your score and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - ③ Level & progress

struct LevelView: View {
    private var colour: Color { Improvy.colour("animal_color", Ink.mint) }

    var body: some View {
        let pct = min(max(Improvy.int("progress_pct"), 0), 100)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow(text: "YOUR LEVEL", accent: colour) {
                Text("\(Improvy.int("animal_level", 1))/\(Improvy.int("animal_levels_total", 8))")
                    .font(.ui(10, .black))
                    .foregroundStyle(.white.opacity(0.40))
            }
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(Improvy.string("animal_emoji", "🐌"))
                    .font(.system(size: 30))
                Text("\(pct)%")
                    .font(.display(30))
                    .foregroundStyle(.white)
                    .fitted(0.6)
            }
            Text(Improvy.string("animal_name", "Snail"))
                .font(.ui(13, .black))
                .foregroundStyle(colour)
                .fitted(0.6)
            Spacer(minLength: 6)
            Bar(value: Double(pct) / 100, colour: colour)
            Text(Improvy.string("animal_quote"))
                .font(.ui(9.5, .medium))
                .foregroundStyle(.white.opacity(0.42))
                .lineLimit(2)
                .padding(.top, 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour)
        .widgetURL(URL(string: "improvy://stats"))
    }
}

struct ImprovyLevelWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyLevelWidget", provider: StateProvider()) { _ in
            LevelView()
        }
        .configurationDisplayName("Improvy · Level")
        .description("How far you have taken all twelve keys, and the animal that says so.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - ④ Key mastery map
//
// Twelve keys in chromatic order, each tile filled by how well it is known. A
// key never played is drawn hollow rather than at 0%: "not started" and
// "started badly" are different facts and must not look the same.

struct KeyDatum {
    let name: String
    let pct: Int
    let colour: Color
    let played: Bool

    static var all: [KeyDatum] {
        guard
            let data = Improvy.string("keys_json").data(using: .utf8),
            let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]]
        else { return [] }
        return list.map {
            KeyDatum(
                name: $0["k"] as? String ?? "—",
                pct: $0["p"] as? Int ?? 0,
                colour: Color(hex: $0["c"] as? String ?? "") ?? .white,
                played: $0["played"] as? Bool ?? false
            )
        }
    }
}

struct MapView: View {
    var tall = false

    var body: some View {
        let keys = KeyDatum.all
        let columns = tall ? 4 : 6
        VStack(alignment: .leading, spacing: tall ? 10 : 8) {
            Eyebrow(text: "KEY MASTERY", accent: Ink.cyan) {
                Text("\(Improvy.int("progress_pct"))%")
                    .font(.ui(11, .black))
                    .foregroundStyle(.white.opacity(0.55))
            }
            if keys.isEmpty {
                Text("Open Improvy to fill this in.")
                    .font(.ui(12, .medium))
                    .foregroundStyle(.white.opacity(0.45))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                GeometryReader { geo in
                    let gap: CGFloat = tall ? 9 : 7
                    let rows = (keys.count + columns - 1) / columns
                    // Never let a cramped container drive the tiles negative.
                    let side = max(12, min(
                        (geo.size.width - gap * CGFloat(columns - 1)) / CGFloat(columns),
                        (geo.size.height - gap * CGFloat(rows - 1)) / CGFloat(rows)
                    ))
                    VStack(spacing: gap) {
                        ForEach(0..<rows, id: \.self) { row in
                            HStack(spacing: gap) {
                                ForEach(0..<columns, id: \.self) { col in
                                    let i = row * columns + col
                                    if i < keys.count {
                                        let k = keys[i]
                                        KeyTile(
                                            key: k.name,
                                            colour: k.played ? k.colour : .white.opacity(0.30),
                                            size: side,
                                            fill: k.played ? Double(k.pct) / 100 : 0
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            }
            if tall {
                Bar(value: Double(Improvy.int("progress_pct")) / 100, colour: Ink.cyan, height: 7)
                Text("\(Improvy.string("animal_emoji", "🐌"))  \(Improvy.string("animal_name", "Snail"))")
                    .font(.ui(11, .black))
                    .foregroundStyle(Improvy.colour("animal_color", Ink.mint))
                    .fitted(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surface(Ink.cyan)
        .widgetURL(URL(string: "improvy://stats"))
    }
}

struct ImprovyMapWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyMapWidget", provider: StateProvider()) { _ in
            MapView()
        }
        .configurationDisplayName("Improvy · Key Map")
        .description("All twelve keys, filled by how well you know each one.")
        .supportedFamilies([.systemMedium])
    }
}

struct ImprovyMapTallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyMapTallWidget", provider: StateProvider()) { _ in
            MapView(tall: true)
        }
        .configurationDisplayName("Improvy · Key Map (large)")
        .description("The twelve keys, your total progress and your level.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - ⑤ Streak

struct StreakView: View {
    var wide = false

    var body: some View {
        let streak = Improvy.int("daily_streak")
        // Only warn when there is actually something to lose.
        let atRisk = streak > 0 && !Improvy.bool("played_today")
        let colour = atRisk ? Ink.gold : Ink.ember

        Group {
            if wide {
                HStack(spacing: 16) {
                    flame(size: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(streak)")
                            .font(.display(40))
                            .foregroundStyle(.white)
                            .fitted()
                        Text(atRisk ? "Play today to keep it" : "day streak")
                            .font(.ui(12, .semibold))
                            .foregroundStyle(atRisk ? Ink.gold : .white.opacity(0.5))
                            .fitted(0.7)
                    }
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 10) {
                        WeekDots(colour: colour, size: 11)
                        if atRisk { GlyphButton(system: "play.fill", colour: Ink.gold, size: 44) }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow("STREAK", accent: colour)
                    Spacer(minLength: 4)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        flame(size: 30)
                        Text("\(streak)")
                            .font(.display(42))
                            .foregroundStyle(.white)
                            .fitted()
                    }
                    Spacer(minLength: 4)
                    WeekDots(colour: colour)
                        .padding(.bottom, 7)
                    Text(atRisk ? "Play today to keep it" : "days in a row")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(atRisk ? Ink.gold : .white.opacity(0.45))
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour, lit: atRisk)
        .widgetURL(URL(string: "improvy://daily"))
    }

    private func flame(size: CGFloat) -> some View {
        Text("🔥").font(.system(size: size))
    }
}

struct ImprovyStreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyStreakWidget", provider: StateProvider()) { _ in
            StreakView()
        }
        .configurationDisplayName("Improvy · Streak")
        .description("Days in a row, and a warning on the day you are about to break one.")
        .supportedFamilies([.systemSmall])
    }
}

struct ImprovyStreakTallWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyStreakTallWidget", provider: StateProvider()) { _ in
            StreakView(wide: true)
        }
        .configurationDisplayName("Improvy · Streak (wide)")
        .description("The streak banner, with a way straight into today's challenge.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - ⑥ Weakest key
//
// "Weakest" means nothing until there is something to compare, so an untouched
// profile gets an invitation rather than an arbitrary C.

struct WeakestView: View {
    var body: some View {
        let key = Improvy.string("weak_key")
        let colour = Improvy.colour("weak_color", Ink.rose)
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("NEEDS WORK", accent: colour)
            Spacer(minLength: 6)
            HStack(spacing: 10) {
                KeyTile(key: key.isEmpty ? "?" : key, colour: colour, size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text(key.isEmpty ? "—" : "\(Improvy.int("weak_pct"))%")
                        .font(.display(26))
                        .foregroundStyle(colour)
                        .fitted(0.6)
                    Text(key.isEmpty ? "Play a key first" : "mastered")
                        .font(.ui(10, .medium))
                        .foregroundStyle(.white.opacity(0.45))
                        .fitted(0.7)
                }
            }
            Spacer(minLength: 6)
            Text(key.isEmpty ? "Tap to start training" : "Your weakest key. Tap to train it.")
                .font(.ui(10.5, .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour)
        .widgetURL(URL(string: key.isEmpty
                       ? "improvy://train"
                       : "improvy://key?k=\(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)"))
    }
}

struct ImprovyWeakestWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyWeakestWidget", provider: StateProvider()) { _ in
            WeakestView()
        }
        .configurationDisplayName("Improvy · Weakest Key")
        .description("The key most worth practising, one tap from training it.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - ⑦ Quick launch
//
// Each mode wears its own accent from home_screen.dart — the widget must not
// invent colours the app does not use.

struct LaunchMode: Identifiable {
    let id: String
    let glyph: String
    let colour: Color
    let url: String
}

struct LauncherView: View {
    private static let modes: [LaunchMode] = [
        LaunchMode(id: "Daily", glyph: "flame.fill", colour: Ink.gold, url: "improvy://daily"),
        LaunchMode(id: "Pocket", glyph: "headphones", colour: Ink.indigo, url: "improvy://pocket"),
        LaunchMode(id: "Chromatic", glyph: "music.note", colour: Ink.violet, url: "improvy://chromatic"),
        LaunchMode(id: "Custom", glyph: "slider.horizontal.3",
                   colour: Color(red: 0.847, green: 0.341, blue: 0.925), url: "improvy://custom"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Eyebrow("START TRAINING", accent: Ink.indigo)
            HStack(spacing: 9) {
                ForEach(Self.modes) { mode in
                    let colour = mode.colour
                    Link(destination: URL(string: mode.url)!) {
                        VStack(spacing: 6) {
                            GlyphButton(system: mode.glyph, colour: colour, size: 40)
                            Text(mode.id)
                                .font(.ui(9.5, .black))
                                .foregroundStyle(.white.opacity(0.72))
                                .fitted(0.6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(colour.opacity(0.10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(colour.opacity(0.22), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surface(Ink.indigo)
    }
}

struct ImprovyLauncherWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyLauncherWidget", provider: StateProvider()) { _ in
            LauncherView()
        }
        .configurationDisplayName("Improvy · Quick Start")
        .description("Four modes, one tap each.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - ⑧ Pocket Mode

struct PocketView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Eyebrow("HANDS-FREE", accent: Ink.indigo)
            Spacer(minLength: 6)
            GlyphButton(system: "headphones", colour: Ink.indigo, size: 46)
            Spacer(minLength: 6)
            Text("Pocket Mode")
                .font(.display(19))
                .foregroundStyle(.white)
                .fitted(0.6)
            Text("Train with the screen off")
                .font(.ui(10.5, .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(Ink.indigo)
        .widgetURL(URL(string: "improvy://pocket"))
    }
}

struct ImprovyPocketWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyPocketWidget", provider: StateProvider()) { _ in
            PocketView()
        }
        .configurationDisplayName("Improvy · Pocket Mode")
        .description("Straight into the hands-free drill.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - ⑨ Theory of the day

struct TheoryView: View {
    var body: some View {
        let colour = Improvy.colour("theory_color", Ink.rose)
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(colour.opacity(0.14))
                Circle().strokeBorder(colour.opacity(0.35), lineWidth: 1)
                Text(Improvy.string("theory_degree", "5"))
                    .font(.display(28))
                    .foregroundStyle(colour)
                    .fitted(0.5)
                    .padding(6)
            }
            .frame(width: 64, height: 64)
            VStack(alignment: .leading, spacing: 5) {
                Eyebrow("DEGREE OF THE DAY", accent: colour)
                Text(Improvy.string("theory_text", "Open Improvy to see today's card."))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .lineLimit(4)
                    .minimumScaleFactor(0.75)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour)
        .widgetURL(URL(string: "improvy://theory"))
    }
}

struct ImprovyTheoryWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyTheoryWidget", provider: StateProvider()) { _ in
            TheoryView()
        }
        .configurationDisplayName("Improvy · Theory")
        .description("One scale degree explained, a new one every day.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Plumbing

/// Reads the family the widget was rendered at, so one view can serve small and
/// medium without duplicating it.
struct FamilyReader<Content: View>: View {
    @Environment(\.widgetFamily) private var family
    private let content: (WidgetFamily) -> Content

    init(@ViewBuilder content: @escaping (WidgetFamily) -> Content) {
        self.content = content
    }

    var body: some View { content(family) }
}

// MARK: - Bundle

@main
struct ImprovyWidgetBundle: WidgetBundle {
    var body: some Widget {
        ImprovyQuizWidget()
        ImprovyQuizWideWidget()
        ImprovyDailyWidget()
        ImprovyLevelWidget()
        ImprovyMapWidget()
        ImprovyMapTallWidget()
        ImprovyStreakWidget()
        ImprovyStreakTallWidget()
        ImprovyWeakestWidget()
        ImprovyLauncherWidget()
        ImprovyPocketWidget()
        ImprovyTheoryWidget()
    }
}
