# Medical Records (SwiftUI)

A clean SwiftUI iOS app that lets users:

- Add medical records with hospital name, date, and an attachment (PDF or image from camera/photo library)
- Store attachments locally using FileManager
- Display all saved records in a list
- Edit and delete records
- Persist records using JSON in the app's Documents directory
- Load saved records automatically on launch

## How to run

1. Open Xcode and create a new iOS App project named `MedicalRecords` using the SwiftUI App lifecycle.
2. In the project navigator, create folder groups that match this repo structure: `Models`, `Storage`, `Views` (with a `Components` subgroup), and `Utilities`.
3. Add the Swift files from this repository into the project. You can drag the `MedicalRecords` folder into Xcode and select "Create folder references" or add files to the app target manually.
4. Add the following Privacy keys to your app's `Info.plist`:
   - `NSCameraUsageDescription` = "This app uses the camera to capture medical document photos."
   - `NSPhotoLibraryUsageDescription` = "This app needs access to your photo library to attach images."
   - `NSPhotoLibraryAddUsageDescription` = "This app saves selected images to your library when needed."
5. Build and run on an iOS device or simulator. Camera requires a real device.

## Notes

- Attachments are copied into `Documents/Attachments` inside your app sandbox.
- Records metadata is saved in `Documents/records.json`.
- When editing a record, if you select a new attachment, the previous file is deleted from disk.
- The UI uses system SF Symbols to differentiate PDF vs image attachments in the list.