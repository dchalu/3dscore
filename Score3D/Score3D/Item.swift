import Foundation
import SwiftData

@Model
final class Archer {
    var name: String

    init(name: String) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@Model
final class ShootingRound {
    var name: String
    var date: Date
    var firstTarget: Int
    var currentTargetIndex: Int
    var currentArcherIndex: Int
    var highestReachedTargetIndex: Int
    var isFinished: Bool
    var finishedAt: Date?

    @Relationship(deleteRule: .cascade, inverse: \ScoreEntry.round)
    var entries: [ScoreEntry]

    convenience init(name: String, date: Date = .now, firstTarget: Int, archers: [Archer]) {
        self.init(name: name, date: date, firstTarget: firstTarget, archerNames: archers.map(\.name))
    }

    init(name: String, date: Date = .now, firstTarget: Int, archerNames: [String]) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.date = date
        self.firstTarget = firstTarget
        self.currentTargetIndex = 0
        self.currentArcherIndex = 0
        self.highestReachedTargetIndex = 0
        self.isFinished = false
        self.finishedAt = nil
        self.entries = []

        let targetOrder = TargetOrder(firstTarget: firstTarget).targets
        let sortedArcherNames = RoundSetupRules.resolvedPelotonNames(archerNames)

        self.entries = targetOrder.enumerated().flatMap { targetIndex, targetNumber in
            sortedArcherNames.enumerated().map { archerIndex, archerName in
                ScoreEntry(
                    archerName: archerName,
                    archerOrder: archerIndex,
                    targetNumber: targetNumber,
                    targetOrderIndex: targetIndex,
                    round: self
                )
            }
        }
    }

    var targetNumbers: [Int] {
        Array(Set(entries.map(\.targetNumber))).sorted { first, second in
            guard let firstIndex = entries.first(where: { $0.targetNumber == first })?.targetOrderIndex,
                  let secondIndex = entries.first(where: { $0.targetNumber == second })?.targetOrderIndex else {
                return first < second
            }

            return firstIndex < secondIndex
        }
    }

    var archerNames: [String] {
        Array(Set(entries.map(\.archerName))).sorted { first, second in
            guard let firstIndex = entries.first(where: { $0.archerName == first })?.archerOrder,
                  let secondIndex = entries.first(where: { $0.archerName == second })?.archerOrder else {
                return first.localizedCaseInsensitiveCompare(second) == .orderedAscending
            }

            return firstIndex < secondIndex
        }
    }

    var orderedEntries: [ScoreEntry] {
        entries.sorted {
            if $0.targetOrderIndex != $1.targetOrderIndex {
                return $0.targetOrderIndex < $1.targetOrderIndex
            }

            return $0.archerOrder < $1.archerOrder
        }
    }

    var activeEntry: ScoreEntry? {
        entries.first {
            $0.targetOrderIndex == currentTargetIndex && $0.archerOrder == currentArcherIndex
        }
    }

    var currentTargetNumber: Int {
        activeEntry?.targetNumber ?? firstTarget
    }

    var completedTargetCount: Int {
        if isFinished { return 24 }
        return validatedCompletedTargetCount
    }

    var validatedCompletedTargetCount: Int {
        completedTargetIndexes.count
    }

    var canFinish: Bool {
        validatedCompletedTargetCount == 24
    }

    var canFinishAfterValidatingCurrentTarget: Bool {
        let archerCount = archerNames.count
        guard archerCount > 0 else { return false }

        return (0..<24).allSatisfy { targetIndex in
            let targetEntries = entries.filter { $0.targetOrderIndex == targetIndex }
            guard targetEntries.count == archerCount else { return false }

            if targetIndex == currentTargetIndex {
                return targetEntries.allSatisfy(\.hasTwoArrows)
            }

            return targetEntries.allSatisfy { $0.isValidated && $0.hasTwoArrows }
        }
    }

    var total: Int {
        entries.reduce(0) { total, entry in
            total + entry.targetTotal
        }
    }

    func total(for archerName: String) -> Int {
        entries.reduce(0) { total, entry in
            guard entry.archerName == archerName else { return total }
            return total + entry.targetTotal
        }
    }

    func scoreBreakdown(for archerName: String) -> ScoreBreakdown {
        ScoreRules.scoreBreakdown(entries: entries.map(\.snapshot), archerName: archerName)
    }

    private var completedTargetIndexes: Set<Int> {
        let archerCount = archerNames.count
        guard archerCount > 0 else { return [] }

        return Set((0..<24).filter { targetIndex in
            let targetEntries = entries.filter { $0.targetOrderIndex == targetIndex }
            return targetEntries.count == archerCount && targetEntries.allSatisfy { $0.isValidated && $0.hasTwoArrows }
        })
    }
}

@Model
final class ScoreEntry {
    var archerName: String
    var archerOrder: Int
    var targetNumber: Int
    var targetOrderIndex: Int
    var arrow1: Int?
    var arrow2: Int?
    var isValidated: Bool
    var round: ShootingRound?

    init(
        archerName: String,
        archerOrder: Int,
        targetNumber: Int,
        targetOrderIndex: Int,
        round: ShootingRound? = nil
    ) {
        self.archerName = archerName
        self.archerOrder = archerOrder
        self.targetNumber = targetNumber
        self.targetOrderIndex = targetOrderIndex
        self.arrow1 = nil
        self.arrow2 = nil
        self.isValidated = false
        self.round = round
    }

    var targetTotal: Int {
        ScoreRules.targetTotal(arrow1: arrow1, arrow2: arrow2)
    }

    var hasTwoArrows: Bool {
        arrow1 != nil && arrow2 != nil
    }

    var snapshot: ScoreEntrySnapshot {
        ScoreEntrySnapshot(
            archerName: archerName,
            targetNumber: targetNumber,
            arrow1: arrow1,
            arrow2: arrow2
        )
    }
}
