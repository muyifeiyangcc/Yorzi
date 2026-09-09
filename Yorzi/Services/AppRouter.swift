import UIKit

enum AppRouter {
    static func root(for window: UIWindow) {
        let repository = DataRepository.shared
        if repository.eulaAccepted {
            window.rootViewController = UINavigationController(rootViewController: repository.isSignedIn || repository.isGuest ? MainTabBarController() : WelcomeViewController())
        } else {
            let navigation = UINavigationController(rootViewController: WelcomeViewController())
            window.rootViewController = navigation
            window.makeKeyAndVisible()
            DispatchQueue.main.async {
                let eula = EULAViewController()
                eula.modalPresentationStyle = .overFullScreen
                navigation.present(eula, animated: false)
            }
            return
        }
        window.makeKeyAndVisible()
    }
    static func showWelcome() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = scene.windows.first else { return }
        window.rootViewController = UINavigationController(rootViewController: WelcomeViewController()); window.makeKeyAndVisible()
    }
    static func showTabs() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene, let window = scene.windows.first else { return }
        window.rootViewController = UINavigationController(rootViewController: MainTabBarController()); window.makeKeyAndVisible()
    }
}
