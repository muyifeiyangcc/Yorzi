import UIKit
import SnapKit

final class WelcomeViewController: BaseViewController, UITextViewDelegate {
    private let agreement = UISwitch()
    private let agreementButton = UIButton(type: .system)

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.isHidden = true
        view.backgroundColor = UIColor(hex: 0x101B34)
        agreement.isOn = false

        let backgroundView = UIImageView(image: UIImage(named: "login_bg"))
        backgroundView.contentMode = .scaleAspectFill
        view.insertSubview(backgroundView, at: 0)
        backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let newButton = makePillButton(title: "I’m New")
        let emailButton = makePillButton(title: "Sign In By Email")
        let signUpButton = makeSignUpButton()
        let legalTextView = makeLegalTextView()
        configureAgreementButton()

        let agreementRow = UIStackView(arrangedSubviews: [agreementButton, legalTextView])
        agreementRow.axis = .horizontal
        agreementRow.alignment = .center
        agreementRow.spacing = 6

        view.addSubview(newButton)
        view.addSubview(emailButton)
        view.addSubview(signUpButton)
        view.addSubview(agreementRow)

        [newButton, emailButton].forEach { button in
            button.snp.makeConstraints {
                $0.centerX.equalToSuperview()
                $0.width.equalTo(285)
                $0.height.equalTo(44)
            }
        }
        agreementButton.snp.makeConstraints {
            $0.width.height.equalTo(12)
        }
        legalTextView.snp.makeConstraints {
            $0.width.equalTo(252)
            // Keep enough room for the legal copy to wrap on compact-width devices.
            $0.height.equalTo(48)
        }
        agreementRow.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            // Keep the complete agreement row inside the safe area so it is not
            // clipped by the home indicator on devices with a shorter viewport.
            $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(10)
        }
        signUpButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalTo(18)
            $0.bottom.equalTo(agreementRow.snp.top).offset(-9)
        }
        emailButton.snp.makeConstraints {
            $0.bottom.equalTo(signUpButton.snp.top).offset(-17)
        }
        newButton.snp.makeConstraints {
            $0.bottom.equalTo(emailButton.snp.top).offset(-21)
        }

        newButton.addAction(UIAction { _ in DataRepository.shared.enterGuest(); AppRouter.showTabs() }, for: .touchUpInside)
        emailButton.addAction(UIAction { [weak self] _ in self?.showEmailPath() }, for: .touchUpInside)
        signUpButton.addAction(UIAction { [weak self] _ in self?.push(SignUpViewController()) }, for: .touchUpInside)
    }

    private func showEmailPath() {
        guard agreement.isOn else { let dialog = AppDialogView(title: "Agreement required", message: "Please accept the agreements before signing in.", actions: [.init(title: "OK", style: .accent, handler: nil)]); dialog.present(in: view); return }; push(SignInViewController())
    }

    private func makePillButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setTitle(title, for: .normal)
        button.setTitleColor(UIColor(hex: 0x222222), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        button.layer.cornerRadius = 22
        button.layer.masksToBounds = true
        return button
    }

    private func makeSignUpButton() -> UIButton {
        let button = UIButton(type: .system)
        let text = "Don't have an account? Sign up"
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.white
        ])
        let signUpRange = (text as NSString).range(of: "Sign up")
        attributed.addAttributes([
            .foregroundColor: UIColor(hex: 0xB4B8FF),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ], range: signUpRange)
        button.setAttributedTitle(attributed, for: .normal)
        button.contentEdgeInsets = .zero
        return button
    }

    private func makeLegalTextView() -> UITextView {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.linkTextAttributes = [
            .foregroundColor: UIColor(hex: 0xB4B8FF),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        let text = "By continuing, you agree to our Terms of Service and\nPrivacy Policy"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineSpacing = 1
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: UIColor.white,
            .paragraphStyle: paragraph
        ])
        attributed.addAttribute(.link, value: "yorzi://terms", range: (text as NSString).range(of: "Terms of Service"))
        attributed.addAttribute(.link, value: "yorzi://privacy", range: (text as NSString).range(of: "Privacy Policy"))
        textView.attributedText = attributed
        return textView
    }

    private func configureAgreementButton() {
        agreementButton.tintColor = .white
        agreementButton.contentEdgeInsets = .zero
        agreementButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            agreement.isOn.toggle()
            updateAgreementButton()
        }, for: .touchUpInside)
        updateAgreementButton()
    }

    private func updateAgreementButton() {
        let symbolName = agreement.isOn ? "checkmark.circle.fill" : "circle"
        let configuration = UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)
        agreementButton.setImage(UIImage(systemName: symbolName, withConfiguration: configuration), for: .normal)
    }

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.absoluteString.contains("privacy") {
            push(LegalWebViewController(title: "Privacy Policy"))
        } else {
            push(LegalWebViewController(title: "Terms of Service"))
        }
        return false
    }
}
