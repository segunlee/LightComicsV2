import Foundation

public extension Notification.Name {
  static let finderShouldRefresh = Notification.Name("finderShouldRefresh")
  static let finderShouldOpenReader = Notification.Name("finderShouldOpenReader")
}

public enum FinderNotificationKey {
  public static let filePath = "filePath"
}
