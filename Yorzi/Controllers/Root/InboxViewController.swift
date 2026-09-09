import UIKit
import SnapKit

final class InboxViewController: BaseViewController {
    private let tableView = UITableView()
    private var conversations: [Conversation] = []

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
        let title = UILabel()
        title.text = "Inbox•"
        title.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(10); $0.leading.equalToSuperview().offset(15) }
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(52); $0.leading.trailing.bottom.equalToSuperview() }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 80, right: 0)

        // AI banner as table header
        let banner = AIBannerView()
        banner.onTap = { [weak self] in self?.push(AIChatViewController()) }
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 150))
        headerContainer.addSubview(banner)
        banner.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 15, bottom: 8, right: 15)) }
        tableView.tableHeaderView = headerContainer
    }

    private func reload() {
        conversations = DataRepository.shared.visibleConversations
        tableView.reloadData()
    }
}

extension InboxViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { conversations.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseID, for: indexPath) as! ConversationCell
        cell.configure(conversation: conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        push(ChatViewController(participantID: conversations[indexPath.row].participantID))
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 76 }
}

// MARK: - AI Banner

private final class AIBannerView: UIControl {
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { nil }

    private func setup() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        backgroundColor = AppTheme.ink

        // Background image
        let bg = UIImageView(image: UIImage(named: "ai_bg"))
        bg.contentMode = .scaleAspectFill
        bg.clipsToBounds = true
        addSubview(bg)
        bg.snp.makeConstraints { $0.edges.equalToSuperview() }

        let overlay = UIView()
        overlay.backgroundColor = UIColor(hex: 0x1E2A38).withAlphaComponent(0.55)
        addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        // AI title
        let titleLabel = UILabel()
        titleLabel.text = "AI Yorzi"
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 26) ?? .systemFont(ofSize: 26, weight: .bold)
        titleLabel.textColor = .white
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.top.equalToSuperview().offset(18); $0.leading.equalToSuperview().offset(18) }

        // Subtitle
        let subtitle = UILabel()
        subtitle.text = "Ask for visual direction, collaboration ideas, or a refined project brief."
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = UIColor.white.withAlphaComponent(0.85)
        subtitle.numberOfLines = 2
        addSubview(subtitle)
        subtitle.snp.makeConstraints { $0.top.equalTo(titleLabel.snp.bottom).offset(6); $0.leading.equalToSuperview().offset(18); $0.width.equalTo(200) }

        // Open Chat button
        let button = UIView()
        button.backgroundColor = AppTheme.lavender
        button.layer.cornerRadius = 18
        button.layer.masksToBounds = true
        addSubview(button)
        button.snp.makeConstraints { $0.leading.equalToSuperview().offset(18); $0.bottom.equalToSuperview().inset(16); $0.height.equalTo(36) }

        let btnLabel = UILabel()
        btnLabel.text = "Open Chat"
        btnLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        btnLabel.textColor = .white
        button.addSubview(btnLabel)
        btnLabel.snp.makeConstraints { $0.leading.equalToSuperview().offset(16); $0.centerY.equalToSuperview() }

        let arrow = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrow.tintColor = .white
        arrow.contentMode = .scaleAspectFit
        button.addSubview(arrow)
        arrow.snp.makeConstraints { $0.leading.equalTo(btnLabel.snp.trailing).offset(8); $0.trailing.equalToSuperview().inset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }

        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    @objc private func tapped() { onTap?() }
}

// MARK: - Conversation cell

private final class ConversationCell: UITableViewCell {
    static let reuseID = "ConversationCell"
    private let avatarView = UIImageView()
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()
    private let separator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 28
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = UIColor(hex: 0xE0E0E8)
        contentView.addSubview(avatarView)
        avatarView.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(56) }

        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = AppTheme.ink
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { $0.leading.equalTo(avatarView.snp.trailing).offset(12); $0.top.equalTo(avatarView).offset(4) }

        previewLabel.font = .systemFont(ofSize: 14, weight: .regular)
        previewLabel.textColor = AppTheme.secondary
        contentView.addSubview(previewLabel)
        previewLabel.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.top.equalTo(nameLabel.snp.bottom).offset(4); $0.trailing.lessThanOrEqualToSuperview().inset(70) }

        timeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        timeLabel.textColor = AppTheme.muted
        timeLabel.textAlignment = .right
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { $0.trailing.equalToSuperview().inset(15); $0.top.equalTo(nameLabel); $0.width.equalTo(80) }

        separator.backgroundColor = AppTheme.divider
        contentView.addSubview(separator)
        separator.snp.makeConstraints { $0.leading.equalTo(nameLabel); $0.trailing.equalToSuperview().inset(15); $0.bottom.equalToSuperview(); $0.height.equalTo(1) }
    }
    required init?(coder: NSCoder) { nil }

    func configure(conversation: Conversation) {
        let user = DataRepository.shared.user(conversation.participantID)
        nameLabel.text = user?.name ?? "Creator"
        if let data = user?.avatarData { avatarView.image = UIImage(data: data) }
        else { avatarView.image = UIImage(systemName: "person.crop.circle.fill"); avatarView.tintColor = AppTheme.lavender }

        let last = conversation.messages.last
        switch last?.kind {
        case .image: previewLabel.text = "Photo"
        case .voice: previewLabel.text = "Voice message"
        default: previewLabel.text = last?.text ?? ""
        }
        timeLabel.text = conversationTime(conversation.messages.last)
    }

    private func conversationTime(_ message: ChatMessage?) -> String {
        guard let date = message?.createdAt else { return "" }
        let formatter = DateFormatter(); formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "MMM d"
        return formatter.string(from: date)
    }
}
