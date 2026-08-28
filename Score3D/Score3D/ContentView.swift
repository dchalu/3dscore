import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShootingRound.date, order: .reverse) private var rounds: [ShootingRound]

    @State private var isShowingNewRound = false
    @State private var roundPendingDeletion: ShootingRound?
    @State private var selectedRound: ShootingRound?
    @State private var pendingCreatedRound: ShootingRound?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Score3D")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 18)
                        .padding(.bottom, 20)
                        .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 22))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    Button {
                        isShowingNewRound = true
                    } label: {
                        Text("Nouveau parcours")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 20, trailing: 22))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                        if rounds.isEmpty {
                            Text("Aucun parcours")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(rounds) { round in
                                Button {
                                    selectedRound = round
                                } label: {
                                    RoundRowView(round: round)
                                }
                                .buttonStyle(.plain)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        roundPendingDeletion = round
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                        }
                } header: {
                    Text("Parcours")
                        .font(.headline)
                        .textCase(nil)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingNewRound) {
                NewRoundFlowView { round in
                    pendingCreatedRound = round
                    isShowingNewRound = false
                }
            }
            .onChange(of: isShowingNewRound) { _, isPresented in
                guard !isPresented, let pendingCreatedRound else { return }
                selectedRound = pendingCreatedRound
                self.pendingCreatedRound = nil
            }
            .navigationDestination(item: $selectedRound) { round in
                roundDestination(for: round)
            }
            .alert("Supprimer ce parcours ?", isPresented: deleteConfirmationBinding) {
                Button("Annuler", role: .cancel) {
                    roundPendingDeletion = nil
                }
                Button("Supprimer", role: .destructive, action: deletePendingRound)
            } message: {
                if let roundPendingDeletion {
                    Text("« \(roundPendingDeletion.name) » et tous les scores associés seront définitivement supprimés.")
                }
            }
        }
    }

    private var deleteConfirmationBinding: Binding<Bool> {
        Binding(
            get: { roundPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    roundPendingDeletion = nil
                }
            }
        )
    }

    @ViewBuilder
    private func roundDestination(for round: ShootingRound) -> some View {
        if RoundListRules.destination(isFinished: round.isFinished) == .summary {
            RoundSummaryView(round: round)
        } else {
            ScoringView(round: round)
        }
    }

    private func deletePendingRound() {
        guard let round = roundPendingDeletion else { return }
        modelContext.delete(round)
        roundPendingDeletion = nil
        try? modelContext.save()
    }
}

private struct RoundRowView: View {
    let round: ShootingRound

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(round.name)
                .font(.headline)
                .lineLimit(1)

            Text(round.date, format: .dateTime.day().month(.wide).year())
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("\(round.completedTargetCount) / 24 cibles")
                    .font(.subheadline)
                Spacer()
                Text(RoundListRules.statusLabel(isFinished: round.isFinished))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(round.isFinished ? Color.secondary : Color.accentColor)
            }

            ProgressView(value: Double(round.completedTargetCount), total: 24)
        }
        .padding(.vertical, 6)
    }
}

struct RoundSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let round: ShootingRound

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(round.name)
                        .font(.title)
                        .lineLimit(2)

                    Text(round.date, format: .dateTime.day().month(.wide).year())
                        .font(.body)
                        .foregroundStyle(.secondary)

                    HStack {
                        Text("24 / 24 cibles")
                            .font(.body.weight(.semibold))
                        Spacer()
                        Text("Terminé")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: 24, total: 24)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(round.archerNames, id: \.self) { archerName in
                        ArcherSummaryRow(breakdown: round.scoreBreakdown(for: archerName))
                    }
                }

                Button {
                    dismiss()
                } label: {
                    Text("Retour à l’accueil")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 6)
            }
            .padding()
        }
        .navigationTitle("Parcours terminé")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArcherSummaryRow: View {
    let breakdown: ScoreBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(breakdown.archerName)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)

                Spacer()

                Text("\(breakdown.total) pts")
                    .font(.title2.monospacedDigit().bold())
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 8)], spacing: 8) {
                summaryChip("11", breakdown.elevens)
                summaryChip("10", breakdown.tens)
                summaryChip("8", breakdown.eights)
                summaryChip("5", breakdown.fives)
                summaryChip("M", breakdown.misses)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
    }

    private func summaryChip(_ label: String, _ value: Int) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.callout.weight(.semibold))
                .frame(minWidth: 34, minHeight: 28)
                .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.secondary.opacity(0.18), lineWidth: 1)
                }

            Text(":")
                .font(.callout.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(value)")
                .font(.callout.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
    }
}

struct NewRoundFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var rounds: [ShootingRound]
    let onRoundCreated: (ShootingRound) -> Void

    @State private var settings = RoundDraftSettings(date: .now)
    @State private var initialSettings = RoundDraftSettings(date: .now)
    @State private var slots = [RoundArcherSlot()]
    @State private var isShowingCancelConfirmation = false
    @State private var datePickerID = UUID()
    @FocusState private var focusedSlotID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Parcours") {
                    TextField("Nom du parcours", text: $settings.name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onChange(of: settings.name) { _, newValue in
                            settings.userDidCustomizeName(newValue)
                        }

                    DatePicker("Date", selection: $settings.date, in: ...Date(), displayedComponents: .date)
                        .id(datePickerID)
                        .onChange(of: settings.date) { _, newDate in
                            settings.updateDate(newDate)
                            datePickerID = UUID()
                        }

                    Picker("Cible de départ", selection: $settings.firstTarget) {
                        ForEach(1...24, id: \.self) { target in
                            Text("Cible \(target)").tag(target)
                        }
                    }
                }

                Section {
                    ForEach($slots) { $slot in
                        let index = slotIndex(for: slot)
                        RoundArcherSlotView(
                            index: index,
                            slot: $slot,
                            focusedSlotID: $focusedSlotID,
                            canRemove: canRemoveSlot(at: index)
                        )
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if canRemoveSlot(at: index) {
                                Button(role: .destructive) {
                                    removeSlot(slot)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                        }
                    }

                    if RoundSetupRules.canAddArcherSlot(currentSlotCount: slots.count) {
                        Button {
                            addSlot()
                        } label: {
                            Label("Ajouter un archer", systemImage: "plus")
                        }
                    } else {
                        Label("6 archers maximum", systemImage: "checkmark.circle")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Peloton")
                } footer: {
                    if hasDuplicateNames {
                        Text("Chaque archer du peloton doit avoir un nom distinct.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Le peloton contient 1 à 6 archers. Les archers seront triés alphabétiquement pour le parcours.")
                    }
                }

                Section {
                    Button(action: startRound) {
                        Text("Démarrer le parcours")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 44)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartRound)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Nouveau parcours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: cancel)
                }
            }
            .alert("Abandonner la création ?", isPresented: $isShowingCancelConfirmation) {
                Button("Continuer l’édition", role: .cancel) { }
                Button("Abandonner", role: .destructive) {
                    dismiss()
                }
            } message: {
                Text("Les informations saisies pour ce parcours seront perdues.")
            }
            .onAppear {
                initialSettings = settings
            }
            .interactiveDismissDisabled(hasChanges)
            .background {
                SheetDismissAttemptHandler(isDisabled: hasChanges) {
                    isShowingCancelConfirmation = true
                }
            }
        }
    }

    private var hasDuplicateNames: Bool {
        RoundSetupRules.containsDuplicateArcherNames(RoundSetupRules.resolvedPelotonNames(slots.map(\.name)))
    }

    private var canStartRound: Bool {
        !slots.isEmpty && !hasDuplicateNames
    }

    private var hasChanges: Bool {
        settings != initialSettings || slots.map(\.name).contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } || slots.count != 1
    }

    private func slotIndex(for slot: RoundArcherSlot) -> Int {
        (slots.firstIndex { $0.id == slot.id } ?? 0) + 1
    }

    private func canRemoveSlot(at index: Int) -> Bool {
        index > 1 && RoundSetupRules.canRemoveArcherSlot(currentSlotCount: slots.count)
    }

    private func addSlot() {
        guard RoundSetupRules.canAddArcherSlot(currentSlotCount: slots.count) else { return }
        let slot = RoundArcherSlot()
        slots.append(slot)
        focusedSlotID = slot.id
    }

    private func removeSlot(_ slot: RoundArcherSlot) {
        guard RoundSetupRules.canRemoveArcherSlot(currentSlotCount: slots.count),
              let index = slots.firstIndex(where: { $0.id == slot.id }) else { return }
        slots.remove(at: index)
    }

    private func cancel() {
        if hasChanges {
            isShowingCancelConfirmation = true
        } else {
            dismiss()
        }
    }

    private func startRound() {
        let validNames = RoundSetupRules.resolvedPelotonNames(slots.map(\.name))
        let roundName = RoundSetupRules.uniqueRoundName(
            baseName: settings.name,
            date: settings.date,
            existingRounds: rounds.map { RoundListSnapshot(name: $0.name, date: $0.date, isFinished: $0.isFinished) }
        )

        let round = ShootingRound(
            name: roundName,
            date: settings.date,
            firstTarget: settings.firstTarget,
            archerNames: validNames
        )
        modelContext.insert(round)
        try? modelContext.save()
        onRoundCreated(round)
    }
}

private struct RoundArcherSlotView: View {
    let index: Int
    @Binding var slot: RoundArcherSlot
    var focusedSlotID: FocusState<UUID?>.Binding
    let canRemove: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Archer \(index)")
                    .font(.headline)

                TextField("Archer \(index)", text: $slot.name)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused(focusedSlotID, equals: slot.id)
            }

            if canRemove {
                Button(action: {}) {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("La suppression se fait en balayant la ligne vers la gauche")
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SheetDismissAttemptHandler: UIViewControllerRepresentable {
    let isDisabled: Bool
    let onAttempt: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isDisabled: isDisabled, onAttempt: onAttempt)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.isDisabled = isDisabled
        context.coordinator.onAttempt = onAttempt

        DispatchQueue.main.async {
            uiViewController.parent?.presentationController?.delegate = context.coordinator
        }
    }

    final class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var isDisabled: Bool
        var onAttempt: () -> Void

        init(isDisabled: Bool, onAttempt: @escaping () -> Void) {
            self.isDisabled = isDisabled
            self.onAttempt = onAttempt
        }

        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            !isDisabled
        }

        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            guard isDisabled else { return }
            onAttempt()
        }
    }
}

struct ScoringView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var round: ShootingRound

    @State private var selectedArrow: ArrowSlot?
    @State private var correctionReturnArcherIndex: Int?
    @State private var isShowingCompletedArrowCorrection = false

    var body: some View {
        if round.isFinished {
            RoundSummaryView(round: round)
        } else {
            scoringContent
        }
    }

    private var scoringContent: some View {
        VStack(spacing: 0) {
            if let entry = round.activeEntry {
                scoringTopBar
                    .padding(.bottom, 16)
                targetProgressHeader(for: entry)
                    .padding(.bottom, 28)
                archerList
                Spacer(minLength: 8)
                scoringPanel(for: entry)
                    .padding(.bottom, 26)
                primaryActionButton(for: entry)
            } else {
                ContentUnavailableView("Parcours indisponible", systemImage: "exclamationmark.triangle")
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .safeAreaPadding(.top, 8)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshSelectedArrowForActiveEntry)
    }

    private var scoringTopBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(.thinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Quitter le parcours")

            Text(round.name)
                .font(.title3)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func targetProgressHeader(for entry: ScoreEntry) -> some View {
        HStack(spacing: 8) {
            targetNavigationButton(
                systemImage: "chevron.left",
                accessibilityLabel: "Cible précédente",
                isEnabled: navigationState.canMoveToPreviousTarget,
                action: moveToPreviousTarget
            )

            VStack(spacing: 4) {
                Text("Cible \(entry.targetNumber) / 24")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                ProgressView(value: Double(round.currentTargetIndex + 1), total: 24)
                    .scaleEffect(x: 1, y: 1.25, anchor: .center)
            }

            targetNavigationButton(
                systemImage: "chevron.right",
                accessibilityLabel: "Cible suivante atteinte",
                isEnabled: navigationState.canMoveToNextReachedTarget,
                action: moveToNextReachedTarget
            )
        }
    }

    private func targetNavigationButton(
        systemImage: String,
        accessibilityLabel: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .frame(width: 36, height: 36)
                .background(Color(.secondarySystemGroupedBackground), in: Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Color.accentColor : Color.secondary.opacity(0.45))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }

    private var archerList: some View {
        VStack(spacing: 3) {
            HStack(spacing: 6) {
                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text("F1")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                        .accessibilityLabel("Flèche 1")

                    Text("F2")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, alignment: .trailing)
                        .accessibilityLabel("Flèche 2")

                    Color.clear
                        .frame(width: 12, height: 1)

                    Text("Total")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 40, alignment: .trailing)

                    Text("Cumul")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 46, alignment: .trailing)
                }
            }
            .padding(.horizontal, 8)

            ForEach(Array(round.archerNames.enumerated()), id: \.offset) { index, name in
                let entry = entryForCurrentTarget(archerName: name)
                Button {
                    selectArcher(at: index)
                } label: {
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(index == round.currentArcherIndex ? Color.accentColor : Color.clear)
                            .frame(width: 3, height: 22)

                        Text(name)
                            .font(.title3.weight(index == round.currentArcherIndex ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(index == round.currentArcherIndex ? .primary : .secondary)

                        Spacer(minLength: 6)

                        HStack(spacing: 6) {
                            Text(ScoreRules.displayValue(entry?.arrow1))
                                .font(.title3.monospacedDigit().weight(.regular))
                                .foregroundStyle(index == round.currentArcherIndex ? .primary : .secondary)
                                .frame(width: 32, alignment: .trailing)
                                .accessibilityLabel("Flèche 1 \(ScoreRules.displayValue(entry?.arrow1))")

                            Text(ScoreRules.displayValue(entry?.arrow2))
                                .font(.title3.monospacedDigit().weight(.regular))
                                .foregroundStyle(index == round.currentArcherIndex ? .primary : .secondary)
                                .frame(width: 32, alignment: .trailing)
                                .accessibilityLabel("Flèche 2 \(ScoreRules.displayValue(entry?.arrow2))")

                            Color.clear
                                .frame(width: 12, height: 1)

                            Text("\(entry?.targetTotal ?? 0)")
                                .font(.title3.monospacedDigit().weight(index == round.currentArcherIndex ? .bold : .regular))
                                .foregroundStyle(index == round.currentArcherIndex ? .primary : .secondary)
                                .frame(width: 40, alignment: .trailing)

                            Text("\(round.total(for: name))")
                                .font(.title3.monospacedDigit().weight(index == round.currentArcherIndex ? .bold : .regular))
                                .foregroundStyle(index == round.currentArcherIndex ? .primary : .secondary)
                                .frame(width: 46, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .padding(.horizontal, 8)
                    .background(
                        index == round.currentArcherIndex
                        ? Color.accentColor.opacity(0.12)
                        : Color(.secondarySystemGroupedBackground).opacity(0.55),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func scoringPanel(for entry: ScoreEntry) -> some View {
        VStack(spacing: 7) {
            arrowPanel(for: entry)
            scoreButtons(for: entry)
        }
    }

    private func arrowPanel(for entry: ScoreEntry) -> some View {
        HStack(spacing: 7) {
            ArrowValueButton(
                title: "Flèche 1",
                value: ScoreRules.displayValue(entry.arrow1),
                isSelected: isArrowVisuallySelected(.first, in: entry),
                canDelete: isArrowVisuallySelected(.first, in: entry) && entry.arrow1 != nil,
                deleteAction: { clearArrowValue(.first, in: entry) }
            ) {
                isShowingCompletedArrowCorrection = false
                selectedArrow = .first
            }

            ArrowValueButton(
                title: "Flèche 2",
                value: ScoreRules.displayValue(entry.arrow2),
                isSelected: isArrowVisuallySelected(.second, in: entry),
                canDelete: isArrowVisuallySelected(.second, in: entry) && entry.arrow2 != nil,
                deleteAction: { clearArrowValue(.second, in: entry) }
            ) {
                isShowingCompletedArrowCorrection = false
                selectedArrow = .second
            }

            VStack(spacing: 3) {
                Text("Total")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("\(entry.targetTotal)")
                    .font(.title2.monospacedDigit().bold())
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private func scoreButtons(for entry: ScoreEntry) -> some View {
        HStack(spacing: 6) {
            ForEach(ArrowScore.allCases) { score in
                Button {
                    apply(score, to: entry)
                } label: {
                    Text(score.label)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!ArrowInputRules.isScoreInputEnabled(selectedArrow: selectedArrow))
            }
        }
    }

    private func primaryActionButton(for entry: ScoreEntry) -> some View {
        Button {
            performPrimaryAction(for: entry)
        } label: {
            Text(primaryActionTitle(for: entry))
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isPrimaryActionDisabled(for: entry))
    }

    private func primaryActionTitle(for entry: ScoreEntry) -> String {
        switch navigationState.primaryAction {
        case .validateArcher:
            if !hasIncompleteArcherOtherThanCurrent {
                return round.currentTargetIndex == 23 ? "Terminer le parcours" : "Cible suivante"
            }
            return "Archer suivant"
        case .validateCorrection:
            return "Archer suivant"
        case .nextTarget:
            return "Cible suivante"
        case .finishRound:
            return "Terminer le parcours"
        }
    }

    private var navigationState: ScoringNavigationState {
        ScoringNavigationState(
            targetIndex: round.currentTargetIndex,
            archerIndex: round.currentArcherIndex,
            highestReachedTargetIndex: max(round.highestReachedTargetIndex, round.currentTargetIndex),
            correctionReturnArcherIndex: correctionReturnArcherIndex,
            archerCount: max(round.archerNames.count, 1),
            targetCount: 24,
            validatedArcherIndexes: validatedArcherIndexesForCurrentTarget,
            scoredArcherIndexes: scoredArcherIndexesForCurrentTarget
        )
    }

    private var validatedArcherIndexesForCurrentTarget: Set<Int> {
        Set(entriesForCurrentTarget.filter { $0.isValidated && $0.hasTwoArrows }.map(\.archerOrder))
    }

    private var scoredArcherIndexesForCurrentTarget: Set<Int> {
        Set(entriesForCurrentTarget.filter(\.hasTwoArrows).map(\.archerOrder))
    }

    private var hasIncompleteArcherOtherThanCurrent: Bool {
        let allIndexes = Set(0..<round.archerNames.count)
        let incompleteIndexes = allIndexes.subtracting(scoredArcherIndexesForCurrentTarget)
        return incompleteIndexes.contains { $0 != round.currentArcherIndex }
    }

    private var entriesForCurrentTarget: [ScoreEntry] {
        round.entries.filter { $0.targetOrderIndex == round.currentTargetIndex }
    }

    private func entryForCurrentTarget(archerName: String) -> ScoreEntry? {
        entriesForCurrentTarget.first { $0.archerName == archerName }
    }

    private func selectArcher(at index: Int) {
        let selectedEntry = round.entries.first {
            $0.targetOrderIndex == round.currentTargetIndex && $0.archerOrder == index
        }
        let nextState = navigationState.selectingArcher(index)
        applyNavigationState(nextState)
        isShowingCompletedArrowCorrection = selectedEntry?.hasTwoArrows == true
    }

    private func apply(_ score: ArrowScore, to entry: ScoreEntry) {
        guard let selectedArrow else { return }

        switch selectedArrow {
        case .first:
            entry.arrow1 = score.rawValue
        case .second:
            entry.arrow2 = score.rawValue
        }

        entry.isValidated = false
        self.selectedArrow = ArrowInputRules.selectionAfterScoring(selectedArrow)
        isShowingCompletedArrowCorrection = false
        save()
    }

    private func clearArrowValue(_ arrow: ArrowSlot, in entry: ScoreEntry) {
        switch arrow {
        case .first:
            entry.arrow1 = nil
        case .second:
            entry.arrow2 = nil
        }

        selectedArrow = arrow
        isShowingCompletedArrowCorrection = false
        entry.isValidated = false
        save()
    }

    private func refreshSelectedArrowForActiveEntry() {
        guard let entry = round.activeEntry else { return }
        selectedArrow = ArrowInputRules.initialSelection(arrow1: entry.arrow1, arrow2: entry.arrow2)
    }

    private func isArrowVisuallySelected(_ arrow: ArrowSlot, in entry: ScoreEntry) -> Bool {
        selectedArrow == arrow || (isShowingCompletedArrowCorrection && selectedArrow == nil && entry.hasTwoArrows)
    }

    private func performPrimaryAction(for entry: ScoreEntry) {
        switch navigationState.primaryAction {
        case .validateArcher, .validateCorrection:
            guard entry.hasTwoArrows else { return }
            entry.isValidated = true
            let nextState = navigationState.validatingCurrentArcher()
            applyNavigationState(nextState)
        case .nextTarget:
            validateCompleteCurrentTarget()
            let nextState = navigationState.openingNextTarget()
            applyNavigationState(nextState)
        case .finishRound:
            validateCompleteCurrentTarget()
            guard round.canFinish else { return }
            round.isFinished = true
            round.finishedAt = .now
            save()
        }
    }

    private func isPrimaryActionDisabled(for entry: ScoreEntry) -> Bool {
        switch navigationState.primaryAction {
        case .validateArcher, .validateCorrection:
            return !entry.hasTwoArrows
        case .nextTarget, .finishRound:
            return navigationState.primaryAction == .finishRound && !round.canFinishAfterValidatingCurrentTarget
        }
    }

    private func validateCompleteCurrentTarget() {
        for entry in entriesForCurrentTarget where entry.hasTwoArrows {
            entry.isValidated = true
        }
    }

    private func moveToPreviousTarget() {
        let nextState = navigationState.swipingToPreviousTarget()
        applyNavigationState(nextState, showsCorrectionForValidatedEntry: true)
    }

    private func moveToNextReachedTarget() {
        let nextState = navigationState.swipingToNextReachedTarget()
        applyNavigationState(nextState, showsCorrectionForValidatedEntry: true)
    }

    private func applyNavigationState(
        _ state: ScoringNavigationState,
        showsCorrectionForValidatedEntry: Bool = false
    ) {
        round.currentTargetIndex = state.targetIndex
        round.currentArcherIndex = state.archerIndex
        round.highestReachedTargetIndex = state.highestReachedTargetIndex
        correctionReturnArcherIndex = state.correctionReturnArcherIndex
        refreshSelectedArrowForActiveEntry()
        isShowingCompletedArrowCorrection = showsCorrectionForValidatedEntry
            && round.activeEntry?.isValidated == true
            && round.activeEntry?.hasTwoArrows == true
            && selectedArrow == nil
        save()
    }

    private func save() {
        try? modelContext.save()
    }
}

private struct RoundArcherSlot: Identifiable {
    let id = UUID()
    var name = ""
}

private struct ArrowValueButton: View {
    let title: String
    let value: String
    let isSelected: Bool
    let canDelete: Bool
    let deleteAction: () -> Void
    let action: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(value)
                    .font(.title.monospacedDigit().bold())

                if canDelete {
                    Button(action: deleteAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Supprimer la valeur de \(title)")
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.18) : Color(.secondarySystemGroupedBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: action)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Archer.self, ShootingRound.self, ScoreEntry.self], inMemory: true)
}
