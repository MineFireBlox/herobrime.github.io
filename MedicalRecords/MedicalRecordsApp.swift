import SwiftUI

@main
struct MedicalRecordsApp: App {
    @StateObject private var store = RecordsStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}