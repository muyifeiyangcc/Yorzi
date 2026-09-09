import UIKit
import SnapKit

final class WorkCardView: UIControl {
    let work: Work
    let likeButton = UIButton(type: .system)
    let moreButton = UIButton(type: .system)
    var onTap: (() -> Void)?
    var onFollow: (() -> Void)?
    var onCollaborate: (() -> Void)?
    private let showsFollow: Bool
    private let showsCollaborate: Bool

    private let cardView = UIView()
    private let imageView = UIImageView()
    private let playIndicator = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
    private let tagPill = UIView()
    private let tagLabel = UILabel()
    private let greenDot = UIView()
    private let titleLabel = UILabel()
    private let avatarView = UIImageView()
    private let authorLabel = UILabel()
    private let metaLabel = UILabel()
    private let collabScroll = UIScrollView()
    private let collabStack = UIStackView()
    private let divider = UIView()
    private let bottomBar = UIView()
    private let viewsIcon = UIImageView()
    private let viewsLabel = UILabel()
    private let collaborateLabel = UIButton(type: .system)
    private let arrowIcon = UIImageView()
    private let followIcon = UIImageView()

    init(work: Work, showsFollow: Bool = true, showsCollaborate: Bool = true) {
        self.work = work
        self.showsFollow = showsFollow
        self.showsCollaborate = showsCollaborate
        super.init(frame: .zero)
        setupUI()
        configure()
    }
    required init?(coder: NSCoder) { nil }

    private func setupUI() {
        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 16
        cardView.layer.masksToBounds = true
        addSubview(cardView)
        cardView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let cardTap = UITapGestureRecognizer(target: self, action: #selector(cardTapped))
        cardTap.delegate = self
        cardView.addGestureRecognizer(cardTap)

        // Image
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = UIColor(hex: 0xE8E8F0)
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        cardView.addSubview(imageView)
        imageView.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(220) }

        playIndicator.tintColor = AppTheme.ink
        playIndicator.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        playIndicator.contentMode = .center
        playIndicator.layer.cornerRadius = 26
        playIndicator.layer.masksToBounds = true
        playIndicator.isUserInteractionEnabled = false
        playIndicator.isHidden = true
        imageView.addSubview(playIndicator)
        playIndicator.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(52) }

        // Category tag pill
        tagPill.backgroundColor = UIColor.white.withAlphaComponent(0.92)
        tagPill.layer.cornerRadius = 14
        tagPill.layer.masksToBounds = true
        imageView.addSubview(tagPill)
        tagPill.snp.makeConstraints { $0.top.leading.equalToSuperview().offset(12); $0.height.equalTo(28) }

        greenDot.backgroundColor = UIColor(hex: 0xC4A26A)
        greenDot.layer.cornerRadius = 3
        greenDot.layer.masksToBounds = true
        tagPill.addSubview(greenDot)
        greenDot.snp.makeConstraints { $0.leading.equalToSuperview().offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(6) }

        tagLabel.font = .systemFont(ofSize: 12, weight: .medium)
        tagLabel.textColor = AppTheme.ink
        tagPill.addSubview(tagLabel)
        tagLabel.snp.makeConstraints { $0.leading.equalTo(greenDot.snp.trailing).offset(5); $0.trailing.equalToSuperview().inset(12); $0.centerY.equalToSuperview() }

        // Like button
        likeButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        likeButton.layer.cornerRadius = 16
        likeButton.layer.masksToBounds = true
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.tintColor = AppTheme.ink
        likeButton.imageView?.contentMode = .scaleAspectFit
        likeButton.imageEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        likeButton.isUserInteractionEnabled = true
        imageView.addSubview(likeButton)
        likeButton.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.trailing.equalToSuperview().inset(12); $0.size.equalTo(32) }

        // More button
        moreButton.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        moreButton.layer.cornerRadius = 16
        moreButton.layer.masksToBounds = true
        moreButton.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        moreButton.tintColor = AppTheme.ink
        moreButton.imageView?.contentMode = .scaleAspectFit
        moreButton.imageEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        moreButton.isUserInteractionEnabled = true
        imageView.addSubview(moreButton)
        moreButton.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.trailing.equalTo(likeButton.snp.leading).offset(-8); $0.size.equalTo(32) }
        imageView.bringSubviewToFront(likeButton)
        imageView.bringSubviewToFront(moreButton)

        // Title
        titleLabel.font = UIFont(name: "Georgia-Bold", size: 22) ?? .systemFont(ofSize: 22, weight: .bold)
        titleLabel.textColor = AppTheme.ink
        cardView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.top.equalTo(imageView.snp.bottom).offset(14); $0.leading.trailing.equalToSuperview().inset(14) }

        // Author row
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 14
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = UIColor(hex: 0xE0E0E8)
        cardView.addSubview(avatarView)
        avatarView.snp.makeConstraints { $0.top.equalTo(titleLabel.snp.bottom).offset(10); $0.leading.equalToSuperview().offset(14); $0.size.equalTo(28) }

        authorLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        authorLabel.textColor = AppTheme.ink
        cardView.addSubview(authorLabel)
        authorLabel.snp.makeConstraints { $0.centerY.equalTo(avatarView); $0.leading.equalTo(avatarView.snp.trailing).offset(8) }

        // Meta
        metaLabel.font = .systemFont(ofSize: 12, weight: .regular)
        metaLabel.textColor = AppTheme.secondary
        cardView.addSubview(metaLabel)
        metaLabel.snp.makeConstraints { $0.top.equalTo(avatarView.snp.bottom).offset(6); $0.leading.equalToSuperview().offset(14) }

        // Collaborator pills
        collabScroll.showsHorizontalScrollIndicator = false
        cardView.addSubview(collabScroll)
        collabScroll.snp.makeConstraints { $0.top.equalTo(metaLabel.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(14); $0.height.equalTo(28) }
        collabStack.axis = .horizontal
        collabStack.spacing = 8
        collabScroll.addSubview(collabStack)
        collabStack.snp.makeConstraints { $0.edges.equalTo(collabScroll.contentLayoutGuide); $0.height.equalTo(collabScroll.frameLayoutGuide) }

        // Divider
        divider.backgroundColor = AppTheme.divider
        cardView.addSubview(divider)
        divider.snp.makeConstraints { $0.top.equalTo(collabScroll.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(14); $0.height.equalTo(1) }

        // Bottom bar
        cardView.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { $0.top.equalTo(divider.snp.bottom).offset(10); $0.leading.trailing.equalToSuperview().inset(14); $0.bottom.equalToSuperview().inset(12); $0.height.equalTo(24) }

        viewsIcon.image = UIImage(systemName: "bubble.left")
        viewsIcon.tintColor = AppTheme.secondary
        viewsIcon.contentMode = .scaleAspectFit
        bottomBar.addSubview(viewsIcon)
        viewsIcon.snp.makeConstraints { $0.leading.centerY.equalToSuperview(); $0.size.equalTo(16) }

        viewsLabel.font = .systemFont(ofSize: 13, weight: .regular)
        viewsLabel.textColor = AppTheme.secondary
        bottomBar.addSubview(viewsLabel)
        viewsLabel.snp.makeConstraints { $0.leading.equalTo(viewsIcon.snp.trailing).offset(4); $0.centerY.equalToSuperview() }

        followIcon.image = UIImage(systemName: "plus")
        followIcon.tintColor = AppTheme.secondary
        followIcon.contentMode = .scaleAspectFit
        bottomBar.addSubview(followIcon)
        followIcon.snp.makeConstraints { $0.leading.equalTo(viewsLabel.snp.trailing).offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(14) }

        let followLabel = UIButton(type: .system)
        followLabel.setTitle("Follow", for: .normal)
        followLabel.titleLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        followLabel.setTitleColor(AppTheme.secondary, for: .normal)
        bottomBar.addSubview(followLabel)
        followLabel.snp.makeConstraints { $0.leading.equalTo(followIcon.snp.trailing).offset(4); $0.centerY.equalToSuperview() }
        followLabel.addAction(UIAction { [weak self] _ in self?.onFollow?() }, for: .touchUpInside)

        collaborateLabel.setTitle("Collaborate", for: .normal)
        collaborateLabel.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        collaborateLabel.setTitleColor(AppTheme.ink, for: .normal)
        bottomBar.addSubview(collaborateLabel)
        collaborateLabel.snp.makeConstraints { $0.trailing.equalToSuperview().offset(-20); $0.centerY.equalToSuperview() }

        arrowIcon.image = UIImage(systemName: "arrow.right")
        arrowIcon.tintColor = AppTheme.ink
        arrowIcon.contentMode = .scaleAspectFit
        bottomBar.addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints { $0.leading.equalTo(collaborateLabel.snp.trailing).offset(4); $0.centerY.equalToSuperview(); $0.size.equalTo(14); $0.trailing.equalToSuperview() }
        collaborateLabel.addAction(UIAction { [weak self] _ in self?.onCollaborate?() }, for: .touchUpInside)
        followIcon.isHidden = !showsFollow
        followLabel.isHidden = !showsFollow
        collaborateLabel.isHidden = !showsCollaborate
        arrowIcon.isHidden = !showsCollaborate
    }

    private func configure() {
        let displayData = work.mediaData ?? work.mediaDatas?.first
        imageView.image = displayData.flatMap(UIImage.init(data:)) ?? UIImage(named: "login_bg") ?? UIImage(systemName: "photo")
        imageView.tintColor = AppTheme.lavender
        playIndicator.isHidden = work.videoData == nil
        tagLabel.text = "\(work.category) · \(work.location)"
        titleLabel.text = work.title

        let author = DataRepository.shared.user(work.authorID)
        authorLabel.text = author?.name ?? "Creator"
        metaLabel.text = "\(work.location) · \(work.timeAgo ?? "")"

        if let data = author?.avatarData { avatarView.image = UIImage(data: data) }
        else { avatarView.image = UIImage(systemName: "person.crop.circle.fill"); avatarView.tintColor = AppTheme.lavender }

        likeButton.setImage(UIImage(systemName: work.liked ? "heart.fill" : "heart"), for: .normal)
        likeButton.tintColor = work.liked ? AppTheme.destructive : AppTheme.ink

        viewsLabel.text = "\(DataRepository.shared.visibleComments.filter { $0.workID == work.id }.count)"
        let following = DataRepository.shared.isFollowing(work.authorID)
        followIcon.image = UIImage(systemName: following ? "minus" : "plus")
        let followButton = bottomBar.subviews.compactMap { $0 as? UIButton }.first { $0 !== collaborateLabel }
        followButton?.setTitle(following ? "Followed" : "Follow", for: .normal)
        followButton?.setTitleColor(following ? AppTheme.ink : AppTheme.secondary, for: .normal)

        collabStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        (work.collaborators ?? []).forEach { tag in
            collabStack.addArrangedSubview(makeCollabPill(tag))
        }
    }

    @objc private func cardTapped() { onTap?() }

    private func makeCollabPill(_ text: String) -> UIView {
        let pill = UIView()
        pill.backgroundColor = UIColor(hex: 0xF0F0F2)
        pill.layer.cornerRadius = 10
        pill.layer.masksToBounds = true
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = AppTheme.secondary
        pill.addSubview(label)
        label.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)) }
        return pill
    }
}

extension WorkCardView: UIGestureRecognizerDelegate {
    /// Keep the card tap for non-control content, but let overlay controls
    /// receive their own touch-up events instead of being cancelled by it.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var view = touch.view
        while let current = view, current !== self {
            if current is UIControl { return false }
            view = current.superview
        }
        return true
    }
}

final class WorkCardCell: UITableViewCell {
    static let reuseID = "WorkCardCell"
    var onLike: (() -> Void)?
    var onMore: (() -> Void)?
    var onTap: (() -> Void)?
    var onFollow: (() -> Void)?
    var onCollaborate: (() -> Void)?

    private var cardView: WorkCardView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    func configure(work: Work, showsFollow: Bool = true, showsCollaborate: Bool = true) {
        cardView?.removeFromSuperview()
        let card = WorkCardView(work: work, showsFollow: showsFollow, showsCollaborate: showsCollaborate)
        card.moreButton.isHidden = work.authorID == DataRepository.shared.currentUserID
        card.likeButton.addAction(UIAction { [weak self] _ in self?.onLike?() }, for: .touchUpInside)
        card.moreButton.addAction(UIAction { [weak self] _ in self?.onMore?() }, for: .touchUpInside)
        card.onTap = { [weak self] in self?.onTap?() }
        card.onFollow = { [weak self] in self?.onFollow?() }
        card.onCollaborate = { [weak self] in self?.onCollaborate?() }
        contentView.addSubview(card)
        card.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 8, right: 16)) }
        cardView = card
    }
}
