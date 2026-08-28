import Foundation

nonisolated enum ArrowScore: Int, CaseIterable, Identifiable, Sendable {
    case eleven = 11
    case ten = 10
    case eight = 8
    case five = 5
    case miss = 0

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .miss:
            return "M"
        default:
            return String(rawValue)
        }
    }
}

nonisolated struct TargetOrder: Equatable, Sendable {
    let targets: [Int]

    init(firstTarget: Int, targetCount: Int = 24) {
        let clampedFirstTarget = min(max(firstTarget, 1), targetCount)
        targets = Array(clampedFirstTarget...targetCount) + Array(1..<clampedFirstTarget)
    }
}

nonisolated struct ScoreRules: Sendable {
    static func targetTotal(arrow1: Int?, arrow2: Int?) -> Int {
        (arrow1 ?? 0) + (arrow2 ?? 0)
    }

    static func roundTotal(entries: [ScoreEntrySnapshot], archerName: String? = nil) -> Int {
        entries.reduce(0) { total, entry in
            guard archerName == nil || entry.archerName == archerName else {
                return total
            }

            return total + targetTotal(arrow1: entry.arrow1, arrow2: entry.arrow2)
        }
    }

    static func displayValue(_ value: Int?) -> String {
        guard let value else { return "-" }
        return value == 0 ? "M" : String(value)
    }

    static func scoreBreakdown(entries: [ScoreEntrySnapshot], archerName: String) -> ScoreBreakdown {
        entries.reduce(into: ScoreBreakdown(archerName: archerName)) { breakdown, entry in
            guard entry.archerName == archerName else { return }
            breakdown.total += targetTotal(arrow1: entry.arrow1, arrow2: entry.arrow2)
            breakdown.record(entry.arrow1)
            breakdown.record(entry.arrow2)
        }
    }
}

nonisolated struct ScoreBreakdown: Equatable, Sendable {
    let archerName: String
    var total = 0
    var elevens = 0
    var tens = 0
    var eights = 0
    var fives = 0
    var misses = 0

    mutating func record(_ value: Int?) {
        switch value {
        case 11:
            elevens += 1
        case 10:
            tens += 1
        case 8:
            eights += 1
        case 5:
            fives += 1
        case 0:
            misses += 1
        default:
            break
        }
    }
}

nonisolated struct ArcherScoreSheet: Equatable, Identifiable, Sendable {
    let roundName: String
    let roundDate: Date
    let archerName: String
    let rows: [ArcherScoreSheetRow]
    let breakdown: ScoreBreakdown

    var id: String {
        "\(roundName)-\(roundDate.timeIntervalSince1970)-\(archerName)"
    }

    var shareTitle: String {
        "\(roundName) - \(archerName)"
    }
}

nonisolated struct ArcherScoreSheetRow: Equatable, Sendable {
    let targetNumber: Int
    let arrow1: Int?
    let arrow2: Int?
    let targetTotal: Int
    let cumulativeTotal: Int
}

nonisolated struct ScoreSheetFormatter: Sendable {
    static func makeSheet(
        roundName: String,
        roundDate: Date,
        archerName: String,
        entries: [ScoreEntrySnapshot]
    ) -> ArcherScoreSheet {
        var cumulativeTotal = 0
        let archerEntries = entries.filter { $0.archerName == archerName }
        let rows = archerEntries.map { entry in
            let targetTotal = ScoreRules.targetTotal(arrow1: entry.arrow1, arrow2: entry.arrow2)
            let displayArrows = orderedDisplayArrows(arrow1: entry.arrow1, arrow2: entry.arrow2)
            cumulativeTotal += targetTotal

            return ArcherScoreSheetRow(
                targetNumber: entry.targetNumber,
                arrow1: displayArrows.first,
                arrow2: displayArrows.second,
                targetTotal: targetTotal,
                cumulativeTotal: cumulativeTotal
            )
        }

        return ArcherScoreSheet(
            roundName: roundName,
            roundDate: roundDate,
            archerName: archerName,
            rows: rows,
            breakdown: ScoreRules.scoreBreakdown(entries: entries, archerName: archerName)
        )
    }

    static func orderedDisplayArrows(arrow1: Int?, arrow2: Int?) -> (first: Int?, second: Int?) {
        guard let arrow1 else { return (arrow2, nil) }
        guard let arrow2 else { return (arrow1, nil) }
        return arrow1 >= arrow2 ? (arrow1, arrow2) : (arrow2, arrow1)
    }
}

nonisolated struct RoundSetupRules: Sendable {
    static func defaultRoundName(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return "Parcours du \(formatter.string(from: date))"
    }

    static func normalizedArcherName(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func sortedArcherNames(_ names: [String]) -> [String] {
        names
            .map(normalizedArcherName)
            .filter { !$0.isEmpty }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func resolvedPelotonNames(_ names: [String]) -> [String] {
        names.enumerated()
            .map { index, name in
                let normalizedName = normalizedArcherName(name)
                return normalizedName.isEmpty ? "Archer \(index + 1)" : normalizedName
            }
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
    }

    static func uniqueRoundName(
        baseName: String,
        date: Date,
        existingRounds: [RoundListSnapshot],
        calendar: Calendar = .current
    ) -> String {
        let normalizedBaseName = normalizedArcherName(baseName)
        let resolvedBaseName = normalizedBaseName.isEmpty ? defaultRoundName(for: date) : normalizedBaseName
        let sameDayNames = Set(
            existingRounds
                .filter { calendar.isDate($0.date, inSameDayAs: date) }
                .map(\.name)
        )

        guard sameDayNames.contains(resolvedBaseName) else {
            return resolvedBaseName
        }

        var suffix = 2
        while sameDayNames.contains("\(resolvedBaseName) \(suffix)") {
            suffix += 1
        }

        return "\(resolvedBaseName) \(suffix)"
    }

    static func containsDuplicateArcherNames(_ names: [String]) -> Bool {
        var seenNames = Set<String>()

        for name in names.map(normalizedArcherName).filter({ !$0.isEmpty }) {
            let key = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            guard seenNames.insert(key).inserted else {
                return true
            }
        }

        return false
    }

    static func canAddArcherSlot(currentSlotCount: Int) -> Bool {
        currentSlotCount < 6
    }

    static func canRemoveArcherSlot(currentSlotCount: Int) -> Bool {
        currentSlotCount > 1
    }
}

nonisolated struct RoundListRules: Sendable {
    static func sortNewestFirst(_ rounds: [RoundListSnapshot]) -> [RoundListSnapshot] {
        rounds.sorted { $0.date > $1.date }
    }

    static func completedTargetCount(
        targetCount: Int = 24,
        archerCount: Int,
        validatedTargetArchers: [Int: Set<Int>]
    ) -> Int {
        guard archerCount > 0 else { return 0 }

        return (0..<targetCount).filter { targetIndex in
            validatedTargetArchers[targetIndex]?.count == archerCount
        }.count
    }

    static func statusLabel(isFinished: Bool) -> String {
        isFinished ? "Terminé" : "En cours"
    }

    static func destination(isFinished: Bool) -> RoundOpenDestination {
        isFinished ? .summary : .scoring
    }
}

nonisolated enum RoundOpenDestination: Equatable, Sendable {
    case scoring
    case summary
}

nonisolated struct RoundListSnapshot: Equatable, Sendable {
    var name: String
    var date: Date
    var isFinished: Bool
}

nonisolated struct RoundDraftSettings: Equatable, Sendable {
    var name: String
    var date: Date
    var firstTarget: Int
    private var generatedName: String
    private var isUsingGeneratedName = true

    init(date: Date) {
        self.date = date
        self.firstTarget = 1
        self.generatedName = RoundSetupRules.defaultRoundName(for: date)
        self.name = generatedName
    }

    mutating func updateDate(_ newDate: Date) {
        date = newDate
        let nextGeneratedName = RoundSetupRules.defaultRoundName(for: newDate)
        if isUsingGeneratedName {
            name = nextGeneratedName
        }
        generatedName = nextGeneratedName
    }

    mutating func userDidCustomizeName(_ newName: String) {
        isUsingGeneratedName = newName == generatedName
    }
}

nonisolated struct ScoreEntrySnapshot: Equatable, Sendable {
    var archerName: String
    var targetNumber: Int
    var arrow1: Int?
    var arrow2: Int?
}

nonisolated enum ArrowSlot: Equatable, Sendable {
    case first
    case second
}

nonisolated struct ArrowInputRules: Sendable {
    static func initialSelection(arrow1: Int?, arrow2: Int?) -> ArrowSlot? {
        if arrow1 == nil { return .first }
        if arrow2 == nil { return .second }
        return nil
    }

    static func isScoreInputEnabled(selectedArrow: ArrowSlot?) -> Bool {
        selectedArrow != nil
    }

    static func selectionAfterScoring(_ selectedArrow: ArrowSlot?) -> ArrowSlot? {
        switch selectedArrow {
        case .first:
            return .second
        case .second, nil:
            return nil
        }
    }
}

nonisolated struct ScoringNavigationState: Equatable, Sendable {
    var targetIndex: Int
    var archerIndex: Int
    var highestReachedTargetIndex: Int
    var correctionReturnArcherIndex: Int?
    let archerCount: Int
    let targetCount: Int
    let validatedArcherIndexes: Set<Int>
    let scoredArcherIndexes: Set<Int>

    var completedArcherCount: Int {
        scoredArcherIndexes.count
    }

    var progressValue: Double {
        Double(targetIndex + 1) / Double(targetCount)
    }

    var allArchersScored: Bool {
        scoredArcherIndexes.count >= archerCount
    }

    var canMoveToPreviousTarget: Bool {
        targetIndex > 0
    }

    var canMoveToNextReachedTarget: Bool {
        targetIndex < highestReachedTargetIndex
    }

    var primaryAction: ScoringPrimaryAction {
        if allArchersScored {
            return targetIndex == targetCount - 1 ? .finishRound : .nextTarget
        }

        return .validateArcher
    }

    func selectingArcher(_ selectedIndex: Int) -> ScoringNavigationState {
        guard selectedIndex >= 0 && selectedIndex < archerCount else { return self }

        let shouldEnterCorrection = targetIndex == highestReachedTargetIndex
            && scoredArcherIndexes.contains(selectedIndex)
            && selectedIndex != archerIndex
            && correctionReturnArcherIndex == nil

        return ScoringNavigationState(
            targetIndex: targetIndex,
            archerIndex: selectedIndex,
            highestReachedTargetIndex: highestReachedTargetIndex,
            correctionReturnArcherIndex: shouldEnterCorrection ? archerIndex : correctionReturnArcherIndex,
            archerCount: archerCount,
            targetCount: targetCount,
            validatedArcherIndexes: validatedArcherIndexes,
            scoredArcherIndexes: scoredArcherIndexes
        )
    }

    func validatingCurrentArcher() -> ScoringNavigationState {
        let nextValidatedIndexes = validatedArcherIndexes.union([archerIndex])

        if let correctionReturnArcherIndex {
            return ScoringNavigationState(
                targetIndex: targetIndex,
                archerIndex: correctionReturnArcherIndex,
                highestReachedTargetIndex: highestReachedTargetIndex,
                correctionReturnArcherIndex: nil,
                archerCount: archerCount,
                targetCount: targetCount,
                validatedArcherIndexes: nextValidatedIndexes,
                scoredArcherIndexes: scoredArcherIndexes
            )
        }

        return ScoringNavigationState(
            targetIndex: targetIndex,
            archerIndex: nextIncompleteArcherIndex(afterAdding: archerIndex),
            highestReachedTargetIndex: highestReachedTargetIndex,
            correctionReturnArcherIndex: nil,
            archerCount: archerCount,
            targetCount: targetCount,
            validatedArcherIndexes: nextValidatedIndexes,
            scoredArcherIndexes: scoredArcherIndexes.union([archerIndex])
        )
    }

    func openingNextTarget() -> ScoringNavigationState {
        guard allArchersScored, targetIndex < targetCount - 1 else { return self }
        let nextTargetIndex = targetIndex + 1

        return ScoringNavigationState(
            targetIndex: nextTargetIndex,
            archerIndex: 0,
            highestReachedTargetIndex: max(highestReachedTargetIndex, nextTargetIndex),
            correctionReturnArcherIndex: nil,
            archerCount: archerCount,
            targetCount: targetCount,
            validatedArcherIndexes: [],
            scoredArcherIndexes: []
        )
    }

    func swipingToPreviousTarget() -> ScoringNavigationState {
        guard canMoveToPreviousTarget else { return self }
        return movedToTarget(targetIndex - 1)
    }

    func swipingToNextReachedTarget() -> ScoringNavigationState {
        guard canMoveToNextReachedTarget else { return self }
        return movedToTarget(targetIndex + 1)
    }

    private func movedToTarget(_ nextTargetIndex: Int) -> ScoringNavigationState {
        ScoringNavigationState(
            targetIndex: nextTargetIndex,
            archerIndex: 0,
            highestReachedTargetIndex: highestReachedTargetIndex,
            correctionReturnArcherIndex: nil,
            archerCount: archerCount,
            targetCount: targetCount,
            validatedArcherIndexes: [],
            scoredArcherIndexes: []
        )
    }

    private func nextIncompleteArcherIndex(afterAdding completedIndex: Int) -> Int {
        let nextScoredIndexes = scoredArcherIndexes.union([completedIndex])
        guard nextScoredIndexes.count < archerCount else { return archerIndex }

        let orderedIndexes = Array((completedIndex + 1)..<archerCount) + Array(0...completedIndex)
        return orderedIndexes.first { !nextScoredIndexes.contains($0) } ?? archerIndex
    }
}

nonisolated enum ScoringPrimaryAction: Equatable, Sendable {
    case validateArcher
    case validateCorrection
    case nextTarget
    case finishRound
}

nonisolated struct RoundProgress: Equatable, Sendable {
    var targetIndex: Int
    var archerIndex: Int
    let archerCount: Int
    let targetCount: Int

    var canGoToPreviousArcher: Bool {
        archerIndex > 0
    }

    var isLastArcher: Bool {
        archerIndex == archerCount - 1
    }

    var isLastTarget: Bool {
        targetIndex == targetCount - 1
    }

    var nextAction: RoundNextAction {
        if isLastArcher && isLastTarget {
            return .finishRound
        }

        if isLastArcher {
            return .nextTarget
        }

        return .nextArcher
    }

    mutating func moveToPreviousArcher() {
        guard canGoToPreviousArcher else { return }
        archerIndex -= 1
    }

    mutating func moveForward() -> RoundNextAction {
        let action = nextAction

        switch action {
        case .nextArcher:
            archerIndex += 1
        case .nextTarget:
            targetIndex += 1
            archerIndex = 0
        case .finishRound:
            break
        }

        return action
    }
}

nonisolated enum RoundNextAction: Equatable, Sendable {
    case nextArcher
    case nextTarget
    case finishRound
}
