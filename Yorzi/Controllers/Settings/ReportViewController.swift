import UIKit
import SnapKit

final class ReportViewController: BaseViewController {
    private let targetID: UUID
    private let options = [
        "Spam or scam",
        "Harassment or bullying",
        "Hate speech",
        "Nudity or sexual content",
        "Dangerous activity",
        "False water or safety information",
        "Other"
    ]
    private var selectedIndex = -1

    init(targetID: UUID) {
        self.targetID = targetID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

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
        title.text = "Report"
        title.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.centerY.equalTo(back); $0.leading.equalTo(back.snp.trailing).offset(14) }
    }

    private func setupContent() {
        let heading = UILabel()
        heading.text = "Why are you reporting this?"
        heading.font = .systemFont(ofSize: 22, weight: .bold)
        heading.textColor = AppTheme.ink
        heading.numberOfLines = 0
        view.addSubview(heading)
        heading.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(68); $0.leading.trailing.equalToSuperview().inset(20) }

        let subtitle = UILabel()
        subtitle.text = "Your report is confidential. Select the reason that best describes the issue."
        subtitle.font = .systemFont(ofSize: 14, weight: .regular)
        subtitle.textColor = AppTheme.secondary
        subtitle.numberOfLines = 0
        view.addSubview(subtitle)
        subtitle.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview().inset(20) }

        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        card.layer.borderWidth = 1
        card.layer.borderColor = AppTheme.divider.cgColor
        view.addSubview(card)
        card.snp.makeConstraints { $0.top.equalTo(subtitle.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(15) }

        let stack = UIStackView()
        stack.axis = .vertical
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }

        for (i, option) in options.enumerated() {
            let row = makeOptionRow(option, index: i)
            stack.addArrangedSubview(row)
            row.snp.makeConstraints { $0.height.equalTo(52) }
            if i < options.count - 1 {
                let divider = UIView()
                divider.backgroundColor = AppTheme.divider
                row.addSubview(divider)
                divider.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 18)); $0.height.equalTo(1) }
            }
        }

        let reportButton = UIButton(type: .system)
        reportButton.setTitle("Report", for: .normal)
        reportButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        reportButton.setTitleColor(.white, for: .normal)
        reportButton.backgroundColor = AppTheme.ink
        reportButton.layer.cornerRadius = 16
        reportButton.layer.masksToBounds = true
        reportButton.addAction(UIAction { [weak self] _ in self?.submit() }, for: .touchUpInside)
        view.addSubview(reportButton)
        reportButton.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(20); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16); $0.height.equalTo(56) }
    }

    private func makeOptionRow(_ title: String, index: Int) -> UIControl {
        let row = UIControl()
        row.tag = index
        row.addAction(UIAction { [weak self] _ in self?.select(index) }, for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = AppTheme.ink
        label.tag = 100
        row.addSubview(label)
        label.snp.makeConstraints { $0.leading.equalToSuperview().offset(18); $0.centerY.equalToSuperview() }

        let radio = UIImageView()
        radio.tag = 101
        radio.contentMode = .scaleAspectFit
        radio.tintColor = AppTheme.muted
        radio.image = UIImage(systemName: "circle")
        row.addSubview(radio)
        radio.snp.makeConstraints { $0.trailing.equalToSuperview().inset(18); $0.centerY.equalToSuperview(); $0.size.equalTo(22) }

        return row
    }

    private func select(_ index: Int) {
        selectedIndex = index
        refreshRadios()
    }

    private func refreshRadios() {
        func walk(_ view: UIView) {
            if let row = view as? UIControl, options.indices.contains(row.tag),
               let radio = row.viewWithTag(101) as? UIImageView {
                let selected = row.tag == selectedIndex
                radio.image = UIImage(systemName: selected ? "record.circle.fill" : "circle")
                radio.tintColor = selected ? AppTheme.ink : AppTheme.muted
            }
            view.subviews.forEach(walk)
        }
        view.subviews.forEach(walk)
    }

    private func submit() {
        guard selectedIndex >= 0 else {
            let d = AppDialogView(title: "Select a reason", message: "Please choose a reason for your report.", actions: [.init(title: "OK", style: .plain, handler: nil)])
            d.present(in: view)
            return
        }
        DataRepository.shared.report(targetID, reason: options[selectedIndex])
        let d = AppDialogView(title: "Report submitted", message: "Thanks for helping keep Yorzi thoughtful.", actions: [
            .init(title: "Done", style: .accent) { [weak self] in self?.navigationController?.popViewController(animated: true) }
        ])
        d.present(in: view)
    }
}
