import FinderFeatureInterface
import Logger
import UIKit

@MainActor
final class FileImportService: SceneDelegateService {

  // MARK: SceneDelegateService

  func sceneWillConnect(_ scene: UIWindowScene, session: UISceneSession, connectionOptions: UIScene.ConnectionOptions) -> UIWindow? {
    if let urlContext = connectionOptions.urlContexts.first {
      handleIncomingFile(urlContext.url)
    }
    return nil
  }

  func sceneDidOpenURLContexts(_ scene: UIScene, urlContexts: Set<UIOpenURLContext>) {
    guard let urlContext = urlContexts.first else { return }
    handleIncomingFile(urlContext.url)
  }

  // MARK: Private Methods

  private func handleIncomingFile(_ url: URL) {
    guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      Log.error("FileImportService: Documents directory not found")
      return
    }
    let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

    Log.info("FileImportService: incoming file: \(url.lastPathComponent)")

    let isSecured = url.startAccessingSecurityScopedResource()
    defer {
      if isSecured { url.stopAccessingSecurityScopedResource() }
    }

    do {
      if FileManager.default.fileExists(atPath: destinationURL.path) {
        try FileManager.default.removeItem(at: destinationURL)
      }

      if url.path.contains("/Documents/Inbox/") {
        try FileManager.default.moveItem(at: url, to: destinationURL)
      } else {
        try FileManager.default.copyItem(at: url, to: destinationURL)
      }

      Log.info("FileImportService: file saved to Documents: \(destinationURL.lastPathComponent)")
      NotificationCenter.default.post(name: .finderShouldRefresh, object: nil)
      NotificationCenter.default.post(name: .finderShouldOpenReader, object: nil, userInfo: [FinderNotificationKey.filePath: destinationURL.path])
    } catch {
      Log.error("FileImportService: failed to import file: \(error)")
    }
  }
}
