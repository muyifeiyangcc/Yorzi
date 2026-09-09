import Foundation

struct AppUser: Codable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var location: String
    var bio: String
    var gender: String? = nil
    var birthDate: String? = nil
    var avatarData: Data? = nil
}

struct Work: Codable, Hashable {
    let id: UUID
    let authorID: UUID
    var title: String
    var category: String
    var location: String
    var description: String
    var liked: Bool
    var saved: Bool
    var likes: Int
    var timeAgo: String? = nil
    var collaborators: [String]? = nil
    var openToCollab: Bool = false
    var createdAt: Date? = nil
    var mediaData: Data? = nil
    var mediaDatas: [Data]? = nil
    var videoData: Data? = nil
}

struct CollabCall: Codable, Hashable {
    let id: UUID
    let authorID: UUID
    var title: String
    var location: String
    var budget: String
    var roles: String
    var timing: String? = nil
    // Optional fields keep persisted calls from older app versions decodable.
    var description: String? = nil
    var date: String? = nil
    var deadline: String? = nil
    var mediaData: Data? = nil
    var mediaDatas: [Data]? = nil
    var videoData: Data? = nil
}

struct AppComment: Codable, Hashable {
    let id: UUID
    let workID: UUID
    let authorID: UUID
    let text: String
    var createdAt: Date? = nil
}

struct ChatMessage: Codable, Hashable {
    enum Kind: String, Codable { case text, image, voice }
    let id: UUID
    let senderID: UUID
    var text: String
    let kind: Kind
    var duration: TimeInterval?
    var mediaData: Data? = nil
    var createdAt: Date? = nil
}

struct Conversation: Codable, Hashable {
    let id: UUID
    let participantID: UUID
    var messages: [ChatMessage]
}

struct ReportRecord: Codable, Hashable {
    let id: UUID
    let targetID: UUID
    let reason: String
    let date: Date
}

enum RepositoryViewState { case loading, content, empty, parseError }

enum WorkVisibility: String, Codable, CaseIterable {
    case `public` = "Public"
    case diveCircle = "Dive Circle"
    case onlyMe = "Only Me"
    var title: String { rawValue }
}
