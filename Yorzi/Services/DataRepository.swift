import Foundation
import UIKit

extension Notification.Name {
    static let repositoryDidChange = Notification.Name("repositoryDidChange")
    static let authenticationDidChange = Notification.Name("authenticationDidChange")
}

final class DataRepository {
    static let shared = DataRepository()

    private let defaults = UserDefaults.standard
    private(set) var users: [AppUser]
    private(set) var works: [Work]
    private(set) var calls: [CollabCall]
    private(set) var comments: [AppComment]
    private(set) var conversations: [Conversation]
    private(set) var reports: [ReportRecord]
    private(set) var blockedIDs: Set<UUID>
    private(set) var followingIDs: Set<UUID>
    private(set) var followerIDs: Set<UUID>
    private(set) var collaboratedCallIDs: Set<UUID>
    private(set) var balance: Int
    private(set) var isGuest = false
    private(set) var isSignedIn: Bool
    private var workVisibilities: [UUID: WorkVisibility] = [:]

    private struct PersistedState: Codable {
        var users: [AppUser]; var works: [Work]; var calls: [CollabCall]; var comments: [AppComment]; var conversations: [Conversation]; var reports: [ReportRecord]; var blockedIDs: [UUID]; var followingIDs: [UUID]; var balance: Int
    }

    let currentUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    var currentUser: AppUser { users.first(where: { $0.id == currentUserID })! }
    var eulaAccepted: Bool { defaults.bool(forKey: "yorzi.eula.accepted") }
    var testAccountValid: Bool { !defaults.bool(forKey: "yorzi.test.deleted") }
    private let testEmail: String = "123@gmail.com"
    private let testPassword: String = "12345678"

    private init() {
        let current = AppUser(id: currentUserID, name: "Clara Moreau", role: "Retoucher and visual storyteller", location: "New York", bio: "Open to thoughtful collaborations.")
        let elena = AppUser(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "Elena Rossi", role: "Photographer", location: "New York", bio: "Portraits shaped by quiet light.")
        let marcus = AppUser(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "Marcus Hale", role: "Photographer", location: "Berlin", bio: "Honest portraits and editorial stories.")
        let maya = AppUser(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "Maya Chen", role: "Model", location: "Amsterdam", bio: "Movement, fashion, and film.")
        users = [current, elena, marcus, maya]
        works = [
            Work(id: UUID(), authorID: elena.id, title: "Quiet Hours", category: "Portraits", location: "New York", description: "A quiet study of blue-hour light, soft expressions, and the space between movement and stillness.", liked: false, saved: false, likes: 24, timeAgo: "2h ago", collaborators: ["Mina · Model", "Jonas · Retoucher", "Aya · Stylist"], openToCollab: true),
            Work(id: UUID(), authorID: marcus.id, title: "City in Motion", category: "Motion", location: "Berlin", description: "Editorial frames from an early morning walk.", liked: true, saved: false, likes: 41, timeAgo: "5h ago", collaborators: ["Leo · Model", "Sora · Stylist"], openToCollab: false),
            Work(id: UUID(), authorID: maya.id, title: "Open Air", category: "Outdoor", location: "Amsterdam", description: "A natural-light series built around motion.", liked: false, saved: true, likes: 18, timeAgo: "1d ago", collaborators: ["Iris · Model", "Nico · Retoucher"], openToCollab: true)
        ]
        calls = [
            CollabCall(id: UUID(), authorID: elena.id, title: "Street portrait project needs a model", location: "Amsterdam", budget: "TFP", roles: "Model", timing: "This weekend"),
            CollabCall(id: UUID(), authorID: marcus.id, title: "Editorial beauty shoot looking for stylist", location: "Berlin", budget: "$200", roles: "Stylist", timing: "Next week")
        ]
        comments = [AppComment(id: UUID(), workID: works[0].id, authorID: maya.id, text: "This is a small change with a big effect.")]
        conversations = [Conversation(id: UUID(), participantID: marcus.id, messages: [
            ChatMessage(id: UUID(), senderID: marcus.id, text: "I loved the color direction in your latest series.", kind: .text),
            ChatMessage(id: UUID(), senderID: currentUserID, text: "Thank you. I am looking for a quiet editorial story next month.", kind: .text)
        ])]
        reports = []
        blockedIDs = Set(defaults.stringArray(forKey: "yorzi.blocked")?.compactMap(UUID.init(uuidString:)) ?? [])
        followingIDs = [elena.id]
        followerIDs = [elena.id]
        collaboratedCallIDs = Set(defaults.stringArray(forKey: "yorzi.collaborated.calls")?.compactMap(UUID.init(uuidString:)) ?? [])
        balance = defaults.integer(forKey: "yorzi.balance")
        if let data = defaults.data(forKey: "yorzi.repository"), let saved = try? JSONDecoder().decode(PersistedState.self, from: data) { users = saved.users; works = saved.works; calls = saved.calls; comments = saved.comments; conversations = saved.conversations; reports = saved.reports; blockedIDs = Set(saved.blockedIDs); followingIDs = Set(saved.followingIDs); balance = saved.balance }
        if let followerData = defaults.data(forKey: "yorzi.followers"), let savedFollowers = try? JSONDecoder().decode([UUID].self, from: followerData) { followerIDs = Set(savedFollowers) }
        // Older builds incorrectly mirrored Following into Followers. Reset that one-time
        // migration state so each direction is independent going forward.
        if defaults.integer(forKey: "yorzi.relationships.version") < 2 {
            followerIDs = [elena.id]
            defaults.set(2, forKey: "yorzi.relationships.version")
        }
        if let data = defaults.data(forKey: "yorzi.work.visibility"), let saved = try? JSONDecoder().decode([String: WorkVisibility].self, from: data) { workVisibilities = Dictionary(uniqueKeysWithValues: saved.compactMap { key, value in UUID(uuidString: key).map { ($0, value) } }) }
        isSignedIn = defaults.bool(forKey: "yorzi.signedIn")
    }

    var visibleUsers: [AppUser] { users.filter { !blockedIDs.contains($0.id) && $0.id != currentUserID } }
    var visibleWorks: [Work] { works.filter { work in guard !blockedIDs.contains(work.authorID) else { return false }; switch workVisibilities[work.id] ?? .public { case .public: return true; case .diveCircle: return work.authorID == currentUserID || (followingIDs.contains(work.authorID) && followerIDs.contains(work.authorID)); case .onlyMe: return false } } }
    var visibleComments: [AppComment] { comments.filter { !blockedIDs.contains($0.authorID) } }
    var visibleConversations: [Conversation] { conversations.filter { !blockedIDs.contains($0.participantID) } }
    var collaboratedCalls: [CollabCall] { calls.filter { collaboratedCallIDs.contains($0.id) && !blockedIDs.contains($0.authorID) } }

    func acceptEULA() { defaults.set(true, forKey: "yorzi.eula.accepted") }
    func enterGuest() { isGuest = true; isSignedIn = false; notifyAuth() }
    func signIn(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let registeredEmail = defaults.string(forKey: "yorzi.registered.email")?.lowercased()
        let validTest = testAccountValid && normalized == testEmail && password == testPassword
        let validRegistered = normalized == registeredEmail && password == defaults.string(forKey: "yorzi.registered.password")
        guard validTest || validRegistered else { return false }
        isGuest = false; isSignedIn = true; defaults.set(true, forKey: "yorzi.signedIn"); notifyAuth(); return true
    }
    func completeRegistration(email: String, password: String, name: String, gender: String?, birthDate: String?, avatar: UIImage?) {
        defaults.set(email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), forKey: "yorzi.registered.email")
        defaults.set(password, forKey: "yorzi.registered.password")
        updateCurrentProfile(name: name, gender: gender, birthDate: birthDate, avatar: avatar)
        isGuest = false; isSignedIn = true; defaults.set(true, forKey: "yorzi.signedIn"); notifyAuth()
    }
    func resetPassword(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized != testEmail, normalized == defaults.string(forKey: "yorzi.registered.email")?.lowercased() else { return false }
        defaults.set(password, forKey: "yorzi.registered.password"); return true
    }
    func signOut() { isGuest = false; isSignedIn = false; defaults.set(false, forKey: "yorzi.signedIn"); notifyAuth() }
    func deleteAccount() { defaults.set(true, forKey: "yorzi.test.deleted"); signOut() }

    func user(_ id: UUID) -> AppUser? { users.first { $0.id == id } }
    func isFollowing(_ id: UUID) -> Bool { followingIDs.contains(id) }
    func toggleFollow(_ id: UUID) {
        if followingIDs.contains(id) {
            followingIDs.remove(id)
        } else {
            followingIDs.insert(id)
        }
        persist(); notify()
    }
    func toggleLike(_ workID: UUID) {
        guard let index = works.firstIndex(where: { $0.id == workID }) else { return }
        works[index].liked.toggle(); works[index].likes += works[index].liked ? 1 : -1; persist(); notify()
    }
    func toggleSave(_ workID: UUID) { guard let index = works.firstIndex(where: { $0.id == workID }) else { return }; works[index].saved.toggle(); persist(); notify() }
    func addComment(workID: UUID, text: String) { comments.append(.init(id: UUID(), workID: workID, authorID: currentUserID, text: text, createdAt: Date())); persist(); notify() }
    func addWork(title: String, category: String, location: String, description: String, visibility: WorkVisibility = .public, mediaData: Data? = nil, mediaDatas: [Data]? = nil, videoData: Data? = nil) {
        let id = UUID()
        let primary = mediaData ?? mediaDatas?.first
        works.insert(.init(id: id, authorID: currentUserID, title: title, category: category, location: location, description: description, liked: false, saved: false, likes: 0, createdAt: Date(), mediaData: primary, mediaDatas: mediaDatas, videoData: videoData), at: 0)
        workVisibilities[id] = visibility; persist(); persistVisibility(); notify()
    }
    func addCall(title: String, location: String, date: String = "", budget: String, roles: String, deadline: String = "", description: String = "", mediaData: Data? = nil, mediaDatas: [Data]? = nil, videoData: Data? = nil) {
        calls.insert(.init(id: UUID(), authorID: currentUserID, title: title, location: location, budget: budget, roles: roles, description: description.isEmpty ? nil : description, date: date.isEmpty ? nil : date, deadline: deadline.isEmpty ? nil : deadline, mediaData: mediaData ?? mediaDatas?.first, mediaDatas: mediaDatas, videoData: videoData), at: 0)
        persist(); notify()
    }
    func hasCollaborated(on callID: UUID) -> Bool { collaboratedCallIDs.contains(callID) }
    func collaborate(on callID: UUID) {
        guard calls.contains(where: { $0.id == callID }) else { return }
        collaboratedCallIDs.insert(callID)
        persistCollaboratedCalls()
        notify()
    }
    func block(_ id: UUID) { blockedIDs.insert(id); persist(); notify() }
    func unblock(_ id: UUID) { blockedIDs.remove(id); persist(); notify() }
    func report(_ id: UUID, reason: String) { reports.append(.init(id: UUID(), targetID: id, reason: reason, date: Date())); persist(); notify() }
    func spend(_ amount: Int) -> Bool { guard balance >= amount else { return false }; balance -= amount; persistBalance(); notify(); return true }
    func credit(_ amount: Int) { balance += amount; persistBalance(); notify() }
    func addCollaborator(workID: UUID, name: String, role: String) {
        guard let index = works.firstIndex(where: { $0.id == workID }) else { return }
        var credits = works[index].collaborators ?? []
        let entry = "\(name) · \(role)"
        if !credits.contains(entry) { credits.append(entry); works[index].collaborators = credits; persist(); notify() }
    }
    func isResolutionUnlocked(for workID: UUID) -> Bool {
        defaults.bool(forKey: "yorzi.work.resolution.unlocked.\(workID.uuidString)")
    }
    func unlockResolution(for workID: UUID) {
        defaults.set(true, forKey: "yorzi.work.resolution.unlocked.\(workID.uuidString)")
        notify()
    }
    func updateProfile(name: String, bio: String) { guard let index = users.firstIndex(where: { $0.id == currentUserID }) else { return }; users[index].name = name; users[index].bio = bio; persist(); notify() }
    func updateCurrentProfile(name: String, gender: String?, birthDate: String? = nil, avatar: UIImage?) {
        guard let index = users.firstIndex(where: { $0.id == currentUserID }) else { return }
        users[index].name = name
        if let gender { users[index].gender = gender }
        if let birthDate { users[index].birthDate = birthDate }
        if let avatar, let data = avatar.jpegData(compressionQuality: 0.8) { users[index].avatarData = data }
        persist(); notify()
    }
    func send(_ message: ChatMessage, to participantID: UUID) {
        if let index = conversations.firstIndex(where: { $0.participantID == participantID }) { conversations[index].messages.append(message) }
        else { conversations.append(.init(id: UUID(), participantID: participantID, messages: [message])) }
        persist(); notify()
    }

    private func persistBlocks() { defaults.set(blockedIDs.map(\.uuidString), forKey: "yorzi.blocked") }
    private func persist() { let state = PersistedState(users: users, works: works, calls: calls, comments: comments, conversations: conversations, reports: reports, blockedIDs: Array(blockedIDs), followingIDs: Array(followingIDs), balance: balance); if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: "yorzi.repository") } }
    private func persistFollowers() { if let data = try? JSONEncoder().encode(Array(followerIDs)) { defaults.set(data, forKey: "yorzi.followers") } }
    private func persistCollaboratedCalls() { defaults.set(collaboratedCallIDs.map(\.uuidString), forKey: "yorzi.collaborated.calls") }
    private func persistVisibility() { let values = Dictionary(uniqueKeysWithValues: workVisibilities.map { ($0.key.uuidString, $0.value) }); if let data = try? JSONEncoder().encode(values) { defaults.set(data, forKey: "yorzi.work.visibility") } }
    private func persistBalance() { defaults.set(balance, forKey: "yorzi.balance") }
    private func notify() { NotificationCenter.default.post(name: .repositoryDidChange, object: self) }
    private func notifyAuth() { NotificationCenter.default.post(name: .authenticationDidChange, object: self) }
}
