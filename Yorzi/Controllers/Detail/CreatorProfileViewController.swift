import UIKit
import SnapKit

final class CreatorProfileViewController: BaseViewController {
    private let userID: UUID
    private let tableView = UITableView()
    private var works: [Work] = []
    private var collabCalls: [CollabCall] = []
    private var selectedTab = 0
    private var followButton: UIButton?

    init(userID: UUID) {
        self.userID = userID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNav()
        setupTable()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
        reload()
    }

    private func setupNav() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppTheme.ink
        back.backgroundColor = .white
        back.layer.cornerRadius = 20
        back.layer.masksToBounds = true
        back.layer.borderWidth = 1
        back.layer.borderColor = AppTheme.divider.cgColor
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(40) }

        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        more.tintColor = AppTheme.ink
        more.backgroundColor = .white
        more.layer.cornerRadius = 20
        more.layer.masksToBounds = true
        more.layer.borderWidth = 1
        more.layer.borderColor = AppTheme.divider.cgColor
        more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        view.addSubview(more)
        more.snp.makeConstraints { $0.top.equalTo(back); $0.trailing.equalToSuperview().inset(15); $0.size.equalTo(40) }
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(WorkCardCell.self, forCellReuseIdentifier: WorkCardCell.reuseID)
        tableView.register(CollabCallCell.self, forCellReuseIdentifier: CollabCallCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(68); $0.leading.trailing.bottom.equalToSuperview() }
        tableView.tableHeaderView = makeHeader()
    }

    private func makeHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 364))

        guard let user = DataRepository.shared.user(userID) else { return container }

        // Avatar centered
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 40
        avatar.layer.masksToBounds = true
        avatar.backgroundColor = UIColor(hex: 0xE0E0E8)
        if let data = user.avatarData { avatar.image = UIImage(data: data) }
        else { avatar.image = UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender }
        container.addSubview(avatar)
        avatar.snp.makeConstraints { $0.top.equalToSuperview().offset(8); $0.centerX.equalToSuperview(); $0.size.equalTo(80) }

        // Name centered
        let name = UILabel()
        name.text = user.name
        name.font = .systemFont(ofSize: 20, weight: .semibold)
        name.textColor = AppTheme.ink
        name.textAlignment = .center
        container.addSubview(name)
        name.snp.makeConstraints { $0.top.equalTo(avatar.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(24) }

        // Bio centered
        let bio = UILabel()
        bio.text = user.bio
        bio.font = .systemFont(ofSize: 12, weight: .regular)
        bio.textColor = AppTheme.secondary
        bio.textAlignment = .center
        bio.numberOfLines = 0
        container.addSubview(bio)
        bio.snp.makeConstraints { $0.top.equalTo(name.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(30) }

        // Stats
        let topDivider = UIView(); topDivider.backgroundColor = AppTheme.divider
        let bottomDivider = UIView(); bottomDivider.backgroundColor = AppTheme.divider
        container.addSubview(topDivider)
        container.addSubview(bottomDivider)
        topDivider.snp.makeConstraints { $0.top.equalTo(bio.snp.bottom).offset(18); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(1) }

        let worksCount = statLabel(formatCount(DataRepository.shared.works.filter { $0.authorID == userID }.count)); let followers = statLabel(formatCount(DataRepository.shared.followerIDs.contains(userID) ? 1 : 0)); let following = statLabel(formatCount(DataRepository.shared.followingIDs.contains(userID) ? 1 : 0))
        let worksLbl = statCaption("Works"); let followersLbl = statCaption("Followers"); let followingLbl = statCaption("Following")
        let col1 = UIStackView(arrangedSubviews: [worksCount, worksLbl]); col1.axis = .vertical; col1.spacing = 2
        let col2 = UIStackView(arrangedSubviews: [followers, followersLbl]); col2.axis = .vertical; col2.spacing = 2
        let col3 = UIStackView(arrangedSubviews: [following, followingLbl]); col3.axis = .vertical; col3.spacing = 2
        let statsRow = UIStackView(arrangedSubviews: [col1, col2, col3]); statsRow.axis = .horizontal; statsRow.distribution = .fillEqually
        container.addSubview(statsRow)
        statsRow.snp.makeConstraints { $0.top.equalTo(topDivider).offset(12); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(44) }
        bottomDivider.snp.makeConstraints { $0.top.equalTo(statsRow.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(1) }

        // Follow + Message buttons
        let follow = UIButton(type: .system)
        follow.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        follow.layer.cornerRadius = 14
        follow.layer.masksToBounds = true
        follow.addAction(UIAction { [weak self] _ in
            DataRepository.shared.toggleFollow(user.id)
            self?.refreshFollowButton(follow)
        }, for: .touchUpInside)
        container.addSubview(follow)
        followButton = follow

        let message = UIButton(type: .system)
        message.setTitle("Message", for: .normal)
        message.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        message.setTitleColor(AppTheme.secondary, for: .normal)
        message.backgroundColor = .white
        message.layer.cornerRadius = 14
        message.layer.masksToBounds = true
        message.layer.borderWidth = 1.5
        message.layer.borderColor = AppTheme.divider.cgColor
        message.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            let canChat = DataRepository.shared.isFollowing(user.id) && DataRepository.shared.followerIDs.contains(user.id)
            if canChat { self.push(ChatViewController(participantID: user.id)) }
            else {
                let dialog = AppDialogView(title: "Connect to Chat", message: "Follow each other to unlock messages.", actions: [.init(title: "OK", style: .accent, handler: nil)])
                dialog.present(in: self.view.window ?? self.view)
            }
        }, for: .touchUpInside)
        container.addSubview(message)
        message.snp.makeConstraints {
            $0.top.equalTo(bottomDivider.snp.bottom).offset(20)
            $0.trailing.equalToSuperview().inset(15)
            $0.height.equalTo(40); $0.width.equalToSuperview().multipliedBy(0.45)
        }
        follow.snp.makeConstraints {
            $0.top.equalTo(message)
            $0.leading.equalToSuperview().offset(15)
            $0.height.equalTo(40); $0.width.equalTo(message)
        }
        refreshFollowButton(follow)

        // Works / Collab history tabs
        let worksTab = UIButton(type: .system)
        worksTab.setTitle("Works", for: .normal)
        worksTab.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
        worksTab.setTitleColor(selectedTab == 0 ? AppTheme.ink : AppTheme.secondary, for: .normal)
        let collabTab = UIButton(type: .system)
        collabTab.setTitle("Collab history", for: .normal)
        collabTab.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        collabTab.setTitleColor(selectedTab == 1 ? AppTheme.ink : AppTheme.secondary, for: .normal)

        let underline = UIView()
        underline.backgroundColor = AppTheme.ink
        container.addSubview(worksTab)
        container.addSubview(collabTab)
        container.addSubview(underline)
        worksTab.addAction(UIAction { [weak self] _ in self?.selectedTab = 0; self?.reload() }, for: .touchUpInside)
        collabTab.addAction(UIAction { [weak self] _ in self?.selectedTab = 1; self?.reload() }, for: .touchUpInside)
        worksTab.snp.makeConstraints { $0.top.equalTo(follow.snp.bottom).offset(20); $0.leading.equalToSuperview().offset(15); $0.height.equalTo(34) }
        collabTab.snp.makeConstraints { $0.centerY.equalTo(worksTab); $0.leading.equalTo(worksTab.snp.trailing).offset(28) }
        underline.snp.makeConstraints { $0.top.equalTo(worksTab.snp.bottom); $0.leading.equalTo(selectedTab == 0 ? worksTab.snp.leading : collabTab.snp.leading); $0.width.equalTo(selectedTab == 0 ? worksTab.snp.width : collabTab.snp.width); $0.height.equalTo(2) }

        return container
    }

    private func statLabel(_ text: String) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 18, weight: .bold); l.textColor = AppTheme.ink; l.textAlignment = .center; return l
    }
    private func formatCount(_ value: Int) -> String { value >= 1000 ? String(format: "%.1fk", Double(value) / 1000.0) : "\(value)" }
    private func statCaption(_ text: String) -> UILabel {
        let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 11, weight: .regular); l.textColor = AppTheme.secondary; l.textAlignment = .center; return l
    }

    private func refreshFollowButton(_ button: UIButton) {
        let following = DataRepository.shared.isFollowing(userID)
        button.setTitle(following ? "Following" : "Follow", for: .normal)
        if following {
            button.backgroundColor = .white
            button.setTitleColor(AppTheme.secondary, for: .normal)
            button.layer.borderWidth = 1.5
            button.layer.borderColor = AppTheme.divider.cgColor
        } else {
            button.backgroundColor = AppTheme.ink
            button.setTitleColor(.white, for: .normal)
            button.layer.borderWidth = 0
        }
    }

    private func showMore() {
        let sheet = CustomSheetView(items: ["Report", "Block User", "Cancel"]) { [weak self] item in
            guard let self else { return }
            if item == "Report" {
                self.push(ReportViewController(targetID: self.userID))
            } else if item == "Block User" {
                self.blockUserAndReturnToRoot(self.userID)
            }
        }
        sheet.present(in: view.window ?? view)
    }

    private func reload() {
        works = DataRepository.shared.visibleWorks.filter { $0.authorID == userID }
        collabCalls = DataRepository.shared.calls.filter { $0.authorID == userID }
        tableView.tableHeaderView = makeHeader()
        tableView.reloadData()
    }
}

extension CreatorProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { selectedTab == 0 ? works.count : collabCalls.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedTab == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: WorkCardCell.reuseID, for: indexPath) as! WorkCardCell
            let work = works[indexPath.row]
            cell.configure(work: work, showsFollow: false, showsCollaborate: false)
            cell.onLike = { DataRepository.shared.toggleLike(work.id) }
            cell.onMore = { [weak self] in self?.showMore() }
            cell.onTap = { [weak self] in self?.push(WorkDetailViewController(work: work)) }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: CollabCallCell.reuseID, for: indexPath) as! CollabCallCell
        let call = collabCalls[indexPath.row]
        cell.configure(call: call)
        cell.onTap = { [weak self] in self?.push(CollabCallDetailViewController(call: call)) }
        cell.onMore = { [weak self] in self?.showMore() }
        cell.onCollaborate = { [weak self] in
            DataRepository.shared.collaborate(on: call.id)
            self?.reload()
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { selectedTab == 0 ? 380 : 340 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedTab == 0 { push(WorkDetailViewController(work: works[indexPath.row])) }
    }
}
