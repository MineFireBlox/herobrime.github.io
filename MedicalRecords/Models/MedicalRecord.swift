import Foundation

struct MedicalRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var hospitalName: String
    var date: Date
    var attachmentFilename: String

    init(id: UUID = UUID(), hospitalName: String, date: Date, attachmentFilename: String) {
        self.id = id
        self.hospitalName = hospitalName
        self.date = date
        self.attachmentFilename = attachmentFilename
    }
}