import UIKit
import SnapKit

final class ProfileViewController: BaseViewController {
    private let tableView = UITableView()
    private var myWorks: [Work] = []
    private var collabHistory: [CollabCall] = []
    private var sectionButtons: [UIButton] = []
    private var selectedSection = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHeader()
        setupTable()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
        reload()
    }

    private func setupHeader() {
        // Title
        let title = UILabel()
        title.text = "Profile•"
        title.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(10); $0.leading.equalToSuperview().offset(15) }

        // Edit button
        let settings = UIButton(type: .system)
        settings.setImage(UIImage(named: "setting")?.withRenderingMode(.alwaysOriginal), for: .normal)
        settings.backgroundColor = .white
        settings.layer.cornerRadius = 18
        settings.layer.masksToBounds = true
        settings.layer.borderWidth = 1
        settings.layer.borderColor = AppTheme.divider.cgColor
        settings.addAction(UIAction { [weak self] _ in self?.push(SettingsViewController()) }, for: .touchUpInside)
        view.addSubview(settings)
        settings.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.trailing.equalToSuperview().inset(15); $0.size.equalTo(36) }

        let edit = UIButton(type: .system)
        edit.setImage(UIImage(named: "edit")?.withRenderingMode(.alwaysOriginal), for: .normal)
        edit.backgroundColor = .white
        edit.layer.cornerRadius = 18
        edit.layer.masksToBounds = true
        edit.layer.borderWidth = 1
        edit.layer.borderColor = AppTheme.divider.cgColor
        edit.addAction(UIAction { [weak self] _ in self?.push(EditProfileViewController()) }, for: .touchUpInside)
        view.addSubview(edit)
        edit.snp.makeConstraints { $0.top.equalTo(settings); $0.trailing.equalTo(settings.snp.leading).offset(-10); $0.size.equalTo(36) }
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
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(56); $0.leading.trailing.bottom.equalToSuperview() }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        tableView.tableHeaderView = makeProfileHeader()
    }

    private func makeProfileHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 320))

        let user = DataRepository.shared.currentUser

        // Avatar
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 36
        avatar.layer.masksToBounds = true
        avatar.backgroundColor = UIColor(hex: 0xE0E0E8)
        if let data = user.avatarData { avatar.image = UIImage(data: data) }
        else { avatar.image = UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender }
        container.addSubview(avatar)
        avatar.snp.makeConstraints { $0.top.equalToSuperview().offset(2); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(72) }

        // Name
        let name = UILabel()
        name.text = user.name
        name.font = .systemFont(ofSize: 17, weight: .semibold)
        name.textColor = AppTheme.ink
        container.addSubview(name)
        name.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(14); $0.top.equalTo(avatar).offset(8) }

        // Bio
        let bio = UILabel()
        bio.text = user.bio
        bio.font = .systemFont(ofSize: 12, weight: .regular)
        bio.textColor = AppTheme.secondary
        bio.numberOfLines = 0
        container.addSubview(bio)
        bio.snp.makeConstraints { $0.leading.equalTo(name); $0.trailing.equalToSuperview().inset(15); $0.top.equalTo(name.snp.bottom).offset(4) }

        // Stats row
        let stats = UIView()
        container.addSubview(stats)
        stats.snp.makeConstraints { $0.top.equalTo(avatar.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview() }

        let worksCount = UILabel(); worksCount.text = formatCount(DataRepository.shared.works.filter { $0.authorID == DataRepository.shared.currentUserID }.count); worksCount.font = .systemFont(ofSize: 16, weight: .semibold); worksCount.textColor = AppTheme.ink; worksCount.textAlignment = .center
        let followers = UILabel(); followers.text = formatCount(DataRepository.shared.followerIDs.count); followers.font = .systemFont(ofSize: 16, weight: .semibold); followers.textColor = AppTheme.ink; followers.textAlignment = .center
        let following = UILabel(); following.text = formatCount(DataRepository.shared.followingIDs.count); following.font = .systemFont(ofSize: 16, weight: .semibold); following.textColor = AppTheme.ink; following.textAlignment = .center
        let worksLbl = UILabel(); worksLbl.text = "Works"; worksLbl.font = .systemFont(ofSize: 10); worksLbl.textColor = AppTheme.secondary; worksLbl.textAlignment = .center
        let followersLbl = UILabel(); followersLbl.text = "Followers"; followersLbl.font = .systemFont(ofSize: 10); followersLbl.textColor = AppTheme.secondary; followersLbl.textAlignment = .center
        let followingLbl = UILabel(); followingLbl.text = "Following"; followingLbl.font = .systemFont(ofSize: 10); followingLbl.textColor = AppTheme.secondary; followingLbl.textAlignment = .center

        let col1 = UIStackView(arrangedSubviews: [worksCount, worksLbl]); col1.axis = .vertical; col1.spacing = 2
        let col2 = UIStackView(arrangedSubviews: [followers, followersLbl]); col2.axis = .vertical; col2.spacing = 2
        let col3 = UIStackView(arrangedSubviews: [following, followingLbl]); col3.axis = .vertical; col3.spacing = 2
        let statsRow = UIStackView(arrangedSubviews: [col1, col2, col3]); statsRow.axis = .horizontal; statsRow.distribution = .fillEqually
        stats.addSubview(statsRow)
        statsRow.snp.makeConstraints { $0.edges.equalToSuperview() }

        // The stat labels are tappable targets, matching the profile design.
        let followersButton = UIButton(type: .custom)
        followersButton.backgroundColor = .clear
        followersButton.addAction(UIAction { [weak self] _ in self?.push(FollowersViewController()) }, for: .touchUpInside)
        stats.addSubview(followersButton)
        followersButton.snp.makeConstraints { $0.top.bottom.equalToSuperview(); $0.centerX.equalTo(stats.snp.centerX); $0.width.equalTo(stats.snp.width).multipliedBy(1.0 / 3.0) }

        let followingButton = UIButton(type: .custom)
        followingButton.backgroundColor = .clear
        followingButton.addAction(UIAction { [weak self] _ in self?.push(FollowingViewController()) }, for: .touchUpInside)
        stats.addSubview(followingButton)
        followingButton.snp.makeConstraints { $0.top.bottom.equalToSuperview(); $0.trailing.equalToSuperview(); $0.width.equalTo(stats.snp.width).multipliedBy(1.0 / 3.0) }

        let topDivider = UIView(); topDivider.backgroundColor = AppTheme.divider
        let bottomDivider = UIView(); bottomDivider.backgroundColor = AppTheme.divider
        container.addSubview(topDivider)
        container.addSubview(bottomDivider)
        topDivider.snp.makeConstraints { $0.top.equalTo(stats.snp.top).offset(-12); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(1) }
        bottomDivider.snp.makeConstraints { $0.bottom.equalTo(stats.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(1) }

        // Coin balance banner
        let coinBanner = CoinBalanceView(balance: DataRepository.shared.balance)
        coinBanner.addAction(UIAction { [weak self] _ in self?.push(RechargeViewController()) }, for: .touchUpInside)
        container.addSubview(coinBanner)
        coinBanner.snp.makeConstraints { $0.top.equalTo(bottomDivider.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(102) }

        // Segmented control
        let seg = UIView()
        container.addSubview(seg)
        seg.snp.makeConstraints { $0.top.equalTo(coinBanner.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(34) }

        let myWorksBtn = makeSegButton("My works", selected: selectedSection == 0)
        let collabBtn = makeSegButton("Collab history", selected: selectedSection == 1)
        sectionButtons = [myWorksBtn, collabBtn]
        [myWorksBtn, collabBtn].enumerated().forEach { index, button in
            button.addAction(UIAction { [weak self] _ in self?.selectSection(index) }, for: .touchUpInside)
        }
        let segStack = UIStackView(arrangedSubviews: [myWorksBtn, collabBtn])
        segStack.axis = .horizontal; segStack.spacing = 10; segStack.distribution = .fillEqually
        seg.addSubview(segStack)
        segStack.snp.makeConstraints { $0.edges.equalToSuperview() }

        return container
    }

    private func makeSegButton(_ title: String, selected: Bool) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 12, weight: selected ? .semibold : .regular)
        b.setTitleColor(selected ? .white : AppTheme.secondary, for: .normal)
        b.backgroundColor = selected ? AppTheme.ink : .white
        b.layer.cornerRadius = 12
        b.layer.masksToBounds = true
        b.layer.borderWidth = selected ? 0 : 1
        b.layer.borderColor = AppTheme.divider.cgColor
        return b
    }

    private func selectSection(_ index: Int) {
        selectedSection = index
        updateSectionButtons()
        reload()
    }

    private func updateSectionButtons() {
        sectionButtons.enumerated().forEach { idx, button in
            let selected = idx == selectedSection
            button.titleLabel?.font = .systemFont(ofSize: 12, weight: selected ? .semibold : .regular)
            button.setTitleColor(selected ? .white : AppTheme.secondary, for: .normal)
            button.backgroundColor = selected ? AppTheme.ink : .white
            button.layer.borderWidth = selected ? 0 : 1
        }
    }

    private func reload() {
        let uid = DataRepository.shared.currentUserID
        let works = DataRepository.shared.works
        switch selectedSection {
        case 1:
            myWorks = []
            collabHistory = DataRepository.shared.collaboratedCalls
        default:
            collabHistory = []
            myWorks = works.filter { $0.authorID == uid }
        }
        updateSectionButtons()
        tableView.tableHeaderView = makeProfileHeader()
        tableView.reloadData()
    }

    private func showModeration(for work: Work) {
        showModeration(for: work.authorID)
    }

    private func showModeration(for authorID: UUID) {
        let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in
            if item == "Report" {
                self?.push(ReportViewController(targetID: authorID))
            } else if item == "Block" {
                self?.blockUserAndReturnToRoot(authorID)
            }
        }
        sheet.present(in: view.window ?? view)
    }

    private func openWork(_ work: Work) {
        push(WorkDetailViewController(work: work))
    }

    private func formatCount(_ value: Int) -> String { value >= 1000 ? String(format: "%.1fk", Double(value) / 1000.0) : "\(value)" }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { selectedSection == 1 ? collabHistory.count : myWorks.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if selectedSection == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: CollabCallCell.reuseID, for: indexPath) as! CollabCallCell
            let call = collabHistory[indexPath.row]
            cell.configure(call: call)
            cell.onTap = { [weak self] in self?.push(CollabCallDetailViewController(call: call)) }
            cell.onMore = { [weak self] in self?.showModeration(for: call.authorID) }
            cell.onCollaborate = { [weak self] in
                DataRepository.shared.collaborate(on: call.id)
                self?.reload()
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkCardCell.reuseID, for: indexPath) as! WorkCardCell
        let work = myWorks[indexPath.row]
        cell.configure(work: work, showsFollow: false, showsCollaborate: false)
        cell.onLike = { DataRepository.shared.toggleLike(work.id) }
        cell.onMore = { [weak self] in self?.showModeration(for: work) }
        cell.onTap = { [weak self] in self?.openWork(work) }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { selectedSection == 1 ? 340 : 380 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if selectedSection == 0 { push(WorkDetailViewController(work: myWorks[indexPath.row])) }
    }
}

// MARK: - Coin balance banner

private final class CoinBalanceView: UIControl {
    init(balance: Int) {
        super.init(frame: .zero)
        setup(balance: balance)
    }
    required init?(coder: NSCoder) { nil }

    private func setup(balance: Int) {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = UIColor(hex: 0x2B2E6B)

        let bg = UIImageView(image: UIImage(named: "coin_bg"))
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        addSubview(bg)
        bg.snp.makeConstraints { $0.edges.equalToSuperview() }

        let coinIcon = UIImageView(image: UIImage(named: "coin"))
        coinIcon.contentMode = .scaleAspectFit
        addSubview(coinIcon)
        coinIcon.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview(); $0.size.equalTo(52) }

        let caption = UILabel()
        caption.text = "COIN BALANCE"
        caption.font = .systemFont(ofSize: 13, weight: .semibold)
        caption.textColor = UIColor.white.withAlphaComponent(0.8)
        addSubview(caption)
        caption.snp.makeConstraints { $0.leading.equalTo(coinIcon.snp.trailing).offset(14); $0.top.equalTo(coinIcon).offset(6) }

        let amount = UILabel()
        amount.text = "\(balance)"
        amount.font = .systemFont(ofSize: 28, weight: .bold)
        amount.textColor = .white
        addSubview(amount)
        amount.snp.makeConstraints { $0.leading.equalTo(caption); $0.bottom.equalTo(coinIcon).offset(-4) }
    }
}
