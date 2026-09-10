import UIKit
import SnapKit

final class CollabCallDetailViewController: BaseViewController {
    private let call: CollabCall

    init(call: CollabCall) {
        self.call = call
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.keyboardDismissMode = .interactive
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildPage()
    }

    private func buildPage() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        contentView.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 15, bottom: 24, right: 15)) }

        stack.addArrangedSubview(navigationHeader())
        stack.addArrangedSubview(titleSection())
        stack.addArrangedSubview(mediaSection())
        stack.addArrangedSubview(hostSection())
        stack.addArrangedSubview(infoSection())
        stack.addArrangedSubview(descriptionSection())
        stack.addArrangedSubview(actionSection())
    }

    private func navigationHeader() -> UIView {
        let container = UIView()
        container.snp.makeConstraints { $0.height.equalTo(48) }

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppTheme.ink
        back.backgroundColor = .white
        back.layer.borderWidth = 1
        back.layer.borderColor = AppTheme.divider.cgColor
        back.layer.cornerRadius = 20
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        container.addSubview(back)
        back.snp.makeConstraints { $0.leading.centerY.equalToSuperview(); $0.size.equalTo(40) }

        let title = UILabel.appLabel("Collab call", size: 22, weight: .semibold)
        container.addSubview(title)
        title.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(12); $0.centerY.equalToSuperview() }

        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        more.tintColor = AppTheme.ink
        more.backgroundColor = .white
        more.layer.borderWidth = 1
        more.layer.borderColor = AppTheme.divider.cgColor
        more.layer.cornerRadius = 20
        more.isHidden = call.authorID == DataRepository.shared.currentUserID
        more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        container.addSubview(more)
        more.snp.makeConstraints { $0.trailing.centerY.equalToSuperview(); $0.size.equalTo(40) }
        return container
    }

    private func titleSection() -> UIView {
        let container = detailCard()
        let state = UILabel.appLabel(DataRepository.shared.hasCollaborated(on: call.id) ? "COLLABORATED" : "OPEN CALL", size: 9, weight: .semibold, color: AppTheme.lavender)
        state.textAlignment = .center
        state.backgroundColor = AppTheme.lavenderTint
        state.layer.cornerRadius = 11
        state.layer.masksToBounds = true
        container.addSubview(state)
        state.snp.makeConstraints { $0.top.leading.equalToSuperview().offset(15); $0.height.equalTo(22); $0.width.greaterThanOrEqualTo(84) }

        let title = UILabel.appLabel(call.title, size: 25, weight: .bold)
        title.font = UIFont(name: "Georgia-Bold", size: 25) ?? .systemFont(ofSize: 25, weight: .bold)
        title.numberOfLines = 0
        container.addSubview(title)
        title.snp.makeConstraints { $0.top.equalTo(state.snp.bottom).offset(10); $0.leading.trailing.bottom.equalToSuperview().inset(15) }
        return container
    }

    private func mediaSection() -> UIView {
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 18
        container.layer.masksToBounds = true

        let images = referenceImages()
        if images.isEmpty {
            let placeholder = UIImageView(image: UIImage(systemName: "photo.on.rectangle.angled"))
            placeholder.tintColor = AppTheme.lavender
            placeholder.contentMode = .center
            container.addSubview(placeholder)
            placeholder.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(190) }
            let label = UILabel.appLabel("No reference material", size: 13, color: AppTheme.secondary)
            label.textAlignment = .center
            container.addSubview(label)
            label.snp.makeConstraints { $0.top.equalTo(placeholder.snp.bottom).offset(-42); $0.centerX.equalToSuperview(); $0.bottom.equalToSuperview().inset(18) }
            return container
        }

        // Reference media is represented by a single static cover in the
        // detail banner. Multi-image calls use the first image; videos use the
        // first frame saved at publish time.
        let imageView = UIImageView(image: images.first)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openMedia)))
        container.addSubview(imageView)
        imageView.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(230) }

        let label = UILabel.appLabel(call.videoData == nil ? "Reference material" : "Reference video", size: 12, weight: .medium, color: AppTheme.secondary)
        container.addSubview(label)
        label.snp.makeConstraints { $0.top.equalTo(imageView.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalToSuperview().inset(14) }
        return container
    }

    private func hostSection() -> UIView {
        let container = detailCard()
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 22
        avatar.backgroundColor = UIColor(hex: 0xE0E0E8)
        let user = DataRepository.shared.user(call.authorID)
        avatar.image = user?.avatarData.flatMap(UIImage.init(data:)) ?? UIImage(systemName: "person.crop.circle.fill")
        avatar.tintColor = AppTheme.lavender
        container.addSubview(avatar)
        avatar.snp.makeConstraints { $0.leading.top.equalToSuperview().offset(15); $0.size.equalTo(44) }

        let eyebrow = UILabel.appLabel("Hosted by", size: 11, color: AppTheme.muted)
        let name = UILabel.appLabel(user?.name ?? "Creator", size: 16, weight: .semibold)
        let role = UILabel.appLabel([user?.role, user?.location].compactMap { $0 }.joined(separator: " · "), size: 11, color: AppTheme.secondary)
        let texts = UIStackView(arrangedSubviews: [eyebrow, name, role])
        texts.axis = .vertical
        texts.spacing = 2
        container.addSubview(texts)
        texts.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(10); $0.centerY.equalTo(avatar) }
        container.snp.makeConstraints { $0.height.equalTo(74) }
        return container
    }

    private func infoSection() -> UIView {
        let container = detailCard()
        let heading = UILabel.appLabel("Call details", size: 16, weight: .semibold)
        container.addSubview(heading)
        heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15) }

        let values: [(String, String)] = [
            ("Location", display(call.location)),
            ("Date", display(call.date)),
            ("Budget", display(call.budget)),
            ("Roles needed", display(call.roles)),
            ("Application deadline", display(call.deadline))
        ]
        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12
        container.addSubview(grid)
        grid.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(14); $0.leading.trailing.bottom.equalToSuperview().inset(15) }
        for pair in stride(from: 0, to: values.count, by: 2) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
            row.addArrangedSubview(infoItem(title: values[pair].0, value: values[pair].1))
            if pair + 1 < values.count { row.addArrangedSubview(infoItem(title: values[pair + 1].0, value: values[pair + 1].1)) }
            else { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
        }
        return container
    }

    private func infoItem(title: String, value: String) -> UIView {
        let item = UIView()
        let titleLabel = UILabel.appLabel(title.uppercased(), size: 9, weight: .medium, color: AppTheme.muted)
        let valueLabel = UILabel.appLabel(value, size: 13, weight: .medium)
        valueLabel.numberOfLines = 0
        item.addSubview(titleLabel)
        item.addSubview(valueLabel)
        titleLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        valueLabel.snp.makeConstraints { $0.top.equalTo(titleLabel.snp.bottom).offset(4); $0.leading.trailing.bottom.equalToSuperview() }
        return item
    }

    private func descriptionSection() -> UIView {
        let container = detailCard()
        let heading = UILabel.appLabel("Project description", size: 16, weight: .semibold)
        let body = UILabel.appLabel(display(call.description, fallback: "No project description provided."), size: 13, color: AppTheme.secondary)
        body.numberOfLines = 0
        container.addSubview(heading)
        container.addSubview(body)
        heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15) }
        body.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview().inset(15) }
        return container
    }

    private func actionSection() -> UIView {
        let container = UIView()
        let collaborated = DataRepository.shared.hasCollaborated(on: call.id)
        let button = UIButton.primary(collaborated ? "Collaborated" : "Collaborate")
        button.isEnabled = !collaborated
        button.alpha = collaborated ? 0.6 : 1
        container.addSubview(button)
        button.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.bottom.equalToSuperview().inset(4); $0.height.equalTo(50) }
        button.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            DataRepository.shared.collaborate(on: self.call.id)
            self.buildPage()
        }, for: .touchUpInside)
        return container
    }

    private func detailCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        return card
    }

    private func display(_ value: String?, fallback: String = "Not specified") -> String {
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return fallback }
        return value
    }

    private func showMore() {
        let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in
            guard let self else { return }
            if item == "Report" { self.push(ReportViewController(targetID: self.call.authorID)) }
            else if item == "Block" { self.blockUserAndReturnToRoot(self.call.authorID) }
        }
        sheet.present(in: view.window ?? view)
    }

    @objc private func openMedia() {
        guard let image = referenceImages().first else { return }
        let viewer = UIViewController()
        viewer.view.backgroundColor = .black
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        viewer.view.addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        close.layer.cornerRadius = 18
        close.addAction(UIAction { [weak viewer] _ in viewer?.dismiss(animated: true) }, for: .touchUpInside)
        viewer.view.addSubview(close)
        close.snp.makeConstraints { $0.top.equalTo(viewer.view.safeAreaLayoutGuide).offset(12); $0.trailing.equalToSuperview().inset(16); $0.size.equalTo(36) }
        viewer.modalPresentationStyle = .fullScreen
        present(viewer, animated: true)
    }

    private func referenceImages() -> [UIImage] {
        var data = call.mediaDatas ?? []
        if data.isEmpty, let cover = call.mediaData { data = [cover] }
        return data.compactMap(UIImage.init(data:))
    }
}
