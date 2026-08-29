import Foundation
import SwiftData
import Testing
@testable import Score3D

struct ScoreRulesTests {
    @Test func ffta3DScoreValuesDisplayMissAsM() {
        #expect(ArrowScore.allCases.map(\.rawValue) == [11, 10, 8, 5, 0])
        #expect(ArrowScore.allCases.map(\.label) == ["11", "10", "8", "5", "M"])
        #expect(ScoreRules.displayValue(0) == "M")
        #expect(ScoreRules.displayValue(nil) == "-")
    }

    @Test func targetOrderWrapsFromConfiguredFirstTarget() {
        let order = TargetOrder(firstTarget: 17).targets

        #expect(order.count == 24)
        #expect(Array(order.prefix(8)) == [17, 18, 19, 20, 21, 22, 23, 24])
        #expect(Array(order.suffix(16)) == Array(1...16))
    }

    @Test func homeRoundsAreSortedNewestFirstAndShowStatus() {
        let calendar = Calendar(identifier: .gregorian)
        let olderDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 26))!
        let newerDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 27))!
        let rounds = [
            RoundListSnapshot(name: "Ancien", date: olderDate, isFinished: true),
            RoundListSnapshot(name: "Récent", date: newerDate, isFinished: false),
        ]

        #expect(RoundListRules.sortNewestFirst(rounds).map(\.name) == ["Récent", "Ancien"])
        #expect(RoundListRules.statusLabel(isFinished: false) == "En cours")
        #expect(RoundListRules.statusLabel(isFinished: true) == "Terminé")
        #expect(RoundListRules.destination(isFinished: false) == .scoring)
        #expect(RoundListRules.destination(isFinished: true) == .summary)
    }

    @Test func completedTargetsRequireEveryArcherValidatedOnTarget() {
        let completedTargets = RoundListRules.completedTargetCount(
            archerCount: 3,
            validatedTargetArchers: [
                0: [0, 1, 2],
                1: [0, 1],
                2: [0, 1, 2],
            ]
        )

        #expect(completedTargets == 2)
    }

    @Test func defaultRoundNameTracksDateUntilUserCustomizesIt() {
        let calendar = Calendar(identifier: .gregorian)
        let firstDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 27))!
        let secondDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28))!
        var settings = RoundDraftSettings(date: firstDate)

        #expect(settings.name == RoundSetupRules.defaultRoundName(for: firstDate))

        settings.updateDate(secondDate)
        #expect(settings.name == RoundSetupRules.defaultRoundName(for: secondDate))

        settings.name = "Championnat club"
        settings.userDidCustomizeName(settings.name)
        settings.updateDate(firstDate)

        #expect(settings.name == "Championnat club")
    }

    @Test func duplicateRoundNamesOnSameDateAreIncremented() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 27))!
        let otherDate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28))!
        let rounds = [
            RoundListSnapshot(name: "Parcours du 27 août 2026", date: date, isFinished: false),
            RoundListSnapshot(name: "Parcours du 27 août 2026 2", date: date, isFinished: false),
            RoundListSnapshot(name: "Parcours du 27 août 2026", date: otherDate, isFinished: false),
        ]

        let uniqueName = RoundSetupRules.uniqueRoundName(
            baseName: "Parcours du 27 août 2026",
            date: date,
            existingRounds: rounds,
            calendar: calendar
        )

        #expect(uniqueName == "Parcours du 27 août 2026 3")
    }

    @Test func emptyRoundNameFallsBackToDefaultDateName() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 27))!

        let uniqueName = RoundSetupRules.uniqueRoundName(
            baseName: "   ",
            date: date,
            existingRounds: [],
            calendar: calendar
        )

        #expect(uniqueName == RoundSetupRules.defaultRoundName(for: date))
    }

    @Test func roundCreationCanStartWithoutStoredArchers() {
        #expect(RoundSetupRules.resolvedPelotonNames([""]) == ["Archer 1"])
    }

    @Test func emptyPelotonSlotStartsWithGenericArcherName() {
        #expect(RoundSetupRules.resolvedPelotonNames([""]) == ["Archer 1"])
    }

    @Test func multipleEmptyPelotonSlotsUsePredictableGenericNames() {
        #expect(RoundSetupRules.resolvedPelotonNames(["", "", ""]) == ["Archer 1", "Archer 2", "Archer 3"])
    }

    @Test func customPelotonNameIsKeptAndSortedWithGenericNames() {
        #expect(RoundSetupRules.resolvedPelotonNames(["", "Marie", ""]) == ["Archer 1", "Archer 3", "Marie"])
    }

    @Test func pelotonAcceptsOneToSixArchersAndSortsAlphabetically() {
        let names = ["  Zoe", "alice ", "Bruno"]

        #expect(RoundSetupRules.resolvedPelotonNames(names) == ["alice", "Bruno", "Zoe"])
        #expect(RoundSetupRules.canAddArcherSlot(currentSlotCount: 1))
        #expect(RoundSetupRules.canAddArcherSlot(currentSlotCount: 5))
        #expect(!RoundSetupRules.canAddArcherSlot(currentSlotCount: 6))
        #expect(!RoundSetupRules.canRemoveArcherSlot(currentSlotCount: 1))
        #expect(RoundSetupRules.canRemoveArcherSlot(currentSlotCount: 2))
    }

    @Test func editedPelotonNamesKeepExistingOrder() {
        let names = ["Zoe", "  alice ", ""]

        #expect(RoundSetupRules.resolvedEditedPelotonNames(names) == ["Zoe", "alice", "Archer 3"])
    }

    @Test func renamingArcherEntriesByOrderPreservesScores() {
        let round = ShootingRound(name: "Parcours club", firstTarget: 1, archerNames: ["Alice", "Bruno"])
        let entry = round.entries.first { $0.archerOrder == 0 && $0.targetOrderIndex == 0 }
        entry?.arrow1 = 11
        entry?.arrow2 = 10

        for entry in round.entries where entry.archerOrder == 0 {
            entry.archerName = "Camille"
        }

        #expect(round.total(for: "Camille") == 21)
        #expect(round.total(for: "Alice") == 0)
    }

    @Test func pelotonCanStartWithoutTypedText() {
        let names = RoundSetupRules.resolvedPelotonNames([""])

        #expect(names == ["Archer 1"])
        #expect(!names.isEmpty)
    }

    @Test func pelotonDetectsDuplicatesWithoutMemorizationRules() {
        #expect(RoundSetupRules.containsDuplicateArcherNames(["Alice", " alice "]))
        #expect(!RoundSetupRules.containsDuplicateArcherNames(["Alice", "Bruno"]))
    }

    @Test func arrowSelectionStartsOnFirstArrowForEmptyEntry() {
        #expect(ArrowInputRules.initialSelection(arrow1: nil, arrow2: nil) == .first)
        #expect(ArrowInputRules.isScoreInputEnabled(selectedArrow: .first))
    }

    @Test func arrowSelectionMovesFromFirstToSecondThenNone() {
        #expect(ArrowInputRules.selectionAfterScoring(.first) == .second)
        #expect(ArrowInputRules.selectionAfterScoring(.second) == nil)
        #expect(!ArrowInputRules.isScoreInputEnabled(selectedArrow: nil))
    }

    @Test func arrowSelectionForPartiallyAndFullyScoredEntry() {
        #expect(ArrowInputRules.initialSelection(arrow1: 11, arrow2: nil) == .second)
        #expect(ArrowInputRules.initialSelection(arrow1: 11, arrow2: 10) == nil)
    }

    @Test func arrowReplacementAndDeletionRecalculateTargetScore() {
        var entry = ScoreEntrySnapshot(archerName: "Alice", targetNumber: 1, arrow1: 11, arrow2: 8)

        entry.arrow2 = 10
        #expect(ScoreRules.targetTotal(arrow1: entry.arrow1, arrow2: entry.arrow2) == 21)

        entry.arrow2 = nil
        #expect(ScoreRules.targetTotal(arrow1: entry.arrow1, arrow2: entry.arrow2) == 11)
    }

    @Test func validationRequiresTwoArrows() {
        let incomplete = ScoringNavigationState.make(scoredArcherIndexes: [])
        let complete = ScoringNavigationState.make(scoredArcherIndexes: [0])

        #expect(incomplete.primaryAction == .validateArcher)
        #expect(complete.primaryAction == .validateArcher)
    }

    @Test func validatingArcherMovesToNextIncompleteArcherOnlyAfterValidate() {
        let state = ScoringNavigationState.make(
            archerIndex: 0,
            validatedArcherIndexes: [],
            scoredArcherIndexes: []
        )

        let nextState = state.validatingCurrentArcher()

        #expect(nextState.archerIndex == 1)
        #expect(nextState.targetIndex == 0)
        #expect(nextState.validatedArcherIndexes == [0])
        #expect(nextState.primaryAction == .validateArcher)
    }

    @Test func secondArrowDoesNotAutomaticallyChangeArcher() {
        let state = ScoringNavigationState.make(archerIndex: 0, scoredArcherIndexes: [0])

        #expect(state.archerIndex == 0)
        #expect(state.primaryAction == .validateArcher)
    }

    @Test func allArchersScoredShowsNextTargetWithoutExtraValidate() {
        let state = ScoringNavigationState.make(
            archerIndex: 2,
            archerCount: 3,
            scoredArcherIndexes: [0, 1, 2]
        )

        #expect(state.primaryAction == .nextTarget)
    }

    @Test func completeRegularTargetShowsNextTargetButCompleteLastTargetShowsFinish() {
        let regularTarget = ScoringNavigationState.make(
            targetIndex: 22,
            archerCount: 2,
            scoredArcherIndexes: [0, 1]
        )
        let lastTarget = ScoringNavigationState.make(
            targetIndex: 23,
            archerCount: 2,
            scoredArcherIndexes: [0, 1]
        )

        #expect(regularTarget.primaryAction == .nextTarget)
        #expect(lastTarget.primaryAction == .finishRound)
    }

    @Test func lastRealTargetDependsOnConfiguredTargetOrder() {
        let order = TargetOrder(firstTarget: 17).targets

        #expect(order.first == 17)
        #expect(order.last == 16)
    }

    @Test func nextTargetValidatesAndOpensTargetOnlyAfterAllArchersAreScored() {
        let incompleteState = ScoringNavigationState.make(scoredArcherIndexes: [0])
        let completeState = ScoringNavigationState.make(scoredArcherIndexes: [0, 1, 2])

        #expect(incompleteState.openingNextTarget() == incompleteState)

        let nextState = completeState.openingNextTarget()
        #expect(nextState.targetIndex == 1)
        #expect(nextState.archerIndex == 0)
        #expect(nextState.highestReachedTargetIndex == 1)
    }

    @Test func completeTargetKeepsNextTargetActionEvenWhenSelectingScoredArcher() {
        let state = ScoringNavigationState.make(
            archerIndex: 2,
            correctionReturnArcherIndex: 1,
            scoredArcherIndexes: [0, 1, 2]
        )

        #expect(state.primaryAction == .nextTarget)
    }

    @Test func directSelectionOfScoredArcherEntersCorrectionAndReturnsAfterValidation() {
        let state = ScoringNavigationState.make(
            archerIndex: 2,
            scoredArcherIndexes: [0, 1]
        )

        let correctionState = state.selectingArcher(0)
        #expect(correctionState.archerIndex == 0)
        #expect(correctionState.correctionReturnArcherIndex == 2)
        #expect(correctionState.primaryAction == .validateArcher)

        let returnedState = correctionState.validatingCurrentArcher()
        #expect(returnedState.archerIndex == 2)
        #expect(returnedState.correctionReturnArcherIndex == nil)
        #expect(returnedState.validatedArcherIndexes == [0])
    }

    @Test func targetNavigationOnlyAllowsReachedTargets() {
        let state = ScoringNavigationState.make(targetIndex: 1, highestReachedTargetIndex: 2)

        #expect(state.canMoveToPreviousTarget)
        #expect(state.canMoveToNextReachedTarget)
        #expect(state.swipingToPreviousTarget().targetIndex == 0)
        #expect(state.swipingToNextReachedTarget().targetIndex == 2)

        let furthestState = ScoringNavigationState.make(targetIndex: 2, highestReachedTargetIndex: 2)
        #expect(furthestState.canMoveToPreviousTarget)
        #expect(!furthestState.canMoveToNextReachedTarget)
        #expect(furthestState.swipingToNextReachedTarget() == furthestState)
    }

    @Test func targetOrderAndProgressRespectNonFirstStartingTarget() {
        let order = TargetOrder(firstTarget: 24).targets
        let state = ScoringNavigationState.make(targetIndex: 1, highestReachedTargetIndex: 1)

        #expect(order[0] == 24)
        #expect(order[1] == 1)
        #expect(state.progressValue == 2.0 / 24.0)
    }

    @Test func scoringSnapshotsKeepScoresAcrossCorrections() {
        var entries = [
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 24, arrow1: 11, arrow2: 10),
            ScoreEntrySnapshot(archerName: "Bruno", targetNumber: 24, arrow1: 8, arrow2: 5),
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 1, arrow1: 10, arrow2: 0),
        ]

        entries[0].arrow2 = 0

        #expect(ScoreRules.roundTotal(entries: entries, archerName: "Alice") == 21)
        #expect(ScoreRules.roundTotal(entries: entries, archerName: "Bruno") == 13)
    }

    @Test func roundTotalRecalculatesAfterCorrection() {
        var entries = [
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 1, arrow1: 11, arrow2: 10),
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 2, arrow1: 8, arrow2: 5),
            ScoreEntrySnapshot(archerName: "Bruno", targetNumber: 1, arrow1: 10, arrow2: 0),
        ]

        #expect(ScoreRules.roundTotal(entries: entries) == 44)
        #expect(ScoreRules.roundTotal(entries: entries, archerName: "Alice") == 34)

        entries[0].arrow2 = 0

        #expect(ScoreRules.roundTotal(entries: entries) == 34)
        #expect(ScoreRules.roundTotal(entries: entries, archerName: "Alice") == 24)
    }

    @Test func scoreBreakdownCountsEveryScoringValueForOneArcher() {
        let entries = [
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 1, arrow1: 11, arrow2: 10),
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 2, arrow1: 8, arrow2: 5),
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 3, arrow1: 0, arrow2: nil),
            ScoreEntrySnapshot(archerName: "Bruno", targetNumber: 1, arrow1: 11, arrow2: 11),
        ]

        let breakdown = ScoreRules.scoreBreakdown(entries: entries, archerName: "Alice")

        #expect(breakdown.total == 34)
        #expect(breakdown.elevens == 1)
        #expect(breakdown.tens == 1)
        #expect(breakdown.eights == 1)
        #expect(breakdown.fives == 1)
        #expect(breakdown.misses == 1)
    }

    @Test func archerScoreSheetKeepsTargetRowsBestArrowFirstAndCumulativeTotal() {
        let calendar = Calendar(identifier: .gregorian)
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 28))!
        let entries = [
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 17, arrow1: 11, arrow2: 10),
            ScoreEntrySnapshot(archerName: "Bruno", targetNumber: 17, arrow1: 8, arrow2: 5),
            ScoreEntrySnapshot(archerName: "Alice", targetNumber: 18, arrow1: 0, arrow2: 8),
        ]

        let sheet = ScoreSheetFormatter.makeSheet(
            roundName: "Parcours club",
            roundDate: date,
            archerName: "Alice",
            entries: entries
        )

        #expect(sheet.rows.map(\.targetNumber) == [17, 18])
        #expect(sheet.rows.map(\.arrow1) == [11, 8])
        #expect(sheet.rows.map(\.arrow2) == [10, 0])
        #expect(sheet.rows.map(\.targetTotal) == [21, 8])
        #expect(sheet.rows.map(\.cumulativeTotal) == [21, 29])
        #expect(sheet.breakdown.total == 29)
    }

    @Test @MainActor func leavingScoringKeepsRoundInProgressAndScoresPersisted() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Archer.self, ShootingRound.self, ScoreEntry.self, configurations: configuration)
        let context = container.mainContext
        let round = ShootingRound(name: "Parcours test", firstTarget: 1, archerNames: [""])
        context.insert(round)

        let entry = try #require(round.activeEntry)
        entry.arrow1 = 11
        entry.arrow2 = 8
        try context.save()

        let rounds = try context.fetch(FetchDescriptor<ShootingRound>())
        let reopenedRound = try #require(rounds.first)
        let reopenedEntry = try #require(reopenedRound.activeEntry)

        #expect(!reopenedRound.isFinished)
        #expect(reopenedEntry.arrow1 == 11)
        #expect(reopenedEntry.arrow2 == 8)
    }

    @Test @MainActor func deletingRoundRemovesOnlyItsEntriesAndKeepsOtherRounds() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Archer.self, ShootingRound.self, ScoreEntry.self, configurations: configuration)
        let context = container.mainContext
        let firstRound = ShootingRound(name: "A", firstTarget: 1, archerNames: ["Alice"])
        let secondRound = ShootingRound(name: "B", firstTarget: 1, archerNames: ["Bruno"])

        context.insert(firstRound)
        context.insert(secondRound)
        try context.save()

        let firstRoundEntryCount = firstRound.entries.count
        context.delete(firstRound)
        try context.save()

        let rounds = try context.fetch(FetchDescriptor<ShootingRound>())
        let entries = try context.fetch(FetchDescriptor<ScoreEntry>())

        #expect(firstRoundEntryCount == 24)
        #expect(rounds.map(\.name) == ["B"])
        #expect(entries.allSatisfy { $0.archerName == "Bruno" })
    }

    @Test @MainActor func finishingRoundRequiresCompleteDataAndPersistsFinishedState() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Archer.self, ShootingRound.self, ScoreEntry.self, configurations: configuration)
        let context = container.mainContext
        let round = ShootingRound(name: "Parcours final", firstTarget: 17, archerNames: ["Alice", "Bruno"])
        context.insert(round)

        fillRound(round, exceptTargetIndex: 23)
        round.currentTargetIndex = 23
        round.currentArcherIndex = 1

        #expect(!round.canFinishAfterValidatingCurrentTarget)
        #expect(!round.canFinish)

        for entry in round.entries where entry.targetOrderIndex == 23 {
            entry.arrow1 = 11
            entry.arrow2 = 10
        }

        #expect(round.canFinishAfterValidatingCurrentTarget)
        for entry in round.entries where entry.targetOrderIndex == 23 {
            entry.isValidated = true
        }
        #expect(round.canFinish)

        round.isFinished = true
        try context.save()

        let rounds = try context.fetch(FetchDescriptor<ShootingRound>())
        let reopenedRound = try #require(rounds.first)

        #expect(reopenedRound.isFinished)
        #expect(reopenedRound.completedTargetCount == 24)
        #expect(RoundListRules.destination(isFinished: reopenedRound.isFinished) == .summary)
        #expect(reopenedRound.scoreBreakdown(for: "Alice").total == 24 * 21)
    }
}

private extension ScoringNavigationState {
    static func make(
        targetIndex: Int = 0,
        archerIndex: Int = 0,
        highestReachedTargetIndex: Int = 0,
        correctionReturnArcherIndex: Int? = nil,
        archerCount: Int = 3,
        targetCount: Int = 24,
        validatedArcherIndexes: Set<Int> = [],
        scoredArcherIndexes: Set<Int> = []
    ) -> ScoringNavigationState {
        ScoringNavigationState(
            targetIndex: targetIndex,
            archerIndex: archerIndex,
            highestReachedTargetIndex: highestReachedTargetIndex,
            correctionReturnArcherIndex: correctionReturnArcherIndex,
            archerCount: archerCount,
            targetCount: targetCount,
            validatedArcherIndexes: validatedArcherIndexes,
            scoredArcherIndexes: scoredArcherIndexes
        )
    }
}

@MainActor
private func fillRound(_ round: ShootingRound, exceptTargetIndex: Int? = nil) {
    for entry in round.entries where entry.targetOrderIndex != exceptTargetIndex {
        entry.arrow1 = 11
        entry.arrow2 = 10
        entry.isValidated = true
    }
}
