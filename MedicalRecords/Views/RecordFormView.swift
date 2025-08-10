import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct RecordFormView: View {
    enum Mode: Equatable {
        case add
        case edit(existing: MedicalRecord)
    }

    enum OutputAction {
        case save(hospitalName: String, date: Date, attachment: PendingAttachment?)
        case cancel
    }

    let mode: Mode
    let onComplete: (OutputAction) -> Void

    @State private var hospitalName: String = ""
    @State private var date: Date = Date()

    @State private var selectedImage: UIImage? = nil
    @State private var selectedDocumentURL: URL? = nil

    @State private var isShowingDocumentPicker = false
    @State private var isShowingPhotoLibrary = false
    @State private var isShowingCamera = false

    init(mode: Mode, onComplete: @escaping (OutputAction) -> Void) {
        self.mode = mode
        self.onComplete = onComplete
        _hospitalName = State(initialValue: {
            if case .edit(let existing) = mode { return existing.hospitalName }
            return ""
        }())
        _date = State(initialValue: {
            if case .edit(let existing) = mode { return existing.date }
            return Date()
        }())
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Hospital Name", text: $hospitalName)
                DatePicker("Date", selection: $date, displayedComponents: [.date])
            }

            Section("Attachment") {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let selectedDocumentURL {
                    HStack {
                        Image(systemName: "doc.richtext")
                        Text(selectedDocumentURL.lastPathComponent)
                        Spacer()
                    }
                } else if case .edit(let existing) = mode {
                    HStack {
                        Image(systemName: iconName(for: existing.attachmentFilename))
                        Text(existing.attachmentFilename)
                            .lineLimit(1)
                        Spacer()
                    }
                } else {
                    Text("No file selected")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button {
                        isShowingDocumentPicker = true
                    } label: {
                        Label("Import PDF", systemImage: "doc.fill")
                    }
                    Spacer()
                    Button {
                        isShowingPhotoLibrary = true
                    } label: {
                        Label("Photo Library", systemImage: "photo")
                    }
                    Spacer()
                    Button {
                        isShowingCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle(mode == .add ? "New Record" : "Edit Record")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { onComplete(.cancel) }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    switch mode {
                    case .add:
                        if let attachment = buildAttachment() {
                            onComplete(.save(hospitalName: hospitalName, date: date, attachment: attachment))
                        }
                    case .edit:
                        onComplete(.save(hospitalName: hospitalName, date: date, attachment: buildAttachment()))
                    }
                }
                .disabled(!canSave)
            }
        }
        .sheet(isPresented: $isShowingDocumentPicker) {
            DocumentPickerView(allowedContentTypes: [UTType.pdf]) { url in
                selectedDocumentURL = url
                selectedImage = nil
            }
        }
        .sheet(isPresented: $isShowingPhotoLibrary) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                selectedImage = image
                selectedDocumentURL = nil
            }
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePickerView(sourceType: .camera) { image in
                selectedImage = image
                selectedDocumentURL = nil
            }
        }
    }

    private var canSave: Bool {
        guard !hospitalName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        switch mode {
        case .add:
            return selectedImage != nil || selectedDocumentURL != nil
        case .edit:
            return true
        }
    }

    private func buildAttachment() -> PendingAttachment? {
        if let selectedImage { return .image(selectedImage) }
        if let selectedDocumentURL { return .fileURL(selectedDocumentURL) }
        return nil
    }

    private func iconName(for filename: String) -> String {
        let lower = filename.lowercased()
        if lower.hasSuffix(".pdf") { return "doc.richtext" }
        if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".png") { return "photo" }
        return "doc"
    }
}

#Preview {
    NavigationStack {
        RecordFormView(mode: .add) { _ in }
    }
}