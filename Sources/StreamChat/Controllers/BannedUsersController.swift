import Foundation

// MARK: - BanChatChannel

public struct BanChatChannel {
  public let cid: ChannelId
  public let name: String?
  public let imageURL: URL?
}

extension BanChatChannel {
  init(from payload: ChannelDetailPayload) {
    self.init(
      cid: payload.cid,
      name: payload.name,
      imageURL: payload.imageURL
    )
  }
}

// MARK: - BanChatUser

public struct BanChatUser {
  public let id: UserId
  public let name: String?
  public let imageURL: URL?
  public let isOnline: Bool
  public let isBanned: Bool
  public let userRole: UserRole
  public let createdAt: Date
  public let updatedAt: Date
  public let deactivatedAt: Date?
  public let lastActiveAt: Date?
  public let teams: Set<TeamId>
}

extension BanChatUser {
  init(from payload: UserPayload) {
    self.init(
      id: payload.id,
      name: payload.name,
      imageURL: payload.imageURL,
      isOnline: payload.isOnline,
      isBanned: payload.isBanned,
      userRole: payload.role,
      createdAt: payload.createdAt,
      updatedAt: payload.updatedAt,
      deactivatedAt: payload.deactivatedAt,
      lastActiveAt: payload.lastActiveAt,
      teams: Set(payload.teams)
    )
  }
}

// MARK: - Ban

public struct Ban {
  public let bannedBy: BanChatUser
  public let channel: BanChatChannel
  public let createdAt: Date
  public let expires: Date?
  public let reason: String?
  public let user: BanChatUser
}

extension BanPayload {
  func transform() -> Ban {
    .init(
      bannedBy: .init(from: bannedBy),
      channel: .init(from: channel),
      createdAt: createdAt,
      expires: expires,
      reason: reason,
      user: .init(from: user)
    )
  }
}

extension BanListPayload {
  func transform() -> [Ban] {
    bans.map { $0.transform() }
  }
}

// MARK: - BannedUsersController

public struct BannedUsersController {
  public let client: ChatClient

  public func bans(
    query: BanListQuery = .init(),
    completion: @escaping (Result<[Ban], Error>) -> Void
  ) {
    client.apiClient.request(
      endpoint: .bannedUsers(query: query),
      completion: { result in
        switch result {
        case .success(let payload):
          completion(.success(payload.transform()))
        case .failure(let error):
          completion(.failure(error))
        }
      }
    )
  }
}

extension ChatClient {
  public func bannedUsersController() -> BannedUsersController {
    .init(client: self)
  }
}
