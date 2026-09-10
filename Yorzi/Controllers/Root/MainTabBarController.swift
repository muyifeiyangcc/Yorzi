import UIKit
import SnapKit

final class MainTabBarController: UITabBarController, UITabBarControllerDelegate, UINavigationControllerDelegate {
    private let repository = DataRepository.shared
    private var guestOverlay: UIControl?
    private let customTabBar = CustomTabBar()
    private var customTabBarBottomConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        delegate = self

        let tabs: [UIViewController] = [
            HomeViewController(),
            ExploreViewController(),
            PostViewController(),
            InboxViewController(),
            ProfileViewController()
        ]

        let navs = tabs.map { UINavigationController(rootViewController: $0) }
        viewControllers = navs
        // Track navigation pushes/pops so the custom bar hides on 2nd-level pages.
        navs.forEach { $0.delegate = self }

        // Hide the system tab bar entirely; we render our own floating bar.
        tabBar.isHidden = true
        tabBar.alpha = 0
        tabBar.isUserInteractionEnabled = false

        // Tab bar icons using SF Symbols
        let icons = ["house", "magnifyingglass", "paperplane", "bubble.left.and.bubble.right", "person"]
        customTabBar.configure(icons: icons) { [weak self] index in
            guard let self else { return }
            if self.repository.isGuest { self.showGuestGate(); return }
            self.selectedIndex = index
        }
        // Custom bar lives on the tab container view.
        view.addSubview(customTabBar)
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBarBottomConstraint = customTabBar.bottomAnchor.constraint(
            equalTo: view.safeAreaLayoutGuide.bottomAnchor,
            constant: view.safeAreaInsets.bottom == 0 ? 0 : -4
        )
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            customTabBarBottomConstraint!,
            customTabBar.heightAnchor.constraint(equalToConstant: 58)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(repositoryChanged), name: .repositoryDidChange, object: nil)
        refreshGuestOverlay()
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if repository.isGuest { showGuestGate(); return false }
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        syncTabBarVisibility(for: selectedViewController)
    }

    func selectTab(_ index: Int) {
        guard let controllers = viewControllers, controllers.indices.contains(index) else { return }
        if let navigationController = controllers[index] as? UINavigationController {
            navigationController.popToRootViewController(animated: false)
        }
        customTabBar.select(index)
    }

    // MARK: Navigation visibility

    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        // Root page => show bar; any pushed (2nd-level) page => hide bar.
        let isRoot = navigationController.viewControllers.first === viewController
        updateFloatingBar(hidden: !isRoot, animated: animated)
    }

    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        let isRoot = navigationController.viewControllers.first === viewController
        updateFloatingBar(hidden: !isRoot, animated: false)
    }

    private func syncTabBarVisibility(for controller: UIViewController?) {
        guard let nav = controller as? UINavigationController else { return }
        let isRoot = nav.viewControllers.count <= 1
        updateFloatingBar(hidden: !isRoot, animated: false)
    }

    private func updateFloatingBar(hidden: Bool, animated: Bool) {
        let transform = hidden ? CGAffineTransform(translationX: 0, y: 120) : .identity
        let animations = {
            self.customTabBar.transform = transform
            self.customTabBar.alpha = hidden ? 0 : 1
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut], animations: animations)
        } else {
            animations()
        }
        customTabBar.isUserInteractionEnabled = !hidden
    }

    @objc private func repositoryChanged() {
        viewControllers?.forEach { ($0 as? UINavigationController)?.viewControllers.first?.viewIfLoaded?.setNeedsLayout() }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        refreshGuestOverlay()
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Preserve the floating 4pt lift where a home-indicator inset exists,
        // but never place the bar below the screen on devices without one.
        customTabBarBottomConstraint?.constant = view.safeAreaInsets.bottom == 0 ? 0 : -4
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tabBar.isHidden = true
        tabBar.frame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 0)
    }

    private func refreshGuestOverlay() {
        guestOverlay?.removeFromSuperview()
        guard repository.isGuest else { return }
        let overlay = UIControl()
        overlay.backgroundColor = UIColor.clear
        overlay.addAction(UIAction { [weak self] _ in self?.showGuestGate() }, for: .touchUpInside)
        view.addSubview(overlay)
        overlay.snp.makeConstraints { $0.edges.equalToSuperview() }
        guestOverlay = overlay
    }

    private func showGuestGate() {
        let dialog = AppDialogView(title: "Sign In Required", message: "Please sign in to continue.", actions: [
            .init(title: "Cancel", style: .plain, handler: nil),
            .init(title: "Sign In", style: .accent) { AppRouter.showWelcome() }
        ])
        dialog.present(in: view)
    }
}

// MARK: - Custom floating tab bar

private final class CustomTabBar: UIView {
    private let stack = UIStackView()
    private var buttons: [UIButton] = []
    private var selectedIdx = 0
    private var onSelect: ((Int) -> Void)?

    func configure(icons: [String], onSelect: @escaping (Int) -> Void) {
        self.onSelect = onSelect
        backgroundColor = .white
        layer.cornerRadius = 22
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.06
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 8

        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (i, icon) in icons.enumerated() {
            let button = UIButton(type: .custom)
            button.setImage(UIImage(systemName: icon), for: .normal)
            button.tintColor = AppTheme.secondary
            button.imageView?.contentMode = .scaleAspectFit
            button.imageEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
            button.tag = i
            button.addAction(UIAction { [weak self] _ in self?.select(i) }, for: .touchUpInside)
            stack.addArrangedSubview(button)
            button.snp.makeConstraints { $0.size.equalTo(48) }
            buttons.append(button)
        }
        // Set the initial visual state without treating setup as a user tap.
        select(0, notify: false)
    }

    fileprivate func select(_ index: Int, notify: Bool = true) {
        selectedIdx = index
        for (i, button) in buttons.enumerated() {
            let selected = i == index
            button.tintColor = selected ? .white : AppTheme.secondary
            button.backgroundColor = selected ? AppTheme.lavender : .clear
            button.layer.cornerRadius = 16
            button.layer.masksToBounds = true
        }
        if notify { onSelect?(index) }
    }
}
