import Foundation

// MARK: - BanListSortingKey

public enum BanListSortingKey: String, SortingKey {
  case createdAt

  // MARK: Public

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    let value: String

    switch self {
    case .createdAt: value = "created_at"
    }

    try container.encode(value)
  }
}

extension BanListSortingKey {
  static let defaultSortDescriptor: NSSortDescriptor = {
    let dateKeyPath: KeyPath<UserDTO, DBDate?> = \UserDTO.lastActivityAt
    return .init(keyPath: dateKeyPath, ascending: false)
  }()

  func sortDescriptor(isAscending: Bool) -> NSSortDescriptor? {
    .init(key: rawValue, ascending: isAscending)
  }
}
