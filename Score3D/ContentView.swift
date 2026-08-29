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
    @State private var roundPendingEdition: ShootingRound?
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

                }

                Section {
                    Text("Parcours")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textPrimary)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    if rounds.isEmpty {
                        Text("Aucun parcours")
                            .font(.body)
                            .foregroundStyle(Score3DTheme.textSecondary)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(rounds) { round in
                            Button {
                                selectedRound = round
                            } label: {
                                RoundRowView(round: round)
                            }
                            .buttonStyle(.plain)
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    roundPendingEdition = round
                                } label: {
                                    RoundEditButton()
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Modifier \(round.name)")
                                .padding(.top, 12)
                                .padding(.trailing, 14)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    roundPendingDeletion = round
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                    }
                } header: {
                    newRoundButton
                        .padding(.horizontal, 22)
                        .padding(.top, 10)
                        .padding(.bottom, 12)
                        .background(Score3DTheme.background)
                        .textCase(nil)
                }
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
            .sheet(item: $roundPendingEdition) { round in
                EditRoundFlowView(round: round) {
                    roundPendingEdition = nil
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

    private var newRoundButton: some View {
        Button {
            isShowingNewRound = true
        } label: {
            Text("Nouveau parcours")
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(PrimaryActionButtonStyle())
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
                .padding(.trailing, 58)

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

private struct RoundEditButton: View {
    var body: some View {
        Image(systemName: "pencil")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Score3DTheme.interaction)
            .frame(width: 28, height: 28)
            .background(Score3DTheme.selection, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Score3DTheme.interaction.opacity(0.38), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct RoundSummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let round: ShootingRound

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                summaryTopBar

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
                        NavigationLink {
                            ArcherScoreSheetView(sheet: round.scoreSheet(for: archerName))
                        } label: {
                            ArcherSummaryRow(breakdown: round.scoreBreakdown(for: archerName))
                        }
                        .buttonStyle(.plain)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var summaryTopBar: some View {
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
            .accessibilityLabel("Retour à l’accueil")

            Text("Parcours terminé")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Score3DTheme.textSecondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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

                Image(systemName: "chevron.right")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Score3DTheme.textSecondary)
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

private struct ArcherScoreSheetView: View {
    let sheet: ArcherScoreSheet
    @State private var pdfURL: URL?
    @State private var pdfExportAlert: PersistenceAlert?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                scoreSheetHeader
                scoreSheetTable
                scoreSheetTotals
            }
            .padding()
        }
        .background(Score3DTheme.background)
        .tint(Score3DTheme.interaction)
        .navigationTitle("Feuille de score")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            preparePDF()
        }
        .alert(item: $pdfExportAlert) { alert in
            Alert(
                title: Text("Export impossible"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let pdfURL {
                    ShareLink(
                        item: pdfURL,
                        subject: Text(sheet.shareTitle)
                    ) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Partager la feuille de score de \(sheet.archerName)")
                } else {
                    Button(action: preparePDF) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("Préparer la feuille de score de \(sheet.archerName)")
                }
            }
        }
    }

    private func preparePDF() {
        do {
            pdfURL = try ArcherScoreSheetPDFExporter.export(sheet)
        } catch {
            pdfExportAlert = PersistenceAlert(message: "Le PDF de la feuille de score n’a pas pu être préparé.")
        }
    }

    private var scoreSheetHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sheet.archerName.uppercased())
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Score3DTheme.textPrimary)
                .lineLimit(2)

            Text(sheet.roundName)
                .font(.headline)
                .foregroundStyle(Score3DTheme.textSecondary)
                .lineLimit(2)

            Text(sheet.roundDate, format: .dateTime.day().month(.wide).year())
                .font(.body)
                .foregroundStyle(Score3DTheme.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
    }

    private var scoreSheetTable: some View {
        VStack(spacing: 0) {
            scoreSheetHeaderRow

            ForEach(Array(sheet.rows.enumerated()), id: \.offset) { _, row in
                ArcherScoreSheetRowView(row: row)
            }
        }
        .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var scoreSheetHeaderRow: some View {
        HStack(spacing: 8) {
            scoreSheetColumnTitle("Cible", alignment: .leading)
            scoreSheetColumnTitle("F1", width: 34)
            scoreSheetColumnTitle("F2", width: 34)
            scoreSheetColumnTitle("Total", width: 52)
            scoreSheetColumnTitle("Cumul", width: 58)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Score3DTheme.paleForest)
    }

    private var scoreSheetTotals: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Total général")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Score3DTheme.textSecondary)

                Spacer()

                Text("\(sheet.breakdown.total) pts")
                    .font(.system(size: 32, weight: .bold).monospacedDigit())
                    .foregroundStyle(Score3DTheme.textPrimary)
            }

            HStack(spacing: 6) {
                summaryStat("11", sheet.breakdown.elevens)
                summaryStat("10", sheet.breakdown.tens)
                summaryStat("8", sheet.breakdown.eights)
                summaryStat("5", sheet.breakdown.fives)
                summaryStat("M", sheet.breakdown.misses)
            }
        }
        .padding(14)
        .background(Score3DTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Score3DTheme.border, lineWidth: 1)
        }
    }

    private func scoreSheetColumnTitle(
        _ title: String,
        width: CGFloat? = nil,
        alignment: Alignment = .trailing
    ) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Score3DTheme.textSecondary)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: alignment)
            .frame(width: width, alignment: alignment)
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

private enum ArcherScoreSheetPDFExporter {
    static func export(_ sheet: ArcherScoreSheet) throws -> URL {
        let fileName = "\(sanitizedFileName(sheet.shareTitle)).pdf"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let data = renderPDF(for: sheet)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func renderPDF(for sheet: ArcherScoreSheet) -> Data {
        let pageBounds = CGRect(x: 0, y: 0, width: 420, height: 595)
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: sheet.shareTitle,
            kCGPDFContextCreator as String: "Score3D",
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds, format: format)
        return renderer.pdfData { context in
            context.beginPage()
            drawSheet(sheet, in: pageBounds)
        }
    }

    private static func drawSheet(_ sheet: ArcherScoreSheet, in pageBounds: CGRect) {
        let margin: CGFloat = 24
        let contentWidth = pageBounds.width - margin * 2
        var y = margin

        drawHeader(sheet, x: margin, y: y, width: contentWidth)
        y += 112

        let columns = [
            PDFColumn(title: "N°", width: 34, alignment: .center),
            PDFColumn(title: "Flèche 1", width: 64, alignment: .center),
            PDFColumn(title: "Flèche 2", width: 64, alignment: .center),
            PDFColumn(title: "Total", width: 70, alignment: .center),
            PDFColumn(title: "Cumul", width: 68, alignment: .center),
            PDFColumn(title: "11", width: 36, alignment: .center),
            PDFColumn(title: "10", width: 36, alignment: .center),
        ]

        drawTable(sheet, columns: columns, x: margin, y: y, width: contentWidth)
    }

    private static func drawHeader(_ sheet: ArcherScoreSheet, x: CGFloat, y: CGFloat, width: CGFloat) {
        let logoRect = CGRect(x: x + (width - 174) / 2, y: y, width: 174, height: 50)
        if let logo = UIImage(named: "Score3DHomeLogo") {
            logo.draw(in: aspectFittedRect(for: logo.size, in: logoRect))
        } else {
            drawText("Score3D", in: logoRect, font: .boldSystemFont(ofSize: 28), color: .black, alignment: .center)
        }

        drawText(sheet.roundName, in: CGRect(x: x, y: y + 58, width: width, height: 18), font: .boldSystemFont(ofSize: 12), color: .black, alignment: .center)
        drawText(sheet.archerName.uppercased(), in: CGRect(x: x, y: y + 78, width: width, height: 18), font: .boldSystemFont(ofSize: 13), color: .black, alignment: .center)
        drawText(formattedDate(sheet.roundDate), in: CGRect(x: x, y: y + 98, width: width, height: 12), font: .systemFont(ofSize: 8), color: .darkGray, alignment: .center)
    }

    private static func drawTable(_ sheet: ArcherScoreSheet, columns: [PDFColumn], x: CGFloat, y: CGFloat, width: CGFloat) {
        let headerHeight: CGFloat = 24
        let rowHeight: CGFloat = 16.8
        var currentX = x

        UIColor(white: 0.92, alpha: 1).setFill()
        UIRectFill(CGRect(x: x, y: y, width: width, height: headerHeight))

        for column in columns {
            let rect = CGRect(x: currentX, y: y, width: column.width, height: headerHeight)
            stroke(rect)
            drawText(column.title, in: rect.insetBy(dx: 2, dy: 7), font: .boldSystemFont(ofSize: 7), color: .black, alignment: column.alignment)
            currentX += column.width
        }

        for (index, row) in sheet.rows.enumerated() {
            let rowY = y + headerHeight + CGFloat(index) * rowHeight
            let values = [
                "\(row.targetNumber)",
                ScoreRules.displayValue(row.arrow1),
                ScoreRules.displayValue(row.arrow2),
                "\(row.targetTotal)",
                "\(row.cumulativeTotal)",
                row.scoreCount(11),
                row.scoreCount(10),
            ]
            currentX = x

            for (columnIndex, column) in columns.enumerated() {
                let rect = CGRect(x: currentX, y: rowY, width: column.width, height: rowHeight)
                stroke(rect)
                drawText(values[columnIndex], in: rect.insetBy(dx: 2, dy: 4), font: .systemFont(ofSize: 9), color: .black, alignment: column.alignment)
                currentX += column.width
            }
        }

        drawTotalRow(
            sheet,
            columns: columns,
            x: x,
            y: y + headerHeight + CGFloat(sheet.rows.count) * rowHeight,
            rowHeight: rowHeight
        )
    }

    private static func drawTotalRow(
        _ sheet: ArcherScoreSheet,
        columns: [PDFColumn],
        x: CGFloat,
        y: CGFloat,
        rowHeight: CGFloat
    ) {
        UIColor(white: 0.92, alpha: 1).setFill()
        UIRectFill(CGRect(x: x, y: y, width: columns.reduce(0) { $0 + $1.width }, height: rowHeight))

        let labelWidth = columns.prefix(3).reduce(0) { $0 + $1.width }
        let labelRect = CGRect(x: x, y: y, width: labelWidth, height: rowHeight)
        stroke(labelRect)
        drawText("TOTAL GÉNÉRAL", in: labelRect.insetBy(dx: 4, dy: 4), font: .boldSystemFont(ofSize: 8), color: .black, alignment: .left)

        let values = [
            "\(sheet.breakdown.total)",
            "\(sheet.breakdown.total)",
            "\(sheet.breakdown.elevens)",
            "\(sheet.breakdown.tens)",
        ]
        var currentX = x + labelWidth

        for (index, column) in columns.dropFirst(3).enumerated() {
            let rect = CGRect(x: currentX, y: y, width: column.width, height: rowHeight)
            stroke(rect)
            drawText(values[index], in: rect.insetBy(dx: 2, dy: 4), font: .boldSystemFont(ofSize: 9), color: .black, alignment: column.alignment)
            currentX += column.width
        }
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = .byTruncatingTail

        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraphStyle,
            ]
        )
    }

    private static func stroke(_ rect: CGRect) {
        UIColor.black.setStroke()
        UIBezierPath(rect: rect).stroke()
    }

    private static func aspectFittedRect(for imageSize: CGSize, in boundingRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return boundingRect }

        let scale = min(boundingRect.width / imageSize.width, boundingRect.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: boundingRect.midX - fittedSize.width / 2,
            y: boundingRect.midY - fittedSize.height / 2,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }

    private static func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let forbiddenCharacters = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        return name
            .components(separatedBy: forbiddenCharacters)
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct PDFColumn {
    let title: String
    let width: CGFloat
    let alignment: NSTextAlignment
}

private extension ArcherScoreSheetRow {
    func scoreCount(_ score: Int) -> String {
        let count = [arrow1, arrow2].filter { $0 == score }.count
        return count == 0 ? "" : "\(count)"
    }
}

private struct ArcherScoreSheetRowView: View {
    let row: ArcherScoreSheetRow

    var body: some View {
        HStack(spacing: 8) {
            Text("\(row.targetNumber)")
                .font(.body.weight(.semibold))
                .foregroundStyle(Score3DTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            scoreCell(ScoreRules.displayValue(row.arrow1), width: 34)
            scoreCell(ScoreRules.displayValue(row.arrow2), width: 34)
            scoreCell("\(row.targetTotal)", width: 52, isStrong: true)
            scoreCell("\(row.cumulativeTotal)", width: 58, isStrong: true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Score3DTheme.border)
                .frame(height: 1)
        }
    }

    private func scoreCell(_ value: String, width: CGFloat, isStrong: Bool = false) -> some View {
        Text(value)
            .font(.body.monospacedDigit().weight(isStrong ? .semibold : .regular))
            .foregroundStyle(isStrong ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
            .frame(width: width, alignment: .trailing)
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
                            suggestionNames: recentArcherNameSuggestions,
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

    private var recentArcherNameSuggestions: [String] {
        RoundSetupRules.recentArcherNameSuggestions(
            from: rounds.map { ArcherNameSuggestionSource(date: $0.date, archerNames: $0.archerNames) }
        )
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

struct EditRoundFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var round: ShootingRound
    @Query private var rounds: [ShootingRound]
    let onDone: () -> Void

    @State private var name: String
    @State private var date: Date
    @State private var initialName: String
    @State private var initialDate: Date
    @State private var slots: [RoundArcherSlot]
    @State private var initialSlotNames: [String]
    @State private var isShowingCancelConfirmation = false
    @State private var persistenceAlert: PersistenceAlert?
    @State private var datePickerID = UUID()
    @FocusState private var focusedSlotID: UUID?

    init(round: ShootingRound, onDone: @escaping () -> Void) {
        self.round = round
        self.onDone = onDone

        let archerSlots = round.archerNames.map { RoundArcherSlot(name: $0) }
        _name = State(initialValue: round.name)
        _date = State(initialValue: round.date)
        _initialName = State(initialValue: round.name)
        _initialDate = State(initialValue: round.date)
        _slots = State(initialValue: archerSlots)
        _initialSlotNames = State(initialValue: archerSlots.map(\.name))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Parcours") {
                    TextField("Nom du parcours", text: $name)
                        .foregroundStyle(Score3DTheme.textPrimary)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)

                    DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                        .id(datePickerID)
                        .onChange(of: date) { _, _ in
                            datePickerID = UUID()
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
                            suggestionNames: recentArcherNameSuggestions,
                            canRemove: false,
                            removeAction: { }
                        )
                    }
                } header: {
                    Text("Peloton")
                        .foregroundStyle(Score3DTheme.textPrimary)
                } footer: {
                    if hasDuplicateNames {
                        Text("Chaque archer du peloton doit avoir un nom distinct.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Le nombre d’archers ne peut pas être modifié après la création du parcours.")
                            .foregroundStyle(Score3DTheme.textSecondary)
                    }
                }
                .listRowBackground(Score3DTheme.surface)

                Section {
                    Button(action: saveChanges) {
                        Text("Enregistrer les modifications")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 54)
                    }
                    .buttonStyle(PrimaryActionButtonStyle())
                    .disabled(!canSave)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Score3DTheme.background)
            .tint(Score3DTheme.interaction)
            .navigationTitle("Modifier le parcours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler", action: cancel)
                }

            }
            .alert("Abandonner les modifications ?", isPresented: $isShowingCancelConfirmation) {
                Button("Continuer l’édition", role: .cancel) { }
                Button("Abandonner", role: .destructive, action: onDone)
            } message: {
                Text("Les modifications saisies pour ce parcours seront perdues.")
            }
            .alert(item: $persistenceAlert) { alert in
                Alert(
                    title: Text("Sauvegarde impossible"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .interactiveDismissDisabled(hasChanges)
            .background {
                SheetDismissAttemptHandler(isDisabled: hasChanges) {
                    isShowingCancelConfirmation = true
                }
            }
        }
    }

    private var editedArcherNames: [String] {
        RoundSetupRules.resolvedEditedPelotonNames(slots.map(\.name))
    }

    private var hasDuplicateNames: Bool {
        RoundSetupRules.containsDuplicateArcherNames(editedArcherNames)
    }

    private var canSave: Bool {
        !slots.isEmpty && !hasDuplicateNames
    }

    private var recentArcherNameSuggestions: [String] {
        RoundSetupRules.recentArcherNameSuggestions(
            from: rounds.map { ArcherNameSuggestionSource(date: $0.date, archerNames: $0.archerNames) }
        )
    }

    private var hasChanges: Bool {
        name != initialName || date != initialDate || slots.map(\.name) != initialSlotNames
    }

    private func slotIndex(for slot: RoundArcherSlot) -> Int {
        (slots.firstIndex { $0.id == slot.id } ?? 0) + 1
    }

    private func cancel() {
        if hasChanges {
            isShowingCancelConfirmation = true
        } else {
            onDone()
        }
    }

    private func saveChanges() {
        let resolvedName = RoundSetupRules.uniqueRoundName(
            baseName: name,
            date: date,
            existingRounds: rounds
                .filter { $0.persistentModelID != round.persistentModelID }
                .map { RoundListSnapshot(name: $0.name, date: $0.date, isFinished: $0.isFinished) }
        )
        let archerNamesByOrder = Dictionary(uniqueKeysWithValues: editedArcherNames.enumerated().map { ($0.offset, $0.element) })

        round.name = resolvedName
        round.date = date
        for entry in round.entries {
            if let archerName = archerNamesByOrder[entry.archerOrder] {
                entry.archerName = archerName
            }
        }

        do {
            try modelContext.save()
            onDone()
        } catch {
            modelContext.rollback()
            persistenceAlert = PersistenceAlert(message: "Le parcours n’a pas pu être modifié. Réessayez avant de fermer l’app.")
        }
    }
}

private struct RoundArcherSlotView: View {
    let index: Int
    @Binding var slot: RoundArcherSlot
    var focusedSlotID: FocusState<UUID?>.Binding
    let suggestionNames: [String]
    let canRemove: Bool
    let removeAction: () -> Void

    private var bestSuggestion: String? {
        RoundSetupRules.matchingArcherNameSuggestions(for: slot.name, in: suggestionNames, limit: 1).first
    }

    private var completionSuffix: String? {
        guard focusedSlotID.wrappedValue == slot.id,
              let bestSuggestion,
              slot.name.count < bestSuggestion.count else { return nil }

        let suffixStartIndex = bestSuggestion.index(bestSuggestion.startIndex, offsetBy: slot.name.count)
        return String(bestSuggestion[suffixStartIndex...])
    }

    private func applyBestSuggestion() {
        if let bestSuggestion {
            slot.name = bestSuggestion
        }

        focusedSlotID.wrappedValue = nil
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Archer \(index)")
                    .font(.headline)
                    .foregroundStyle(Score3DTheme.textPrimary)

                ZStack(alignment: .leading) {
                    if let completionSuffix {
                        HStack(spacing: 0) {
                            Text(slot.name)
                                .foregroundStyle(.clear)
                            Text(completionSuffix)
                                .foregroundStyle(Score3DTheme.textSecondary.opacity(0.7))
                        }
                        .font(.body)
                        .allowsHitTesting(false)
                    }

                    TextField("Archer \(index)", text: $slot.name)
                        .foregroundStyle(Score3DTheme.textPrimary)
                        .textInputAutocapitalization(.words)
                        .textContentType(.name)
                        .autocorrectionDisabled(true)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .focused(focusedSlotID, equals: slot.id)
                        .onSubmit(applyBestSuggestion)
                }
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
                    .padding(.top, 14)
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
            Button("Retour") {
                dismiss()
            }
            .font(.body)
            .foregroundStyle(Score3DTheme.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Score3DTheme.surface, in: Capsule())
            .contentShape(Capsule())
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
                        .frame(width: 32, alignment: .center)
                        .accessibilityLabel("Flèche 1")

                    Text("F2")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .frame(width: 32, alignment: .center)
                        .accessibilityLabel("Flèche 2")

                    Color.clear
                        .frame(width: 12, height: 1)

                    Text("Total")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .frame(width: 40, alignment: .center)

                    Text("Cumul")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(Score3DTheme.textSecondary)
                        .lineLimit(1)
                        .frame(width: 54, alignment: .center)
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
                                .frame(width: 32, alignment: .center)
                                .accessibilityLabel("Flèche 1 \(ScoreRules.displayValue(entry?.arrow1))")

                            Text(ScoreRules.displayValue(entry?.arrow2))
                                .font(.system(size: 20, weight: .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 32, alignment: .center)
                                .accessibilityLabel("Flèche 2 \(ScoreRules.displayValue(entry?.arrow2))")

                            Color.clear
                                .frame(width: 12, height: 1)

                            Text("\(entry?.targetTotal ?? 0)")
                                .font(.system(size: 20, weight: index == round.currentArcherIndex ? .bold : .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 40, alignment: .center)

                            Text("\(round.total(for: name))")
                                .font(.system(size: 20, weight: index == round.currentArcherIndex ? .bold : .regular, design: .default).monospacedDigit())
                                .foregroundStyle(index == round.currentArcherIndex ? Score3DTheme.textPrimary : Score3DTheme.textSecondary)
                                .frame(width: 54, alignment: .center)
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
