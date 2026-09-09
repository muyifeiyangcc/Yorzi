import UIKit
import SnapKit

final class AppDialogView: UIView {
    struct Action { let title: String; let style: Style; let handler: (() -> Void)?; enum Style { case plain, accent, destructive } }
    private let actions: [Action]
    init(title: String, message: String, actions: [Action]) {
        self.actions = actions
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.38)
        let card = UIView(); card.backgroundColor = .white; card.layer.cornerRadius = 22; card.layer.masksToBounds = true; card.addSoftShadow(); addSubview(card)
        card.snp.makeConstraints { $0.center.equalToSuperview(); $0.leading.trailing.equalToSuperview().inset(22) }
        let titleLabel = UILabel.appLabel(title, size: 22, weight: .bold); let messageLabel = UILabel.appLabel(message, size: 14, color: AppTheme.secondary); messageLabel.numberOfLines = 0
        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel]); stack.axis = .vertical; stack.spacing = 10; card.addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(22) }
        let buttonStack = UIStackView(); buttonStack.axis = .horizontal; buttonStack.spacing = 10; buttonStack.distribution = .fillEqually; card.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { $0.top.equalTo(stack.snp.bottom).offset(22); $0.leading.trailing.bottom.equalToSuperview().inset(22); $0.height.equalTo(48) }
        for action in actions {
            let button = UIButton(type: .system); button.setTitle(action.title, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold); button.layer.cornerRadius = 16; button.layer.masksToBounds = true
            switch action.style { case .plain: button.backgroundColor = .white; button.setTitleColor(AppTheme.ink, for: .normal); button.layer.borderWidth = 1; button.layer.borderColor = UIColor(hex: 0xDDE2E2).cgColor; case .accent: button.backgroundColor = AppTheme.lavender; button.setTitleColor(.white, for: .normal); case .destructive: button.backgroundColor = AppTheme.destructive; button.setTitleColor(.white, for: .normal) }
            button.addAction(UIAction { [weak self] _ in self?.dismiss(); action.handler?() }, for: .touchUpInside)
            buttonStack.addArrangedSubview(button)
        }
    }
    required init?(coder: NSCoder) { nil }
    func present(in host: UIView) { frame = host.bounds; autoresizingMask = [.flexibleWidth, .flexibleHeight]; host.addSubview(self) }
    private func dismiss() { removeFromSuperview() }
}

final class CustomSheetView: UIView {
    private let onSelect: (String) -> Void
    init(items: [String], onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect; super.init(frame: .zero); backgroundColor = UIColor.black.withAlphaComponent(0.25)
        let sheet = UIView(); sheet.backgroundColor = .white; sheet.round(20); addSubview(sheet)
        sheet.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(CGFloat(items.count) * 58 + 24) }
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 0; stack.distribution = .fillEqually; sheet.addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(12); $0.bottom.equalToSuperview().inset(12) }
        items.forEach { item in
            let button = UIButton(type: .system); button.setTitle(item, for: .normal); button.setTitleColor(AppTheme.ink, for: .normal); button.titleLabel?.font = .systemFont(ofSize: 15); button.backgroundColor = .white
            button.addAction(UIAction { [weak self] _ in self?.removeFromSuperview(); self?.onSelect(item) }, for: .touchUpInside); stack.addArrangedSubview(button)
        }
    }
    required init?(coder: NSCoder) { nil }
    func present(in host: UIView) { frame = host.bounds; autoresizingMask = [.flexibleWidth, .flexibleHeight]; host.addSubview(self) }
}
