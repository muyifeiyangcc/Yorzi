import UIKit
import SnapKit

final class ExploreViewController: BaseViewController {
    private let tableView = UITableView()
    private let tabStack = UIStackView()
    private var worksMode = true
    private var selectedTab = 0
    private var searchTimer: Timer?
    private var searchText = ""
    private let searchField = UITextField()

    private var works: [Work] = []
    private var calls: [CollabCall] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHeader()
        setupSearch()
        setupCreators()
        setupTabs()
        setupContent()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabSelection()
    }

    // MARK: - Header

    private func setupHeader() {
        let logo = UILabel()
        logo.text = "Explore•"
        logo.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        logo.textColor = AppTheme.ink
        view.addSubview(logo)
        logo.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(10); $0.leading.equalToSuperview().offset(15) }
    }

    // MARK: - Search

    private func setupSearch() {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 12
        container.layer.masksToBounds = true
        container.layer.borderWidth = 1
        container.layer.borderColor = AppTheme.divider.cgColor

        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = AppTheme.secondary
        icon.contentMode = .scaleAspectFit
        container.addSubview(icon)
        icon.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(18) }

        searchField.placeholder = "Search works, creators, places..."
        searchField.font = .systemFont(ofSize: 14)
        searchField.textColor = AppTheme.ink
        searchField.clearButtonMode = .whileEditing
        searchField.returnKeyType = .search
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchFieldDidChange(_:)), for: .editingChanged)
        container.addSubview(searchField)
        searchField.snp.makeConstraints { $0.leading.equalTo(icon.snp.trailing).offset(10); $0.trailing.equalToSuperview().inset(12); $0.top.bottom.equalToSuperview().inset(11) }

        view.addSubview(container)
        container.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(50); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(44) }
    }

    // MARK: - Creator avatars

    private func setupCreators() {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(106); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(86) }

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 14
        scroll.addSubview(stack)
        stack.snp.makeConstraints {
            $0.edges.equalTo(scroll.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
            $0.height.equalTo(scroll.frameLayoutGuide)
        }

        let creators = DataRepository.shared.visibleUsers
        for creator in creators {
            let item = UIControl()
            item.accessibilityLabel = creator.name
            item.addAction(UIAction { [weak self] _ in
                self?.push(CreatorProfileViewController(userID: creator.id))
            }, for: .touchUpInside)
            let avatar = UIImageView()
            avatar.contentMode = .scaleAspectFill
            avatar.layer.cornerRadius = 28
            avatar.layer.masksToBounds = true
            avatar.backgroundColor = UIColor(hex: 0xE0E0E8)
            if let data = creator.avatarData { avatar.image = UIImage(data: data) }
            else { avatar.image = UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender }
            item.addSubview(avatar)
            avatar.snp.makeConstraints { $0.top.centerX.equalToSuperview(); $0.size.equalTo(56) }

            let name = UILabel()
            name.text = creator.name
            name.font = .systemFont(ofSize: 11, weight: .regular)
            name.textColor = AppTheme.secondary
            name.textAlignment = .center
            item.addSubview(name)
            name.snp.makeConstraints { $0.top.equalTo(avatar.snp.bottom).offset(6); $0.leading.trailing.bottom.equalToSuperview() }

            stack.addArrangedSubview(item)
            item.snp.makeConstraints { $0.width.equalTo(64) }
        }
    }

    // MARK: - Tabs

    private func setupTabs() {
        let works = makeTabButton("Works", index: 0)
        let collab = makeTabButton("Collab calls", index: 1)
        tabStack.axis = .horizontal
        tabStack.spacing = 20
        tabStack.addArrangedSubview(works)
        tabStack.addArrangedSubview(collab)
        view.addSubview(tabStack)
        tabStack.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(204); $0.leading.equalToSuperview().offset(15) }

        let tabDivider = UIView()
        tabDivider.backgroundColor = AppTheme.divider
        view.addSubview(tabDivider)
        tabDivider.snp.makeConstraints { $0.top.equalTo(tabStack.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }

        updateTabSelection()
    }

    private func makeTabButton(_ title: String, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.tag = index
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 6, right: 0)
        button.addAction(UIAction { [weak self] _ in self?.selectTab(index) }, for: .touchUpInside)
        return button
    }

    private func selectTab(_ index: Int) {
        selectedTab = index
        worksMode = index == 0
        updateTabSelection()
        reload()
    }

    private func updateTabSelection() {
        for (i, view) in tabStack.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton else { continue }
            let selected = i == selectedTab
            button.setTitleColor(selected ? AppTheme.ink : AppTheme.muted, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: selected ? .semibold : .regular)
            button.layer.sublayers?.filter { $0.name == "underline" }.forEach { $0.removeFromSuperlayer() }
            if selected {
                let underline = CALayer()
                underline.name = "underline"
                underline.backgroundColor = AppTheme.ink.cgColor
                underline.frame = CGRect(x: 0, y: button.bounds.height - 2, width: button.bounds.width, height: 2)
                button.layer.addSublayer(underline)
            }
        }
    }

    // MARK: - Content

    private func setupContent() {
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(WorkCardCell.self, forCellReuseIdentifier: WorkCardCell.reuseID)
        tableView.register(CollabCallCell.self, forCellReuseIdentifier: CollabCallCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(240); $0.leading.trailing.bottom.equalToSuperview() }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        reload()
    }

    private func reload() {
        if worksMode {
            var list = DataRepository.shared.visibleWorks
            list = list.filter { matchesSearch(searchText, values: searchValues(for: $0)) }
            works = list
        } else {
            var list = DataRepository.shared.calls.filter { !DataRepository.shared.blockedIDs.contains($0.authorID) }
            list = list.filter { matchesSearch(searchText, values: searchValues(for: $0)) }
            calls = list
        }
        updateHeader()
        tableView.reloadData()
    }

    private func searchValues(for work: Work) -> [String] {
        let author = DataRepository.shared.user(work.authorID)
        return [work.title, work.category, work.location, work.description, author?.name ?? "", author?.role ?? ""]
    }

    private func searchValues(for call: CollabCall) -> [String] {
        let author = DataRepository.shared.user(call.authorID)
        return [call.title, call.location, call.roles, call.budget, call.timing ?? "", call.date ?? "", call.deadline ?? "", call.description ?? "", author?.name ?? "", author?.role ?? ""]
    }

    private func matchesSearch(_ query: String, values: [String]) -> Bool {
        let terms = query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
        guard !terms.isEmpty else { return true }
        return terms.allSatisfy { term in
            values.contains { $0.localizedCaseInsensitiveContains(term) }
        }
    }

    private func updateHeader() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 64))
        let label = UILabel()
        label.text = worksMode ? "Works for you" : "Open collab calls"
        label.font = UIFont(name: "Georgia-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        label.textColor = AppTheme.ink
        container.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }
        tableView.tableHeaderView = container
    }

    private func showModeration(for work: Work) {
        showModeration(for: work.authorID)
    }

    private func showModeration(for authorID: UUID) {
        let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in
            if item == "Report" { self?.push(ReportViewController(targetID: authorID)) }
            else if item == "Block" { DataRepository.shared.block(authorID) }
        }
        sheet.present(in: view.window ?? view)
    }
}

// MARK: - Search

extension ExploreViewController: UITextFieldDelegate {
    @objc private func searchFieldDidChange(_ textField: UITextField) {
        searchText = textField.text ?? ""
        scheduleSearch()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let current = (textField.text as NSString?) ?? ""
        searchText = current.replacingCharacters(in: range, with: string)
        scheduleSearch()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    private func scheduleSearch() {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in self?.reload() }
    }
}

// MARK: - Table

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        worksMode ? works.count : calls.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if worksMode {
            let cell = tableView.dequeueReusableCell(withIdentifier: WorkCardCell.reuseID, for: indexPath) as! WorkCardCell
            cell.configure(work: works[indexPath.row])
            let work = works[indexPath.row]
            cell.onLike = { DataRepository.shared.toggleLike(work.id) }
            cell.onMore = { [weak self] in self?.showModeration(for: work) }
            cell.onTap = { [weak self] in self?.push(WorkDetailViewController(work: work)) }
            cell.onFollow = { DataRepository.shared.toggleFollow(work.authorID) }
            cell.onCollaborate = { [weak self] in self?.push(WorkDetailViewController(work: work)) }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: CollabCallCell.reuseID, for: indexPath) as! CollabCallCell
            let call = calls[indexPath.row]
            cell.configure(call: call)
            cell.onTap = { [weak self] in self?.push(CollabCallDetailViewController(call: call)) }
            cell.onMore = { [weak self] in self?.showModeration(for: call.authorID) }
            cell.onCollaborate = { [weak self] in
                DataRepository.shared.collaborate(on: call.id)
                self?.reload()
            }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        worksMode ? 400 : 340
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if worksMode { push(WorkDetailViewController(work: works[indexPath.row])) }
    }
}
