import Foundation

// MARK: - BanPayload

struct BanPayload {
  let bannedBy: UserPayload
  let channel: ChannelDetailPayload
  let createdAt: Date
  let expires: Date?
  let reason: String?
  let user: UserPayload
}

// MARK: Decodable

extension BanPayload: Decodable {
  enum CodingKeys: String, CodingKey {
    case bannedBy = "banned_by"
    case channel
    case createdAt = "created_at"
    case expires
    case reason
    case user
  }
}

// MARK: - BanListPayload

struct BanListPayload {
  let bans: [BanPayload]
}

// MARK: Decodable

extension BanListPayload: Decodable {

  // MARK: Lifecycle

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    bans = try container
      .decodeArrayIgnoringFailures([BanPayload].self, forKey: .bans)
  }

  // MARK: Internal

  enum CodingKeys: String, CodingKey {
    case bans
  }
}
