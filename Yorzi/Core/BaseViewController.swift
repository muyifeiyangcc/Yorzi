import UIKit
import SnapKit

class BaseViewController: UIViewController {
    let scrollView = UIScrollView()
    let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        navigationItem.backButtonDisplayMode = .minimal
        navigationController?.navigationBar.tintColor = AppTheme.ink
        navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: AppTheme.ink]
        configureScrollableCanvas()
    }

    func configureScrollableCanvas() {
        view.addSubview(scrollView)
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.addSubview(contentView)
        scrollView.snp.makeConstraints { $0.edges.equalTo(view.safeAreaLayoutGuide) }
        contentView.snp.makeConstraints {
            $0.edges.equalTo(scrollView.contentLayoutGuide)
            $0.width.equalTo(scrollView.frameLayoutGuide)
            $0.height.greaterThanOrEqualTo(scrollView.frameLayoutGuide).priority(.low)
        }
    }

    func showMessage(title: String, message: String, action: String = "OK", completion: (() -> Void)? = nil) {
        let overlay = AppDialogView(title: title, message: message, actions: [
            .init(title: action, style: .accent, handler: completion)
        ])
        overlay.present(in: view.window ?? view)
    }

    func push(_ controller: UIViewController) {
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }

    func blockUserAndReturnToRoot(_ userID: UUID) {
        DataRepository.shared.block(userID)
        if let navigationController {
            navigationController.popToRootViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        }
    }
}

final class FormField: UIView, UITextViewDelegate {
    let titleLabel = UILabel.appLabel(size: 12, weight: .medium)
    let textField = UITextField()
    let textView = UITextView()
    private let placeholderLabel = UILabel.appLabel(size: 14, color: AppTheme.muted)
    private let multiline: Bool

    var text: String { multiline ? textView.text : (textField.text ?? "") }

    init(title: String, placeholder: String, secure: Bool = false, multiline: Bool = false, multilineHeight: CGFloat = 96) {
        self.multiline = multiline
        super.init(frame: .zero)
        titleLabel.text = title
        textField.placeholder = placeholder
        textField.isSecureTextEntry = secure
        textField.font = .systemFont(ofSize: 14)
        textField.textColor = AppTheme.ink
        textField.backgroundColor = .white
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppTheme.divider.cgColor
        textField.round(8)
        textField.setLeftPadding(12)
        textView.font = .systemFont(ofSize: 14)
        textView.textColor = AppTheme.ink
        textView.backgroundColor = .white
        textView.layer.borderWidth = 1
        textView.layer.borderColor = AppTheme.divider.cgColor
        textView.round(8)
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        textView.delegate = self
        placeholderLabel.text = placeholder
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }
        if multiline {
            addSubview(textView)
            textView.addSubview(placeholderLabel)
            textView.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(8)
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(multilineHeight)
            }
            placeholderLabel.snp.makeConstraints { $0.top.equalToSuperview().offset(12); $0.leading.equalToSuperview().offset(14); $0.trailing.lessThanOrEqualToSuperview().inset(14) }
            textField.isHidden = true
        } else {
            addSubview(textField)
            textField.snp.makeConstraints {
                $0.top.equalTo(titleLabel.snp.bottom).offset(8)
                $0.leading.trailing.bottom.equalToSuperview()
                $0.height.equalTo(48)
            }
            textView.isHidden = true
        }
    }

    required init?(coder: NSCoder) { nil }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.isEmpty
    }
}

extension UITextField {
    func setLeftPadding(_ amount: CGFloat) {
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: 1))
        leftView = padding
        leftViewMode = .always
    }
}
