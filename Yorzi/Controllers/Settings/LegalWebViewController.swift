import UIKit
import WebKit
import SnapKit

final class LegalWebViewController: BaseViewController {
    init(title: String) { super.init(nibName: nil, bundle: nil); self.title = title }; required init?(coder: NSCoder) { nil }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppTheme.ink
        back.backgroundColor = .white
        back.layer.cornerRadius = 20
        back.layer.masksToBounds = true
        back.layer.borderWidth = 1
        back.layer.borderColor = AppTheme.divider.cgColor
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        view.addSubview(back)
        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(8); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(40) }

        let webView = WKWebView()
        contentView.addSubview(webView)
        webView.snp.makeConstraints { $0.top.equalToSuperview().offset(56); $0.leading.trailing.bottom.equalToSuperview() }
        if let url = URL(string: "https://www.baidu.com") { webView.load(URLRequest(url: url)) }
    }
}
