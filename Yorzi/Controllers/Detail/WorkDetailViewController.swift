import UIKit
import SnapKit
import Photos
import AVKit

final class WorkDetailViewController: BaseViewController {
    private let work: Work
    private var heroImages: [UIImage] = []
    private let creditsStack = UIStackView()
    private let commentsStack = UIStackView()
    private let commentField = UITextField()
    private let sendButton = UIButton.primary("Send")
    private let likeButton = UIButton(type: .system)
    private var unlocked = false
    private var likeActionInstalled = false

    init(work: Work) { self.work = work; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        unlocked = DataRepository.shared.isResolutionUnlocked(for: work.id)
        buildPage()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.refreshComments() }
    }

    private func buildPage() {
        let mediaImages = (work.mediaDatas ?? []).compactMap(UIImage.init(data:))
        heroImages = Array(mediaImages.prefix(1))
        if heroImages.isEmpty, let image = work.mediaData.flatMap(UIImage.init(data:)) { heroImages = [image] }
        if heroImages.isEmpty, let fallback = UIImage(named: "login_bg") ?? UIImage(systemName: "photo") { heroImages = [fallback] }
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 0; contentView.addSubview(stack); stack.snp.makeConstraints { $0.edges.equalToSuperview(); $0.width.equalToSuperview() }
        let heroContainer = UIView()
        // The detail banner is intentionally a static cover: multi-image works
        // use only the first image and videos use their stored first frame.
        let heroImageView = UIImageView(image: heroImages.first)
        heroImageView.contentMode = .scaleAspectFill
        heroImageView.clipsToBounds = true
        heroImageView.backgroundColor = UIColor(hex: 0xE8E8F0)
        heroImageView.isUserInteractionEnabled = true
        heroImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openHero)))
        heroContainer.addSubview(heroImageView)
        heroImageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let back = roundIcon(image: UIImage(named: "back"), systemName: "chevron.left"); back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        let more = roundIcon(image: nil, systemName: "ellipsis"); more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        heroContainer.addSubview(back); heroContainer.addSubview(more); back.snp.makeConstraints { $0.top.equalToSuperview().offset(52); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(40) }; more.snp.makeConstraints { $0.top.equalTo(back); $0.trailing.equalToSuperview().inset(15); $0.size.equalTo(40) }
        heroContainer.snp.makeConstraints { $0.height.equalTo(398) }; stack.addArrangedSubview(heroContainer)
        stack.addArrangedSubview(authorHeader()); stack.addArrangedSubview(titleSection()); stack.addArrangedSubview(creditsSection()); stack.addArrangedSubview(collaborationButton()); stack.addArrangedSubview(resolutionSection()); stack.addArrangedSubview(commentsSection()); stack.addArrangedSubview(commentBar())
    }

    private func roundIcon(image: UIImage?, systemName: String) -> UIButton {
        let b = UIButton(type: .system); b.backgroundColor = .white; b.layer.borderWidth = 1; b.layer.borderColor = AppTheme.divider.cgColor; b.layer.cornerRadius = 20
        b.setImage((image ?? UIImage(systemName: systemName))?.withRenderingMode(.alwaysOriginal), for: .normal); b.tintColor = AppTheme.ink; return b
    }

    private func authorHeader() -> UIView {
        let c = UIView(); c.backgroundColor = .white; c.snp.makeConstraints { $0.height.equalTo(74) }
        let avatar = UIImageView(); avatar.contentMode = .scaleAspectFill; avatar.clipsToBounds = true; avatar.layer.cornerRadius = 18
        let user = DataRepository.shared.user(work.authorID); avatar.image = user?.avatarData.flatMap(UIImage.init(data:)) ?? UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender
        let name = UILabel.appLabel(user?.name ?? "Creator", size: 14, weight: .semibold); let role = UILabel.appLabel("\(user?.role ?? "Creator") · \(work.location)", size: 11, color: AppTheme.secondary)
        let texts = UIStackView(arrangedSubviews: [name, role]); texts.axis = .vertical; texts.spacing = 3
        let studio = UIButton.outline("View Studio"); studio.configuration?.contentInsets = .zero; studio.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attrs = $0; attrs.font = .systemFont(ofSize: 10); return attrs }; studio.snp.makeConstraints { $0.width.equalTo(72); $0.height.equalTo(30) }
        [avatar, texts, studio].forEach(c.addSubview); avatar.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(36) }; texts.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(9); $0.centerY.equalToSuperview() }; studio.snp.makeConstraints { $0.trailing.equalToSuperview().inset(15); $0.centerY.equalToSuperview() }
        studio.addAction(UIAction { [weak self] _ in self?.push(CreatorProfileViewController(userID: self?.work.authorID ?? UUID())) }, for: .touchUpInside); return c
    }

    private func titleSection() -> UIView {
        let c = UIView(); c.backgroundColor = .white; let title = UILabel(); title.text = work.title; title.font = UIFont(name: "Georgia", size: 24) ?? .systemFont(ofSize: 24); title.textColor = AppTheme.ink
        let published = work.createdAt.map { DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none) } ?? (work.timeAgo ?? "Recently")
        let commentCount = DataRepository.shared.visibleComments.filter { $0.workID == work.id }.count
        let meta = UILabel.appLabel("\(work.category) · Published \(published)\n\(work.location)", size: 12, color: AppTheme.secondary); let body = UILabel.appLabel(work.description, size: 12, color: AppTheme.secondary)
        let stats = UIView(); let comments = UILabel.appLabel("\(commentCount)", size: 13, color: AppTheme.secondary); let commentIcon = UIImageView(image: UIImage(systemName: "bubble.left")); commentIcon.tintColor = AppTheme.secondary; let likeCount = UILabel.appLabel("\(work.likes)", size: 13, color: AppTheme.secondary); likeButton.setImage(UIImage(systemName: work.liked ? "heart.fill" : "heart"), for: .normal); likeButton.tintColor = work.liked ? AppTheme.destructive : AppTheme.ink; if !likeActionInstalled { likeActionInstalled = true; likeButton.addAction(UIAction { [weak self] _ in guard let self else { return }; DataRepository.shared.toggleLike(self.work.id); let current = DataRepository.shared.works.first { $0.id == self.work.id }; self.likeButton.setImage(UIImage(systemName: current?.liked == true ? "heart.fill" : "heart"), for: .normal); self.likeButton.tintColor = current?.liked == true ? AppTheme.destructive : AppTheme.ink }, for: .touchUpInside) }; [likeButton, likeCount, commentIcon, comments].forEach(stats.addSubview); likeButton.snp.makeConstraints { $0.leading.centerY.equalToSuperview(); $0.size.equalTo(20) }; likeCount.snp.makeConstraints { $0.leading.equalTo(likeButton.snp.trailing).offset(4); $0.centerY.equalToSuperview() }; commentIcon.snp.makeConstraints { $0.leading.equalTo(likeCount.snp.trailing).offset(18); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }; comments.snp.makeConstraints { $0.leading.equalTo(commentIcon.snp.trailing).offset(4); $0.centerY.equalToSuperview() }; stats.snp.makeConstraints { $0.height.equalTo(22) }
        let stack = UIStackView(arrangedSubviews: [title, meta, body, stats]); stack.axis = .vertical; stack.spacing = 8; c.addSubview(stack); stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalToSuperview().inset(14) }; return c
    }

    private func creditsSection() -> UIView {
        let c = UIView(); c.backgroundColor = .white; let heading = UILabel.appLabel("Credits", size: 13, weight: .semibold); c.addSubview(heading); heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15) }
        creditsStack.axis = .vertical; creditsStack.spacing = 0; c.addSubview(creditsStack); creditsStack.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(6); $0.leading.trailing.bottom.equalToSuperview().inset(15) }
        creditsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let currentWork = DataRepository.shared.visibleWorks.first(where: { $0.id == work.id }) ?? work
        (currentWork.collaborators ?? []).forEach { creditsStack.addArrangedSubview(creditRow($0)) }; return c
    }

    private func creditRow(_ value: String) -> UIView { let row = UIView(); row.snp.makeConstraints { $0.height.equalTo(30) }; let label = UILabel.appLabel(value, size: 11); let button = UIButton(type: .system); button.setTitle("View profile", for: .normal); button.setTitleColor(AppTheme.secondary, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 10); row.addSubview(label); row.addSubview(button); label.snp.makeConstraints { $0.leading.centerY.equalToSuperview() }; button.snp.makeConstraints { $0.trailing.centerY.equalToSuperview() }; let name = value.components(separatedBy: " · ").first ?? value; let matched = DataRepository.shared.users.first(where: { $0.name == name }); let fallback = DataRepository.shared.visibleUsers.first; if let user = matched ?? fallback { button.addAction(UIAction { [weak self] _ in self?.push(CreatorProfileViewController(userID: user.id)) }, for: .touchUpInside) }; let line = UIView(); line.backgroundColor = AppTheme.divider; row.addSubview(line); line.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(1) }; return row }

    private func collaborationButton() -> UIView { let c = UIView();
        let b = UIButton.primary("500 Coins · Start a collaboration");
        b.configuration?.baseBackgroundColor = AppTheme.lavender; b.configuration?.baseForegroundColor = .white; b.configuration?.contentInsets = .zero; b.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attrs = $0; attrs.font = .systemFont(ofSize: 13, weight: .medium); return attrs }; c.addSubview(b); b.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalToSuperview().inset(10); $0.height.equalTo(40) }; b.addAction(UIAction { [weak self] _ in self?.startCollaboration() }, for: .touchUpInside); return c }

    private func resolutionSection() -> UIView {
        let c = UIView(); let title = UILabel.appLabel("Full-resolution set", size: 13, weight: .semibold); c.addSubview(title); title.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15) }
        let card = UIView(); card.tag = 1001; card.backgroundColor = UIColor(hex: 0xF1F8F4); card.layer.borderWidth = 1; card.layer.borderColor = UIColor(hex: 0xC7DFD0).cgColor; card.layer.cornerRadius = 12; c.addSubview(card); card.snp.makeConstraints { $0.top.equalTo(title.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview().inset(15); $0.height.equalTo(unlocked ? 56 : 78) }
        if unlocked { let text = UILabel.appLabel("Full-resolution set unlocked", size: 12, weight: .medium); let sub = UILabel.appLabel("Download access is now available", size: 9, color: AppTheme.secondary); let check = UIImageView(image: UIImage(named: "gou")); check.contentMode = .scaleAspectFit; let download = UIButton.outline("Download"); download.configuration?.baseForegroundColor = UIColor(hex: 0x4F7E65); download.configuration?.background.strokeColor = UIColor(hex: 0x8FB8A0); download.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attrs = $0; attrs.font = .systemFont(ofSize: 11, weight: .semibold); return attrs }; download.configuration?.contentInsets = .zero; [check, text, sub, download].forEach(card.addSubview); check.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(32) }; text.snp.makeConstraints { $0.leading.equalTo(check.snp.trailing).offset(8); $0.top.equalToSuperview().offset(11) }; sub.snp.makeConstraints { $0.leading.equalTo(text); $0.top.equalTo(text.snp.bottom).offset(3) }; download.snp.makeConstraints { $0.trailing.equalToSuperview().inset(14); $0.centerY.equalToSuperview(); $0.width.equalTo(80); $0.height.equalTo(30) }; download.addAction(UIAction { [weak self] _ in self?.downloadAll() }, for: .touchUpInside); addMediaGrid(to: c) }
        else { let text = UILabel.appLabel("Unlock the full-resolution set and download access", size: 11, color: AppTheme.secondary); text.textAlignment = .center; let buy = UIButton.primary("500 platform coins"); buy.configuration?.baseBackgroundColor = AppTheme.lavender; buy.configuration?.baseForegroundColor = .white; buy.configuration?.contentInsets = .zero; buy.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attrs = $0; attrs.font = .systemFont(ofSize: 11, weight: .medium); return attrs }; card.addSubview(text); card.addSubview(buy); text.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.centerX.equalToSuperview() }; buy.snp.makeConstraints { $0.top.equalTo(text.snp.bottom).offset(8); $0.centerX.equalToSuperview(); $0.width.equalTo(144); $0.height.equalTo(28) }; buy.addAction(UIAction { [weak self] _ in self?.unlockSet() }, for: .touchUpInside) }
        if !unlocked || (work.mediaDatas ?? []).isEmpty { card.snp.makeConstraints { $0.bottom.equalToSuperview().inset(15) } }
        return c
    }
    private func addMediaGrid(to container: UIView) {
        let images = (work.mediaDatas ?? [work.mediaData].compactMap { $0 }).compactMap(UIImage.init(data:))
        guard !images.isEmpty, let card = container.subviews.first(where: { $0.tag == 1001 }) else { return }

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 8
        container.addSubview(grid)
        grid.snp.makeConstraints {
            $0.top.equalTo(card.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(15)
            $0.bottom.equalToSuperview().inset(8)
        }

        for pair in stride(from: 0, to: images.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .fillEqually
            let rowImages = images[pair..<min(pair + 2, images.count)]
            for (offset, image) in rowImages.enumerated() {
                let index = pair + offset
                let mediaCell = UIControl()
                mediaCell.addAction(UIAction { [weak self] _ in self?.openResolutionMedia(at: index) }, for: .touchUpInside)

                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.cornerRadius = 10
                mediaCell.addSubview(imageView)
                imageView.snp.makeConstraints { $0.edges.equalToSuperview() }

                if work.videoData != nil && index == 0 {
                    let play = makePlayIndicator()
                    mediaCell.addSubview(play)
                    play.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(52) }
                }
                row.addArrangedSubview(mediaCell)
            }
            if rowImages.count == 1 { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(135) }
        }
    }

    private func makePlayIndicator() -> UIImageView {
        let play = UIImageView(image: UIImage(systemName: "play.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)))
        play.tintColor = AppTheme.ink
        play.backgroundColor = UIColor.white.withAlphaComponent(0.9)
        play.contentMode = .center
        play.layer.cornerRadius = 26
        play.layer.masksToBounds = true
        play.isUserInteractionEnabled = false
        return play
    }

    private func openResolutionMedia(at index: Int) {
        if work.videoData != nil {
            playResolutionVideo()
            return
        }
        let images = (work.mediaDatas ?? [work.mediaData].compactMap { $0 }).compactMap(UIImage.init(data:))
        guard images.indices.contains(index) else { return }
        presentImageViewer(images[index])
    }

    private func playResolutionVideo() {
        guard let videoData = work.videoData else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("yorzi-resolution-\(UUID().uuidString).mov")
        guard (try? videoData.write(to: url)) != nil else {
            showMessage(title: "Video unavailable", message: "The video could not be opened.")
            return
        }
        let playerViewController = AVPlayerViewController()
        playerViewController.player = AVPlayer(url: url)
        playerViewController.modalPresentationStyle = .fullScreen
        present(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }

    private func commentsSection() -> UIView { let c = UIView(); let heading = UILabel.appLabel("Comments", size: 13, weight: .semibold); c.addSubview(heading); heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15) }; commentsStack.axis = .vertical; commentsStack.spacing = 0; c.addSubview(commentsStack); commentsStack.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview().inset(15) }; commentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; DataRepository.shared.visibleComments.filter { $0.workID == work.id }.forEach { commentsStack.addArrangedSubview(commentRow($0)) }; return c }
    private func refreshComments() { guard commentsStack.superview != nil else { return }; commentsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; DataRepository.shared.visibleComments.filter { $0.workID == work.id }.forEach { commentsStack.addArrangedSubview(commentRow($0)) } }
    private func commentRow(_ comment: AppComment) -> UIView {
        let row = UIView()
        let avatar = UIImageView(); avatar.contentMode = .scaleAspectFill; avatar.clipsToBounds = true; avatar.layer.cornerRadius = 16
        let user = DataRepository.shared.user(comment.authorID)
        avatar.image = user?.avatarData.flatMap(UIImage.init(data:)) ?? UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender
        let when = comment.createdAt.map { DateFormatter.localizedString(from: $0, dateStyle: .short, timeStyle: .none) } ?? "Recently"
        let name = UILabel.appLabel(user?.name ?? "User", size: 12, weight: .semibold)
        let time = UILabel.appLabel(when, size: 10, color: AppTheme.muted)
        let text = UILabel.appLabel(comment.text, size: 12); text.numberOfLines = 0
        let line = UIView(); line.backgroundColor = AppTheme.divider
        [avatar, name, time, text, line].forEach(row.addSubview)
        avatar.snp.makeConstraints { $0.leading.top.equalToSuperview(); $0.size.equalTo(32) }
        name.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(8); $0.top.equalToSuperview() }
        time.snp.makeConstraints { $0.leading.equalTo(name.snp.trailing).offset(5); $0.centerY.equalTo(name) }
        text.snp.makeConstraints { $0.leading.equalTo(name); $0.top.equalTo(name.snp.bottom).offset(4); $0.trailing.equalToSuperview().inset(24) }
        line.snp.makeConstraints { $0.leading.trailing.equalToSuperview(); $0.top.equalTo(text.snp.bottom).offset(10); $0.bottom.equalToSuperview().inset(12); $0.height.equalTo(1) }
        if comment.authorID != DataRepository.shared.currentUserID { let more = UIButton(type: .system); more.setTitle("···", for: .normal); more.setTitleColor(AppTheme.ink, for: .normal); more.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold); row.addSubview(more); more.snp.makeConstraints { $0.trailing.top.equalToSuperview(); $0.width.equalTo(28); $0.height.equalTo(24) }; more.addAction(UIAction { [weak self] _ in self?.showCommentMore(comment) }, for: .touchUpInside) }
        return row
    }

    private func commentBar() -> UIView { let c = UIView(); c.backgroundColor = .white; commentField.placeholder = "Write a comment..."; commentField.font = .systemFont(ofSize: 12); commentField.layer.borderWidth = 1; commentField.layer.borderColor = AppTheme.divider.cgColor; commentField.layer.cornerRadius = 9; commentField.setLeftPadding(12); commentField.delegate = self; sendButton.configuration?.contentInsets = .zero; sendButton.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attrs = $0; attrs.font = .systemFont(ofSize: 12, weight: .medium); return attrs }; c.addSubview(commentField); c.addSubview(sendButton); commentField.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.top.bottom.equalToSuperview().inset(10); $0.trailing.equalTo(sendButton.snp.leading).offset(-8); $0.height.equalTo(38) }; sendButton.snp.makeConstraints { $0.trailing.equalToSuperview().inset(15); $0.centerY.equalTo(commentField); $0.width.equalTo(68); $0.height.equalTo(38) }; sendButton.addAction(UIAction { [weak self] _ in self?.submitComment() }, for: .touchUpInside); return c }

    private func submitComment() { guard let text = commentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return }; DataRepository.shared.addComment(workID: work.id, text: text); commentField.text = ""; commentField.resignFirstResponder() }
    private func showCommentMore(_ comment: AppComment) { let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { item in if item == "Report" { DataRepository.shared.report(comment.authorID, reason: "Comment") } else if item == "Block" { DataRepository.shared.block(comment.authorID) } }; sheet.present(in: view.window ?? view) }

    private func startCollaboration() { let dialog = AppDialogView(title: "Start a collaboration", message: "500 coins will be deducted from your balance.", actions: [.init(title: "Cancel", style: .plain, handler: nil), .init(title: "Confirm", style: .accent) { [weak self] in self?.confirmCollaboration() }]); dialog.present(in: view.window ?? view) }
    private func confirmCollaboration() { guard DataRepository.shared.balance >= 500 else { showMessage(title: "Not enough coins", message: "Please recharge your coins to continue.", action: "Recharge") { [weak self] in self?.push(RechargeViewController()) }; return }; guard DataRepository.shared.spend(500) else { return }; let roles = ["Model", "Retoucher", "Stylist"]; DataRepository.shared.addCollaborator(workID: work.id, name: DataRepository.shared.currentUser.name, role: roles.randomElement() ?? "Model"); rebuild(); showMessage(title: "Collaboration started", message: "You have been added to the credits.") }
    private func unlockSet() { let dialog = AppDialogView(title: "Unlock full-resolution set", message: "500 platform coins will be deducted.", actions: [.init(title: "Cancel", style: .plain, handler: nil), .init(title: "Confirm", style: .accent) { [weak self] in self?.confirmUnlock() }]); dialog.present(in: view.window ?? view) }
    private func confirmUnlock() { guard DataRepository.shared.balance >= 500 else { showMessage(title: "Not enough coins", message: "Please recharge your coins to continue.", action: "Recharge") { [weak self] in self?.push(RechargeViewController()) }; return }; guard DataRepository.shared.spend(500) else { return }; DataRepository.shared.unlockResolution(for: work.id); unlocked = true; rebuild() }
    private func rebuild() { buildPage() }
    private func showMore() { let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in if item == "Report", let id = self?.work.authorID { self?.push(ReportViewController(targetID: id)) } else if item == "Block", let id = self?.work.authorID { DataRepository.shared.block(id) } }; sheet.present(in: view.window ?? view) }
    private func downloadAll() {
        let dialog = AppDialogView(title: "Download to Photos", message: "Save the full-resolution media to your photo library?", actions: [
            .init(title: "Cancel", style: .plain, handler: nil),
            .init(title: "Confirm", style: .accent) { [weak self] in self?.confirmDownload() }
        ])
        dialog.present(in: view.window ?? view)
    }

    private func confirmDownload() {
        let save: () -> Void = { [weak self] in self?.saveMediaToPhotos() }
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited: save()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                guard status == .authorized || status == .limited else { return }
                DispatchQueue.main.async(execute: save)
            }
        default:
            showMessage(title: "Photo access needed", message: "Allow photo access in Settings to save this media.")
        }
    }

    private func saveMediaToPhotos() {
        let imageData = (work.mediaDatas ?? []).isEmpty ? [work.mediaData].compactMap { $0 } : (work.mediaDatas ?? [])
        guard work.videoData != nil || !imageData.isEmpty else {
            showMessage(title: "Nothing to download", message: "This work has no downloadable media.")
            return
        }
        var videoURL: URL?
        if let videoData = work.videoData {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("yorzi-\(UUID().uuidString).mov")
            guard (try? videoData.write(to: url)) != nil else {
                showMessage(title: "Download failed", message: "The video could not be prepared.")
                return
            }
            videoURL = url
        }
        PHPhotoLibrary.shared().performChanges({
            if let videoURL { PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL) }
            else { imageData.compactMap(UIImage.init(data:)).forEach { PHAssetChangeRequest.creationRequestForAsset(from: $0) } }
        }) { [weak self] success, _ in
            if let videoURL { try? FileManager.default.removeItem(at: videoURL) }
            DispatchQueue.main.async {
                self?.showMessage(title: success ? "Download complete" : "Download failed", message: success ? "The media was saved to your photo library." : "Please try again later.")
            }
        }
    }

    @objc private func openHero() {
        guard let heroImage = heroImages.first else { return }
        presentImageViewer(heroImage)
    }

    private func presentImageViewer(_ image: UIImage) {
        let viewer = UIViewController(); viewer.view.backgroundColor = .black
        let imageView = UIImageView(image: image); imageView.contentMode = .scaleAspectFit; viewer.view.addSubview(imageView); imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let close = UIButton(type: .system); close.setImage(UIImage(systemName: "xmark"), for: .normal); close.tintColor = .white; close.backgroundColor = UIColor.black.withAlphaComponent(0.45); close.layer.cornerRadius = 20; close.addAction(UIAction { [weak viewer] _ in viewer?.dismiss(animated: true) }, for: .touchUpInside); viewer.view.addSubview(close); close.snp.makeConstraints { $0.top.equalTo(viewer.view.safeAreaLayoutGuide).offset(10); $0.trailing.equalToSuperview().inset(15); $0.size.equalTo(40) }; viewer.modalPresentationStyle = .fullScreen; present(viewer, animated: true)
    }
}

extension WorkDetailViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { submitComment(); return true }
}
