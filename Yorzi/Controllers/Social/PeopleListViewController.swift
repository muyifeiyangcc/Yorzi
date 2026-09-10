import UIKit
import SnapKit

// Reusable people-list page used by Block List / Following / Followers.
class PeopleListViewController: BaseViewController {
    enum Mode {
        case block
        case following
        case followers
    }

    private let mode: Mode
    private let pageTitle: String
    private let tableView = UITableView()
    private var users: [AppUser] = []

    init(title: String, mode: Mode) {
        self.pageTitle = title
        self.mode = mode
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
        back.layer.cornerRadius = 18
        back.layer.masksToBounds = true
        back.layer.borderWidth = 1
        back.layer.borderColor = AppTheme.divider.cgColor
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        // Keep the control below the status bar on devices whose top safe area
        // is only the status-bar height (for example iPhone 8 Plus).
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(0); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(36) }

        let title = UILabel()
        title.text = pageTitle
        title.font = UIFont(name: "Georgia", size: 25) ?? .systemFont(ofSize: 25, weight: .regular)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.centerY.equalTo(back); $0.leading.equalTo(back.snp.trailing).offset(10) }
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(PeopleRowCell.self, forCellReuseIdentifier: PeopleRowCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(43); $0.leading.trailing.bottom.equalToSuperview() }
    }

    private func reload() {
        switch mode {
        case .block:
            users = DataRepository.shared.blockedIDs.compactMap { DataRepository.shared.user($0) }
        case .following:
            users = DataRepository.shared.visibleUsers.filter { DataRepository.shared.isFollowing($0.id) }
        case .followers:
            users = DataRepository.shared.visibleUsers.filter { DataRepository.shared.followerIDs.contains($0.id) }
        }
        tableView.reloadData()
    }
}

extension PeopleListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { users.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PeopleRowCell.reuseID, for: indexPath) as! PeopleRowCell
        let user = users[indexPath.row]
        let actionTitle: String
        var filled = false
        switch mode {
        case .block:
            actionTitle = "Unblock"
        case .following:
            actionTitle = "Following"; filled = true
        case .followers:
            let isFollowing = DataRepository.shared.isFollowing(user.id)
            actionTitle = isFollowing ? "Following" : "Follow"
            filled = isFollowing
        }
        cell.configure(user: user, actionTitle: actionTitle, filled: filled) { [weak self] in
            guard let self else { return }
            switch self.mode {
            case .block:
                DataRepository.shared.unblock(user.id)
            default:
                DataRepository.shared.toggleFollow(user.id)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 69 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if mode != .block {
            push(CreatorProfileViewController(userID: users[indexPath.row].id))
        }
    }
}

// MARK: - Row cell

private final class PeopleRowCell: UITableViewCell {
    static let reuseID = "PeopleRowCell"
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var action: (() -> Void)?
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 21
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = UIColor(hex: 0xE0E0E8)
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { $0.leading.equalToSuperview().offset(20); $0.centerY.equalToSuperview(); $0.size.equalTo(42) }

        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = AppTheme.ink
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(14); $0.top.equalTo(avatarView).offset(2) }

        detailLabel.font = .systemFont(ofSize: 10, weight: .regular)
        detailLabel.textColor = AppTheme.secondary
        contentView.addSubview(detailLabel)
        detailLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(3) }

        actionButton.titleLabel?.font = .systemFont(ofSize: 10, weight: .regular)
        actionButton.layer.cornerRadius = 8
        actionButton.layer.masksToBounds = true
        actionButton.contentEdgeInsets = .zero
        actionButton.addAction(UIAction { [weak self] _ in self?.action?() }, for: .touchUpInside)
        contentView.addSubview(actionButton)
        actionButton.snp.makeConstraints { $0.trailing.equalToSuperview().inset(16); $0.centerY.equalToSuperview(); $0.width.equalTo(77); $0.height.equalTo(30) }

        separator.backgroundColor = AppTheme.divider
        contentView.addSubview(separator)
        separator.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.trailing.equalToSuperview().inset(20); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }
    required init?(coder: NSCoder) { nil }

    func configure(user: AppUser, actionTitle: String, filled: Bool, action: @escaping () -> Void) {
        self.action = action
        nameLabel.text = user.name
        detailLabel.text = user.location
        if let data = user.avatarData { avatarView.image = UIImage(data: data) }
        else { avatarView.image = UIImage(systemName: "person.crop.circle.fill"); avatarView.tintColor = AppTheme.lavender }

        actionButton.setTitle(actionTitle, for: .normal)
        if filled {
            actionButton.backgroundColor = AppTheme.ink
            actionButton.setTitleColor(.white, for: .normal)
            actionButton.layer.borderWidth = 0
        } else {
            actionButton.backgroundColor = .white
            actionButton.setTitleColor(AppTheme.secondary, for: .normal)
            actionButton.layer.borderWidth = 1.5
            actionButton.layer.borderColor = AppTheme.divider.cgColor
        }
    }
}
