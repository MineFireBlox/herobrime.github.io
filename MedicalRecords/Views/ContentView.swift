import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: RecordsStore

    @State private var isPresentingAddSheet = false
    @State private var editingRecord: MedicalRecord? = nil

    var body: some View {
        NavigationStack {
            Group {
                if store.records.isEmpty {
                    ContentEmptyStateView(onAdd: { isPresentingAddSheet = true })
                } else {
                    List {
                        ForEach(store.records) { record in
                            Button {
                                editingRecord = record
                            } label: {
                                RecordRow(record: record)
                            }
                        }
                        .onDelete(perform: store.delete)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Medical Records")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add Record")
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                NavigationStack {
                    RecordFormView(mode: .add) { action in
                        switch action {
                        case .save(let hospitalName, let date, let attachment):
                            if let attachment { // guaranteed non-nil in .add mode
                                store.addRecord(hospitalName: hospitalName, date: date, attachment: attachment)
                            }
                        case .cancel:
                            break
                        }
                    }
                }
            }
            .sheet(item: $editingRecord) { record in
                NavigationStack {
                    RecordFormView(mode: .edit(existing: record)) { action in
                        switch action {
                        case .save(let hospitalName, let date, let attachment):
                            store.updateRecord(record, hospitalName: hospitalName, date: date, newAttachment: attachment)
                        case .cancel:
                            break
                        }
                    }
                }
            }
        }
    }
}

private struct RecordRow: View {
    let record: MedicalRecord

    var body: some View {
        HStack {
            Image(systemName: iconName(for: record.attachmentFilename))
                .foregroundStyle(.accent)
                .frame(width: 24)
            VStack(alignment: .leading) {
                Text(record.hospitalName)
                    .font(.headline)
                Text(record.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
    }

    private func iconName(for filename: String) -> String {
        let lower = filename.lowercased()
        if lower.hasSuffix(".pdf") { return "doc.richtext" }
        if lower.hasSuffix(".jpg") || lower.hasSuffix(".jpeg") || lower.hasSuffix(".png") { return "photo" }
        return "doc"
    }
}

private struct ContentEmptyStateView: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No records yet")
                .font(.title3)
                .bold()
            Text("Tap the + button to add your first medical record.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button(action: onAdd) {
                Label("Add Record", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environmentObject(RecordsStore())
}