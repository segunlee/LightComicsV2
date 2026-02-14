import CoreImage
import UIKit

// MARK: - UIImage + ReaderImageFilter

extension UIImage {
  func applyFilter(_ filter: ReaderImageFilterMode) -> UIImage? {
    guard filter != .none else { return self }
    guard let ciImage = CIImage(image: self) else { return nil }

    let filterName: String
    switch filter {
    case .none: return self
    case .contrast: filterName = "CIColorControls"
    case .inverted: filterName = "CIColorInvert"
    case .grayScale: filterName = "CIPhotoEffectNoir"
    }

    guard let ciFilter = CIFilter(name: filterName) else { return nil }
    ciFilter.setValue(ciImage, forKey: kCIInputImageKey)

    if filter == .contrast {
      ciFilter.setValue(1.5, forKey: kCIInputContrastKey)
    }

    guard let output = ciFilter.outputImage else { return nil }
    let context = CIContext()
    guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
    return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
  }

  var cutLeftHalf: UIImage? {
    guard let cgImage else { return nil }
    let halfWidth = cgImage.width / 2
    let rect = CGRect(x: 0, y: 0, width: halfWidth, height: cgImage.height)
    guard let cropped = cgImage.cropping(to: rect) else { return nil }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }

  var cutRightHalf: UIImage? {
    guard let cgImage else { return nil }
    let halfWidth = cgImage.width / 2
    let rect = CGRect(x: halfWidth, y: 0, width: cgImage.width - halfWidth, height: cgImage.height)
    guard let cropped = cgImage.cropping(to: rect) else { return nil }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }
}
