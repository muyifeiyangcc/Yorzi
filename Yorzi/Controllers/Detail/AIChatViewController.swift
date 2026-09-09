import UIKit
import SnapKit

final class AIChatViewController: BaseViewController {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let amountLabel = UILabel()

    struct AIMessage {
        let id = UUID()
        let isAI: Bool
        let text: String
        let time: String
    }

    private var messages: [AIMessage] = [
        .init(isAI: true, text: "Hi Clara, I’m here to help shape your visual direction, collaboration ideas, or project brief.", time: "09:32")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNav(); setupTable(); setupInputBar()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.amountLabel.text = "\(DataRepository.shared.balance)" }
    }

    private func setupNav() {
        let navBar = UIView(); navBar.backgroundColor = .white; view.addSubview(navBar); navBar.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(56) }
        let back = UIButton(type: .system); back.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "chevron.left"), for: .normal); back.backgroundColor = .white; back.layer.borderWidth = 1; back.layer.borderColor = AppTheme.divider.cgColor; back.layer.cornerRadius = 20; back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside); navBar.addSubview(back); back.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(40) }
        let title = UILabel(); title.text = "Yorzi AI"; title.font = UIFont(name: "Georgia", size: 24) ?? .systemFont(ofSize: 24); title.textColor = AppTheme.ink; navBar.addSubview(title); title.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(8); $0.centerY.equalToSuperview() }
        let credits = UIView(); credits.backgroundColor = .white; credits.layer.borderWidth = 1; credits.layer.borderColor = AppTheme.divider.cgColor; credits.layer.cornerRadius = 18; navBar.addSubview(credits); credits.snp.makeConstraints { $0.trailing.equalToSuperview().inset(15); $0.centerY.equalToSuperview(); $0.width.equalTo(92); $0.height.equalTo(36) }
        let coin = UIImageView(image: UIImage(named: "coin")); coin.contentMode = .scaleAspectFit; credits.addSubview(coin); coin.snp.makeConstraints { $0.leading.equalToSuperview().offset(13); $0.centerY.equalToSuperview(); $0.size.equalTo(23) }; amountLabel.text = "\(DataRepository.shared.balance)"; amountLabel.font = .systemFont(ofSize: 14, weight: .semibold); amountLabel.textColor = AppTheme.ink; credits.addSubview(amountLabel); amountLabel.snp.makeConstraints { $0.leading.equalTo(coin.snp.trailing).offset(4); $0.centerY.equalToSuperview() }
    }

    private func setupTable() {
        tableView.separatorStyle = .none; tableView.backgroundColor = .white; tableView.showsVerticalScrollIndicator = false; tableView.dataSource = self; tableView.delegate = self; tableView.rowHeight = UITableView.automaticDimension; tableView.estimatedRowHeight = 72; tableView.register(AICell.self, forCellReuseIdentifier: AICell.reuseID); view.addSubview(tableView); tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(56); $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(inputBar.snp.top) }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 121)); header.backgroundColor = .clear; let banner = UIImageView(image: UIImage(named: "ai_content_bg")); banner.contentMode = .scaleAspectFill; banner.clipsToBounds = true; banner.layer.cornerRadius = 10; header.addSubview(banner); banner.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 15, bottom: 0, right: 15)) }; let bannerTitle = UILabel.appLabel("Shape your next\nstory", size: 17, color: .white); bannerTitle.font = UIFont(name: "Georgia", size: 17); banner.addSubview(bannerTitle); bannerTitle.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.top.equalToSuperview().offset(27) }; let bannerSub = UILabel.appLabel("Ask for visual direction, collaboration\nideas, or a refined project brief.", size: 9, color: UIColor.white.withAlphaComponent(0.85)); banner.addSubview(bannerSub); bannerSub.snp.makeConstraints { $0.leading.equalTo(bannerTitle); $0.top.equalTo(bannerTitle.snp.bottom).offset(8) }; tableView.tableHeaderView = header
    }

    private func setupInputBar() {
        inputBar.backgroundColor = .white; view.addSubview(inputBar); inputBar.snp.makeConstraints { $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide); $0.height.equalTo(64) }; let line = UIView(); line.backgroundColor = AppTheme.divider; inputBar.addSubview(line); line.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }
        textField.placeholder = "Write a message..."; textField.font = .systemFont(ofSize: 12); textField.layer.borderWidth = 1; textField.layer.borderColor = AppTheme.divider.cgColor; textField.layer.cornerRadius = 19; textField.setLeftPadding(13); textField.returnKeyType = .send; textField.delegate = self; inputBar.addSubview(textField); textField.snp.makeConstraints { $0.leading.equalToSuperview().offset(11); $0.centerY.equalToSuperview(); $0.height.equalTo(38); $0.trailing.equalTo(sendButton.snp.leading).offset(-8) }
        sendButton.setImage(UIImage(systemName: "paperplane"), for: .normal); sendButton.tintColor = .white; sendButton.backgroundColor = AppTheme.ink; sendButton.layer.cornerRadius = 19; sendButton.addAction(UIAction { [weak self] _ in self?.send() }, for: .touchUpInside); inputBar.addSubview(sendButton); sendButton.snp.makeConstraints { $0.trailing.equalToSuperview().inset(11); $0.centerY.equalToSuperview(); $0.size.equalTo(38) }
    }

    private func send() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }
        messages.append(.init(isAI: false, text: text, time: "09:34")); textField.text = ""; tableView.reloadData(); tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in guard let self else { return }; self.messages.append(.init(isAI: true, text: AIReplyLibrary.reply(to: text), time: "09:32")); self.tableView.reloadData(); self.tableView.scrollToRow(at: IndexPath(row: self.messages.count - 1, section: 0), at: .bottom, animated: true) }
    }
}

private enum AIReplyLibrary {
    private struct Entry { let terms: [String]; let response: String }
    private static let entries: [Entry] = [
        .init(terms: ["collab", "collaboration", "partner"], response: "A clear collaboration brief should name the concept, mood, deliverables, timeline, and the roles you need. I can help turn those details into a concise call."),
        .init(terms: ["color", "grading", "palette"], response: "For a cohesive color direction, choose one dominant temperature and keep skin tones natural. Warm film tones feel intimate; cool neutrals feel editorial."),
        .init(terms: ["portrait", "portraits", "model"], response: "For portraits, start with the subject’s expression and the quality of light. A simple location, one strong wardrobe idea, and a short shot list usually create the most focused set."),
        .init(terms: ["retouch", "retouching", "edit", "editing"], response: "A refined retouching brief works best when it separates essentials from preferences: skin cleanup, color balance, texture, and the references that define the final mood."),
        .init(terms: ["mood", "moodboard", "reference"], response: "A useful mood board combines a few visual references with short notes about light, framing, texture, and emotion. Keep the references consistent enough to guide decisions."),
        .init(terms: ["location", "place", "city"], response: "Choose a location that supports the story and the available light. Consider access, background texture, weather, and how much movement the space allows."),
        .init(terms: ["date", "dates", "timeline", "schedule"], response: "Set a realistic timeline with time for preparation, the shoot, selects, and final delivery. Sharing the key dates early makes collaboration much smoother."),
        .init(terms: ["brief", "project", "idea"], response: "A strong project brief can be kept simple: intention, audience, visual language, references, practical details, and the decision you need from each collaborator."),
        .init(terms: ["feedback", "review", "opinion"], response: "When giving creative feedback, point to the intended feeling first, then describe the specific change in framing, light, color, or pacing that would support it.")
    ]
    static func reply(to text: String) -> String {
        let words = Set(text.lowercased().split { !$0.isLetter }.map(String.init)); var best: (score: Int, response: String)?
        for entry in entries { let score = entry.terms.reduce(0) { $0 + (words.contains($1) ? 1 : 0) }; if score > (best?.score ?? 0) { best = (score, entry.response) } }
        return best?.response ?? "I can help shape the direction, structure, or practical details. Share the goal, the visual feeling, and what is still undecided, and I’ll suggest a focused next step."
    }
}

extension AIChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { send(); return true }
}

extension AIChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { let cell = tableView.dequeueReusableCell(withIdentifier: AICell.reuseID, for: indexPath) as! AICell; cell.configure(message: messages[indexPath.row]); return cell }
}

private final class AICell: UITableViewCell {
    static let reuseID = "AICell"; private let bubble = UIView(); private let label = UILabel(); private let timeLabel = UILabel()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) { super.init(style: style, reuseIdentifier: reuseIdentifier); selectionStyle = .none; backgroundColor = .white; contentView.backgroundColor = .white; bubble.layer.cornerRadius = 16; bubble.layer.masksToBounds = true; contentView.addSubview(bubble); bubble.addSubview(label); timeLabel.font = .systemFont(ofSize: 9); timeLabel.textColor = AppTheme.muted; contentView.addSubview(timeLabel); label.font = .systemFont(ofSize: 12); label.numberOfLines = 0; label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)) }; bubble.snp.makeConstraints { $0.top.equalToSuperview().offset(8); $0.bottom.equalTo(timeLabel.snp.top).offset(-3); $0.width.lessThanOrEqualTo(280) }; timeLabel.snp.makeConstraints { $0.bottom.equalToSuperview().inset(2) } }
    required init?(coder: NSCoder) { nil }
    func configure(message: AIChatViewController.AIMessage) { label.text = message.text; timeLabel.text = message.time; label.textColor = message.isAI ? AppTheme.ink : .white; bubble.backgroundColor = message.isAI ? .white : AppTheme.ink; bubble.layer.borderWidth = message.isAI ? 1 : 0; bubble.layer.borderColor = AppTheme.divider.cgColor; bubble.snp.remakeConstraints { $0.top.equalToSuperview().offset(8); $0.bottom.equalTo(timeLabel.snp.top).offset(-3); $0.width.lessThanOrEqualTo(280); if message.isAI { $0.leading.equalToSuperview().offset(15) } else { $0.trailing.equalToSuperview().inset(15) } }; timeLabel.snp.remakeConstraints { $0.bottom.equalToSuperview().inset(2); if message.isAI { $0.leading.equalTo(bubble) } else { $0.trailing.equalTo(bubble) } } }
}
