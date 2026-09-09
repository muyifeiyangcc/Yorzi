import UIKit
import SnapKit
import PhotosUI

final class EditProfileViewController: BaseViewController {
    private let avatarView = UIImageView()
    private let cameraButton = UIButton(type: .system)
    private let nicknameField = UITextField()
    private let bioTextView = UITextView()
    private let bioPlaceholder = UILabel()
    private var selectedAvatar: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupNav()
        setupContent()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.loadUser() }
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
        title.text = "Profile"
        title.font = UIFont(name: "Georgia-Bold", size: 28) ?? .systemFont(ofSize: 28, weight: .bold)
        title.textColor = AppTheme.ink
        view.addSubview(title)
        title.snp.makeConstraints { $0.centerY.equalTo(back); $0.leading.equalTo(back.snp.trailing).offset(14) }
    }

    private func setupContent() {
        // Avatar
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 60
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = UIColor(hex: 0xE0E0E8)
        avatarView.isUserInteractionEnabled = true
        avatarView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changePhoto)))
        view.addSubview(avatarView)
        avatarView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(60); $0.centerX.equalToSuperview(); $0.size.equalTo(120) }

        // Camera badge
        cameraButton.setImage(UIImage(named: "camera"), for: .normal)
        cameraButton.tintColor = .white
        cameraButton.backgroundColor = AppTheme.lavender
        cameraButton.layer.cornerRadius = 22
        cameraButton.layer.masksToBounds = true
        cameraButton.addAction(UIAction { [weak self] _ in self?.changePhoto() }, for: .touchUpInside)
        view.addSubview(cameraButton)
        cameraButton.snp.makeConstraints { $0.trailing.equalTo(avatarView.snp.trailing).offset(4); $0.bottom.equalTo(avatarView.snp.bottom).offset(4); $0.size.equalTo(44) }

        // CHANGE PHOTO label
        let changeLabel = UILabel()
        changeLabel.text = "CHANGE PHOTO"
        changeLabel.font = .systemFont(ofSize: 13, weight: .medium)
        changeLabel.textColor = AppTheme.muted
        let spaced = NSMutableAttributedString(string: "CHANGE PHOTO")
        spaced.addAttribute(.kern, value: 3, range: NSRange(location: 0, length: spaced.length))
        changeLabel.attributedText = spaced
        changeLabel.textAlignment = .center
        changeLabel.isUserInteractionEnabled = true
        changeLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(changePhoto)))
        view.addSubview(changeLabel)
        changeLabel.snp.makeConstraints { $0.top.equalTo(avatarView.snp.bottom).offset(12); $0.centerX.equalToSuperview() }

        // Nickname label
        let nickLbl = UILabel()
        nickLbl.text = "Nickname"
        nickLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        nickLbl.textColor = AppTheme.ink
        view.addSubview(nickLbl)
        nickLbl.snp.makeConstraints { $0.top.equalTo(changeLabel.snp.bottom).offset(30); $0.leading.equalToSuperview().offset(20) }

        // Nickname field
        nicknameField.font = .systemFont(ofSize: 15)
        nicknameField.textColor = AppTheme.ink
        nicknameField.backgroundColor = .white
        nicknameField.layer.cornerRadius = 12
        nicknameField.layer.masksToBounds = true
        nicknameField.layer.borderWidth = 1
        nicknameField.layer.borderColor = AppTheme.divider.cgColor
        nicknameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        nicknameField.leftViewMode = .always
        view.addSubview(nicknameField)
        nicknameField.snp.makeConstraints { $0.top.equalTo(nickLbl.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview().inset(20); $0.height.equalTo(52) }

        // Bio label
        let bioLbl = UILabel()
        bioLbl.text = "Bio"
        bioLbl.font = .systemFont(ofSize: 15, weight: .semibold)
        bioLbl.textColor = AppTheme.ink
        view.addSubview(bioLbl)
        bioLbl.snp.makeConstraints { $0.top.equalTo(nicknameField.snp.bottom).offset(20); $0.leading.equalToSuperview().offset(20) }

        // Bio text view
        bioTextView.font = .systemFont(ofSize: 15)
        bioTextView.textColor = AppTheme.ink
        bioTextView.backgroundColor = .white
        bioTextView.layer.cornerRadius = 12
        bioTextView.layer.masksToBounds = true
        bioTextView.layer.borderWidth = 1
        bioTextView.layer.borderColor = AppTheme.divider.cgColor
        bioTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        bioTextView.delegate = self
        view.addSubview(bioTextView)
        bioTextView.snp.makeConstraints { $0.top.equalTo(bioLbl.snp.bottom).offset(8); $0.leading.trailing.equalToSuperview().inset(20); $0.height.equalTo(140) }

        bioPlaceholder.text = "Tell creators about your work"
        bioPlaceholder.font = .systemFont(ofSize: 15)
        bioPlaceholder.textColor = AppTheme.muted
        bioTextView.addSubview(bioPlaceholder)
        bioPlaceholder.snp.makeConstraints { $0.top.equalToSuperview().offset(14); $0.leading.equalToSuperview().offset(16) }

        // Save button
        let save = UIButton(type: .system)
        save.setTitle("Save", for: .normal)
        save.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        save.setTitleColor(.white, for: .normal)
        save.backgroundColor = AppTheme.ink
        save.layer.cornerRadius = 16
        save.layer.masksToBounds = true
        save.addAction(UIAction { [weak self] _ in self?.save() }, for: .touchUpInside)
        view.addSubview(save)
        save.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(20); $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16); $0.height.equalTo(56) }

        loadUser()
    }

    private func loadUser() {
        let user = DataRepository.shared.currentUser
        nicknameField.text = user.name
        bioTextView.text = user.bio
        bioPlaceholder.isHidden = !user.bio.isEmpty
        if let data = user.avatarData {
            avatarView.image = UIImage(data: data)
        } else {
            avatarView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarView.tintColor = AppTheme.lavender
        }
    }

    private func save() {
        let name = nicknameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        guard !name.isEmpty else {
            let d = AppDialogView(title: "Nickname required", message: "Please enter a nickname.", actions: [.init(title: "OK", style: .plain, handler: nil)])
            d.present(in: view)
            return
        }
        DataRepository.shared.updateCurrentProfile(name: name, gender: nil, avatar: selectedAvatar)
        DataRepository.shared.updateProfile(name: name, bio: bioTextView.text ?? "")
        navigationController?.popViewController(animated: true)
    }

    @objc private func changePhoto() {
        let sheet = CustomSheetView(items: ["Choose from Photos", "Take Photo", "Cancel"]) { [weak self] item in
            if item.hasPrefix("Choose") { self?.openLibrary() }
            else if item.hasPrefix("Take") { self?.openCamera() }
        }
        sheet.present(in: view)
    }

    private func openLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
}

extension EditProfileViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        bioPlaceholder.isHidden = !textView.text.isEmpty
    }
}

extension EditProfileViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
            guard let image = object as? UIImage else { return }
            DispatchQueue.main.async {
                self?.selectedAvatar = image
                self?.avatarView.image = image
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        selectedAvatar = image
        avatarView.image = image
    }
}
