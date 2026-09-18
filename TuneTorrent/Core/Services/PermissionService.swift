import Foundation
import MediaPlayer

// MARK: - PermissionService
protocol PermissionServiceProtocol {
    func requestMediaLibrary() async -> Bool
}

final class PermissionService: PermissionServiceProtocol {
    func requestMediaLibrary() async -> Bool {
        let status = MPMediaLibrary.authorizationStatus()
        if status == .authorized { return true }
        return await withCheckedContinuation { cont in
            MPMediaLibrary.requestAuthorization { newStatus in
                cont.resume(returning: newStatus == .authorized)
            }
        }
    }
}
