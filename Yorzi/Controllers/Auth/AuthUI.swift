import UIKit
import SnapKit

enum AuthUI {
    static let titleColor = UIColor(hex: 0x202A33)
    static let subtitleColor = UIColor(hex: 0x7E8792)
    static let labelColor = UIColor(hex: 0x1F2933)
    static let fieldBorderColor = UIColor(hex: 0xDCE4EB)
    static let fieldPlaceholderColor = UIColor(hex: 0xB2BAC4)
    static let buttonColor = UIColor(hex: 0x2D3E49)
    static let linkColor = UIColor(hex: 0x8B8DFF)

    static func backButton(target: Any?, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.addTarget(target, action: action, for: .touchUpInside)
        return button
    }

    static func titleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.text = text
        label.textColor = titleColor
        label.font = UIFont(name: "Georgia-Bold", size: 36) ?? .systemFont(ofSize: 36, weight: .semibold)
        return label
    }

    static func subtitleLabel(_ text: String) -> UILabel {
        let label = UILabel()
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 15, weight: .regular),
            .foregroundColor: subtitleColor,
            .paragraphStyle: paragraph
        ])
        return label
    }

    static func primaryButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = buttonColor
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 13
        button.layer.masksToBounds = true
        return button
    }

    static func linkButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(linkColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        button.contentEdgeInsets = .zero
        return button
    }
}

final class AuthFieldView: UIView {
    let textField = UITextField()

    private let titleLabel = UILabel()

    init(title: String, placeholder: String, secure: Bool = false, keyboardType: UIKeyboardType = .default, textContentType: UITextContentType? = nil) {
        super.init(frame: .zero)

        titleLabel.text = title
        titleLabel.textColor = AuthUI.labelColor
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        textField.isSecureTextEntry = secure
        textField.keyboardType = keyboardType
        textField.textContentType = textContentType
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.backgroundColor = .white
        textField.textColor = AuthUI.titleColor
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AuthUI.fieldBorderColor.cgColor
        textField.layer.cornerRadius = 11
        textField.setLeftPadding(14)
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            .foregroundColor: AuthUI.fieldPlaceholderColor,
            .font: UIFont.systemFont(ofSize: 14, weight: .regular)
        ])

        let stack = UIStackView(arrangedSubviews: [titleLabel, textField])
        stack.axis = .vertical
        stack.spacing = 6
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        textField.snp.makeConstraints { $0.height.equalTo(44) }
    }

    required init?(coder: NSCoder) { nil }
}
