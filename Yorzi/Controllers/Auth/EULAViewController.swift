import UIKit
import SnapKit

final class EULAViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = UIColor.black.withAlphaComponent(0.38)

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 22
        card.layer.masksToBounds = true
        view.addSubview(card)
        card.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(22)
            $0.top.greaterThanOrEqualTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }

        let title = UILabel.appLabel("EULA", size: 18, weight: .semibold)
        card.addSubview(title)
        title.snp.makeConstraints { $0.top.equalToSuperview().offset(39); $0.leading.trailing.equalToSuperview().inset(19) }

        let body = UILabel()
        body.text = """
        Welcome to Yorzi! To create a safe and inspiring community for visual creativity and artistic expression, the following content is strictly prohibited:
        1. Any content about child harm, pornography, or material detrimental to children.
        2. Fake and harmful messages about recent or current events.
        3. Any violence, bullying, explicit content, or other inappropriate material.

        If any content is found to violate these guidelines, it will be removed immediately and your account may be banned. By clicking the button below, you agree to our Terms of Use and Privacy Policy.
        """
        body.font = .systemFont(ofSize: 11, weight: .regular)
        body.textColor = AppTheme.secondary
        body.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 2
        body.attributedText = NSAttributedString(string: body.text ?? "", attributes: [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: AppTheme.secondary,
            .paragraphStyle: paragraph
        ])

        card.addSubview(body)
        body.setContentCompressionResistancePriority(.required, for: .vertical)
        body.snp.makeConstraints {
            $0.top.equalTo(title.snp.bottom).offset(9)
            $0.leading.trailing.equalToSuperview().inset(19)
        }

        let cancel = UIButton.outline("Cancel")
        cancel.configuration?.contentInsets = .zero
        cancel.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attributes = $0; attributes.font = .systemFont(ofSize: 12, weight: .semibold); return attributes }
        let agree = UIButton.primary("Agree")
        agree.configuration?.baseBackgroundColor = AppTheme.lavender
        agree.configuration?.contentInsets = .zero
        agree.configuration?.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { var attributes = $0; attributes.font = .systemFont(ofSize: 12, weight: .semibold); return attributes }
        let buttons = UIStackView(arrangedSubviews: [cancel, agree])
        buttons.axis = .horizontal
        buttons.spacing = 8
        buttons.distribution = .fillEqually
        card.addSubview(buttons)
        buttons.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview().inset(19); $0.height.equalTo(44) }

        let termsButton = makeLegalLinkButton(title: "Terms of Use", alignment: .leading)
        let privacyButton = makeLegalLinkButton(title: "Privacy Policy", alignment: .trailing)
        let legalLinks = UIStackView(arrangedSubviews: [termsButton, privacyButton])
        legalLinks.axis = .horizontal
        legalLinks.distribution = .fillEqually
        card.addSubview(legalLinks)
        legalLinks.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(19)
            $0.bottom.equalTo(buttons.snp.top).offset(-10)
            $0.height.equalTo(22)
        }
        body.snp.makeConstraints {
            $0.bottom.equalTo(legalLinks.snp.top).offset(-8)
        }

        termsButton.addAction(UIAction { [weak self] _ in self?.openLegalPage(title: "Terms of Use") }, for: .touchUpInside)
        privacyButton.addAction(UIAction { [weak self] _ in self?.openLegalPage(title: "Privacy Policy") }, for: .touchUpInside)

        agree.addAction(UIAction { _ in
            DataRepository.shared.acceptEULA()
            AppRouter.showWelcome()
        }, for: .touchUpInside)
        cancel.addAction(UIAction { _ in exit(0) }, for: .touchUpInside)
    }

    private func makeLegalLinkButton(title: String, alignment: UIControl.ContentHorizontalAlignment) -> UIButton {
        let button = UIButton(type: .system)
        let attributedTitle = NSAttributedString(string: title, attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: AppTheme.ink,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ])
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.contentHorizontalAlignment = alignment
        return button
    }

    private func openLegalPage(title: String) {
        let legalPage = LegalWebViewController(title: title)
        let navigation = UINavigationController(rootViewController: legalPage)
        navigation.modalPresentationStyle = .fullScreen
        present(navigation, animated: true)
    }
}
