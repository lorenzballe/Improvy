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

    private var gold: LinearGradient {
        LinearGradient(colors: [Color(red: 1, green: 0.91, blue: 0.55), Ink.gold, Ink.amber],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                Eyebrow(wide ? Improvy.label("questionLong", "TODAY'S QUESTION")
                             : Improvy.label("question", "QUESTION"),
                        symbol: "questionmark.circle.fill", accent: Ink.gold)
                Spacer(minLength: 4)
                music(entry.degree, size: wide ? 58 : 50)
                    .foregroundStyle(gold)
                    .fitted()
                if !entry.key.isEmpty {
                    (Text("\(Improvy.label("of", "of")) ").font(.ui(wide ? 17 : 15, .medium))
                        + music(entry.key, size: wide ? 17 : 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .fitted(0.7)
                }
                Spacer(minLength: 4)
                if !wide {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill").font(.system(size: 9, weight: .semibold))
                        Text(Improvy.label("reveal", "Tap to reveal")).font(.ui(11, .medium))
                    }
                    .foregroundStyle(Ink.quiet)
                    .fitted(0.8)
                }
            }
            if wide {
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    GlyphButton(system: "eye.fill", colour: Ink.gold, size: 56, filled: true)
                    Text(Improvy.label("reveal", "Tap to reveal"))
                        .font(.ui(11, .medium))
                        .foregroundStyle(Ink.quiet)
                        .fitted(0.8)
                }
                .frame(width: 96)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(Ink.gold)
        .widgetURL(Improvy.link("quiz?s=\(entry.slot)"))
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
    private var streak: Int { Improvy.int("daily_streak") }
    private var small: Bool { family == .systemSmall }

    var body: some View {
        Group {
            if small { smallBody } else { wideBody }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        // The gold light only while there is still something to do today.
        .surface(played ? Ink.mint : Ink.gold, lit: !played)
        .widgetURL(Improvy.link("daily"))
    }

    private var eyebrow: some View {
        Eyebrow(text: small ? Improvy.label("daily", "DAILY")
                            : Improvy.label("dailyLong", "DAILY CHALLENGE"),
                symbol: played ? "checkmark.seal.fill" : "calendar",
                accent: played ? Ink.mint : Ink.gold) {
            StreakChip(count: streak, dim: played)
        }
    }

    private var score: String { Improvy.string("daily_score", Improvy.label("done", "Done")) }

    @ViewBuilder private var smallBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow
            Spacer(minLength: 6)
            if played {
                Text(score)
                    .font(.display(40))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .fitted(0.6)
                Spacer(minLength: 6)
                ResultBars(grid: Improvy.string("daily_grid"))
                Text(Improvy.label("tomorrow", "Next one tomorrow"))
                    .font(.ui(10.5, .medium))
                    .foregroundStyle(Ink.quiet)
                    .fitted(0.7)
                    .padding(.top, 6)
            } else {
                HStack(spacing: 10) {
                    KeyBadge(key: key.isEmpty ? "?" : key, colour: colour, size: 50)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Improvy.label("today", "today").capitalized)
                            .font(.ui(15, .semibold))
                            .foregroundStyle(.white)
                            .fitted(0.6)
                        Text(Improvy.string("daily_mode"))
                            .font(.ui(11, .semibold))
                            .foregroundStyle(colour)
                            .fitted(0.6)
                    }
                }
                Spacer(minLength: 6)
                Text(Improvy.string("daily_sub", "10 questions"))
                    .font(.ui(10.5, .medium))
                    .foregroundStyle(Ink.quiet)
                    .fitted(0.7)
            }
        }
    }

    @ViewBuilder private var wideBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            eyebrow
            Spacer(minLength: 6)
            HStack(spacing: 14) {
                KeyBadge(key: key.isEmpty ? "?" : key, colour: colour, size: 60)
                VStack(alignment: .leading, spacing: 4) {
                    if played {
                        Text(score)
                            .font(.display(30))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .fitted(0.6)
                        ResultBars(grid: Improvy.string("daily_grid"), height: 5)
                            .frame(maxWidth: 170)
                    } else {
                        (Text("\(Improvy.label("keyOf", "Key of")) ").font(.display(22, .semibold))
                            + music(key, size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                            .fitted(0.6)
                        Text(Improvy.string("daily_mode"))
                            .font(.ui(12, .semibold))
                            .foregroundStyle(colour)
                            .fitted(0.7)
                    }
                    Text(played ? Improvy.label("tomorrow", "Next one tomorrow")
                                : Improvy.string("daily_sub", "10 questions"))
                        .font(.ui(11, .medium))
                        .foregroundStyle(Ink.quiet)
                        .fitted(0.7)
                }
                Spacer(minLength: 0)
                if !played {
                    GlyphButton(system: "play.fill", colour: Ink.gold, size: 50, filled: true)
                }
            }
            Spacer(minLength: 0)
        }
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
            Eyebrow(text: Improvy.label("level", "YOUR LEVEL"), symbol: "sparkles", accent: colour) {
                Text("\(Improvy.int("animal_level", 1))/\(Improvy.int("animal_levels_total", 8))")
                    .font(.ui(10.5, .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Ink.quiet)
            }
            Spacer(minLength: 4)
            HStack(spacing: 9) {
                ZStack {
                    Circle().fill(colour.opacity(0.18))
                    Text(Improvy.string("animal_emoji", "🐌")).font(.system(size: 21))
                }
                .frame(width: 38, height: 38)
                VStack(alignment: .leading, spacing: 1) {
                    Text(Improvy.string("animal_name", "Snail"))
                        .font(.ui(15, .bold))
                        .foregroundStyle(.white)
                        .fitted(0.6)
                    Text(Improvy.string("animal_quote"))
                        .font(.ui(10, .medium))
                        .foregroundStyle(Ink.quiet)
                        .fitted(0.7)
                }
            }
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(pct)")
                    .font(.display(34))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                Text("%")
                    .font(.display(17, .semibold))
                    .foregroundStyle(.white.opacity(0.55))
            }
            Bar(value: Double(pct) / 100, colour: colour)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour)
        .widgetURL(Improvy.link("stats"))
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
// Twelve keys in chromatic order, each with a bar as long as it is known. A
// key never played is drawn quiet, with no bar, rather than at 0%: "not
// started" and "started badly" are different facts and must not look the same.

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
        let gap: CGFloat = tall ? 8 : 6
        VStack(alignment: .leading, spacing: tall ? 12 : 9) {
            Eyebrow(text: Improvy.label("mastery", "KEY MASTERY"),
                    symbol: "square.grid.3x3.fill", accent: Ink.cyan) {
                Text("\(Improvy.int("progress_pct"))%")
                    .font(.ui(11, .bold))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.75))
            }
            if keys.isEmpty {
                Text(Improvy.label("openApp", "Open Improvy to fill this in."))
                    .font(.ui(12, .medium))
                    .foregroundStyle(Ink.quiet)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                let rows = (keys.count + columns - 1) / columns
                VStack(spacing: gap) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: gap) {
                            ForEach(0..<columns, id: \.self) { col in
                                let i = row * columns + col
                                if i < keys.count {
                                    let k = keys[i]
                                    KeyCell(key: k.name, colour: k.colour, pct: k.pct,
                                            played: k.played, large: tall)
                                } else {
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
            }
            if tall {
                HStack(spacing: 8) {
                    Text(Improvy.string("animal_emoji", "🐌")).font(.system(size: 15))
                    Text(Improvy.string("animal_name", "Snail"))
                        .font(.ui(12, .bold))
                        .foregroundStyle(Improvy.colour("animal_color", Ink.mint))
                        .fitted(0.7)
                    Bar(value: Double(Improvy.int("progress_pct")) / 100, colour: Ink.cyan, height: 5)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .surface(Ink.cyan)
        .widgetURL(Improvy.link("stats"))
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
        let caption = atRisk ? Improvy.label("atRisk", "Play today to keep it")
                             : Improvy.label("days", "days in a row")

        Group {
            if wide {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(Ink.ember.opacity(0.16))
                        Flame(size: 26)
                    }
                    .frame(width: 54, height: 54)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak)")
                            .font(.display(42))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .fitted()
                        Text(atRisk ? caption : Improvy.label("dayStreak", "day streak"))
                            .font(.ui(12, .semibold))
                            .foregroundStyle(atRisk ? Ink.gold : Ink.quiet)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .layoutPriority(1)
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing, spacing: 12) {
                        WeekDots(colour: colour, size: 12, letters: true)
                        if atRisk {
                            GlyphButton(system: "play.fill", colour: Ink.gold, size: 36, filled: true)
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Eyebrow(Improvy.label("streak", "STREAK"), symbol: "flame.fill", accent: colour)
                    Spacer(minLength: 4)
                    Text("\(streak)")
                        .font(.display(50))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .fitted()
                    Text(caption)
                        .font(.ui(11, .semibold))
                        .foregroundStyle(atRisk ? Ink.gold : Ink.quiet)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Spacer(minLength: 6)
                    WeekDots(colour: colour, size: 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour, lit: atRisk)
        .widgetURL(Improvy.link("daily"))
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
            Eyebrow(Improvy.label("needsWork", "NEEDS WORK"), symbol: "scope", accent: Ink.rose)
            Spacer(minLength: 6)
            HStack(spacing: 11) {
                KeyBadge(key: key.isEmpty ? "?" : key, colour: colour, size: 50)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(key.isEmpty ? "—" : "\(Improvy.int("weak_pct"))")
                            .font(.display(28))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        if !key.isEmpty {
                            Text("%").font(.display(14, .semibold)).foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    Text(key.isEmpty ? Improvy.label("weakEmpty", "Play a key first")
                                     : Improvy.label("mastered", "mastered"))
                        .font(.ui(10.5, .medium))
                        .foregroundStyle(Ink.quiet)
                        .fitted(0.7)
                }
            }
            Spacer(minLength: 6)
            Text(key.isEmpty ? Improvy.label("weakEmptyHint", "Tap to start training")
                             : Improvy.label("weakHint", "Your weakest key. Tap to train it."))
                .font(.ui(10.5, .medium))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(Ink.rose)
        .widgetURL(Improvy.link(key.isEmpty
                       ? "train"
                       : "key?k=\(key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key)"))
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
        LaunchMode(id: "Daily", glyph: "flame.fill", colour: Ink.gold, url: "daily"),
        LaunchMode(id: "Pocket", glyph: "headphones", colour: Ink.indigo, url: "pocket"),
        LaunchMode(id: "Chromatic", glyph: "music.note", colour: Ink.violet, url: "chromatic"),
        LaunchMode(id: "Custom", glyph: "slider.horizontal.3",
                   colour: Color(red: 0.847, green: 0.341, blue: 0.925), url: "custom"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(Improvy.label("start", "START TRAINING"), symbol: "play.circle.fill", accent: Ink.indigo)
            HStack(spacing: 8) {
                ForEach(Self.modes) { mode in
                    Link(destination: Improvy.link(mode.url)) {
                        VStack(spacing: 8) {
                            GlyphButton(system: mode.glyph, colour: mode.colour, size: 40, filled: true)
                            Text(mode.id)
                                .font(.ui(11, .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .fitted(0.6)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                }
            }
            .frame(maxHeight: .infinity)
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
            Eyebrow(Improvy.label("handsFree", "HANDS-FREE"), symbol: "waveform", accent: Ink.indigo)
            Spacer(minLength: 6)
            GlyphButton(system: "headphones", colour: Ink.indigo, size: 48, filled: true)
            Spacer(minLength: 6)
            Text("Pocket Mode")
                .font(.display(19, .bold))
                .foregroundStyle(.white)
                .fitted(0.6)
            Text(Improvy.label("pocketSub", "Train with the screen off"))
                .font(.ui(11, .medium))
                .foregroundStyle(Ink.quiet)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.top, 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(Ink.indigo)
        .widgetURL(Improvy.link("pocket"))
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
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(colour.opacity(0.14))
                Circle().strokeBorder(colour.opacity(0.30), lineWidth: 1)
                music(Improvy.string("theory_degree", "5"), size: 30)
                    .foregroundStyle(colour)
                    .fitted(0.5)
                    .padding(8)
            }
            .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 6) {
                Eyebrow(Improvy.label("theory", "DEGREE OF THE DAY"), symbol: "book.fill", accent: colour)
                Text(Improvy.string("theory_text", "Open Improvy to see today's card."))
                    .font(.ui(13.5, .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(1.5)
                    .lineLimit(4)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .surface(colour)
        .widgetURL(Improvy.link("theory"))
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
    /// Twelve widgets, in two groups of six.
    ///
    /// `@WidgetBundleBuilder` only has `buildBlock` overloads up to TEN. Past
    /// that it falls to `buildPartialBlock`, which is marked iOS 16.1 while
    /// this extension is built for 16.0 — a bundle resting on an API newer
    /// than the thing it is compiled for, which is the one way a widget
    /// extension installs perfectly and then offers nothing at all.
    ///
    /// Nesting builders is the documented way past the limit and needs
    /// nothing newer than iOS 14. Adding a thirteenth means a third group,
    /// not a longer list.
    var body: some Widget {
        core
        more
    }

    @WidgetBundleBuilder
    var core: some Widget {
        ImprovyQuizWidget()
        ImprovyQuizWideWidget()
        ImprovyDailyWidget()
        ImprovyLevelWidget()
        ImprovyMapWidget()
        ImprovyMapTallWidget()
    }

    @WidgetBundleBuilder
    var more: some Widget {
        ImprovyStreakWidget()
        ImprovyStreakTallWidget()
        ImprovyWeakestWidget()
        ImprovyLauncherWidget()
        ImprovyPocketWidget()
        ImprovyTheoryWidget()
    }
}
