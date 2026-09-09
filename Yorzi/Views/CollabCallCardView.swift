import UIKit
import SnapKit

final class CollabCallCardView: UIView {
    let call: CollabCall
    let moreButton = UIButton(type: .system)
    var onTap: (() -> Void)?
    var onCollaborate: (() -> Void)?
    var onMore: (() -> Void)?

    init(call: CollabCall) {
        self.call = call
        super.init(frame: .zero)
        setupUI()
    }
    required init?(coder: NSCoder) { nil }

    private func setupUI() {
        isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tap.delegate = self
        addGestureRecognizer(tap)
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.masksToBounds = true

        // Background image
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor(hex: 0xE8E8F0)
        let mediaData = call.mediaData ?? call.mediaDatas?.first
        imageView.image = mediaData.flatMap(UIImage.init(data:)) ?? UIImage(systemName: "photo")
        imageView.tintColor = AppTheme.lavender
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(240) }

        moreButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        moreButton.layer.cornerRadius = 16
        moreButton.layer.masksToBounds = true
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = AppTheme.ink
        moreButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        moreButton.isHidden = call.authorID == DataRepository.shared.currentUserID
        moreButton.addAction(UIAction { [weak self] _ in self?.onMore?() }, for: .touchUpInside)
        imageView.addSubview(moreButton)
        moreButton.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.trailing.equalToSuperview().inset(12); $0.size.equalTo(32) }

        // Dark overlay
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        imageView.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }

        if call.videoData != nil {
            let play = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
            play.tintColor = AppTheme.ink
            play.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            play.contentMode = .center
            play.layer.cornerRadius = 26
            play.layer.masksToBounds = true
            play.isUserInteractionEnabled = false
            imageView.addSubview(play)
            play.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(52) }
        }

        // Title on image
        let titleLabel = UILabel()
        titleLabel.text = call.title
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        imageView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(14); $0.bottom.equalTo(imageView.snp.bottom).offset(-48) }

        // Tag pills
        let tagStack = UIStackView()
        tagStack.axis = .horizontal
        tagStack.spacing = 8
        imageView.addSubview(tagStack)
        tagStack.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.bottom.equalToSuperview().inset(14) }

        tagStack.addArrangedSubview(makeTagPill(call.location))
        let schedule = [call.timing, call.date].compactMap { $0 }.first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        if let schedule { tagStack.addArrangedSubview(makeTagPill(schedule)) }
        let roleInfo = [call.budget, call.roles].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.joined(separator: " · ")
        if !roleInfo.isEmpty { tagStack.addArrangedSubview(makeTagPill(roleInfo)) }
        imageView.bringSubviewToFront(moreButton)

        // Bottom bar
        let bottomBar = UIView()
        addSubview(bottomBar)
        bottomBar.snp.makeConstraints { $0.top.equalTo(imageView.snp.bottom); $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(56) }

        let hostAvatar = UIImageView()
        hostAvatar.contentMode = .scaleAspectFill
        hostAvatar.layer.cornerRadius = 16
        hostAvatar.layer.masksToBounds = true
        hostAvatar.backgroundColor = UIColor(hex: 0xE0E0E8)
        let host = DataRepository.shared.user(call.authorID)
        if let data = host?.avatarData { hostAvatar.image = UIImage(data: data) }
        else { hostAvatar.image = UIImage(systemName: "person.crop.circle.fill"); hostAvatar.tintColor = AppTheme.lavender }
        bottomBar.addSubview(hostAvatar)
        hostAvatar.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(32) }

        let hostedBy = UILabel()
        hostedBy.text = "Hosted By"
        hostedBy.font = .systemFont(ofSize: 11, weight: .regular)
        hostedBy.textColor = AppTheme.muted
        bottomBar.addSubview(hostedBy)
        hostedBy.snp.makeConstraints { $0.leading.equalTo(hostAvatar.snp.trailing).offset(8); $0.top.equalTo(hostAvatar.snp.top).offset(2) }

        let hostName = UILabel()
        hostName.text = host?.name ?? "Creator"
        hostName.font = .systemFont(ofSize: 14, weight: .semibold)
        hostName.textColor = AppTheme.ink
        bottomBar.addSubview(hostName)
        hostName.snp.makeConstraints { $0.leading.equalTo(hostAvatar.snp.trailing).offset(8); $0.bottom.equalTo(hostAvatar.snp.bottom).offset(-2) }

        // Collaborate
        let collaborated = DataRepository.shared.hasCollaborated(on: call.id)
        let collaborate = UIButton(type: .system)
        collaborate.setTitle(collaborated ? "Collaborated" : "Collaborate", for: .normal)
        collaborate.setTitleColor(AppTheme.ink, for: .normal)
        collaborate.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        collaborate.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: collaborated ? 10 : 4)
        collaborate.isEnabled = !collaborated
        collaborate.addAction(UIAction { [weak self] _ in self?.onCollaborate?() }, for: .touchUpInside)
        bottomBar.addSubview(collaborate)
        if collaborated {
            collaborate.snp.makeConstraints { $0.trailing.equalToSuperview().inset(14); $0.centerY.equalToSuperview() }
        } else {
            let arrow = UIImageView(image: UIImage(systemName: "arrow.right"))
            arrow.tintColor = AppTheme.ink
            arrow.contentMode = .scaleAspectFit
            bottomBar.addSubview(arrow)
            collaborate.snp.makeConstraints { $0.trailing.equalTo(arrow.snp.leading).offset(-4); $0.centerY.equalToSuperview() }
            arrow.snp.makeConstraints { $0.centerY.equalToSuperview(); $0.size.equalTo(14); $0.trailing.equalToSuperview().inset(14) }
        }
    }

    @objc private func handleTap() { onTap?() }

    private func makeTagPill(_ text: String) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        pill.layer.cornerRadius = 12
        pill.layer.masksToBounds = true
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = AppTheme.ink
        pill.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 6, left: 10, bottom: 6, right: 10)) }
        return pill
    }
}

extension CollabCallCardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }
}

final class CollabCallCell: UITableViewCell {
    static let reuseID = "CollabCallCell"
    var onTap: (() -> Void)?
    var onCollaborate: (() -> Void)?
    var onMore: (() -> Void)?

    private var cardView: CollabCallCardView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    func configure(call: CollabCall) {
        cardView?.removeFromSuperview()
        let card = CollabCallCardView(call: call)
        card.onTap = { [weak self] in self?.onTap?() }
        card.onCollaborate = { [weak self] in self?.onCollaborate?() }
        card.onMore = { [weak self] in self?.onMore?() }
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)) }
        cardView = card
    }
}
