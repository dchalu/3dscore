import SwiftData
import SwiftUI
import UIKit

private enum Score3DTheme {
    static let background = adaptiveColor(light: 0xF5F3EC, dark: 0x111612)
    static let surface = adaptiveColor(light: 0xFCFBF7, dark: 0x1A201B)
    static let textPrimary = adaptiveColor(light: 0x1E2521, dark: 0xF1F3EE)
    static let textSecondary = adaptiveColor(light: 0x6F756F, dark: 0xA8AEA8)
    static let forest = adaptiveColor(light: 0x28513D, dark: 0x8CB7A0)
    static let paleForest = adaptiveColor(light: 0xE7EEE8, dark: 0x26362D)
    static let interaction = adaptiveColor(light: 0x2878C8, dark: 0x7BB7F0)
    static let selection = adaptiveColor(light: 0xE5F1FB, dark: 0x17314A)
    static let border = adaptiveColor(light: 0xD9DDD7, dark: 0x3B463F)

    private static func adaptiveColor(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                isEnabled
                ? Score3DTheme.forest.opacity(configuration.isPressed ? 0.82 : 1)
                : Score3DTheme.border
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct ScoreValueButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
            .background(
                isEnabled
                ? Score3DTheme.surface.opacity(configuration.isPressed ? 0.72 : 1)
                : Score3DTheme.paleForest.opacity(0.55)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isEnabled ? Score3DTheme.interaction : Score3DTheme.border.opacity(0.65), lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct StatusBadge: View {
    let text: String
    let isFinished: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isFinished ? Score3DTheme.textSecondary : Score3DTheme.interaction)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(isFinished ? Score3DTheme.paleForest : Score3DTheme.selection, in: Capsule())
    }
}

private struct PersistenceAlert: Identifiable {
    let id = UUID()
    let message: String
}

private struct Score3DBrandMark: View {
    var body: some View {
        Image("Score3DHomeLogo")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: 280)
            .accessibilityLabel("Score3D")
    }
}

private struct SegmentedTargetProgressView: View {
    let currentIndex: Int
    let completedIndexes: Set<Int>
    let targetCount: Int

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<targetCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(fillColor(for: index))
                    .overlay {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .stroke(strokeColor(for: index), lineWidth: 1)
                    }
                    .frame(maxWidth: .infinity, minHeight: 8, maxHeight: 8)
            }
        }
        .accessibilityLabel("Progression du parcours")
        .accessibilityValue("\(min(currentIndex + 1, targetCount)) sur \(targetCount) cibles")
    }

    private func fillColor(for index: Int) -> Color {
        if index == currentIndex { return Score3DTheme.interaction }
        if completedIndexes.contains(index) { return Score3DTheme.forest }
        return Score3DTheme.surface
    }

    private func strokeColor(for index: Int) -> Color {
        if index == currentIndex { return Score3DTheme.interaction }
        if completedIndexes.contains(index) { return Score3DTheme.forest }
        return Score3DTheme.border
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShootingRound.date, order: .reverse) private var rounds: [ShootingRound]

    @State private var isShowingNewRound = false
    @State private var roundPendingDeletion: ShootingRound?
    @State private var selectedRound: ShootingRound?
    @State private var pendingCreatedRound: ShootingRound?
    @State private var persistenceAlert: PersistenceAlert?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Score3DBrandMark()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 12)
                        .padding(.bottom, 22)
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 0, trailing: 22))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    Button {
                        isShowingNewRound = true
                    } label: {
                        Text("Nouveau parcours")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .listRowInsets(EdgeInsets(top: 0, leading: 22, bottom: 24, trailing: 22))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                        if rounds.isEmpty {
                            Text("Aucun parcours")
                                .font(.body)
                                .foregroundStyle(Score3DTheme.textSecondary)
                                .listRowBackground(Color.clear)
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
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textPrimary)
                        .textCase(nil)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Score3DTheme.background)
            .tint(Score3DTheme.interaction)
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
            .alert(item: $persistenceAlert) { alert in
                Alert(
                    title: Text("Sauvegarde impossible"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
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

        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            persistenceAlert = PersistenceAlert(message: "Le parcours n’a pas pu être supprimé. Réessayez avant de fermer l’app.")
        }
    }
}

private struct RoundRowView: View {
    let round: ShootingRound

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(round.name)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Score3DTheme.textPrimary)
                .lineLimit(1)

            Text(round.date, format: .dateTime.day().month(.wide).year())
                .font(.callout)
                .foregroundStyle(Score3DTheme.textSecondary)

            HStack {
                Text("\(round.completedTargetCount) / 24 cibles")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Score3DTheme.textPrimary)
                Spacer()
                StatusBadge(text: RoundListRules.statusLabel(isFinished: round.isFinished), isFinished: round.isFinished)
            }

            SegmentedTargetProgressView(
                currentIndex: -1,
                completedIndexes: Set(0..<round.completedTargetCount),
                targetCount: 24
            )
            .padding(.top, 4)
        }
        .padding(14)
        .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
        .padding(.vertical, 3)
    }
}

struct RoundSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let round: ShootingRound

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(round.name)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(Score3DTheme.textPrimary)
                        .lineLimit(2)

                    Text(round.date, format: .dateTime.day().month(.wide).year())
                        .font(.body)
                        .foregroundStyle(Score3DTheme.textSecondary)

                    HStack {
                        Text("24 / 24 cibles")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Score3DTheme.textPrimary)
                        Spacer()
                        StatusBadge(text: "Terminé", isFinished: true)
                    }

                    SegmentedTargetProgressView(
                        currentIndex: -1,
                        completedIndexes: Set(0..<24),
                        targetCount: 24
                    )
                }
                .padding(16)
                .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Score3DTheme.border, lineWidth: 1)
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
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 6)
            }
            .padding()
        }
        .background(Score3DTheme.background)
        .tint(Score3DTheme.interaction)
        .navigationTitle("Parcours terminé")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
    }
}

private struct ArcherSummaryRow: View {
    let breakdown: ScoreBreakdown

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(breakdown.archerName.uppercased())
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Score3DTheme.textSecondary)
                    .lineLimit(1)

                Spacer()

                Text("\(breakdown.total) pts")
                    .font(.system(size: 30, weight: .bold, design: .default).monospacedDigit())
                    .foregroundStyle(Score3DTheme.textPrimary)
            }

            HStack(spacing: 6) {
                summaryStat("11", breakdown.elevens)
                summaryStat("10", breakdown.tens)
                summaryStat("8", breakdown.eights)
                summaryStat("5", breakdown.fives)
                summaryStat("M", breakdown.misses)
            }
        }
        .padding(14)
        .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
    }

    private func summaryStat(_ label: String, _ value: Int) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Score3DTheme.textPrimary)
            Text("\(value)")
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(Score3DTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .background(Score3DTheme.paleForest.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
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
    @State private var persistenceAlert: PersistenceAlert?
    @State private var datePickerID = UUID()
    @FocusState private var focusedSlotID: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Parcours") {
                    TextField("Nom du parcours", text: $settings.name)
                        .foregroundStyle(Score3DTheme.textPrimary)
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
                .listRowBackground(Score3DTheme.surface)

                Section {
                    ForEach($slots) { $slot in
                        let index = slotIndex(for: slot)
                        RoundArcherSlotView(
                            index: index,
                            slot: $slot,
                            focusedSlotID: $focusedSlotID,
                            canRemove: canRemoveSlot(at: index),
                            removeAction: { removeSlot(slot) }
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
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Score3DTheme.interaction)
                    } else {
                        Label("6 archers maximum", systemImage: "checkmark.circle")
                            .foregroundStyle(Score3DTheme.textSecondary)
                    }
                } header: {
                    Text("Peloton")
                        .foregroundStyle(Score3DTheme.textPrimary)
                } footer: {
                    if hasDuplicateNames {
                        Text("Chaque archer du peloton doit avoir un nom distinct.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Le peloton contient 1 à 6 archers. Les archers seront triés alphabétiquement pour le parcours.")
                            .foregroundStyle(Score3DTheme.textSecondary)
                    }
                }
                .listRowBackground(Score3DTheme.surface)

                Section {
                    Button(action: startRound) {
                        Text("Démarrer le parcours")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(!canStartRound)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Score3DTheme.background)
            .tint(Score3DTheme.interaction)
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
            .alert(item: $persistenceAlert) { alert in
                Alert(
                    title: Text("Sauvegarde impossible"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
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

        do {
            try modelContext.save()
            onRoundCreated(round)
        } catch {
            modelContext.rollback()
            persistenceAlert = PersistenceAlert(message: "Le parcours n’a pas pu être créé. Réessayez avant de fermer l’app.")
        }
    }
}

private struct RoundArcherSlotView: View {
    let index: Int
    @Binding var slot: RoundArcherSlot
    var focusedSlotID: FocusState<UUID?>.Binding
    let canRemove: Bool
    let removeAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Archer \(index)")
                    .font(.headline)
                    .foregroundStyle(Score3DTheme.textPrimary)

                TextField("Archer \(index)", text: $slot.name)
                    .foregroundStyle(Score3DTheme.textPrimary)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused(focusedSlotID, equals: slot.id)
            }

            if canRemove {
                Button(action: removeAction) {
                    Image(systemName: "minus.circle")
                        .font(.title2)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Score3DTheme.textSecondary)
                .accessibilityLabel("Supprimer Archer \(index)")
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
    @State private var persistenceAlert: PersistenceAlert?

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
                    .padding(.bottom, 14)
                targetProgressHeader(for: entry)
                    .padding(.bottom, 24)
                archerList
                Spacer(minLength: 8)
                scoringPanel(for: entry)
                    .padding(.bottom, 28)
                primaryActionButton(for: entry)
            } else {
                ContentUnavailableView("Parcours indisponible", systemImage: "exclamationmark.triangle")
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .safeAreaPadding(.top, 8)
        .background(Score3DTheme.background)
        .tint(Score3DTheme.interaction)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: refreshSelectedArrowForActiveEntry)
        .alert(item: $persistenceAlert) { alert in
            Alert(
                title: Text("Sauvegarde impossible"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var scoringTopBar: some View {
        HStack(spacing: 10) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(Score3DTheme.surface, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(Score3DTheme.border, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .foregroundStyle(Score3DTheme.interaction)
            .accessibilityLabel("Quitter le parcours")

            Text(round.name)
                .font(.title3)
                .foregroundStyle(Score3DTheme.textSecondary)
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
                    .font(.system(size: 30, weight: .bold, design: .default))
                    .foregroundStyle(Score3DTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                SegmentedTargetProgressView(
                    currentIndex: round.currentTargetIndex,
                    completedIndexes: completedTargetIndexesForProgress,
                    targetCount: 24
                )
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
                .background(Score3DTheme.surface, in: Circle())
                .overlay {
                    Circle()
                        .stroke(Score3DTheme.border.opacity(isEnabled ? 1 : 0.55), lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .foregroundStyle(isEnabled ? Score3DTheme.interaction : Score3DTheme.textSecondary.opacity(0.45))
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }

    private var archerList: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Spacer(minLength: 0)

                HStack(spacing: 6) {
                    Text("F1")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .frame(width: 32, alignment: .trailing)
                        .accessibilityLabel("Flèche 1")

                    Text("F2")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .frame(width: 32, alignment: .trailing)
                        .accessibilityLabel("Flèche 2")

                    Color.clear
                        .frame(width: 12, height: 1)

                    Text("Total")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .frame(width: 40, alignment: .trailing)

                    Text("Cumul")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
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
                            .fill(index == round.currentArcherIndex ? Score3DTheme.interaction : Color.clear)
                            .frame(width: 4, height: 24)

                        Text(name)
                            .font(.system(size: index == round.currentArcherIndex ? 21 : 19, weight: index == round.currentArcherIndex ? .semibold : .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                            .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)

                        Spacer(minLength: 6)

                        HStack(spacing: 6) {
                            Text(ScoreRules.displayValue(entry?.arrow1))
                                .font(.system(size: 20, weight: .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 32, alignment: .trailing)
                                .accessibilityLabel("Flèche 1 \(ScoreRules.displayValue(entry?.arrow1))")

                            Text(ScoreRules.displayValue(entry?.arrow2))
                                .font(.system(size: 20, weight: .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 32, alignment: .trailing)
                                .accessibilityLabel("Flèche 2 \(ScoreRules.displayValue(entry?.arrow2))")

                            Color.clear
                                .frame(width: 12, height: 1)

                            Text("\(entry?.targetTotal ?? 0)")
                                .font(.system(size: 20, weight: index == round.currentArcherIndex ? .bold : .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 40, alignment: .trailing)

                            Text("\(round.total(for: name))")
                                .font(.system(size: 20, weight: index == round.currentArcherIndex ? .bold : .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 46, alignment: .trailing)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .padding(.horizontal, 8)
                    .background(
                        index == round.currentArcherIndex
                        ? Score3DTheme.selection
                        : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10, style: .continuous)
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
                    .foregroundStyle(Score3DTheme.textSecondary)
                Text("\(entry.targetTotal)")
                    .font(.system(size: 28, weight: .bold, design: .default).monospacedDigit())
                    .foregroundStyle(Score3DTheme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 42)
                    .background(Score3DTheme.paleForest, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Score3DTheme.border, lineWidth: 1)
                    }
            }
        }
    }

    private func scoreButtons(for entry: ScoreEntry) -> some View {
        HStack(spacing: 6) {
            ForEach(ArrowScore.allCases) { score in
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    apply(score, to: entry)
                } label: {
                    Text(score.label)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(ScoreValueButtonStyle())
                .disabled(!ArrowInputRules.isScoreInputEnabled(selectedArrow: selectedArrow))
            }
        }
    }

    private func primaryActionButton(for entry: ScoreEntry) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            performPrimaryAction(for: entry)
        } label: {
            Text(primaryActionTitle(for: entry))
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 54)
        }
        .buttonStyle(PrimaryActionButtonStyle())
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

    private var completedTargetIndexesForProgress: Set<Int> {
        let archerCount = round.archerNames.count
        guard archerCount > 0 else { return [] }

        return Set((0..<24).filter { targetIndex in
            let targetEntries = round.entries.filter { $0.targetOrderIndex == targetIndex }
            return targetEntries.count == archerCount && targetEntries.allSatisfy { $0.isValidated && $0.hasTwoArrows }
        })
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
        do {
            guard modelContext.hasChanges else { return }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            refreshSelectedArrowForActiveEntry()
            persistenceAlert = PersistenceAlert(message: "La dernière modification n’a pas pu être enregistrée. Réessayez avant de fermer l’app.")
        }
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
                .foregroundStyle(Score3DTheme.textSecondary)

            HStack(spacing: 8) {
                Spacer(minLength: 0)

                Text(value)
                    .font(.system(size: 30, weight: .bold, design: .default).monospacedDigit())
                    .foregroundStyle(Score3DTheme.textPrimary)

                if canDelete {
                    Button(action: deleteAction) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3.weight(.semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Score3DTheme.textSecondary)
                    .accessibilityLabel("Supprimer la valeur de \(title)")
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
        }
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Score3DTheme.selection : Score3DTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Score3DTheme.interaction : Score3DTheme.border, lineWidth: isSelected ? 2 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onTapGesture(perform: action)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Archer.self, ShootingRound.self, ScoreEntry.self], inMemory: true)
}
