import UIKit

enum AppTheme {
    static let ink = UIColor(hex: 0x273840)
    static let lavender = UIColor(hex: 0x878EFD)
    static let lavenderTint = UIColor(hex: 0xF0F0FF)
    static let canvas = UIColor(hex: 0xF9FAF9)
    static let secondary = UIColor(hex: 0x7F807F)
    static let muted = UIColor(hex: 0xA0A7AA)
    static let divider = UIColor(hex: 0xE9EAE9)
    static let destructive = UIColor(hex: 0xC95858)
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xff) / 255,
                  green: CGFloat((hex >> 8) & 0xff) / 255,
                  blue: CGFloat(hex & 0xff) / 255,
                  alpha: alpha)
    }
}

extension UIView {
    func round(_ radius: CGFloat) { layer.cornerRadius = radius; layer.masksToBounds = true }
    func addSoftShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowRadius = 12
        layer.masksToBounds = false
    }
}

extension UIButton {
    static func primary(_ title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = AppTheme.ink
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = .init(top: 13, leading: 18, bottom: 13, trailing: 18)
        let button = UIButton(configuration: config)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }

    static func outline(_ title: String) -> UIButton {
        var config = UIButton.Configuration.bordered()
        config.title = title
        config.baseForegroundColor = AppTheme.ink
        config.background.strokeColor = AppTheme.divider
        config.cornerStyle = .medium
        return UIButton(configuration: config)
    }
}

extension UILabel {
    static func appLabel(_ text: String = "", size: CGFloat = 14, weight: UIFont.Weight = .regular, color: UIColor = AppTheme.ink) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: size, weight: weight)
        label.textColor = color
        label.numberOfLines = 0
        return label
    }
}
