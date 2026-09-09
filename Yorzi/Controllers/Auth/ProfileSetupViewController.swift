import UIKit
import SnapKit
import PhotosUI

final class ProfileSetupViewController: BaseViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {

    private let registrationEmail: String?
    private let registrationPassword: String?
    init(email: String? = nil, password: String? = nil) {
        registrationEmail = email; registrationPassword = password
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { registrationEmail = nil; registrationPassword = nil; super.init(coder: coder) }

    private let avatarView = UIView()
    private let avatarImageView = UIImageView()
    private let cameraButton = UIButton(type: .custom)
    private let addPhotoLabel = UILabel()

    private let nicknameField = AuthFieldView(title: "Nickname", placeholder: "Your name or studio name")
    private let birthField = AuthFieldView(title: "Date of birth", placeholder: "Year / Month / Day")

    private let maleButton = UIButton(type: .system)
    private let femaleButton = UIButton(type: .system)
    private var selectedGender: String? = "Male"

    private let saveButton = AuthUI.primaryButton("Save")

    private let birthPicker = UIDatePicker()

    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        scrollView.isHidden = true
        navigationItem.title = nil
        setupUI()
        applyGenderSelection()
    }

    private func setupUI() {
        let back = AuthUI.backButton(target: self, action: #selector(goBack))
        let heading = AuthUI.titleLabel("Make it yours")
        let copy = AuthUI.subtitleLabel("Add a few details so creators can recognize\nyou and collaborate with confidence.")

        // Avatar placeholder
        avatarView.backgroundColor = UIColor(hex: 0xCFD8D6)
        avatarView.layer.cornerRadius = 60
        avatarView.layer.masksToBounds = true

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 60
        avatarImageView.layer.masksToBounds = true
        avatarView.addSubview(avatarImageView)
        avatarImageView.snp.makeConstraints { $0.edges.equalToSuperview() }

        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(showPhotoSheet))
        avatarView.addGestureRecognizer(avatarTap)
        avatarView.isUserInteractionEnabled = true

        // Camera badge
        cameraButton.backgroundColor = AppTheme.lavender
        cameraButton.layer.cornerRadius = 22
        cameraButton.layer.masksToBounds = true
        cameraButton.setImage(UIImage(named: "camera")?.withRenderingMode(.alwaysOriginal), for: .normal)
        cameraButton.imageView?.contentMode = .scaleAspectFit
        cameraButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        cameraButton.addTarget(self, action: #selector(showPhotoSheet), for: .touchUpInside)

        // Add profile photo label
        addPhotoLabel.text = "ADD PROFILE PHOTO"
        addPhotoLabel.font = .systemFont(ofSize: 12, weight: .medium)
        addPhotoLabel.textColor = AppTheme.muted
        addPhotoLabel.textAlignment = .center
        addPhotoLabel.setCharacterSpacing(2.5)

        // Gender buttons
        maleButton.setTitle("Male", for: .normal)
        maleButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        maleButton.layer.cornerRadius = 11
        maleButton.layer.masksToBounds = true
        maleButton.layer.borderWidth = 1
        maleButton.addTarget(self, action: #selector(selectMale), for: .touchUpInside)

        femaleButton.setTitle("Female", for: .normal)
        femaleButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        femaleButton.layer.cornerRadius = 11
        femaleButton.layer.masksToBounds = true
        femaleButton.layer.borderWidth = 1
        femaleButton.addTarget(self, action: #selector(selectFemale), for: .touchUpInside)

        let genderTitle = UILabel()
        genderTitle.text = "Gender"
        genderTitle.textColor = AuthUI.labelColor
        genderTitle.font = .systemFont(ofSize: 13, weight: .semibold)

        let genderRow = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        genderRow.axis = .horizontal
        genderRow.spacing = 9
        genderRow.distribution = .fillEqually
        maleButton.snp.makeConstraints { $0.height.equalTo(44) }
        femaleButton.snp.makeConstraints { $0.height.equalTo(44) }

        // Birth date picker – read-only field, 18+ only
        birthPicker.datePickerMode = .date
        birthPicker.preferredDatePickerStyle = .wheels
        birthPicker.maximumDate = Calendar.current.date(byAdding: .year, value: -18, to: Date())
        birthPicker.addTarget(self, action: #selector(birthChanged), for: .valueChanged)
        birthField.textField.inputView = birthPicker
        birthField.textField.tintColor = .clear
        birthField.textField.delegate = self
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(birthDone))
        let flex = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [flex, doneItem]
        birthField.textField.inputAccessoryView = toolbar

        // Save action
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

        // Layout
        [back, heading, copy, avatarView, cameraButton, addPhotoLabel, nicknameField, birthField, genderTitle, genderRow, saveButton].forEach(view.addSubview)

        back.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(18); $0.leading.equalToSuperview().offset(15); $0.size.equalTo(35) }
        heading.snp.makeConstraints { $0.top.equalTo(back.snp.bottom).offset(34); $0.leading.trailing.equalToSuperview().inset(15) }
        copy.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(15) }
        avatarView.snp.makeConstraints { $0.top.equalTo(copy.snp.bottom).offset(30); $0.centerX.equalToSuperview(); $0.width.height.equalTo(120) }
        cameraButton.snp.makeConstraints { $0.width.height.equalTo(44); $0.trailing.equalTo(avatarView.snp.trailing).offset(4); $0.bottom.equalTo(avatarView.snp.bottom).offset(4) }
        addPhotoLabel.snp.makeConstraints { $0.top.equalTo(avatarView.snp.bottom).offset(14); $0.centerX.equalToSuperview() }
        nicknameField.snp.makeConstraints { $0.top.equalTo(addPhotoLabel.snp.bottom).offset(28); $0.leading.trailing.equalToSuperview().inset(15) }
        birthField.snp.makeConstraints { $0.top.equalTo(nicknameField.snp.bottom).offset(9); $0.leading.trailing.equalToSuperview().inset(15) }
        genderTitle.snp.makeConstraints { $0.top.equalTo(birthField.snp.bottom).offset(18); $0.leading.trailing.equalToSuperview().inset(15) }
        genderRow.snp.makeConstraints { $0.top.equalTo(genderTitle.snp.bottom).offset(6); $0.leading.trailing.equalToSuperview().inset(15) }
        saveButton.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(15); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(34); $0.height.equalTo(51) }
    }

    // MARK: - Gender

    @objc private func selectMale() { selectedGender = "Male"; applyGenderSelection() }
    @objc private func selectFemale() { selectedGender = "Female"; applyGenderSelection() }

    private func applyGenderSelection() {
        configureGenderButton(maleButton, selected: selectedGender == "Male")
        configureGenderButton(femaleButton, selected: selectedGender == "Female")
    }

    private func configureGenderButton(_ button: UIButton, selected: Bool) {
        if selected {
            button.backgroundColor = AuthUI.buttonColor
            button.layer.borderColor = AuthUI.buttonColor.cgColor
            button.setTitleColor(.white, for: .normal)
        } else {
            button.backgroundColor = .white
            button.layer.borderColor = AuthUI.fieldBorderColor.cgColor
            button.setTitleColor(AuthUI.subtitleColor, for: .normal)
        }
    }

    // MARK: - Birth date

    @objc private func birthChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy / MM / dd"
        birthField.textField.text = formatter.string(from: birthPicker.date)
    }

    @objc private func birthDone() {
        birthChanged()
        view.endEditing(true)
    }

    // MARK: - Photo sheet

    @objc private func showPhotoSheet() {
        let sheet = PhotoActionSheet { [weak self] action in
            switch action {
            case .photoLibrary: self?.presentPhotoLibrary()
            case .camera: self?.presentCamera()
            case .cancel: break
            }
        }
        sheet.present(in: view.window ?? view)
    }

    private func presentPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func presentCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    // MARK: - Delegates

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            avatarImageView.image = image
            addPhotoLabel.isHidden = true
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }
        item.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
                self?.addPhotoLabel.isHidden = true
            }
        }
    }

    // MARK: - Save

    @objc private func saveTapped() {
        let nickname = nicknameField.textField.text ?? ""
        guard !nickname.trimmingCharacters(in: .whitespaces).isEmpty else {
            showMessage(title: "Add a nickname", message: "Please enter your name or studio name.")
            return
        }
        if let registrationEmail, let registrationPassword {
            DataRepository.shared.completeRegistration(email: registrationEmail, password: registrationPassword, name: nickname, gender: selectedGender, birthDate: birthField.textField.text, avatar: avatarImageView.image)
        } else { DataRepository.shared.updateCurrentProfile(
            name: nickname,
            gender: selectedGender,
            birthDate: birthField.textField.text,
            avatar: avatarImageView.image
        ) }
        AppRouter.showTabs()
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }

    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); navigationController?.setNavigationBarHidden(true, animated: animated) }
    override func viewWillDisappear(_ animated: Bool) { super.viewWillDisappear(animated); navigationController?.setNavigationBarHidden(false, animated: animated) }
}

// MARK: - TextField delegate (birth field read-only)

extension ProfileSetupViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return false
    }
}

// MARK: - Photo action bottom sheet

private final class PhotoActionSheet: UIView {
    enum Action { case photoLibrary, camera, cancel }

    private let onSelect: (Action) -> Void

    init(onSelect: @escaping (Action) -> Void) {
        self.onSelect = onSelect
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.25)

        let sheet = UIView()
        sheet.backgroundColor = .white
        sheet.layer.cornerRadius = 20
        sheet.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        sheet.layer.masksToBounds = true
        addSubview(sheet)
        sheet.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(58 * 3 + 24) }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.distribution = .fillEqually
        sheet.addSubview(stack)
        stack.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(12); $0.bottom.equalToSuperview().inset(12) }

        let libraryBtn = makeButton("Choose from Photos")
        libraryBtn.addAction(UIAction { [weak self] _ in self?.dismiss(); self?.onSelect(.photoLibrary) }, for: .touchUpInside)
        let cameraBtn = makeButton("Take Photo")
        cameraBtn.addAction(UIAction { [weak self] _ in self?.dismiss(); self?.onSelect(.camera) }, for: .touchUpInside)
        let cancelBtn = makeButton("Cancel")
        cancelBtn.addAction(UIAction { [weak self] _ in self?.dismiss(); self?.onSelect(.cancel) }, for: .touchUpInside)

        stack.addArrangedSubview(libraryBtn)
        stack.addArrangedSubview(cameraBtn)
        stack.addArrangedSubview(cancelBtn)

        // Tap outside to dismiss
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissSheet))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { nil }

    private func makeButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(AuthUI.titleColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
        button.backgroundColor = .white
        return button
    }

    func present(in host: UIView) {
        frame = host.bounds
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
        host.addSubview(self)
    }

    @objc private func dismissSheet() { removeFromSuperview() }
    private func dismiss() { removeFromSuperview() }
}

private extension UILabel {
    func setCharacterSpacing(_ spacing: CGFloat) {
        guard let text else { return }
        let attr = NSMutableAttributedString(string: text)
        attr.addAttribute(.kern, value: spacing, range: NSRange(location: 0, length: attr.length))
        attributedText = attr
    }
}
