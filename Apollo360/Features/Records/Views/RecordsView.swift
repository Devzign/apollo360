//
//  RecordsView.swift
//  Apollo360
//
//  Created by Codex on 07/04/26.
//

import SwiftUI
import PDFKit
import UIKit
import Combine

private let recordsPageBackground = Color(
    red: 244 / 255,
    green: 244 / 255,
    blue: 244 / 255
)

struct RecordsView: View {
    @StateObject private var viewModel: RecordsViewModel
    private let horizontalPadding: CGFloat
    private let session: SessionManager

    init(horizontalPadding: CGFloat, session: SessionManager) {
        self.horizontalPadding = horizontalPadding
        self.session = session
        _viewModel = StateObject(wrappedValue: RecordsViewModel(session: session))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                recordsPageBackground.ignoresSafeArea()

                VStack(spacing: 18) {
                    segmentControl

                    if viewModel.isLoading && viewModel.folders.isEmpty && viewModel.encounters.isEmpty {
                        loadingView
                    } else if let error = viewModel.errorMessage,
                              viewModel.folders.isEmpty && viewModel.encounters.isEmpty {
                        errorView(message: error)
                    } else {
                        contentView
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, 16)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.loadIfNeeded()
        }
    }

    private var segmentControl: some View {
        HStack(spacing: 14) {
            ForEach(RecordsViewModel.Segment.allCases) { segment in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedSegment = segment
                    }
                } label: {
                    Text(segment.rawValue)
                        .font(AppFont.body(size: 16, weight: .semibold))
                        .foregroundColor(viewModel.selectedSegment == segment ? .white : AppColor.color414141)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedSegment == segment ? AppColor.green : Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.selectedSegment {
        case .documents:
            documentListView
        case .doctorVisits:
            doctorVisitListView
        }
    }

    private var documentListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 18) {
                ForEach(viewModel.folders) { folder in
                    NavigationLink {
                        DocumentFolderDetailView(folder: folder)
                    } label: {
                        FolderCardView(title: folder.name, count: folder.visibleDocuments.count)
                    }
                    .buttonStyle(.plain)
                }
                bottomSpacer
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    private var doctorVisitListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("MD Visits")
                        .font(AppFont.display(size: 22, weight: .semibold))
                        .foregroundColor(AppColor.color414141)
                    Spacer()
                    CountBadge(count: viewModel.encounters.count)
                }

                LazyVStack(spacing: 18) {
                    ForEach(viewModel.encounters) { encounter in
                        NavigationLink {
                            DoctorVisitDetailView(session: session, encounter: encounter)
                        } label: {
                            DoctorVisitCardView(encounter: encounter)
                        }
                        .buttonStyle(.plain)
                    }
                }

                bottomSpacer
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            viewModel.refresh()
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(AppColor.green)
            Text("Loading records...")
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundColor(AppColor.grey)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 18) {
            Text(message)
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundColor(AppColor.red)
                .multilineTextAlignment(.center)

            Button("Retry") {
                viewModel.refresh()
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .background(AppColor.green)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var bottomSpacer: some View {
        Color.clear.frame(height: 160)
    }
}

private struct FolderCardView: View {
    let title: String
    let count: Int

    var body: some View {
        HStack(spacing: 14) {
            Text(title)
                .font(AppFont.display(size: 18, weight: .semibold))
                .foregroundColor(AppColor.color414141)
                .multilineTextAlignment(.leading)

            CountBadge(count: count)

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppColor.color414141)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 26)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct DoctorVisitCardView: View {
    let encounter: DoctorVisitEncounter

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(encounter.title)
                    .font(AppFont.display(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.green)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .medium))
                    Text(encounter.preferredDisplayDate)
                        .font(AppFont.body(size: 14, weight: .medium))
                }
                .foregroundColor(AppColor.color414141)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(AppColor.color414141)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct CountBadge: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(AppFont.body(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .frame(minWidth: 28, minHeight: 28)
            .padding(.horizontal, 2)
            .background(Circle().fill(AppColor.green.opacity(0.85)))
    }
}

private struct DocumentFolderDetailView: View {
    let folder: PatientDocumentFolder
    @StateObject private var downloadController = RecordDownloadController()
    @State private var previewAsset: PreviewAsset?

    var body: some View {
        ZStack {
            recordsPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Text(folder.name)
                            .font(AppFont.display(size: 22, weight: .semibold))
                            .foregroundColor(AppColor.color414141)
                        Spacer()
                        CountBadge(count: folder.visibleDocuments.count)
                    }

                    LazyVStack(spacing: 16) {
                        ForEach(folder.visibleDocuments) { document in
                            Button {
                                handleSelection(document)
                            } label: {
                                DocumentRowView(document: document)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Color.clear
                        .frame(height: 180)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 40)
            }

            if downloadController.isBusy {
                ProgressOverlayView(text: downloadController.statusText)
            }
        }
        .navigationTitle(folder.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $downloadController.shareItem) { item in
            ActivityView(items: [item.url])
        }
        .fullScreenCover(item: $previewAsset) { asset in
            DocumentPreviewScreen(asset: asset, downloadController: downloadController)
        }
        .alert("Download Failed", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                downloadController.errorMessage = nil
            }
        } message: {
            Text(downloadController.errorMessage ?? "")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { downloadController.errorMessage != nil },
            set: { if !$0 { downloadController.errorMessage = nil } }
        )
    }

    private func handleSelection(_ document: PatientDocumentItem) {
        guard let remoteURL = document.fileURL else { return }
        if document.isPDF || document.isImage {
            previewAsset = PreviewAsset(document: document, remoteURL: remoteURL)
        } else {
            downloadController.downloadAndShare(from: remoteURL, suggestedName: document.title)
        }
    }
}

private struct DocumentRowView: View {
    let document: PatientDocumentItem

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(document.title)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
                    .multilineTextAlignment(.leading)

                if let detail = document.detailText {
                    Text(detail)
                        .font(AppFont.body(size: 13))
                        .foregroundColor(AppColor.grey)
                        .multilineTextAlignment(.leading)
                }

                Text(document.date)
                    .font(AppFont.body(size: 13, weight: .medium))
                    .foregroundColor(AppColor.green)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColor.color414141)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct PreviewAsset: Identifiable {
    let document: PatientDocumentItem
    let remoteURL: URL

    var id: Int { document.id }
}

private struct DocumentPreviewScreen: View {
    let asset: PreviewAsset
    @ObservedObject var downloadController: RecordDownloadController

    @Environment(\.dismiss) private var dismiss
    @State private var localFileURL: URL?
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                recordsPageBackground.ignoresSafeArea()

                VStack(spacing: 16) {
                    actionRow

                    Group {
                        if isLoading {
                            ProgressOverlayView(text: "Preparing preview...")
                        } else if let errorMessage {
                            inlineError(errorMessage)
                        } else if asset.document.isPDF, let localFileURL {
                            PDFKitView(url: localFileURL)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else if asset.document.isImage, let image {
                            ZoomableImageView(image: image)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else {
                            inlineError("This file type cannot be previewed in-app.")
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 16)
            }
            .navigationBarHidden(true)
            .sheet(item: $downloadController.shareItem) { item in
                ActivityView(items: [item.url])
            }
            .task {
                await loadPreview()
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.green)
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                downloadController.downloadAndShare(from: asset.remoteURL, suggestedName: asset.document.title)
            } label: {
                Text("Download")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColor.green)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private func inlineError(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundColor(AppColor.red)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
        )
    }

    private func loadPreview() async {
        isLoading = true
        errorMessage = nil
        do {
            let (url, _) = try await URLSession.shared.download(from: asset.remoteURL)
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + "-" + asset.document.title)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: url, to: destination)
            localFileURL = destination

            if asset.document.isImage {
                guard let data = try? Data(contentsOf: destination),
                      let uiImage = UIImage(data: data) else {
                    throw PreviewError.invalidImage
                }
                image = uiImage
            }
            isLoading = false
        } catch {
            errorMessage = "Unable to load this document."
            isLoading = false
        }
    }
}

private enum PreviewError: Error {
    case invalidImage
}

private struct DoctorVisitDetailView: View {
    let session: SessionManager
    let encounter: DoctorVisitEncounter

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DoctorVisitDetailViewModel
    @StateObject private var exportController = DoctorVisitExportController()

    init(session: SessionManager, encounter: DoctorVisitEncounter) {
        self.session = session
        self.encounter = encounter
        _viewModel = StateObject(wrappedValue: DoctorVisitDetailViewModel(session: session, encounterId: encounter.id))
    }

    var body: some View {
        ZStack {
            recordsPageBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    actionRow

                    Group {
                        if viewModel.isLoading && viewModel.summary == nil {
                            ProgressOverlayView(text: "Loading visit details...")
                                .frame(maxWidth: .infinity, minHeight: 260)
                        } else if let error = viewModel.errorMessage, viewModel.summary == nil {
                            errorCard(message: error)
                        } else if let summary = viewModel.summary {
                            DoctorVisitSummaryContent(summary: summary)
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Color.clear
                        .frame(height: 180)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }

            if exportController.isExporting {
                ProgressOverlayView(text: "Preparing download...")
            }
        }
        .navigationBarHidden(true)
        .task {
            viewModel.load()
        }
        .sheet(item: $exportController.shareItem) { item in
            ActivityView(items: [item.url])
        }
        .alert("Export Failed", isPresented: exportErrorBinding) {
            Button("OK", role: .cancel) {
                exportController.errorMessage = nil
            }
        } message: {
            Text(exportController.errorMessage ?? "")
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .font(AppFont.body(size: 16, weight: .semibold))
                .foregroundColor(AppColor.green)
                .padding(.leading, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                guard let summary = viewModel.summary else { return }
                exportController.export(summary: summary, encounterTitle: encounter.title)
            } label: {
                Text("Download")
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColor.green)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.summary == nil)
        }
    }

    private var exportErrorBinding: Binding<Bool> {
        Binding(
            get: { exportController.errorMessage != nil },
            set: { if !$0 { exportController.errorMessage = nil } }
        )
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(AppFont.body(size: 15, weight: .medium))
                .foregroundColor(AppColor.red)
                .multilineTextAlignment(.center)
            Button("Retry") {
                viewModel.load()
            }
            .font(AppFont.body(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(AppColor.green)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct DoctorVisitSummaryContent: View {
    let summary: DoctorVisitSummaryPayload

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            brandedPractitionerCard
            patientCard
            ForEach(summarySections, id: \.title) { section in
                DetailSectionCard(title: section.title, lines: section.lines)
            }
            attestationFooter
        }
    }

    private var brandedPractitionerCard: some View {
        VStack(alignment: .center, spacing: 12) {
            Image("mantthan_logo")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 230, maxHeight: 84)

            Text(practitionerDisplayName)
                .font(AppFont.display(size: 19, weight: .semibold))
                .foregroundColor(AppColor.color414141)
                .multilineTextAlignment(.center)
            if let credentials = summary.practitioner.credentials?.nonEmpty {
                Text(credentials)
                    .font(AppFont.body(size: 15, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
            }
            if let department = summary.practitioner.department?.nonEmpty {
                Text(department)
                    .font(AppFont.body(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
            }
            ForEach(summary.practitioner.address?.formattedLines ?? [], id: \.self) { line in
                Text(line)
                    .font(AppFont.body(size: 15))
                    .foregroundColor(AppColor.color414141)
                    .multilineTextAlignment(.center)
            }
            let phone = summary.practitioner.phone?.nonEmpty
            let fax = summary.practitioner.fax?.nonEmpty
            if phone != nil || fax != nil {
                Text([phone.map { "Ph: \($0)" }, fax.map { "F: \($0)" }].compactMap { $0 }.joined(separator: "   "))
                    .font(AppFont.body(size: 15, weight: .medium))
                    .foregroundColor(AppColor.color414141)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
    }

    private var practitionerDisplayName: String {
        let name = summary.practitioner.name?.nonEmpty ?? "Practitioner"
        return name.uppercased()
    }

    private var patientCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SummaryKeyValueRow(label: "Date", value: summary.encounter.date?.nonEmpty ?? summary.encounter.dateOfService?.nonEmpty ?? "—")
            SummaryKeyValueRow(label: "Patient's Name", value: summary.patient.name?.nonEmpty ?? "—")
            SummaryKeyValueRow(label: "DOB", value: summary.patient.dob?.nonEmpty ?? "—")
            if let serviceDate = summary.encounter.dateOfService?.nonEmpty,
               serviceDate != (summary.encounter.date?.nonEmpty ?? "") {
                SummaryKeyValueRow(label: "Date of Service", value: serviceDate)
            }
            if !encounterCodes.isEmpty {
                SummaryKeyValueRow(label: "CPT Codes", value: encounterCodes.joined(separator: ", "))
            }
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
    }

    private var encounterCodes: [String] {
        []
    }

    private var signerText: String? {
        let name = summary.encounter.signedBy?.name?.nonEmpty
        let date = summary.encounter.signedBy?.date?.nonEmpty
        if let name, let date {
            return "\(name) | \(date)"
        }
        return name ?? date
    }

    private var summarySections: [SummarySection] {
        buildDoctorVisitSections(summary)
    }

    private var attestationFooter: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let attestation = attestationText {
                Text(attestation)
                    .font(AppFont.body(size: 13))
                    .foregroundColor(AppColor.color414141)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let signatureURL = signatureURL {
                RemoteDetailImage(url: signatureURL, contentMode: .fit) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppColor.colorECF0F3)
                        .overlay(
                            Text("Signature")
                                .font(AppFont.body(size: 12, weight: .medium))
                                .foregroundColor(AppColor.grey)
                        )
                }
                .frame(width: 260, height: 96)
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppColor.colorECF0F3)
                    .overlay(
                        Text("Signature unavailable")
                            .font(AppFont.body(size: 12, weight: .medium))
                            .foregroundColor(AppColor.grey)
                    )
                    .frame(width: 260, height: 96)
            }

            if let signedBy = signerText {
                Text("Electronically signed by \(signedBy)")
                    .font(AppFont.body(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.color414141)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
    }

    private var signatureURL: URL? {
        guard let path = summary.practitioner.signature?.nonEmpty else { return nil }
        return resolvedAssetURL(path)
    }

    private var attestationText: String? {
        guard let signer = summary.encounter.signedBy?.name?.nonEmpty else { return nil }
        let date = summary.encounter.signedBy?.date?.nonEmpty ?? summary.encounter.date?.nonEmpty ?? ""
        if date.isEmpty {
            return "I, \(signer), hereby attest that the medical record entries accurately reflect my notes and actions."
        }
        return "I, \(signer), hereby attest that the medical record entries for \(date) accurately reflect my notes and actions."
    }
}

private struct SummarySection {
    let title: String
    let lines: [String]
}

private struct SummaryKeyValueRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(AppFont.body(size: 17, weight: .semibold))
                .foregroundColor(AppColor.color414141)
            Text(value)
                .font(AppFont.body(size: 17))
                .foregroundColor(AppColor.color414141)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DetailSectionCard: View {
    let title: String
    let lines: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(AppFont.display(size: 18, weight: .semibold))
                .foregroundColor(AppColor.color414141)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                ForEach(lines, id: \.self) { line in
                    Text(line.hasPrefix("•") ? line : "• \(line)")
                        .font(AppFont.body(size: 16))
                        .foregroundColor(AppColor.color414141)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct ProgressOverlayView: View {
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(AppColor.green)
            Text(text)
                .font(AppFont.body(size: 14, weight: .medium))
                .foregroundColor(AppColor.color414141)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
    }
}

private struct PDFKitView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

private struct ZoomableImageView: View {
    let image: UIImage

    var body: some View {
        GeometryReader { proxy in
            ScrollView([.horizontal, .vertical], showsIndicators: false) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
                    .background(Color.white)
            }
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct RemoteDetailImage<Placeholder: View>: View {
    @StateObject private var loader: RemoteDetailImageLoader
    let placeholder: Placeholder
    let contentMode: ContentMode

    init(url: URL, contentMode: ContentMode = .fill, @ViewBuilder placeholder: () -> Placeholder) {
        _loader = StateObject(wrappedValue: RemoteDetailImageLoader(url: url))
        self.placeholder = placeholder()
        self.contentMode = contentMode
    }

    var body: some View {
        Group {
            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .onAppear {
            loader.load()
        }
    }
}

private final class RemoteDetailImageLoader: ObservableObject {
    @Published var image: UIImage?
    private let url: URL
    private var hasLoaded = false

    init(url: URL) {
        self.url = url
    }

    func load() {
        guard !hasLoaded else { return }
        hasLoaded = true
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self.image = image
            }
        }
        .resume()
    }
}

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

@MainActor
private final class RecordDownloadController: ObservableObject {
    @Published var isBusy = false
    @Published var shareItem: ShareItem?
    @Published var errorMessage: String?
    @Published var statusText = "Preparing file..."

    func downloadAndShare(from remoteURL: URL, suggestedName: String) {
        guard !isBusy else { return }
        isBusy = true
        statusText = "Downloading..."
        errorMessage = nil

        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + "-" + suggestedName)
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: tempURL, to: destination)
                shareItem = ShareItem(url: destination)
            } catch {
                errorMessage = "Unable to download this file."
            }
            isBusy = false
        }
    }
}

@MainActor
private final class DoctorVisitExportController: ObservableObject {
    @Published var isExporting = false
    @Published var shareItem: ShareItem?
    @Published var errorMessage: String?

    func export(summary: DoctorVisitSummaryPayload, encounterTitle: String) {
        guard !isExporting else { return }
        isExporting = true
        errorMessage = nil

        Task {
            defer { isExporting = false }
            do {
                let url = try DoctorVisitPDFExporter.export(summary: summary, encounterTitle: encounterTitle)
                shareItem = ShareItem(url: url)
            } catch {
                errorMessage = "Unable to generate the visit PDF."
            }
        }
    }
}

private enum DoctorVisitPDFExporter {
    static func export(summary: DoctorVisitSummaryPayload, encounterTitle: String) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(encounterTitle.replacingOccurrences(of: " ", with: "-"))-\(UUID().uuidString).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: fileURL) { context in
            let margin: CGFloat = 36
            var cursorY: CGFloat = margin

            func newPageIfNeeded(_ height: CGFloat) {
                if cursorY + height > 756 {
                    context.beginPage()
                    cursorY = margin
                }
            }

            func draw(_ text: String, font: UIFont, color: UIColor = .black, spacingAfter: CGFloat = 12) {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                let paragraph = NSMutableParagraphStyle()
                paragraph.lineBreakMode = .byWordWrapping
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: color,
                    .paragraphStyle: paragraph
                ]
                let rect = CGRect(x: margin, y: cursorY, width: 612 - (margin * 2), height: 1000)
                let bounding = NSString(string: text).boundingRect(
                    with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
                    options: [.usesLineFragmentOrigin, .usesFontLeading],
                    attributes: attributes,
                    context: nil
                )
                newPageIfNeeded(bounding.height + spacingAfter)
                NSString(string: text).draw(with: CGRect(x: margin, y: cursorY, width: rect.width, height: ceil(bounding.height)), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
                cursorY += ceil(bounding.height) + spacingAfter
            }

            context.beginPage()

            draw("Doctor Visit Summary", font: .boldSystemFont(ofSize: 24), color: UIColor(AppColor.color414141))
            draw(summary.practitioner.name?.nonEmpty ?? "Practitioner", font: .boldSystemFont(ofSize: 18))
            if let credentials = summary.practitioner.credentials?.nonEmpty { draw(credentials, font: .systemFont(ofSize: 14)) }
            if let department = summary.practitioner.department?.nonEmpty { draw(department, font: .systemFont(ofSize: 14)) }
            for line in summary.practitioner.address?.formattedLines ?? [] {
                draw(line, font: .systemFont(ofSize: 13), spacingAfter: 6)
            }
            if let phone = summary.practitioner.phone?.nonEmpty { draw("Phone: \(phone)", font: .systemFont(ofSize: 13), spacingAfter: 6) }
            if let fax = summary.practitioner.fax?.nonEmpty { draw("Fax: \(fax)", font: .systemFont(ofSize: 13)) }

            draw("Patient", font: .boldSystemFont(ofSize: 18))
            draw("Name: \(summary.patient.name?.nonEmpty ?? "—")", font: .systemFont(ofSize: 14), spacingAfter: 6)
            draw("DOB: \(summary.patient.dob?.nonEmpty ?? "—")", font: .systemFont(ofSize: 14), spacingAfter: 6)
            draw("Date: \(summary.encounter.date?.nonEmpty ?? summary.encounter.dateOfService?.nonEmpty ?? "—")", font: .systemFont(ofSize: 14))

            for section in buildDoctorVisitSections(summary) {
                draw(section.title, font: .boldSystemFont(ofSize: 18))
                for line in section.lines {
                    draw("• \(line)", font: .systemFont(ofSize: 14), spacingAfter: 6)
                }
                cursorY += 6
            }
        }
        return fileURL
    }

}

private extension String {
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var htmlStripped: String {
        replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "\n{2,}", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private func resolvedAssetURL(_ path: String) -> URL? {
    guard let trimmed = path.nonEmpty else { return nil }
    if let directURL = URL(string: trimmed), directURL.scheme != nil {
        return directURL
    }
    guard let baseComponents = URLComponents(string: APIConfiguration.currentEnvironment.baseURLString) else {
        return nil
    }
    var components = URLComponents()
    components.scheme = baseComponents.scheme
    components.host = baseComponents.host
    components.port = baseComponents.port
    components.path = trimmed.hasPrefix("/") ? trimmed : "/\(trimmed)"
    return components.url
}

private func buildDoctorVisitSections(_ summary: DoctorVisitSummaryPayload) -> [SummarySection] {
    func collectLines(_ items: [String]?, note: String?) -> [String] {
        var lines = items?.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []
        if let note = note?.nonEmpty {
            lines.append(note)
        }
        return lines
    }

    func collect(history: [VisitDescriptionNote]?, note: String?, noItemsFallback: String? = nil) -> [String] {
        let items = history?.compactMap(\.formattedLine) ?? []
        if !items.isEmpty {
            return collectLines(items, note: note)
        }
        if let fallback = noItemsFallback {
            return [fallback]
        }
        return collectLines([], note: note)
    }

    func socialHistoryLines() -> [String] {
        func socialLine(title: String, usage: VisitSocialUsage?) -> String? {
            guard let usage else { return nil }
            var parts: [String] = []
            if let status = usage.status?.nonEmpty {
                parts.append("Status: \(status)")
            }
            parts.append(contentsOf: usage.usages.compactMap(\.formattedLine))
            guard !parts.isEmpty else { return nil }
            return "\(title): \(parts.joined(separator: " | "))"
        }

        var lines = [
            socialLine(title: "Tobacco", usage: summary.encounter.socialHistory?.tobacco),
            socialLine(title: "Alcohol", usage: summary.encounter.socialHistory?.alcohol),
            socialLine(title: "Drugs", usage: summary.encounter.socialHistory?.drugs)
        ].compactMap { $0 }

        let extras: [(String, String?)] = [
            ("Marital Status", summary.encounter.socialHistory?.maritalStatus),
            ("Children", summary.encounter.socialHistory?.children),
            ("Occupation", summary.encounter.socialHistory?.occupation),
            ("Notes", summary.encounter.socialHistory?.notes)
        ]
        for (label, value) in extras {
            if let value = value?.nonEmpty {
                lines.append("\(label): \(value)")
            }
        }
        return lines
    }

    return [
        SummarySection(title: "Interim History", lines: summary.encounter.interimHistory?.htmlStripped.nonEmpty.map { [$0] } ?? []),
        SummarySection(title: "Medical History", lines: collect(history: summary.encounter.medicalHistory?.conditions, note: summary.encounter.medicalHistory?.note)),
        SummarySection(title: "Surgical History", lines: collect(history: summary.encounter.surgicalHistory?.procedures, note: summary.encounter.surgicalHistory?.note, noItemsFallback: summary.encounter.surgicalHistory?.noSurgeries == true ? "No surgeries" : nil)),
        SummarySection(title: "Medications", lines: collectLines(summary.encounter.medications?.items.compactMap(\.formattedLine), note: summary.encounter.medications?.notTaking == true ? "Patient reports not taking medications." : nil)),
        SummarySection(title: "Allergies", lines: collectLines(summary.encounter.allergies?.items.compactMap(\.formattedLine), note: summary.encounter.allergies?.nkda == true ? "NKDA" : summary.encounter.allergies?.note)),
        SummarySection(title: "Social History", lines: socialHistoryLines()),
        SummarySection(title: "Family History", lines: collectLines(summary.encounter.familyHistory?.relations.compactMap(\.formattedLine), note: summary.encounter.familyHistory?.note)),
        SummarySection(title: "Conditions", lines: collect(history: summary.encounter.conditions, note: nil)),
        SummarySection(title: "Review of Systems", lines: collectLines(summary.encounter.ros?.items.compactMap(\.formattedLine), note: summary.encounter.ros?.notes)),
        SummarySection(title: "Physical Exam", lines: collect(history: summary.encounter.physicalExam?.items, note: summary.encounter.physicalExam?.notes)),
        SummarySection(title: "Assessment", lines: collectLines(summary.encounter.assessment?.codes.compactMap(\.formattedLine), note: summary.encounter.assessment?.notes)),
        SummarySection(title: "Plan", lines: collectLines(summary.encounter.plan.compactMap(\.formattedLine), note: nil)),
        SummarySection(title: "ECG Report", lines: summary.encounter.ecgReport?.nonEmpty.map { [$0] } ?? [])
    ].filter { !$0.lines.isEmpty }
}
