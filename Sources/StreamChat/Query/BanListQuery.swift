import Foundation

// MARK: - AnyBanListFilterScope

public protocol AnyBanListFilterScope { }

// MARK: - BanListFilterScope

public class BanListFilterScope: FilterScope, AnyBanListFilterScope { }

extension FilterKey where Scope: AnyBanListFilterScope {
  public static var channelId: FilterKey<Scope, ChannelId> { "channel_cid" }
  public static var userId: FilterKey<Scope, UserId> { "user_id" }
  public static var createdAt: FilterKey<Scope, Date> { "created_at" }
  public static var reason: FilterKey<Scope, String> { "reason" }
  public static var bannedById: FilterKey<Scope, UserId> { "banned_by_id" }
}

// MARK: - BanListQuery

public struct BanListQuery: Encodable {

  // MARK: Lifecycle

  public init(
    filter: Filter<BanListFilterScope>? = nil,
    sort: [Sorting<BanListSortingKey>] = [],
    pageSize: Int = 30
  ) {
    self.filter = filter
    self.sort = sort
    pagination = Pagination(pageSize: pageSize)
  }

  // MARK: Public

  public var filter: Filter<BanListFilterScope>?

  public let sort: [Sorting<BanListSortingKey>]

  public var pagination: Pagination?

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    if let filter {
      try container.encode(filter, forKey: .filter)
    } else {
      try container.encode(EmptyObject(), forKey: .filter)
    }

    if !sort.isEmpty {
      try container.encode(sort, forKey: .sort)
    }

    try pagination.map { try $0.encode(to: encoder) }
  }

  // MARK: Private

  private enum CodingKeys: String, CodingKey {
    case filter = "filter_conditions"
    case sort
    case pagination
  }
}

// MARK: - EmptyObject

private struct EmptyObject: Encodable { }
