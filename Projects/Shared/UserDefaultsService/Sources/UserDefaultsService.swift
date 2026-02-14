import Foundation

// MARK: - UserDefault

@propertyWrapper
public struct UserDefault<T>: @unchecked Sendable {
  // MARK: - Properties

  private let key: String
  private let defaultValue: T
  private let storage: UserDefaults

  // MARK: - Initialization

  public init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.storage = storage
  }

  // MARK: - Wrapped Value

  public var wrappedValue: T {
    get {
      storage.object(forKey: key) as? T ?? defaultValue
    }
    nonmutating set {
      storage.set(newValue, forKey: key)
    }
  }
}

// MARK: - UserDefault + RawRepresentable

@propertyWrapper
public struct UserDefaultRawRepresentable<T: RawRepresentable>: @unchecked Sendable {
  // MARK: - Properties

  private let key: String
  private let defaultValue: T
  private let storage: UserDefaults

  // MARK: - Initialization

  public init(key: String, defaultValue: T, storage: UserDefaults = .standard) {
    self.key = key
    self.defaultValue = defaultValue
    self.storage = storage
  }

  // MARK: - Wrapped Value

  public var wrappedValue: T {
    get {
      guard let rawValue = storage.object(forKey: key) as? T.RawValue,
            let value = T(rawValue: rawValue)
      else {
        return defaultValue
      }
      return value
    }
    nonmutating set {
      storage.set(newValue.rawValue, forKey: key)
    }
  }
}

