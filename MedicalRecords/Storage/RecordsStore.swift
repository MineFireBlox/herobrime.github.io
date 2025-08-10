import Foundation
import SwiftUI
import UIKit

final class RecordsStore: ObservableObject {
    @Published private(set) var records: [MedicalRecord] = []

    private let jsonFilename = "records.json"
    private let attachmentsFolderName = "Attachments"

    init() {
        load()
    }

    // MARK: - Public API

    func load() {
        do {
            try ensureAttachmentsDirectoryExists()
            let url = recordsJSONURL()
            if FileManager.default.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([MedicalRecord].self, from: data)
                DispatchQueue.main.async {
                    self.records = decoded
                }
            } else {
                DispatchQueue.main.async {
                    self.records = []
                }
            }
        } catch {
            print("Failed to load records: \(error)")
            DispatchQueue.main.async {
                self.records = []
            }
        }
    }

    func addRecord(hospitalName: String, date: Date, attachment: PendingAttachment) {
        do {
            let filename = try persist(attachment: attachment)
            let record = MedicalRecord(hospitalName: hospitalName, date: date, attachmentFilename: filename)
            records.append(record)
            try save()
        } catch {
            print("Failed to add record: \(error)")
        }
    }

    func updateRecord(_ record: MedicalRecord, hospitalName: String, date: Date, newAttachment: PendingAttachment?) {
        guard let index = records.firstIndex(of: record) else { return }
        var updated = record
        updated.hospitalName = hospitalName
        updated.date = date

        do {
            if let newAttachment = newAttachment {
                // Replace file
                let newFilename = try persist(attachment: newAttachment)
                // Remove old attachment
                removeAttachmentIfExists(filename: updated.attachmentFilename)
                updated.attachmentFilename = newFilename
            }
            records[index] = updated
            try save()
        } catch {
            print("Failed to update record: \(error)")
        }
    }

    func delete(at offsets: IndexSet) {
        for offset in offsets {
            let record = records[offset]
            removeAttachmentIfExists(filename: record.attachmentFilename)
        }
        records.remove(atOffsets: offsets)
        do {
            try save()
        } catch {
            print("Failed to save after delete: \(error)")
        }
    }

    func urlForAttachment(filename: String) -> URL {
        attachmentsDirectoryURL().appendingPathComponent(filename)
    }

    // MARK: - Persistence

    private func save() throws {
        let url = recordsJSONURL()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(records)
        try data.write(to: url, options: [.atomic])
    }

    private func recordsJSONURL() -> URL {
        documentsDirectoryURL().appendingPathComponent(jsonFilename)
    }

    private func attachmentsDirectoryURL() -> URL {
        documentsDirectoryURL().appendingPathComponent(attachmentsFolderName, isDirectory: true)
    }

    private func documentsDirectoryURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private func ensureAttachmentsDirectoryExists() throws {
        let dir = attachmentsDirectoryURL()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func persist(attachment: PendingAttachment) throws -> String {
        try ensureAttachmentsDirectoryExists()
        switch attachment {
        case .image(let uiImage):
            guard let data = uiImage.jpegData(compressionQuality: 0.9) else {
                throw NSError(domain: "MedicalRecords", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image"])
            }
            let filename = "record-\(UUID().uuidString).jpg"
            let url = attachmentsDirectoryURL().appendingPathComponent(filename)
            try data.write(to: url, options: [.atomic])
            return filename
        case .fileURL(let sourceURL):
            let ext = sourceURL.pathExtension.isEmpty ? "dat" : sourceURL.pathExtension
            let filename = "record-\(UUID().uuidString).\(ext)"
            let destURL = attachmentsDirectoryURL().appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            var needsStop = false
            if sourceURL.startAccessingSecurityScopedResource() { needsStop = true }
            defer { if needsStop { sourceURL.stopAccessingSecurityScopedResource() } }
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
            return filename
        }
    }

    private func removeAttachmentIfExists(filename: String) {
        let url = urlForAttachment(filename: filename)
        if FileManager.default.fileExists(atPath: url.path) {
            do { try FileManager.default.removeItem(at: url) } catch { print("Failed to remove file: \(error)") }
        }
    }
}

// MARK: - PendingAttachment abstraction

enum PendingAttachment {
    case image(UIImage)
    case fileURL(URL)
}