//
//  QuitPlan.swift
//  Kare  (shared: app + widget extension)
//
//  The Exhale widget: for people who have stopped smoking.
//
//  Everything is derived from one date. Days smoke-free, cigarettes not
//  smoked, money kept and how far the lungs have come are all computed from
//  `quitDate` at render time, so the widget stays correct without the app
//  ever running again.
//
//  Nothing here leaves the phone. The plan lives in the App Group container,
//  like Focus and Frame.
//

import Foundation
import WidgetKit

nonisolated struct QuitPlan: Codable, Hashable, Sendable {
    var quitDate: Date
    /// Kept for plans saved before packs were asked for. New plans set
    /// `packsPerDay` instead, which is how most smokers count.
    var cigarettesPerDay: Int
    /// "Günde bir buçuk paket". Nil on plans saved before this existed.
    var packsPerDay: Double?
    var packPrice: Double
    var cigarettesPerPack: Int
    var currencyCode: String
    /// How many times the counter has been started over. Shown gently in the
    /// app, never on the widget: a slip is not a headline.
    var restarts: Int = 0
    /// While in the future, the widget draws the lungs full: the "breath"
    /// the user asked for by tapping.
    var breathUntil: Date?
    /// Restarting from a widget is one tap away from an accident, so the
    /// first tap only arms it. A second tap before this passes restarts.
    var resetArmedUntil: Date?

    static var defaultCurrencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    static func starting(now: Date = .now) -> QuitPlan {
        let currency = defaultCurrencyCode
        return QuitPlan(
            quitDate: now,
            cigarettesPerDay: 20,
            packsPerDay: 1,
            // A starting guess the user corrects, not a claim about prices.
            packPrice: currency == "TRY" ? 100 : 8,
            cigarettesPerPack: 20,
            currencyCode: currency
        )
    }

    /// Cigarettes a day, from packs when the user gave packs.
    var dailyCigarettes: Double {
        if let packsPerDay { return packsPerDay * Double(cigarettesPerPack) }
        return Double(cigarettesPerDay)
    }

    /// What smoking used to cost in a day.
    var dailyCost: Double {
        guard cigarettesPerPack > 0 else { return 0 }
        return dailyCigarettes / Double(cigarettesPerPack) * packPrice
    }

    func money(_ amount: Double) -> String {
        amount.formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(WidgetLanguage.locale))
    }

    // MARK: Derived

    func elapsed(at date: Date = .now) -> TimeInterval {
        max(0, date.timeIntervalSince(quitDate))
    }

    func days(at date: Date = .now) -> Int {
        Int(elapsed(at: date) / 86_400)
    }

    func hours(at date: Date = .now) -> Int {
        Int(elapsed(at: date) / 3_600)
    }

    func cigarettesAvoided(at date: Date = .now) -> Int {
        Int(elapsed(at: date) / 86_400 * dailyCigarettes)
    }

    func moneySaved(at date: Date = .now) -> Double {
        elapsed(at: date) / 86_400 * dailyCost
    }

    func moneyText(at date: Date = .now) -> String {
        money(moneySaved(at: date))
    }

    /// Estimated time of life no longer being lost, at 20 minutes per
    /// cigarette (Jackson et al., UCL, Journal of Addiction, 2024). An
    /// average across smokers, and shown as an estimate.
    static let minutesPerCigarette: Double = 20

    func lifeRegained(at date: Date = .now) -> TimeInterval {
        Double(cigarettesAvoided(at: date)) * Self.minutesPerCigarette * 60
    }

    func lifeRegainedText(at date: Date = .now) -> String {
        let seconds = lifeRegained(at: date)
        let formatter = DateComponentsFormatter()
        formatter.calendar = WidgetLanguage.calendar
        formatter.allowedUnits = seconds >= 86_400 ? [.day, .hour] : [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        return formatter.string(from: seconds) ?? ""
    }

    /// How full the lungs are drawn, 0...1, following the recovery milestones.
    func recovery(at date: Date = .now) -> Double {
        QuitMilestone.recovery(after: elapsed(at: date))
    }

    func isBreathing(at date: Date = .now) -> Bool {
        guard let breathUntil else { return false }
        return date < breathUntil
    }

    func isResetArmed(at date: Date = .now) -> Bool {
        guard let resetArmedUntil else { return false }
        return date < resetArmedUntil
    }

    /// The level the widget actually draws: full while breathing, otherwise
    /// the real recovery.
    func drawnLevel(at date: Date = .now) -> Double {
        isBreathing(at: date) ? 1 : recovery(at: date)
    }

    func nextMilestone(at date: Date = .now) -> QuitMilestone? {
        let elapsed = elapsed(at: date)
        return QuitMilestone.all.first { $0.after > elapsed }
    }

    /// The most recent change the body has been through.
    func currentMilestone(at date: Date = .now) -> QuitMilestone? {
        let elapsed = elapsed(at: date)
        return QuitMilestone.all.last { $0.after <= elapsed }
    }

    func milestonesReached(at date: Date = .now) -> Int {
        let elapsed = elapsed(at: date)
        return QuitMilestone.all.filter { $0.after <= elapsed }.count
    }

    func stage(at date: Date = .now) -> QuitStage {
        QuitStage.at(recovery: recovery(at: date))
    }
}

// MARK: - Stages

/// The four chapters of the widget's artwork. The picture behind the lungs
/// moves from haze to open air as the body recovers, so a glance tells you
/// how far you have come before you read a number.
nonisolated enum QuitStage: String, CaseIterable, Sendable {
    /// The first hours. Smoke still in the air.
    case haze
    /// Up to two weeks. The haze lifting at first light.
    case dawn
    /// Up to nine months. Green, damp, breathable.
    case forest
    /// Beyond. Clear mountain air.
    case summit

    static func at(recovery: Double) -> QuitStage {
        switch recovery {
        case ..<0.12: .haze
        case ..<0.40: .dawn
        case ..<0.84: .forest
        default: .summit
        }
    }

    /// Asset name of the background. `-wide` is added for medium widgets.
    var art: String { "exhale-bg-\(rawValue)" }

    var titleKey: String {
        switch self {
        case .haze: "The first day"
        case .dawn: "The air is clearing"
        case .forest: "Breathing easier"
        case .summit: "Free air"
        }
    }

    /// Fallback gradient while there is no artwork.
    var fallbackHexes: [String] {
        switch self {
        case .haze: ["2B2D31", "4A4A4F"]
        case .dawn: ["1F2A44", "B5838D"]
        case .forest: ["0B1F1D", "124A42"]
        case .summit: ["0E3B5C", "5FB3C9"]
        }
    }
}

// MARK: - Milestones

/// Which part of the body a milestone is about. Drawn as an icon next to it.
nonisolated enum BodyPart: String, Sendable {
    case heart, blood, senses, lungs, energy, brain

    var symbolName: String {
        switch self {
        case .heart: "heart.fill"
        case .blood: "drop.fill"
        case .senses: "nose.fill"
        case .lungs: "lungs.fill"
        case .energy: "bolt.fill"
        case .brain: "brain.head.profile"
        }
    }
}

/// What happens to the body after the last cigarette.
///
/// From the World Health Organization ("Tobacco: health benefits of smoking
/// cessation") and the NHS quit-smoking timeline. The wording stays close to
/// theirs on purpose: this is health information and should not be improved
/// upon. Where the sources give a range (WHO: "2 to 12 weeks"), the milestone
/// sits at the start of it and the detail says it keeps going.
nonisolated struct QuitMilestone: Hashable, Sendable, Identifiable {
    /// Seconds after quitting.
    let after: TimeInterval
    let part: BodyPart
    /// Short headline. A string-catalogue key, localized where it is drawn.
    let titleKey: String
    /// One or two sentences on what is happening. Also a catalogue key.
    let detailKey: String
    /// How full the lungs are drawn once this is reached. Nil for the
    /// long-term milestones after the first year, when the lungs are full.
    let level: Double?

    var id: TimeInterval { after }

    private static let hour: TimeInterval = 3_600
    private static let day: TimeInterval = 86_400

    static let all: [QuitMilestone] = [
        QuitMilestone(after: 20 * 60, part: .heart,
                      titleKey: "Heart rate and blood pressure drop",
                      detailKey: "Your pulse is already returning to normal.",
                      level: 0.03),
        QuitMilestone(after: 8 * hour, part: .blood,
                      titleKey: "Oxygen levels are recovering",
                      detailKey: "Carbon monoxide is leaving your blood, and oxygen levels start returning to normal.",
                      level: 0.08),
        QuitMilestone(after: 12 * hour, part: .blood,
                      titleKey: "Carbon monoxide in your blood drops to normal",
                      detailKey: "Your blood carries oxygen the way it did before you smoked.",
                      level: 0.12),
        QuitMilestone(after: 48 * hour, part: .senses,
                      titleKey: "Taste and smell improve",
                      detailKey: "Your lungs start clearing out mucus, and food begins to taste and smell like it used to.",
                      level: 0.18),
        QuitMilestone(after: 72 * hour, part: .energy,
                      titleKey: "Breathing gets easier",
                      detailKey: "Your bronchial tubes begin to relax and your energy levels start to rise.",
                      level: 0.24),
        QuitMilestone(after: 14 * day, part: .lungs,
                      titleKey: "Circulation improves and lung function increases",
                      detailKey: "Between two and twelve weeks, blood flows better and your lungs work better. Walking and climbing stairs get easier.",
                      level: 0.40),
        QuitMilestone(after: 90 * day, part: .lungs,
                      titleKey: "Coughing and wheezing improve",
                      detailKey: "From three months, coughs, wheezing and breathing problems start to ease as your lungs clear.",
                      level: 0.62),
        QuitMilestone(after: 270 * day, part: .lungs,
                      titleKey: "Coughing and shortness of breath decrease",
                      detailKey: "By nine months your lungs are much better at cleaning themselves, and breathlessness is well down.",
                      level: 0.84),
        QuitMilestone(after: 365 * day, part: .heart,
                      titleKey: "Heart disease risk is about half a smoker's",
                      detailKey: "One year in, your risk of coronary heart disease is about half that of someone who still smokes.",
                      level: 1.0),
        QuitMilestone(after: 5 * 365 * day, part: .brain,
                      titleKey: "Stroke risk falls toward a non-smoker's",
                      detailKey: "Between five and fifteen years, your stroke risk falls to that of someone who never smoked.",
                      level: nil),
        QuitMilestone(after: 10 * 365 * day, part: .lungs,
                      titleKey: "Lung cancer risk is about half a smoker's",
                      detailKey: "Ten years in, your risk of lung cancer is about half a smoker's, and the risk of several other cancers falls too.",
                      level: nil),
        QuitMilestone(after: 15 * 365 * day, part: .heart,
                      titleKey: "Heart disease risk is the same as a non-smoker's",
                      detailKey: "Fifteen years in, your risk of coronary heart disease is that of someone who never smoked.",
                      level: nil)
    ]

    /// Linear between milestones, so the lungs visibly move in the first
    /// hours, when it matters most, and keep moving for a year.
    static func recovery(after elapsed: TimeInterval) -> Double {
        var previousTime: TimeInterval = 0
        var previousLevel = 0.0
        for milestone in all {
            guard let level = milestone.level else { break }
            if elapsed < milestone.after {
                let span = milestone.after - previousTime
                let t = span > 0 ? (elapsed - previousTime) / span : 1
                return previousLevel + (level - previousLevel) * t
            }
            previousTime = milestone.after
            previousLevel = level
        }
        return 1
    }

    /// 0...1 progress from the previous milestone to this one.
    func progress(from elapsed: TimeInterval) -> Double {
        let index = QuitMilestone.all.firstIndex(of: self) ?? 0
        let start = index > 0 ? QuitMilestone.all[index - 1].after : 0
        let span = after - start
        guard span > 0 else { return 1 }
        return min(1, max(0, (elapsed - start) / span))
    }

    /// "in 3 days", "in 5 hours": time left until this milestone.
    func remainingText(from elapsed: TimeInterval) -> String {
        let left = max(0, after - elapsed)
        let formatter = DateComponentsFormatter()
        formatter.calendar = WidgetLanguage.calendar
        formatter.allowedUnits = left >= 86_400 ? [.day] : (left >= 3_600 ? [.hour] : [.minute])
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 1
        return formatter.string(from: max(60, left)) ?? ""
    }
}

// MARK: - Store

nonisolated enum QuitStore {
    static let widgetKind = "ExhaleWidget"
    private static let fileName = "exhale-plan.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetStore.appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func load() -> QuitPlan? {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(QuitPlan.self, from: data)
    }

    static func save(_ plan: QuitPlan) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(plan) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func update(_ change: (inout QuitPlan) -> Void) {
        guard var plan = load() else { return }
        change(&plan)
        save(plan)
    }

    /// Start the count again from now. Money and cigarettes restart with it,
    /// because they are derived from the same date.
    static func restart(now: Date = .now) {
        update { plan in
            plan.quitDate = now
            plan.restarts += 1
            plan.breathUntil = nil
            plan.resetArmedUntil = nil
        }
    }
}
