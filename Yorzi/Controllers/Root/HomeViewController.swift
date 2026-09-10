import UIKit
import SnapKit

final class HomeViewController: BaseViewController {
    private let tableView = UITableView()
    private let filterScroll = UIScrollView()
    private let filterStack = UIStackView()
    private let tabStack = UIStackView()
    private var selectedTab = 0
    private var selectedFilter = 0
    private var observer: NSObjectProtocol?
    private var works: [Work] = []

    private let categories = ["All", "Portraits", "Outdoor Stories", "Motion"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupHeader()
        setupFilters()
        setupContent()
        observer = NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabSelection()
    }

    // MARK: - Header

    private func setupHeader() {
        // YORZI. logo - left aligned, Georgia bold
        let logo = UILabel()
        logo.text = "YORZI•"
        logo.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        logo.textColor = AppTheme.ink
        view.addSubview(logo)
        logo.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(10); $0.leading.equalToSuperview().offset(15) }

        // For You / Following tabs
        let forYou = makeTabButton("For You", index: 0)
        let following = makeTabButton("Following", index: 1)
        tabStack.axis = .horizontal
        tabStack.spacing = 20
        tabStack.addArrangedSubview(forYou)
        tabStack.addArrangedSubview(following)
        view.addSubview(tabStack)
        tabStack.snp.makeConstraints { $0.top.equalTo(logo.snp.bottom).offset(14); $0.leading.equalToSuperview().offset(15) }

        // Divider line under tabs
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

    // MARK: - Filters

    private func setupFilters() {
        filterScroll.showsHorizontalScrollIndicator = false
        view.addSubview(filterScroll)
        filterScroll.snp.makeConstraints { $0.top.equalTo(tabStack.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(36) }

        filterStack.axis = .horizontal
        filterStack.spacing = 8
        filterScroll.addSubview(filterStack)
        filterStack.snp.makeConstraints {
            $0.edges.equalTo(filterScroll.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15))
            $0.height.equalTo(filterScroll.frameLayoutGuide)
        }

        categories.enumerated().forEach { index, name in
            let button = UIButton(type: .system)
            button.setTitle(name, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            button.layer.cornerRadius = 18
            button.layer.masksToBounds = true
            button.layer.borderWidth = 1
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.tag = index
            button.addAction(UIAction { [weak self] _ in self?.selectFilter(index) }, for: .touchUpInside)
            filterStack.addArrangedSubview(button)
        }
        updateFilterSelection()
    }

    private func selectFilter(_ index: Int) {
        selectedFilter = index
        updateFilterSelection()
        reload()
    }

    private func updateFilterSelection() {
        for (i, view) in filterStack.arrangedSubviews.enumerated() {
            guard let button = view as? UIButton else { continue }
            let selected = i == selectedFilter
            if selected {
                button.backgroundColor = AppTheme.ink
                button.setTitleColor(.white, for: .normal)
                button.layer.borderColor = AppTheme.ink.cgColor
            } else {
                button.backgroundColor = .white
                button.setTitleColor(AppTheme.secondary, for: .normal)
                button.layer.borderColor = AppTheme.divider.cgColor
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
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(filterScroll.snp.bottom).offset(12); $0.leading.trailing.bottom.equalToSuperview() }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 400
        reload()
    }

    private func reload() {
        var list = DataRepository.shared.visibleWorks
        if selectedTab == 1 { list = list.filter { DataRepository.shared.isFollowing($0.authorID) } }
        let filter = categories[selectedFilter]
        if filter != "All" { list = list.filter { $0.category == filter } }
        works = list
        tableView.reloadData()
    }

    // MARK: - Actions

    private func showModeration(for work: Work) {
        let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in
            if item == "Report" { self?.push(ReportViewController(targetID: work.authorID)) }
            else if item.hasPrefix("Block") { self?.blockUserAndReturnToRoot(work.authorID) }
        }
        sheet.present(in: view.window ?? view)
    }

    private func guestGate() {
        let dialog = AppDialogView(title: "Sign In Required", message: "Please sign in to continue.", actions: [
            .init(title: "Cancel", style: .plain, handler: nil),
            .init(title: "Sign In", style: .accent) { AppRouter.showWelcome() }
        ])
        dialog.present(in: view)
    }
}

// MARK: - Table

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { works.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WorkCardCell.reuseID, for: indexPath) as! WorkCardCell
        let work = works[indexPath.row]
        cell.configure(work: work)
        cell.onLike = { DataRepository.shared.toggleLike(work.id) }
        cell.onMore = { [weak self] in self?.showModeration(for: work) }
        cell.onTap = { [weak self] in self?.tableView(tableView, didSelectRowAt: indexPath) }
        cell.onFollow = { DataRepository.shared.toggleFollow(work.authorID) }
        cell.onCollaborate = { [weak self] in self?.push(WorkDetailViewController(work: work)) }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard !DataRepository.shared.isGuest else { guestGate(); return }
        push(WorkDetailViewController(work: works[indexPath.row]))
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
}
