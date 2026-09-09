import UIKit
import SnapKit
import StoreKit

final class RechargeViewController: BaseViewController {
    private let balanceLabel = UILabel.appLabel(size: 30, weight: .semibold, color: .white)
    private let packageStack = UIStackView()
    private let loading = UIActivityIndicatorView(style: .medium)
    private let loadingLabel = UILabel.appLabel("Loading packages…", size: 13, color: AppTheme.secondary)
    private let rechargeButton = UIButton.primary("Recharge")
    private var selectedProduct: SKProduct?
    private var packageCards: [String: UIControl] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .white
        buildPage(); loadProducts()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.updateBalance() }
    }

    private func buildPage() {
        let back = UIButton(type: .system)
        back.setImage(UIImage(named: "back")?.withRenderingMode(.alwaysOriginal) ?? UIImage(systemName: "chevron.left"), for: .normal)
        back.backgroundColor = .white; back.layer.borderWidth = 1; back.layer.borderColor = AppTheme.divider.cgColor; back.layer.cornerRadius = 20
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back); back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(40) }
        let title = UILabel(); title.text = "Recharge"; title.font = UIFont(name: "Georgia", size: 24) ?? .systemFont(ofSize: 24); title.textColor = AppTheme.ink; view.addSubview(title); title.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(8); $0.centerY.equalTo(back) }
        rechargeButton.isEnabled = false
        rechargeButton.addAction(UIAction { [weak self] _ in self?.rechargeSelectedPackage() }, for: .touchUpInside)
        view.addSubview(rechargeButton)
        rechargeButton.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(12); $0.height.equalTo(51) }
        scrollView.backgroundColor = .white; scrollView.snp.remakeConstraints { $0.top.equalTo(back.snp.bottom).offset(14); $0.leading.trailing.equalTo(view.safeAreaLayoutGuide); $0.bottom.equalTo(rechargeButton.snp.top).offset(-12) }; contentView.snp.remakeConstraints { $0.edges.equalTo(scrollView.contentLayoutGuide); $0.width.equalTo(scrollView.frameLayoutGuide) }
        let stack = UIStackView(); stack.axis = .vertical; stack.spacing = 22; contentView.addSubview(stack); stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalToSuperview().inset(24) }
        stack.addArrangedSubview(balanceCard()); stack.addArrangedSubview(UILabel.appLabel("Choose a package", size: 20)); packageStack.axis = .vertical; packageStack.spacing = 10; stack.addArrangedSubview(packageStack)
    }

    private func balanceCard() -> UIView {
        let card = UIView(); card.layer.cornerRadius = 22; card.clipsToBounds = true; let bg = UIImageView(image: UIImage(named: "coin_bg")); bg.contentMode = .scaleAspectFill; card.addSubview(bg); bg.snp.makeConstraints { $0.edges.equalToSuperview() }
        let caption = UILabel.appLabel("Current platform balance", size: 11, color: .white); let unit = UILabel.appLabel("PLATFORM COINS", size: 9, color: UIColor.white.withAlphaComponent(0.75)); card.addSubview(caption); card.addSubview(balanceLabel); card.addSubview(unit); caption.snp.makeConstraints { $0.top.leading.equalToSuperview().inset(22) }; balanceLabel.snp.makeConstraints { $0.leading.equalTo(caption); $0.top.equalTo(caption.snp.bottom).offset(4) }; unit.snp.makeConstraints { $0.leading.equalTo(caption); $0.top.equalTo(balanceLabel.snp.bottom).offset(1) }
        let coins = UIImageView(image: UIImage(named: "coin")); coins.contentMode = .scaleAspectFit; card.addSubview(coins); coins.snp.makeConstraints { $0.trailing.equalToSuperview().inset(10); $0.centerY.equalToSuperview(); $0.width.equalTo(150); $0.height.equalTo(110) }; card.snp.makeConstraints { $0.height.equalTo(104) }; updateBalance(); return card
    }

    private func updateBalance() { balanceLabel.text = "\(DataRepository.shared.balance)" }

    private func loadProducts() {
        selectedProduct = nil
        rechargeButton.isEnabled = false
        packageCards.removeAll()
        loading.startAnimating(); packageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let loadingRow = UIStackView(arrangedSubviews: [loading, loadingLabel]); loadingRow.axis = .horizontal; loadingRow.alignment = .center; loadingRow.spacing = 8
        packageStack.addArrangedSubview(loadingRow)
        PurchaseManager.shared.loadProducts { [weak self] products in DispatchQueue.main.async { self?.render(products: products) } }
    }

    private func render(products: [SKProduct]) {
        loading.stopAnimating(); packageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; packageCards.removeAll(); let ordered = products.sorted { (PurchaseManager.shared.productIDs.firstIndex(of: $0.productIdentifier) ?? 0) < (PurchaseManager.shared.productIDs.firstIndex(of: $1.productIdentifier) ?? 0) }; guard !ordered.isEmpty else { packageStack.addArrangedSubview(UILabel.appLabel("No packages are available right now.", size: 13, color: AppTheme.secondary)); return }
        var row: UIStackView?
        for (index, product) in ordered.enumerated() { if index % 2 == 0 { row = UIStackView(); row?.axis = .horizontal; row?.spacing = 8; row?.distribution = .fillEqually; packageStack.addArrangedSubview(row!) }; let card = packageCard(amount: PurchaseManager.shared.coins(for: product.productIdentifier), price: product.price.doubleValue); packageCards[product.productIdentifier] = card; card.addAction(UIAction { [weak self] _ in self?.select(product) }, for: .touchUpInside); row?.addArrangedSubview(card) }
    }

    private func select(_ product: SKProduct) {
        selectedProduct = product
        rechargeButton.isEnabled = true
        packageCards.forEach { productID, card in
            let selected = productID == product.productIdentifier
            card.layer.borderWidth = selected ? 3 : 1.5
            card.layer.borderColor = AppTheme.lavender.cgColor
        }
    }

    private func packageCard(amount: Int, price: Double) -> UIControl {
        let card = UIControl(); card.backgroundColor = UIColor(hex: 0x202A63); card.layer.borderWidth = 1.5; card.layer.borderColor = AppTheme.lavender.cgColor; card.layer.cornerRadius = 12; card.clipsToBounds = true; card.snp.makeConstraints { $0.height.equalTo(118) }
        let bg = UIImageView(image: UIImage(named: "coin_value_bg ")); bg.contentMode = .scaleAspectFill; bg.alpha = 0.8; card.addSubview(bg); bg.snp.makeConstraints { $0.edges.equalToSuperview() }; let coin = UIImageView(image: UIImage(named: "coin")); coin.contentMode = .scaleAspectFit; card.addSubview(coin); coin.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalToSuperview().offset(5); $0.width.equalTo(80); $0.height.equalTo(60) }
        let amountLabel = UILabel.appLabel("\(amount) coins", size: 15, color: .white); amountLabel.textAlignment = .center; card.addSubview(amountLabel); amountLabel.snp.makeConstraints { $0.top.equalTo(coin.snp.bottom); $0.centerX.equalToSuperview() }; let priceLabel = UILabel.appLabel("$\(String(format: "%.2f", price))", size: 12, color: .white); priceLabel.textAlignment = .center; priceLabel.backgroundColor = UIColor.white.withAlphaComponent(0.2); priceLabel.layer.cornerRadius = 10; priceLabel.clipsToBounds = true; card.addSubview(priceLabel); priceLabel.snp.makeConstraints { $0.top.equalTo(amountLabel.snp.bottom).offset(4); $0.centerX.equalToSuperview(); $0.width.equalTo(52); $0.height.equalTo(20) }; return card
    }

    private func rechargeSelectedPackage() {
        guard let selectedProduct else {
            showMessage(title: "Choose a package", message: "Select a coin package to continue.")
            return
        }
        purchase(selectedProduct)
    }

    private func purchase(_ product: SKProduct) {
        let overlay = UIView(); overlay.backgroundColor = UIColor.black.withAlphaComponent(0.12); let spinner = UIActivityIndicatorView(style: .large); spinner.startAnimating(); overlay.addSubview(spinner); spinner.snp.makeConstraints { $0.center.equalToSuperview() }; overlay.frame = view.bounds; overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]; view.addSubview(overlay)
        PurchaseManager.shared.buy(product) { [weak self, weak overlay] success in DispatchQueue.main.async { overlay?.removeFromSuperview(); if success { self?.updateBalance(); self?.showMessage(title: "Purchase successful", message: "Coins have been added to your balance.") } else { self?.showMessage(title: "Purchase failed", message: "Please try again later.") } } }
    }
}
