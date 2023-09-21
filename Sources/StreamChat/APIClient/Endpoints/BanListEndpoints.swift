import Foundation

extension Endpoint {
  static func bannedUsers(query: BanListQuery) -> Endpoint<BanListPayload> {
    .init(
      path: .bannedUsers,
      method: .get,
      queryItems: nil,
      requiresConnectionId: false,
      body: ["payload": query]
    )
  }
}
