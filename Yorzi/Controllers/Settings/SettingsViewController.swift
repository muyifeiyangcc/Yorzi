import UIKit
import SnapKit

final class SettingsViewController: BaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNav()
        setupContent()
    }

    private func setupNav() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppTheme.ink
        back.backgroundColor = .white
        back.layer.cornerRadius = 22
        back.layer.masksToBounds = true
        back.layer.borderWidth = 1
        back.layer.borderColor = AppTheme.divider.cgColor
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(6); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(44) }

        let title = UILabel()
        title.text = "Settings"
        title.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.centerY.equalTo(back); $0.leading.equalTo(back.snp.trailing).offset(14) }
    }

    private func setupContent() {
        let group1 = makeGroup([
            makeRow("Block List") { [weak self] in self?.openBlockList() },
            makeRow("Privacy Policy") { [weak self] in self?.openPrivacy() },
            makeRow("Terms of Service") { [weak self] in self?.openTerms() }
        ])
        let group2 = makeGroup([
            makeRow("Log Out") { [weak self] in self?.confirmLogout() },
            makeRow("Delete Account", destructive: true) { [weak self] in self?.confirmDelete() }
        ])

        view.addSubview(group1)
        group1.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(68); $0.leading.trailing.equalToSuperview().inset(15) }

        view.addSubview(group2)
        group2.snp.makeConstraints { $0.top.equalTo(group1.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(15) }
    }

    private func makeGroup(_ rows: [UIView]) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = AppTheme.divider.cgColor

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (i, row) in rows.enumerated() {
            stack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(56) }
            if i < rows.count - 1 {
                let divider = UIView()
                divider.backgroundColor = AppTheme.divider
                row.addSubview(divider)
                divider.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)); $0.height.equalTo(1) }
            }
        }
        return card
    }

    private func makeRow(_ title: String, destructive: Bool = false, onTap: @escaping () -> Void) -> UIControl {
        let row = UIControl()
        row.addAction(UIAction { _ in onTap() }, for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = destructive ? AppTheme.destructive : AppTheme.ink
        row.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(18); $0.centerY.equalToSuperview() }

        if !destructive {
            let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
            chevron.tintColor = AppTheme.muted
            chevron.contentMode = .scaleAspectFit
            row.addSubview(chevron)
            chevron.snp.makeConstraints { $0.trailing.equalToSuperview().inset(18); $0.centerY.equalToSuperview(); $0.size.equalTo(16) }
        }
        return row
    }

    @objc private func openBlockList() { push(BlockListViewController()) }
    @objc private func openPrivacy() { push(LegalWebViewController(title: "Privacy Policy")) }
    @objc private func openTerms() { push(LegalWebViewController(title: "Terms of Service")) }

    @objc private func confirmLogout() {
        let d = AppDialogView(title: "Sign Out", message: "Are you sure you want to sign out?", actions: [
            .init(title: "Cancel", style: .plain, handler: nil),
            .init(title: "Sign Out", style: .accent) { DataRepository.shared.signOut(); AppRouter.showWelcome() }
        ])
        d.present(in: view)
    }

    @objc private func confirmDelete() {
        let d = AppDialogView(title: "Delete Account", message: "This cannot be recovered.", actions: [
            .init(title: "Cancel", style: .plain, handler: nil),
            .init(title: "Delete", style: .destructive) { DataRepository.shared.deleteAccount(); AppRouter.showWelcome() }
        ])
        d.present(in: view)
    }
}
