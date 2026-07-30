import SwiftUI
import WidgetKit

// MARK: - Shared data
//
// These widgets only ever *render*. Every string arrives already formatted from
// `lib/services/widget_service.dart`, which owns notation (C-D-E vs Do-Re-Mi),
// accidental spelling and wording — re-deriving any of it here would let the
// widget and the app drift apart.
//
// The data crosses over through the App Group shared with the app (home_widget
// writes into `UserDefaults(suiteName:)`). The group ID must match
// `WidgetService.iOSAppGroupId` in Dart and the App Group capability on BOTH
// targets in Xcode.

enum Improvy {
    static let appGroupId = "group.com.improvy.app.widget"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroupId) }

    /// home_widget prefixes every key it writes.
    static func string(_ key: String) -> String? {
        defaults?.string(forKey: key)
    }

    static func int(_ key: String) -> Int {
        defaults?.integer(forKey: key) ?? 0
    }

    static func bool(_ key: String) -> Bool {
        defaults?.bool(forKey: key) ?? false
    }

    /// Days since 1970-01-01 for a local calendar date.
    ///
    /// Built as a **UTC** instant from the local Y/M/D on purpose: using local
    /// midnight would land on the previous day east of Greenwich. Dart
    /// (`DateTime.utc(y, m, d)`) and Kotlin do the identical construction —
    /// they must agree, or the rotation reads the wrong hour.
    static func localEpochDay(_ date: Date) -> Int {
        var local = Calendar(identifier: .gregorian)
        local.timeZone = .current
        let c = local.dateComponents([.year, .month, .day], from: date)

        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        var utcComponents = DateComponents()
        utcComponents.year = c.year
        utcComponents.month = c.month
        utcComponents.day = c.day
        guard let midnight = utc.date(from: utcComponents) else { return 0 }
        return Int(midnight.timeIntervalSince1970 / 86_400)
    }

    /// Absolute hour slot — hours since the epoch, in local calendar terms.
    static func slot(for date: Date) -> Int {
        localEpochDay(date) * 24 + Calendar.current.component(.hour, from: date)
    }
}

// MARK: - Design tokens (mirrors the app's card surface)

private extension Color {
    static let improvyTop = Color(red: 0.133, green: 0.094, blue: 0.188)     // #221830
    static let improvyBottom = Color(red: 0.078, green: 0.063, blue: 0.125)  // #141020
    static let improvyGold = Color(red: 0.988, green: 0.827, blue: 0.302)    // #FCD34D
}

private struct ImprovySurface: ViewModifier {
    var gold: Bool = false

    func body(content: Content) -> some View {
        let gradient = LinearGradient(
            colors: [.improvyTop, .improvyBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        if #available(iOS 17.0, *) {
            content
                .containerBackground(for: .widget) { gradient }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(
                            gold ? Color.improvyGold.opacity(0.55) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        } else {
            content.background(gradient)
        }
    }
}

private extension View {
    func improvySurface(gold: Bool = false) -> some View {
        modifier(ImprovySurface(gold: gold))
    }
}

// MARK: - Quiz widget ("the little question")
//
// The answer is withheld on purpose: the unresolved question is what makes the
// widget worth keeping on a home screen, and the tap that resolves it opens the
// app on the reveal.

struct QuizEntry: TimelineEntry {
    let date: Date
    let question: String
    /// The absolute slot actually shown — handed back on tap so the app can
    /// rebuild exactly this question.
    let slot: Int
}

struct QuizProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuizEntry {
        QuizEntry(date: Date(), question: "♭3 of E♭", slot: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuizEntry) -> Void) {
        completion(entry(for: Date()))
    }

    /// One entry per hour for a day ahead. The rotation itself is written a week
    /// ahead by the app, so an untouched phone keeps turning over.
    func getTimeline(in context: Context, completion: @escaping (Timeline<QuizEntry>) -> Void) {
        let calendar = Calendar.current
        let start = calendar.date(bySetting: .minute, value: 0, of: Date()) ?? Date()
        let entries = (0..<24).compactMap { offset -> QuizEntry? in
            guard let date = calendar.date(byAdding: .hour, value: offset, to: start) else { return nil }
            return entry(for: date)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> QuizEntry {
        let fallback = QuizEntry(date: date, question: "Open Improvy", slot: Improvy.slot(for: date))
        guard
            let raw = Improvy.string("quiz_json"),
            let data = raw.data(using: .utf8),
            let list = (try? JSONSerialization.jsonObject(with: data)) as? [[String: String]],
            !list.isEmpty
        else { return fallback }

        let base = Improvy.int("quiz_base_slot")
        let offset = Improvy.slot(for: date) - base
        // Past the end of the written week the rotation wraps rather than going
        // blank; the next app launch rewrites it anyway.
        let index = ((offset % list.count) + list.count) % list.count
        return QuizEntry(
            date: date,
            question: list[index]["q"] ?? fallback.question,
            // The slot actually shown, not the wall clock — after a wrap they
            // differ, and the app must reveal what the user was looking at.
            slot: base + index
        )
    }
}

struct QuizWidgetView: View {
    var entry: QuizEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("TODAY'S QUESTION")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .kerning(1.6)
                .foregroundStyle(Color.improvyGold)
            Spacer(minLength: 8)
            Text(entry.question)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
            Spacer(minLength: 8)
            Text("Tap to reveal the answer")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .improvySurface()
        .widgetURL(URL(string: "improvy://quiz?s=\(entry.slot)"))
    }
}

struct ImprovyQuizWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyQuizWidget", provider: QuizProvider()) { entry in
            QuizWidgetView(entry: entry)
        }
        .configurationDisplayName("Improvy · Question")
        .description("A scale degree to answer, refreshed every hour. Tap to reveal it in the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Daily Challenge widget

struct DailyEntry: TimelineEntry {
    let date: Date
    let played: Bool
    let key: String
    let score: String
    let grid: String
    let streak: Int
}

struct DailyProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(date: Date(), played: false, key: "B♭", score: "", grid: "", streak: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        completion(current())
    }

    /// Refresh on the hour, and again right after midnight — that's when an
    /// unplayed challenge becomes a new one.
    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        let now = Date()
        var dates: [Date] = []
        let calendar = Calendar.current
        if let hour = calendar.date(bySetting: .minute, value: 0, of: now) {
            for offset in 0..<12 {
                if let d = calendar.date(byAdding: .hour, value: offset, to: hour) { dates.append(d) }
            }
        }
        if let midnight = calendar.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 1),
            matchingPolicy: .nextTime
        ) {
            dates.append(midnight)
        }
        let state = current()
        let entries = dates.map {
            DailyEntry(date: $0, played: state.played, key: state.key,
                       score: state.score, grid: state.grid, streak: state.streak)
        }
        completion(Timeline(entries: entries.isEmpty ? [state] : entries, policy: .atEnd))
    }

    private func current() -> DailyEntry {
        DailyEntry(
            date: Date(),
            played: Improvy.bool("daily_played"),
            key: Improvy.string("daily_key") ?? "",
            score: Improvy.string("daily_score") ?? "",
            grid: Improvy.string("daily_grid") ?? "",
            streak: Improvy.int("daily_streak")
        )
    }
}

struct DailyWidgetView: View {
    var entry: DailyEntry

    private var headline: String {
        if entry.played { return entry.score.isEmpty ? "Done" : entry.score }
        return entry.key.isEmpty ? "Daily Challenge" : "Key of \(entry.key)"
    }

    private var sub: String {
        if entry.played {
            return entry.grid.isEmpty ? "Next challenge tomorrow" : entry.grid
        }
        return "10 questions · beat the clock"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Text("DAILY CHALLENGE")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .kerning(1.6)
                    .foregroundStyle(Color.improvyGold)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Text("🔥 \(entry.streak)")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(Color.improvyGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(Color.improvyGold.opacity(0.10))
                            .overlay(Capsule().strokeBorder(Color.improvyGold.opacity(0.28)))
                    )
            }
            Spacer(minLength: 8)
            Text(headline)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Spacer(minLength: 6)
            Text(sub)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Gold frame only while there is still something to do today.
        .improvySurface(gold: !entry.played)
        .widgetURL(URL(string: "improvy://daily"))
    }
}

struct ImprovyDailyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ImprovyDailyWidget", provider: DailyProvider()) { entry in
            DailyWidgetView(entry: entry)
        }
        .configurationDisplayName("Improvy · Daily Challenge")
        .description("The key of the day, your score and your streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle

@main
struct ImprovyWidgetBundle: WidgetBundle {
    var body: some Widget {
        ImprovyQuizWidget()
        ImprovyDailyWidget()
    }
}
