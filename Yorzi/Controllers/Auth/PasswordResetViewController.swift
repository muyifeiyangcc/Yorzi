import UIKit
import SnapKit

final class PasswordResetViewController: BaseViewController {
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .white; scrollView.isHidden = true
        let back = AuthUI.backButton(target: self, action: #selector(goBack)); let heading = AuthUI.titleLabel("Create a new\npassword"); let copy = AuthUI.subtitleLabel("Enter your email and choose a secure\npassword for your Atelier account.")
        let email = AuthFieldView(title: "Email", placeholder: "you@example.com", keyboardType: .emailAddress, textContentType: .username); let pass = AuthFieldView(title: "New password", placeholder: "At least 8 characters", secure: true, textContentType: .newPassword); let confirm = AuthFieldView(title: "Confirm new password", placeholder: "Re-enter your new password", secure: true, textContentType: .newPassword); let button = AuthUI.primaryButton("Save")
        [back, heading, copy, email, pass, confirm, button].forEach(view.addSubview)
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(18); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(35) }; heading.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(34); $0.leading.trailing.equalToSuperview().inset(15) }; copy.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(12); $0.leading.trailing.equalToSuperview().inset(15) }; email.snp.makeConstraints { $0.top.equalTo(copy.snp.bottom).offset(27); $0.leading.trailing.equalToSuperview().inset(15) }; pass.snp.makeConstraints { $0.top.equalTo(email.snp.bottom).offset(9); $0.leading.trailing.equalTo(email) }; confirm.snp.makeConstraints { $0.top.equalTo(pass.snp.bottom).offset(9); $0.leading.trailing.equalTo(email) }; button.snp.makeConstraints { $0.leading.trailing.equalTo(email); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(34); $0.height.equalTo(51) }
        button.addAction(UIAction { [weak self] _ in guard let self else { return }; guard let address = email.textField.text, address.contains("@"), let password = pass.textField.text, password.count >= 8, password == confirm.textField.text else { showMessage(title: "Check your details", message: "Enter a valid email and matching password."); return }; guard DataRepository.shared.resetPassword(email: address, password: password) else { showMessage(title: "Unable to update password", message: "Use the email linked to your account."); return }; showMessage(title: "Password updated", message: "You can now sign in.") }, for: .touchUpInside)
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: animated) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: animated) }
    @objc private func goBack() { navigationController?.popViewController(animated: true) }
}
