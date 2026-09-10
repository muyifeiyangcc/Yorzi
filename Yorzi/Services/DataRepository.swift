import Foundation
import UIKit
import AVFoundation

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
        var users: [AppUser]
        var works: [Work]
        var calls: [CollabCall]
        var comments: [AppComment]
        var conversations: [Conversation]
        var reports: [ReportRecord]
        var blockedIDs: [UUID]
        var followingIDs: [UUID]
        var balance: Int
        var followerIDs: [UUID]? = nil
        var collaboratedCallIDs: [UUID]? = nil
        var workVisibilities: [String: WorkVisibility]? = nil
    }

    private struct SharedState: Codable {
        var users: [AppUser]
        var works: [Work]
        var calls: [CollabCall]
        var comments: [AppComment]
        var workVisibilities: [String: WorkVisibility]
    }

    private(set) var currentUserID: UUID
    private static let testUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let testUserID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    var currentUser: AppUser { users.first(where: { $0.id == currentUserID })! }
    var eulaAccepted: Bool { defaults.bool(forKey: "yorzi.eula.accepted") }
    var testAccountValid: Bool { !defaults.bool(forKey: "yorzi.test.deleted") }
    private static let testAccountEmail = "123@gmail.com"
    private let testEmail: String = "123@gmail.com"
    private let testPassword: String = "12345678"
    private let activeAccountEmailKey = "yorzi.active.account.email"
    private let profileKeyPrefix = "yorzi.account.profile."
    private let accountStateKeyPrefix = "yorzi.account.state."
    private let accountUserIDKeyPrefix = "yorzi.account.user.id."
    private let accountInitializedKeyPrefix = "yorzi.account.initialized."
    private let sharedContentKey = "yorzi.shared.content"
    private var seedState: PersistedState!
    private var sharedContent: SharedState!
    private var defaultTestProfile: AppUser {
        AppUser(
            id: testUserID,
            name: "Clara Moreau",
            role: "Retoucher",
            location: "New York",
            bio: "Open to thoughtful collaborations."
        )
    }

    private init() {
        currentUserID = Self.testUserID
        // Current signed-in account (123@gmail.com) — independent from the 8 seed creators.
        let current = AppUser(id: currentUserID, name: "Clara Moreau", role: "Retoucher", location: "New York", bio: "Open to thoughtful collaborations.")

       
        func seedUser(_ index: Int, _ name: String, _ role: String, _ location: String, _ bio: String, _ avatar: String) -> AppUser {
            AppUser(id: UUID(uuidString: "00000000-0000-0000-0000-00000000001\(index)")!,
                    name: name, role: role, location: location, bio: bio,
                    avatarData: Self.assetPNGData(named: avatar))
        }

        let charlotte = seedUser(1, "Charlotte", "Photographer", "Milan, Italy", "Portrait photographer capturing natural light.", "585c7bc72157d2db05b580f1230c8d61")
        let alexander = seedUser(2, "Alexander", "Photographer", "Berlin, Germany", "Street photography & everyday stories across Europe.", "ad073a8701be14c66504f4075e22ac80")
        let ava = seedUser(3, "Ava", "Motion designer", "Paris, France", "Motion designer exploring minimalist loops.", "991a932f5e4cd8b8cd8d74d2c044cb88")
        let edward = seedUser(4, "Edward", "Photographer", "Vienna, Austria", "Visual observer documenting quiet moments.", "1e685da269e6adfebf2714799600ac5f")
        let luke = seedUser(5, "Luke", "Photographer", "Stockholm, Sweden", "Independent film photographer.", "8b21fabed99342a63df80a57f7019900")
        let judy = seedUser(6, "Judy", "Retoucher", "Zurich, Switzerland", "Editorial colorist & retouch artist.", "a2986e8604c42250a843906ac2c32e5f")
        let jack = seedUser(7, "Jack", "Stylist", "Kiruna, Sweden", "Fashion stylist & moodboard curator.", "df1be54d09523577d2b33866a6b84615")
        let rose = seedUser(8, "Rose", "Creative director", "Copenhagen, Denmark", "Creative director & indie magazine compiler.", "4d1ce4c1e482af1fd83429bf68931347")

        users = [current, charlotte, alexander, ava, edward, luke, judy, jack, rose]

        func imgData(_ name: String) -> Data? { Self.assetPNGData(named: name) }
        func vidData(_ name: String) -> Data? { Self.bundleFileData(named: name, ext: "mp4") }

        func seedWork(_ author: AppUser, _ title: String, _ category: String, _ location: String, _ desc: String,
                      _ images: [String], _ video: String?, _ timeAgo: String) -> Work {
            let imageData = images.compactMap(imgData)
            let videoData = video.flatMap(vidData)
            let thumbnailData = imageData.first ?? videoData.flatMap(Self.videoThumbnailData)
            return Work(id: UUID(), authorID: author.id, title: title, category: category, location: location,
                 description: desc, liked: false, saved: false, likes: Int.random(in: 12...60),
                 timeAgo: timeAgo, collaborators: nil, openToCollab: false, createdAt: Date(),
                 mediaData: thumbnailData,
                 mediaDatas: imageData.isEmpty ? thumbnailData.map { [$0] } : imageData,
                 videoData: videoData)
        }

        let wCharlotte = seedWork(charlotte, "Quiet Hours", "Portraits", "Milan, Italy",
                                  "A study of blue hour light, soft facial expressions, and quiet moments.",
                                  ["b0b8159e468a8d28e517251b1d833674", "ca66b8b6c01e4111a7182e7495aa03c7"], nil, "2h ago")
        let wAlexander = seedWork(alexander, "Berlin Rainy Afternoon", "Outdoor Stories", "Berlin, Germany",
                                  "Rainy day walk through central city streets, capturing reflections on wet pavement.",
                                  [], "9172ae4448a51961913527a7892d4cde", "4h ago")
        let wAva = seedWork(ava, "Geometric Shadow Dance", "Motion", "Paris, France",
                            "Exploring sunlight and geometric leaf shadow loops in clean indoor spaces.",
                            [], "494698b2970f140b68b8ed68937250c2", "6h ago")
        let wEdward = seedWork(edward, "Monochrome Morning", "Portraits", "Vienna, Austria",
                               "A photographic study on morning coffee routines and black and white textures.",
                               ["5e6ede94bd8e68ba66e13d9f309a2853", "9ee7da7ff4b2592173ece6b71158e64e"], nil, "8h ago")
        let wLuke = seedWork(luke, "Rome Shadows", "Portraits", "Stockholm, Sweden",
                             "35mm film snapshots capturing grain and sunlight in quiet alleyways.",
                             ["bdb20ea478dbdda611163421e394a77a", "6cc042ab8cbe4dee864b28442510b44a"], nil, "10h ago")
        let wJudy = seedWork(judy, "Color Tone Moodboard", "Portraits", "Zurich, Switzerland",
                             "Experimenting with cinematic skin tone balance and warm pastel shadows.",
                             ["fd7e3eab9fb712925badb5527bcae902", "9facdbbef5d9b0a159ad82b97f59a8af"], nil, "1d ago")
        let wJack = seedWork(jack, "Autumn Palette", "Outdoor Stories", "Kiruna, Sweden",
                             "Curating natural textures, linen fabrics, and neutral tone outfits outdoors.",
                             ["54d6706f3d9b024a4ff78c6d5b26f044", "46d642a2d0a4e694e0374a19bf50f584"], nil, "1d ago")
        let wRose = seedWork(rose, "Parisian Window Reflections", "Motion", "Copenhagen, Denmark",
                             "Soft ambient motion loop capturing city light refractions through vintage glass.",
                             [], "ac771761c9d84df51038ead761ab637e", "2d ago")
        works = [wCharlotte, wAlexander, wAva, wEdward, wLuke, wJudy, wJack, wRose]


        func parseDetail(_ detail2: String, _ key: String) -> String? {
            let prefix = key + ":"
            for line in detail2.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                if trimmed.hasPrefix(prefix) {
                    return String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
                }
            }
            return nil
        }
        func seedCall(_ author: AppUser, _ role: String, _ cover: String, _ title: String, _ desc: String, _ detail2: String) -> CollabCall {
            CollabCall(id: UUID(), authorID: author.id, title: title,
                       location: parseDetail(detail2, "Location") ?? author.location,
                       budget: parseDetail(detail2, "Budget") ?? "", roles: role, timing: nil,
                       description: desc,
                       date: parseDetail(detail2, "Date"),
                       deadline: parseDetail(detail2, "Deadline"),
                       mediaData: imgData(cover), mediaDatas: nil, videoData: nil)
        }
        calls = [
            seedCall(luke, "Photographer", "2244141ab4ea851a8421aa3e74865fd3",
                     "Editorial Color Grading Collab",
                     "Seeking high-res RAW files to color grade for moodboard.",
                     "Location: Remote\nDate: 2026/11/25\nBudget: Shared Credits\nDeadline: 2026/09/30"),
            seedCall(judy, "Photographer", "869c23002824c4a45cf296d1789143e0",
                     "Looking for Photographer for Lookbook",
                     "Need a portrait photographer for a minimalist apparel shoot.",
                     "Location: Milan, Italy\nDate: 2026/09/25\nBudget: $150 / project\nDeadline: 2026/09/22"),
            seedCall(jack, "Model", "19785c239460cefb31360c03aff8be45",
                     "Street Portrait Project Needs a Model",
                     "Looking for 1 female model for an outdoor 35mm shoot.",
                     "Location: Rome, Italy\nDate: 2026/09/20\nBudget: Unpaid / Collab\nDeadline: 2026/09/18"),
            seedCall(rose, "Videographer", "425929de0ce4c54905b16ad81ddebb57",
                     "Short Fashion Film Videographer Call",
                     "Seeking a videographer with a 16mm aesthetic for a short film.",
                     "Location: Paris, France\nDate: 2026/10/05\nBudget: Shared Credits\nDeadline: 2026/10/01")
        ]

        // Comments on each work; commenter is another creator (not the work's author).
        func seedComment(_ work: Work, _ author: AppUser, _ text: String) -> AppComment {
            AppComment(id: UUID(), workID: work.id, authorID: author.id, text: text, createdAt: Date())
        }
        comments = [
            seedComment(wCharlotte, ava, "So aesthetic!"),
            seedComment(wAlexander, edward, "Pure art!"),
            seedComment(wAva, charlotte, "Love the lighting!"),
            seedComment(wLuke, judy, "Obsessed with this!"),
            seedComment(wJudy, rose, "Incredible mood!"),
            seedComment(wJack, luke, "Amazing work!")
        ]

        conversations = [Conversation(id: UUID(), participantID: alexander.id, messages: [
            ChatMessage(id: UUID(), senderID: alexander.id, text: "I loved the color direction in your latest series.", kind: .text),
            ChatMessage(id: UUID(), senderID: currentUserID, text: "Thank you. I am looking for a quiet editorial story next month.", kind: .text)
        ])]
        reports = []
        blockedIDs = Set(defaults.stringArray(forKey: "yorzi.blocked")?.compactMap(UUID.init(uuidString:)) ?? [])
        // Default: follow 2 of the seed creators, and 2 of them follow me.
        followingIDs = [charlotte.id, luke.id]
        followerIDs = [charlotte.id, ava.id]
        collaboratedCallIDs = Set(defaults.stringArray(forKey: "yorzi.collaborated.calls")?.compactMap(UUID.init(uuidString:)) ?? [])
        balance = defaults.integer(forKey: "yorzi.balance")

        seedState = PersistedState(
            users: users,
            works: works,
            calls: calls,
            comments: comments,
            conversations: conversations,
            reports: reports,
            blockedIDs: [],
            followingIDs: Array(followingIDs),
            balance: 0,
            followerIDs: Array(followerIDs),
            collaboratedCallIDs: [],
            workVisibilities: nil
        )

        let seedVersion = 6
        let hasFreshSeed = defaults.integer(forKey: "yorzi.seed.version") >= seedVersion
        var savedState: PersistedState? = nil
        if hasFreshSeed { savedState = Self.loadLegacyState(from: defaults) }
        if hasFreshSeed, let followerData = defaults.data(forKey: "yorzi.followers"), let savedFollowers = try? JSONDecoder().decode([UUID].self, from: followerData) { followerIDs = Set(savedFollowers) }
        if defaults.integer(forKey: "yorzi.relationships.version") < 3 || !hasFreshSeed {
            followerIDs = [charlotte.id, ava.id]
            followingIDs = [charlotte.id, luke.id]
            defaults.set(3, forKey: "yorzi.relationships.version")
        }
        seedState.followerIDs = [charlotte.id, ava.id]
        seedState.followingIDs = [charlotte.id, luke.id]
        sharedContent = Self.loadSharedContent(
            from: defaults,
            seed: seedState,
            legacyState: savedState,
            testEmail: Self.testAccountEmail,
            testUserID: Self.testUserID,
            accountStateKeyPrefix: "yorzi.account.state.",
            profileKeyPrefix: "yorzi.account.profile.",
            accountUserIDKeyPrefix: "yorzi.account.user.id.",
            sharedContentKey: "yorzi.shared.content"
        )
        isSignedIn = defaults.bool(forKey: "yorzi.signedIn")
        if isSignedIn {
            let email = defaults.string(forKey: activeAccountEmailKey) ?? testEmail
            restoreAccountState(for: email, legacyState: savedState)
        } else {
            resetToGuestState()
        }
        // A user must never be hidden from their own public lists by stale test data.
        blockedIDs.remove(currentUserID)
        if !hasFreshSeed {
            // First launch with the new seed: persist the fresh dataset and reset content caches.
            persist()
            defaults.set(seedVersion, forKey: "yorzi.seed.version")
        }
    }

    // MARK: Seed asset helpers

    private static func assetPNGData(named name: String) -> Data? {
        guard let image = UIImage(named: name) else { return nil }
        return image.pngData()
    }

    private static func bundleFileData(named name: String, ext: String) -> Data? {
        // Videos ship in the app bundle's "file" folder.
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return try? Data(contentsOf: url)
        }
        if let url = Bundle.main.url(forResource: "file/\(name)", withExtension: ext) {
            return try? Data(contentsOf: url)
        }
        if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "file") {
            return try? Data(contentsOf: URL(fileURLWithPath: path))
        }
        return nil
    }

    private static func videoThumbnailData(from videoData: Data) -> Data? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("yorzi-seed-\(UUID().uuidString).mp4")
        guard (try? videoData.write(to: url)) != nil else { return nil }
        defer { try? FileManager.default.removeItem(at: url) }

        let asset = AVAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        let duration = asset.duration.seconds
        let seconds = duration.isFinite && duration > 0 ? min(0.1, max(0, duration - 0.01)) : 0
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        let cgImage = (try? generator.copyCGImage(at: time, actualTime: nil))
            ?? (try? generator.copyCGImage(at: .zero, actualTime: nil))
        guard let cgImage else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86)
    }

    var visibleUsers: [AppUser] { users.filter { !blockedIDs.contains($0.id) && $0.id != currentUserID } }
    var visibleWorks: [Work] { works.filter { work in guard !blockedIDs.contains(work.authorID) else { return false }; switch workVisibilities[work.id] ?? .public { case .public: return true; case .diveCircle: return work.authorID == currentUserID || (followingIDs.contains(work.authorID) && followerIDs.contains(work.authorID)); case .onlyMe: return false } } }
    var visibleCalls: [CollabCall] { calls.filter { !blockedIDs.contains($0.authorID) } }
    var visibleComments: [AppComment] { comments.filter { !blockedIDs.contains($0.authorID) } }
    var visibleConversations: [Conversation] { conversations.filter { !blockedIDs.contains($0.participantID) } }
    var collaboratedCalls: [CollabCall] { calls.filter { !blockedIDs.contains($0.authorID) && (collaboratedCallIDs.contains($0.id) || $0.authorID == currentUserID) } }

    func acceptEULA() { defaults.set(true, forKey: "yorzi.eula.accepted") }
    func enterGuest() {
        saveActiveAccountState()
        resetToGuestState()
        isGuest = true
        isSignedIn = false
        defaults.removeObject(forKey: activeAccountEmailKey)
        notifyAuth()
    }
    func signIn(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let registeredEmail = defaults.string(forKey: "yorzi.registered.email")?.lowercased()
        let validTest = testAccountValid && normalized == testEmail && password == testPassword
        let validRegistered = normalized == registeredEmail && password == defaults.string(forKey: "yorzi.registered.password")
        guard validTest || validRegistered else { return false }
        saveActiveAccountState()
        isGuest = false
        isSignedIn = true
        defaults.set(true, forKey: "yorzi.signedIn")
        restoreAccountState(for: normalized, legacyState: normalized == testEmail ? Self.loadLegacyState(from: defaults) : nil)
        persist()
        notifyAuth()
        return true
    }
    func completeRegistration(email: String, password: String, name: String, gender: String?, birthDate: String?, avatar: UIImage?) {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        saveActiveAccountState()
        defaults.set(normalized, forKey: "yorzi.registered.email")
        defaults.set(password, forKey: "yorzi.registered.password")
        defaults.set(normalized, forKey: activeAccountEmailKey)
        currentUserID = accountUserID(for: normalized)
        resetToNewAccountState()
        setCurrentProfile(name: name, gender: gender, birthDate: birthDate, avatar: avatar)
        isGuest = false
        isSignedIn = true
        defaults.set(true, forKey: "yorzi.signedIn")
        defaults.set(true, forKey: accountInitializedKey(for: normalized))
        persist()
        notifyAuth()
    }
    func resetPassword(email: String, password: String) -> Bool {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized != testEmail, normalized == defaults.string(forKey: "yorzi.registered.email")?.lowercased() else { return false }
        defaults.set(password, forKey: "yorzi.registered.password"); return true
    }
    func signOut() {
        saveActiveAccountState()
        resetToGuestState()
        isGuest = false
        isSignedIn = false
        defaults.set(false, forKey: "yorzi.signedIn")
        defaults.removeObject(forKey: activeAccountEmailKey)
        notifyAuth()
    }
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
        persist()
        notify()
    }
    func block(_ id: UUID) {
        guard id != currentUserID else { return }
        blockedIDs.insert(id); persist(); notify()
    }
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
        defaults.bool(forKey: accountScopedKey("yorzi.work.resolution.unlocked.\(workID.uuidString)"))
    }
    func unlockResolution(for workID: UUID) {
        defaults.set(true, forKey: accountScopedKey("yorzi.work.resolution.unlocked.\(workID.uuidString)"))
        notify()
    }
    func updateProfile(name: String, bio: String) {
        guard let index = users.firstIndex(where: { $0.id == currentUserID }) else { return }
        users[index].name = name
        users[index].bio = bio
        persist()
        notify()
    }
    func updateCurrentProfile(name: String, gender: String?, birthDate: String? = nil, avatar: UIImage?) {
        setCurrentProfile(name: name, gender: gender, birthDate: birthDate, avatar: avatar)
        persist()
        notify()
    }

    private func setCurrentProfile(name: String, gender: String?, birthDate: String?, avatar: UIImage?) {
        if users.firstIndex(where: { $0.id == currentUserID }) == nil {
            users.append(AppUser(id: currentUserID, name: name, role: "", location: "", bio: ""))
        }
        guard let index = users.firstIndex(where: { $0.id == currentUserID }) else { return }
        users[index].name = name
        if let gender { users[index].gender = gender }
        if let birthDate { users[index].birthDate = birthDate }
        if let avatar, let data = avatar.jpegData(compressionQuality: 0.8) {
            users[index].avatarData = data
        }
    }

    private var activeAccountEmail: String {
        defaults.string(forKey: activeAccountEmailKey)?.lowercased() ?? testEmail
    }

    private func accountStateKey(for email: String) -> String {
        accountStateKeyPrefix + email.lowercased()
    }

    private func accountUserID(for email: String) -> UUID {
        Self.persistedUserID(
            for: email,
            defaults: defaults,
            testEmail: testEmail,
            testUserID: testUserID,
            accountUserIDKeyPrefix: accountUserIDKeyPrefix
        )
    }

    private func accountInitializedKey(for email: String) -> String {
        accountInitializedKeyPrefix + email.lowercased()
    }

    private func accountScopedKey(_ key: String) -> String {
        "\(key).\(activeAccountEmail)"
    }

    private static func loadLegacyState(from defaults: UserDefaults) -> PersistedState? {
        guard let data = defaults.data(forKey: "yorzi.repository") else { return nil }
        guard var state = try? JSONDecoder().decode(PersistedState.self, from: data) else { return nil }
        if let followerData = defaults.data(forKey: "yorzi.followers"),
           let savedFollowers = try? JSONDecoder().decode([UUID].self, from: followerData) {
            state.followerIDs = savedFollowers
        }
        state.collaboratedCallIDs = defaults.stringArray(forKey: "yorzi.collaborated.calls")?.compactMap(UUID.init(uuidString:)) ?? []
        if let visibilityData = defaults.data(forKey: "yorzi.work.visibility"),
           let savedVisibility = try? JSONDecoder().decode([String: WorkVisibility].self, from: visibilityData) {
            state.workVisibilities = savedVisibility
        }
        return state
    }

    private static func persistedUserID(
        for email: String,
        defaults: UserDefaults,
        testEmail: String,
        testUserID: UUID,
        accountUserIDKeyPrefix: String
    ) -> UUID {
        let normalized = email.lowercased()
        if normalized == testEmail { return testUserID }
        let key = accountUserIDKeyPrefix + normalized
        if let value = defaults.string(forKey: key), let id = UUID(uuidString: value) {
            return id
        }
        let id = UUID()
        defaults.set(id.uuidString, forKey: key)
        return id
    }

    private static func loadSharedContent(
        from defaults: UserDefaults,
        seed: PersistedState,
        legacyState: PersistedState?,
        testEmail: String,
        testUserID: UUID,
        accountStateKeyPrefix: String,
        profileKeyPrefix: String,
        accountUserIDKeyPrefix: String,
        sharedContentKey: String
    ) -> SharedState {
        var merged = SharedState(
            users: seed.users,
            works: seed.works.map { work in
                var copy = work
                copy.liked = false
                copy.saved = false
                return copy
            },
            calls: seed.calls,
            comments: seed.comments,
            workVisibilities: seed.workVisibilities ?? [:]
        )

        if let data = defaults.data(forKey: sharedContentKey),
           let saved = try? JSONDecoder().decode(SharedState.self, from: data) {
            mergeSharedContent(&merged, saved)
        }

        if let legacyState {
            let legacyEmail = defaults.string(forKey: "yorzi.active.account.email")?.lowercased() ?? testEmail
            mergePersistedContent(
                &merged,
                state: legacyState,
                email: legacyEmail,
                defaults: defaults,
                testEmail: testEmail,
                testUserID: testUserID,
                profileKeyPrefix: profileKeyPrefix,
                accountUserIDKeyPrefix: accountUserIDKeyPrefix
            )
        }

        let accountKeys = defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(accountStateKeyPrefix) }
            .sorted()
        for key in accountKeys {
            let email = String(key.dropFirst(accountStateKeyPrefix.count)).lowercased()
            guard let data = defaults.data(forKey: key),
                  let state = try? JSONDecoder().decode(PersistedState.self, from: data) else { continue }
            mergePersistedContent(
                &merged,
                state: state,
                email: email,
                defaults: defaults,
                testEmail: testEmail,
                testUserID: testUserID,
                profileKeyPrefix: profileKeyPrefix,
                accountUserIDKeyPrefix: accountUserIDKeyPrefix
            )
        }

        return merged
    }

    private static func mergePersistedContent(
        _ target: inout SharedState,
        state: PersistedState,
        email: String,
        defaults: UserDefaults,
        testEmail: String,
        testUserID: UUID,
        profileKeyPrefix: String,
        accountUserIDKeyPrefix: String
    ) {
        let ownerID = persistedUserID(
            for: email,
            defaults: defaults,
            testEmail: testEmail,
            testUserID: testUserID,
            accountUserIDKeyPrefix: accountUserIDKeyPrefix
        )

        var users = state.users
        if email != testEmail {
            users.removeAll { $0.id == testUserID }
        }
        if let profileData = defaults.data(forKey: profileKeyPrefix + email),
           let profile = try? JSONDecoder().decode(AppUser.self, from: profileData) {
            users.removeAll { $0.id == ownerID }
            users.append(AppUser(
                id: ownerID,
                name: profile.name,
                role: profile.role,
                location: profile.location,
                bio: profile.bio,
                gender: profile.gender,
                birthDate: profile.birthDate,
                avatarData: profile.avatarData
            ))
        }

        let remapLegacyOwner = email != testEmail
        let shared = SharedState(
            users: users,
            works: state.works.map { work in
                let work = remapLegacyOwner && work.authorID == testUserID
                    ? remap(work, authorID: ownerID)
                    : work
                var copy = work
                copy.liked = false
                copy.saved = false
                return copy
            },
            calls: state.calls.map { call in
                remapLegacyOwner && call.authorID == testUserID
                    ? remap(call, authorID: ownerID)
                    : call
            },
            comments: state.comments.map { comment in
                remapLegacyOwner && comment.authorID == testUserID
                    ? remap(comment, authorID: ownerID)
                    : comment
            },
            workVisibilities: state.workVisibilities ?? [:]
        )
        mergeSharedContent(&target, shared)
    }

    private static func remap(_ work: Work, authorID: UUID) -> Work {
        Work(
            id: work.id,
            authorID: authorID,
            title: work.title,
            category: work.category,
            location: work.location,
            description: work.description,
            liked: work.liked,
            saved: work.saved,
            likes: work.likes,
            timeAgo: work.timeAgo,
            collaborators: work.collaborators,
            openToCollab: work.openToCollab,
            createdAt: work.createdAt,
            mediaData: work.mediaData,
            mediaDatas: work.mediaDatas,
            videoData: work.videoData
        )
    }

    private static func remap(_ call: CollabCall, authorID: UUID) -> CollabCall {
        CollabCall(
            id: call.id,
            authorID: authorID,
            title: call.title,
            location: call.location,
            budget: call.budget,
            roles: call.roles,
            timing: call.timing,
            description: call.description,
            date: call.date,
            deadline: call.deadline,
            mediaData: call.mediaData,
            mediaDatas: call.mediaDatas,
            videoData: call.videoData
        )
    }

    private static func remap(_ comment: AppComment, authorID: UUID) -> AppComment {
        AppComment(
            id: comment.id,
            workID: comment.workID,
            authorID: authorID,
            text: comment.text,
            createdAt: comment.createdAt
        )
    }

    private static func mergeSharedContent(_ target: inout SharedState, _ source: SharedState) {
        var userMap = Dictionary(uniqueKeysWithValues: target.users.map { ($0.id, $0) })
        source.users.forEach { userMap[$0.id] = $0 }
        target.users = Array(userMap.values)

        var workMap = Dictionary(uniqueKeysWithValues: target.works.map { ($0.id, $0) })
        source.works.forEach {
            var copy = $0
            copy.liked = false
            copy.saved = false
            workMap[$0.id] = copy
        }
        target.works = Array(workMap.values)

        var callMap = Dictionary(uniqueKeysWithValues: target.calls.map { ($0.id, $0) })
        source.calls.forEach { callMap[$0.id] = $0 }
        target.calls = Array(callMap.values)

        var commentMap = Dictionary(uniqueKeysWithValues: target.comments.map { ($0.id, $0) })
        source.comments.forEach { commentMap[$0.id] = $0 }
        target.comments = Array(commentMap.values)

        source.workVisibilities.forEach { target.workVisibilities[$0.key] = $0.value }
    }

    private func currentState() -> PersistedState {
        let visibilityValues = Dictionary(uniqueKeysWithValues: workVisibilities.map { ($0.key.uuidString, $0.value) })
        return PersistedState(
            users: users,
            works: works.map(externalizeMedia),
            calls: calls.map(externalizeMedia),
            comments: comments,
            conversations: conversations.map(externalizeMedia),
            reports: reports,
            blockedIDs: Array(blockedIDs),
            followingIDs: Array(followingIDs),
            balance: balance,
            followerIDs: Array(followerIDs),
            collaboratedCallIDs: Array(collaboratedCallIDs),
            workVisibilities: visibilityValues
        )
    }

    private func applySharedContent(_ state: SharedState) {
        users = state.users
        works = state.works.map(restoreMedia)
        calls = state.calls.map(restoreMedia)
        comments = state.comments
        workVisibilities = Dictionary(uniqueKeysWithValues: state.workVisibilities.compactMap { key, value in
            UUID(uuidString: key).map { ($0, value) }
        })
    }

    private func applyAccountState(_ state: PersistedState) {
        let savedWorks = Dictionary(uniqueKeysWithValues: state.works.map { ($0.id, $0) })
        for index in works.indices {
            guard let savedWork = savedWorks[works[index].id] else { continue }
            works[index].liked = savedWork.liked
            works[index].saved = savedWork.saved
        }
        conversations = state.conversations.map(restoreMedia)
        reports = state.reports
        blockedIDs = Set(state.blockedIDs)
        followingIDs = Set(state.followingIDs)
        if let savedFollowers = state.followerIDs {
            followerIDs = Set(savedFollowers)
        }
        balance = state.balance
        if let savedCollaboratedCalls = state.collaboratedCallIDs {
            collaboratedCallIDs = Set(savedCollaboratedCalls)
        }
    }

    private func mergeCurrentProfile(_ profile: AppUser?) {
        guard let profile else { return }
        var normalized = profile
        normalized = AppUser(
            id: currentUserID,
            name: normalized.name,
            role: normalized.role,
            location: normalized.location,
            bio: normalized.bio,
            gender: normalized.gender,
            birthDate: normalized.birthDate,
            avatarData: normalized.avatarData
        )
        if let index = users.firstIndex(where: { $0.id == currentUserID }) {
            users[index] = normalized
        } else {
            users.append(normalized)
        }
    }

    private func profileFromState(_ state: PersistedState, email: String) -> AppUser? {
        if let data = defaults.data(forKey: profileKeyPrefix + email),
           let profile = try? JSONDecoder().decode(AppUser.self, from: data) {
            return profile
        }
        return state.users.first(where: { $0.id == currentUserID })
            ?? (email == testEmail ? state.users.first(where: { $0.id == testUserID }) : nil)
    }

    private func resetToGuestState() {
        currentUserID = testUserID
        applySharedContent(sharedContent)
        conversations = []
        reports = []
        blockedIDs = []
        followingIDs = []
        followerIDs = []
        collaboratedCallIDs = []
        balance = 0
    }

    private func resetToNewAccountState() {
        applySharedContent(sharedContent)
        conversations = []
        reports = []
        blockedIDs = []
        followingIDs = []
        followerIDs = []
        collaboratedCallIDs = []
        balance = 0
    }

    private func restoreAccountState(for email: String, legacyState: PersistedState? = nil) {
        let normalized = email.lowercased()
        defaults.set(normalized, forKey: activeAccountEmailKey)
        currentUserID = accountUserID(for: normalized)
        applySharedContent(sharedContent)
        if let data = defaults.data(forKey: accountStateKey(for: normalized)),
           let saved = try? JSONDecoder().decode(PersistedState.self, from: data) {
            let profile = profileFromState(saved, email: normalized)
            if normalized != testEmail && !defaults.bool(forKey: accountInitializedKey(for: normalized)) {
                resetToNewAccountState()
                mergeCurrentProfile(profile)
            } else {
                applyAccountState(saved)
                mergeCurrentProfile(profile)
            }
        } else if normalized == testEmail, let legacyState {
            let migratedState: PersistedState
            if legacyState.followingIDs.isEmpty && legacyState.conversations.isEmpty {
                migratedState = seedState
            } else {
                migratedState = legacyState
            }
            applyAccountState(migratedState)
            mergeCurrentProfile(profileFromState(migratedState, email: normalized) ?? defaultTestProfile)
        } else {
            if normalized == testEmail {
                applyAccountState(seedState)
                mergeCurrentProfile(defaultTestProfile)
            } else {
                resetToNewAccountState()
            }
        }
        if normalized != testEmail {
            defaults.set(true, forKey: accountInitializedKey(for: normalized))
        }
    }

    private func saveActiveAccountState() {
        guard isSignedIn, defaults.string(forKey: activeAccountEmailKey) != nil else { return }
        persist()
    }
    func send(_ message: ChatMessage, to participantID: UUID) {
        if let index = conversations.firstIndex(where: { $0.participantID == participantID }) { conversations[index].messages.append(message) }
        else { conversations.append(.init(id: UUID(), participantID: participantID, messages: [message])) }
        persist(); notify()
    }

    private var mediaDirectoryURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("YorziMedia", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func mediaURL(named name: String) -> URL {
        mediaDirectoryURL.appendingPathComponent(name).appendingPathExtension("bin")
    }

    private func writeMedia(_ data: Data?, named name: String) {
        guard let data, !data.isEmpty else { return }
        let url = mediaURL(named: name)
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        try? data.write(to: url, options: .atomic)
    }

    private func readMedia(named name: String) -> Data? {
        try? Data(contentsOf: mediaURL(named: name))
    }

    private func externalizeMedia(_ work: Work) -> Work {
        writeMedia(work.mediaData, named: "work-\(work.id.uuidString)-cover")
        if let mediaDatas = work.mediaDatas {
            for (index, data) in mediaDatas.enumerated() {
                writeMedia(data, named: "work-\(work.id.uuidString)-media-\(index)")
            }
        } else {
            writeMedia(work.mediaData, named: "work-\(work.id.uuidString)-media-0")
        }
        writeMedia(work.videoData, named: "work-\(work.id.uuidString)-video")

        var lightweight = work
        lightweight.mediaData = nil
        lightweight.mediaDatas = nil
        lightweight.videoData = nil
        return lightweight
    }

    private func externalizeMedia(_ call: CollabCall) -> CollabCall {
        writeMedia(call.mediaData, named: "call-\(call.id.uuidString)-cover")
        if let mediaDatas = call.mediaDatas {
            for (index, data) in mediaDatas.enumerated() {
                writeMedia(data, named: "call-\(call.id.uuidString)-media-\(index)")
            }
        } else {
            writeMedia(call.mediaData, named: "call-\(call.id.uuidString)-media-0")
        }
        writeMedia(call.videoData, named: "call-\(call.id.uuidString)-video")

        var lightweight = call
        lightweight.mediaData = nil
        lightweight.mediaDatas = nil
        lightweight.videoData = nil
        return lightweight
    }

    private func restoreMedia(_ work: Work) -> Work {
        var restored = work
        restored.mediaData = restored.mediaData ?? readMedia(named: "work-\(work.id.uuidString)-cover")
        if restored.mediaDatas == nil {
            var mediaDatas: [Data] = []
            var index = 0
            while let data = readMedia(named: "work-\(work.id.uuidString)-media-\(index)") {
                mediaDatas.append(data)
                index += 1
            }
            restored.mediaDatas = mediaDatas.isEmpty ? nil : mediaDatas
        }
        restored.videoData = restored.videoData ?? readMedia(named: "work-\(work.id.uuidString)-video")
        return restored
    }

    private func restoreMedia(_ call: CollabCall) -> CollabCall {
        var restored = call
        restored.mediaData = restored.mediaData ?? readMedia(named: "call-\(call.id.uuidString)-cover")
        if restored.mediaDatas == nil {
            var mediaDatas: [Data] = []
            var index = 0
            while let data = readMedia(named: "call-\(call.id.uuidString)-media-\(index)") {
                mediaDatas.append(data)
                index += 1
            }
            restored.mediaDatas = mediaDatas.isEmpty ? nil : mediaDatas
        }
        restored.videoData = restored.videoData ?? readMedia(named: "call-\(call.id.uuidString)-video")
        return restored
    }

    private func externalizeMedia(_ conversation: Conversation) -> Conversation {
        var lightweight = conversation
        lightweight.messages = conversation.messages.map { message in
            writeMedia(message.mediaData, named: "conversation-\(conversation.id.uuidString)-message-\(message.id.uuidString)")
            var copy = message
            copy.mediaData = nil
            return copy
        }
        return lightweight
    }

    private func restoreMedia(_ conversation: Conversation) -> Conversation {
        var restored = conversation
        restored.messages = conversation.messages.map { message in
            var copy = message
            copy.mediaData = copy.mediaData ?? readMedia(named: "conversation-\(conversation.id.uuidString)-message-\(message.id.uuidString)")
            return copy
        }
        return restored
    }

    private func updateSharedContentFromCurrent() {
        var shared = sharedContent ?? SharedState(
            users: [],
            works: [],
            calls: [],
            comments: [],
            workVisibilities: [:]
        )
        shared.users = users

        var workMap = Dictionary(uniqueKeysWithValues: shared.works.map { ($0.id, $0) })
        works.forEach { work in
            var copy = work
            copy.liked = false
            copy.saved = false
            workMap[work.id] = copy
        }
        shared.works = Array(workMap.values)

        var callMap = Dictionary(uniqueKeysWithValues: shared.calls.map { ($0.id, $0) })
        calls.forEach { callMap[$0.id] = $0 }
        shared.calls = Array(callMap.values)

        var commentMap = Dictionary(uniqueKeysWithValues: shared.comments.map { ($0.id, $0) })
        comments.forEach { commentMap[$0.id] = $0 }
        shared.comments = Array(commentMap.values)
        shared.workVisibilities = Dictionary(uniqueKeysWithValues: workVisibilities.map { ($0.key.uuidString, $0.value) })
        sharedContent = shared
    }

    private func persistBlocks() { defaults.set(blockedIDs.map(\.uuidString), forKey: "yorzi.blocked") }
    private func persist() {
        updateSharedContentFromCurrent()
        let state = currentState()
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: "yorzi.repository")
        let sharedState = SharedState(
            users: sharedContent.users,
            works: sharedContent.works.map(externalizeMedia),
            calls: sharedContent.calls.map(externalizeMedia),
            comments: sharedContent.comments,
            workVisibilities: sharedContent.workVisibilities
        )
        if let sharedData = try? JSONEncoder().encode(sharedState) {
            defaults.set(sharedData, forKey: sharedContentKey)
        }
        guard isSignedIn, defaults.string(forKey: activeAccountEmailKey) != nil else { return }
        defaults.set(data, forKey: accountStateKey(for: activeAccountEmail))
        if let profileData = try? JSONEncoder().encode(currentUser) {
            defaults.set(profileData, forKey: profileKeyPrefix + activeAccountEmail)
        }
        defaults.set(true, forKey: accountInitializedKey(for: activeAccountEmail))
    }
    private func persistFollowers() { if let data = try? JSONEncoder().encode(Array(followerIDs)) { defaults.set(data, forKey: "yorzi.followers") } }
    private func persistCollaboratedCalls() { defaults.set(collaboratedCallIDs.map(\.uuidString), forKey: "yorzi.collaborated.calls") }
    private func persistVisibility() { let values = Dictionary(uniqueKeysWithValues: workVisibilities.map { ($0.key.uuidString, $0.value) }); if let data = try? JSONEncoder().encode(values) { defaults.set(data, forKey: "yorzi.work.visibility") } }
    private func persistBalance() { defaults.set(balance, forKey: "yorzi.balance"); persist() }
    private func notify() { NotificationCenter.default.post(name: .repositoryDidChange, object: self) }
    private func notifyAuth() { NotificationCenter.default.post(name: .authenticationDidChange, object: self) }
}
