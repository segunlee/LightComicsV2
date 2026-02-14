import FinderDomainInterface
import QuickLook
import UIKit

// MARK: - FinderViewController + Preview

extension FinderViewController {
  func previewItem(_ item: FileItem) {
    guard !item.isDirectory else { return }

    let previewController = QLPreviewController()
    previewController.dataSource = self
    previewController.currentPreviewItemIndex = 0

    previewingItem = item

    present(previewController, animated: true)
  }
}

// MARK: - FinderViewController + Key

@MainActor private var qlPreviewPathKey: UInt8 = 0

// MARK: - FinderViewController + QLPreviewControllerDataSource

extension FinderViewController: QLPreviewControllerDataSource {
  var previewingItem: FileItem? {
    get { objc_getAssociatedObject(self, &qlPreviewPathKey) as? FileItem }
    set { objc_setAssociatedObject(self, &qlPreviewPathKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
  }

  func numberOfPreviewItems(in _: QLPreviewController) -> Int {
    1
  }

  func previewController(_: QLPreviewController, previewItemAt _: Int) -> any QLPreviewItem {
    guard let item = previewingItem else {
      return URL(fileURLWithPath: "") as QLPreviewItem
    }
    return URL(fileURLWithPath: item.path) as QLPreviewItem
  }
}
