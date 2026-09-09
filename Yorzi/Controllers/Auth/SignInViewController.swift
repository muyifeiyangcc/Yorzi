import UIKit
import SnapKit

final class SignInViewController: BaseViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .white; scrollView.isHidden = true
        let back = AuthUI.backButton(target: self, action: #selector(goBack)); let heading = AuthUI.titleLabel("Welcome back"); let copy = AuthUI.subtitleLabel("Continue shaping thoughtful visual work.")
        let email = AuthFieldView(title: "Email", placeholder: "you@example.com", keyboardType: .emailAddress, textContentType: .username); let pass = AuthFieldView(title: "Password", placeholder: "At least 8 characters", secure: true, textContentType: .password); let forgot = AuthUI.linkButton("Forgot password?"); let button = AuthUI.primaryButton("Sign in")
        [back, heading, copy, email, pass, forgot, button].forEach(view.addSubview)
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(18); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(35) }; heading.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(34); $0.leading.trailing.equalToSuperview().inset(15) }; copy.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(15) }; email.snp.makeConstraints { $0.top.equalTo(copy.snp.bottom).offset(27); $0.leading.trailing.equalToSuperview().inset(15) }; pass.snp.makeConstraints { $0.top.equalTo(email.snp.bottom).offset(9); $0.leading.trailing.equalTo(email) }; forgot.snp.makeConstraints { $0.top.equalTo(pass.snp.bottom).offset(9); $0.trailing.equalTo(email); $0.height.equalTo(18) }; button.snp.makeConstraints { $0.leading.trailing.equalTo(email); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(34); $0.height.equalTo(51) }
        button.addAction(UIAction { [weak self] _ in guard let self else { return }; guard let value = email.textField.text, value.contains("@"), let password = pass.textField.text, password.count >= 8 else { showMessage(title: "Check your details", message: "Enter a valid email and password."); return }; guard DataRepository.shared.signIn(email: value, password: password) else { showMessage(title: "Unable to sign in", message: "Check your email and password.") ; return }; AppRouter.showTabs() }, for: .touchUpInside)
        forgot.addAction(UIAction { [weak self] _ in self?.push(PasswordResetViewController()) }, for: .touchUpInside)
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: animated) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: animated) }
    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}
