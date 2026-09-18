import UIKit
import UniformTypeIdentifiers

// MARK: - Share Extension: Save audio to Downloads
// Add as new target TuneTorrentShare -> Info.plist NSExtensionItem
class ShareViewController: UIViewController {
    override func viewDidLoad(){
        super.viewDidLoad()
        // Copies shared file URLs to Documents/Downloads via App Group or FileManager
        // Real impl: handle NSExtensionContext attachments -> copy to shared container
        dismiss(animated:true)
    }
}
