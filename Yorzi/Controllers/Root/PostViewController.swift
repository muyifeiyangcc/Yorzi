import UIKit
import SnapKit
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import AVKit

final class PostViewController: BaseViewController {
    private let workTitle = FormField(title: "Work title", placeholder: "e.g. Summer Portrait Series")
    private let workDescription = FormField(title: "Description", placeholder: "Creative background, story, or project notes", multiline: true, multilineHeight: 78)
    private let callTitle = FormField(title: "Call title", placeholder: "e.g. Looking for a model for street portraits")
    private let projectDescription = FormField(title: "Project description", placeholder: "Creative idea, reference style, shoot details, and deliverables", multiline: true, multilineHeight: 78)
    private let location = FormField(title: "Location", placeholder: "City / Country")
    private let date = FormField(title: "Shoot date", placeholder: "Year / Month / Day")
    private let budget = FormField(title: "Budget", placeholder: "$ / project")
    private let roles = FormField(title: "Roles needed", placeholder: "Model / Photographer / Retoucher")
    private let deadline = FormField(title: "Application deadline", placeholder: "Date and time")
    private let mode = UISegmentedControl(items: ["Post a work", "Post a collab call"])
    private let formStack = UIStackView()
    private let shootDatePicker = UIDatePicker()
    private var workType = "Portraits"
    private var visibility = WorkVisibility.public
    private var selectedMedia: [Data] = []
    private var selectedMediaIsVideo = false
    private var selectedVideoData: Data?

    override func viewDidLoad() { super.viewDidLoad(); navigationController?.setNavigationBarHidden(true, animated: false); setupShootDatePicker(); buildPage() }

    private func setupShootDatePicker() {
        shootDatePicker.datePickerMode = .date
        shootDatePicker.preferredDatePickerStyle = .wheels
        shootDatePicker.addTarget(self, action: #selector(shootDateChanged), for: .valueChanged)
        date.textField.inputView = shootDatePicker
        date.textField.tintColor = .clear

        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(shootDateDone))
        toolbar.items = [spacer, done]
        date.textField.inputAccessoryView = toolbar
    }

    @objc private func shootDateChanged() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy / MM / dd"
        date.textField.text = formatter.string(from: shootDatePicker.date)
    }

    @objc private func shootDateDone() {
        shootDateChanged()
        view.endEditing(true)
    }

    private func buildPage() {
        let heading = UILabel(); heading.text = "Post·"; heading.font = UIFont(name: "Georgia-Bold", size: 28) ?? .boldSystemFont(ofSize: 28); heading.textColor = AppTheme.ink; contentView.addSubview(heading); heading.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview().inset(16) }
        mode.selectedSegmentIndex = 0; mode.backgroundColor = UIColor(hex: 0xEEF2F2); mode.selectedSegmentTintColor = .white; mode.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12), .foregroundColor: AppTheme.secondary], for: .normal); mode.setTitleTextAttributes([.font: UIFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: AppTheme.ink], for: .selected); mode.layer.borderWidth = 1; mode.layer.borderColor = UIColor(hex: 0xD7E0E1).cgColor; mode.round(11); contentView.addSubview(mode); mode.snp.makeConstraints { $0.top.equalTo(heading.snp.bottom).offset(16); $0.leading.trailing.equalToSuperview().inset(16); $0.height.equalTo(44) }
        formStack.axis = .vertical; formStack.spacing = 14; contentView.addSubview(formStack); formStack.snp.makeConstraints { $0.top.equalTo(mode.snp.bottom).offset(26); $0.leading.trailing.equalToSuperview().inset(16); $0.bottom.equalToSuperview().inset(20) }; mode.addAction(UIAction { [weak self] _ in self?.renderForm() }, for: .valueChanged); renderForm()
        scrollView.contentInset.bottom = 92
        scrollView.verticalScrollIndicatorInsets.bottom = 92
    }
    private func renderForm() { formStack.arrangedSubviews.forEach { $0.removeFromSuperview() }; if mode.selectedSegmentIndex == 0 { renderWork() } else { renderCall() } }
    private func renderWork() { date.titleLabel.text = "Shoot date"; formStack.addArrangedSubview(mediaBox(title: "Media")); formStack.addArrangedSubview(workTitle); formStack.addArrangedSubview(chipRow()); formStack.addArrangedSubview(workDescription); formStack.addArrangedSubview(twoColumns(left: location, right: date)); formStack.addArrangedSubview(visibilityPicker()); formStack.addArrangedSubview(publishButton(title: "Publish work")) }
    private func renderCall() { formStack.addArrangedSubview(mediaBox(title: "Reference material")); formStack.addArrangedSubview(callTitle); formStack.addArrangedSubview(projectDescription); formStack.addArrangedSubview(twoColumns(left: location, right: date, rightTitle: "Date")); formStack.addArrangedSubview(budget); formStack.addArrangedSubview(roles); formStack.addArrangedSubview(deadline); formStack.addArrangedSubview(publishButton(title: "Publish collab call")) }
    private func mediaBox(title: String) -> UIView {
        let container = UIView()
        let label = UILabel.appLabel(title, size: 12, weight: .medium)
        container.addSubview(label)
        label.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }

        let mediaArea = UIView()
        container.addSubview(mediaArea)
        mediaArea.snp.makeConstraints { $0.top.equalTo(label.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(144) }

        if selectedMedia.isEmpty {
            let empty = makeDashedMediaControl()
            mediaArea.addSubview(empty)
            empty.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            let scroll = UIScrollView()
            scroll.showsHorizontalScrollIndicator = false
            mediaArea.addSubview(scroll)
            scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 8
            stack.alignment = .fill
            scroll.addSubview(stack)
            stack.snp.makeConstraints { $0.edges.equalTo(scroll.contentLayoutGuide); $0.height.equalTo(scroll.frameLayoutGuide) }
            for (index, data) in selectedMedia.enumerated() {
                let cell = PostMediaCell(data: data, isVideo: selectedMediaIsVideo)
                cell.onDelete = { [weak self] in
                    guard let self else { return }
                    self.selectedMedia.remove(at: index)
                    if self.selectedMedia.isEmpty { self.selectedMediaIsVideo = false; self.selectedVideoData = nil }
                    self.renderForm()
                }
                cell.onPreview = { [weak self] in self?.presentPreview(startingAt: index) }
                stack.addArrangedSubview(cell)
                cell.snp.makeConstraints { $0.width.equalTo(112) }
            }
            if !selectedMediaIsVideo {
                let add = makeAddMediaControl()
                stack.addArrangedSubview(add)
                add.snp.makeConstraints { $0.width.equalTo(96) }
            }
        }
        return container
    }

    private func makeDashedMediaControl() -> UIControl {
        let control = DashedMediaControl()
        control.backgroundColor = UIColor(hex: 0xF8FAFA)
        control.layer.cornerRadius = 14
        control.addAction(UIAction { [weak self] _ in self?.showMediaSheet() }, for: .touchUpInside)
        let icon = UIImageView(image: UIImage(systemName: "square.and.arrow.up"))
        icon.tintColor = UIColor(hex: 0xA77D44)
        let main = UILabel.appLabel("Add images or short video", size: 12, color: AppTheme.secondary)
        main.textAlignment = .center
        let sub = UILabel.appLabel("Multiple images supported", size: 10, color: AppTheme.muted)
        sub.textAlignment = .center
        [icon, main, sub].forEach { control.addSubview($0) }
        icon.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.top.equalToSuperview().offset(42); $0.size.equalTo(18) }
        main.snp.makeConstraints { $0.top.equalTo(icon.snp.bottom).offset(12); $0.centerX.equalToSuperview() }
        sub.snp.makeConstraints { $0.top.equalTo(main.snp.bottom).offset(8); $0.centerX.equalToSuperview() }
        return control
    }

    private func makeAddMediaControl() -> UIControl {
        let control = UIControl()
        control.backgroundColor = UIColor(hex: 0xF8FAFA)
        control.layer.borderColor = UIColor(hex: 0xBFCBCD).cgColor
        control.layer.borderWidth = 1
        control.layer.cornerRadius = 12
        control.addAction(UIAction { [weak self] _ in self?.showMediaSheet() }, for: .touchUpInside)
        let icon = UIImageView(image: UIImage(systemName: "plus"))
        icon.tintColor = AppTheme.secondary
        let label = UILabel.appLabel("Add", size: 11, color: AppTheme.secondary)
        label.textAlignment = .center
        control.addSubview(icon); control.addSubview(label)
        icon.snp.makeConstraints { $0.centerX.equalToSuperview(); $0.centerY.equalToSuperview().offset(-10); $0.size.equalTo(20) }
        label.snp.makeConstraints { $0.top.equalTo(icon.snp.bottom).offset(4); $0.centerX.equalToSuperview() }
        return control
    }

    private func showMediaSheet() {
        let sheet = CustomSheetView(items: ["Choose photos", "Choose video", "Take Photo", "Record Video", "Cancel"]) { [weak self] item in
            if item == "Choose photos" { self?.openPhotoPicker() }
            else if item == "Choose video" { self?.openVideoPicker() }
            else if item == "Take Photo" { self?.openCamera(capturingVideo: false) }
            else if item == "Record Video" { self?.openCamera(capturingVideo: true) }
        }
        sheet.present(in: view.window ?? view)
    }

    private func openPhotoPicker() {
        let replacingVideo = selectedMediaIsVideo
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = replacingVideo ? 9 : max(0, 9 - selectedMedia.count)
        guard config.selectionLimit > 0 else {
            showMessage(title: "Image limit reached", message: "You can select up to 9 photos.")
            return
        }
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openVideoPicker() {
        guard !selectedMediaIsVideo else {
            showMessage(title: "Video limit reached", message: "You can select only one video.")
            return
        }
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .videos
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openCamera(capturingVideo: Bool) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showMessage(title: "Camera unavailable", message: "This device does not have a camera.")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [capturingVideo ? UTType.movie.identifier : UTType.image.identifier]
        picker.videoQuality = .typeHigh
        picker.videoMaximumDuration = 60
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true)
    }

    private func processVideo(from url: URL) {
        guard let videoData = try? Data(contentsOf: url) else { return }
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent("yorzi-video-\(UUID().uuidString).mov")
        guard (try? videoData.write(to: localURL)) != nil else { return }
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            defer { try? FileManager.default.removeItem(at: localURL) }
            let asset = AVAsset(url: localURL)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let duration = asset.duration.seconds
            let seconds = duration.isFinite && duration > 0 ? min(0.1, max(0, duration - 0.01)) : 0
            let time = CMTime(seconds: seconds, preferredTimescale: 600)
            let cgImage = (try? generator.copyCGImage(at: time, actualTime: nil)) ?? (try? generator.copyCGImage(at: .zero, actualTime: nil))
            guard let cgImage,
                  let frameData = UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.86) else { return }
            DispatchQueue.main.async {
                guard let self else { return }
                self.selectedMedia = [frameData]
                self.selectedMediaIsVideo = true
                self.selectedVideoData = videoData
                self.renderForm()
            }
        }
    }

    private func presentPreview(startingAt index: Int) {
        if selectedMediaIsVideo, let selectedVideoData {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
            guard (try? selectedVideoData.write(to: url)) != nil else { return }
            let player = AVPlayerViewController()
            player.player = AVPlayer(url: url)
            present(player, animated: true) { player.player?.play() }
            return
        }
        let images = selectedMedia.compactMap(UIImage.init(data:))
        guard !images.isEmpty else { return }
        let preview = PostMediaPreviewViewController(images: images, startIndex: min(index, images.count - 1))
        preview.modalPresentationStyle = .fullScreen
        present(preview, animated: true)
    }
    private func chipRow() -> UIView { let c = UIView(); let l = UILabel.appLabel("Work type", size: 12, weight: .medium); c.addSubview(l); l.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }; let s = UIStackView(); s.axis = .horizontal; s.spacing = 8; c.addSubview(s); s.snp.makeConstraints { $0.top.equalTo(l.snp.bottom).offset(8); $0.leading.trailing.bottom.equalToSuperview() }; ["Portraits", "Outdoor Stories", "Motion"].forEach { t in let b = UIButton(type: .system); b.setTitle(t, for: .normal); b.titleLabel?.font = .systemFont(ofSize: 11); b.contentEdgeInsets = .init(top: 9, left: 14, bottom: 9, right: 14); b.layer.cornerRadius = 18; b.layer.borderWidth = 1; b.layer.borderColor = AppTheme.divider.cgColor; b.backgroundColor = t == workType ? AppTheme.ink : .white; b.setTitleColor(t == workType ? .white : AppTheme.secondary, for: .normal); b.addAction(UIAction { [weak self] _ in self?.workType = t; self?.renderForm() }, for: .touchUpInside); s.addArrangedSubview(b) }; return c }
    private func twoColumns(left: FormField, right: FormField, rightTitle: String? = nil) -> UIView { if let rightTitle { right.titleLabel.text = rightTitle }; let r = UIStackView(arrangedSubviews: [left, right]); r.axis = .horizontal; r.spacing = 10; r.distribution = .fillEqually; return r }
    private func visibilityPicker() -> UIView { let c = UIView(); let l = UILabel.appLabel("Who Can See This?", size: 12, weight: .medium); c.addSubview(l); l.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview() }; let card = UIView(); card.backgroundColor = .white; card.layer.borderWidth = 1; card.layer.borderColor = AppTheme.divider.cgColor; card.round(12); c.addSubview(card); card.snp.makeConstraints { $0.top.equalToSuperview().offset(20); $0.leading.trailing.bottom.equalToSuperview(); $0.height.equalTo(164) }; [WorkVisibility.`public`, .diveCircle, .onlyMe].enumerated().forEach { idx, value in let row = UIButton(type: .system); row.contentHorizontalAlignment = .left; row.setTitle(value.title, for: .normal); row.setTitleColor(AppTheme.ink, for: .normal); row.titleLabel?.font = .systemFont(ofSize: 12); card.addSubview(row); row.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.trailing.equalToSuperview().inset(14); $0.top.equalToSuperview().offset(idx * 54); $0.height.equalTo(54) }; let radio = UIView(); radio.layer.borderWidth = 1; radio.layer.borderColor = (visibility == value ? AppTheme.lavender : UIColor(hex: 0xD6DEDF)).cgColor; radio.round(9); row.addSubview(radio); radio.snp.makeConstraints { $0.trailing.centerY.equalToSuperview(); $0.size.equalTo(18) }; if visibility == value { let dot = UIView(); dot.backgroundColor = AppTheme.lavender; dot.round(5); radio.addSubview(dot); dot.snp.makeConstraints { $0.center.equalToSuperview(); $0.size.equalTo(10) } }; row.addAction(UIAction { [weak self] _ in self?.visibility = value; self?.renderForm() }, for: .touchUpInside); if idx < 2 { let line = UIView(); line.backgroundColor = AppTheme.divider; card.addSubview(line); line.snp.makeConstraints { $0.leading.trailing.equalToSuperview().inset(14); $0.top.equalTo(row.snp.bottom); $0.height.equalTo(1) } } }; return c }
    private func publishButton(title: String) -> UIButton { let b = UIButton.primary(title); b.snp.makeConstraints { $0.height.equalTo(50) }; b.addAction(UIAction { [weak self] _ in self?.publish() }, for: .touchUpInside); return b }
    private func publish() { let title = mode.selectedSegmentIndex == 0 ? workTitle.textField.text : callTitle.textField.text; guard let title, !title.trimmingCharacters(in: .whitespaces).isEmpty else { showMessage(title: "Add a title", message: "A title is required before publishing."); return }; if mode.selectedSegmentIndex == 0 { DataRepository.shared.addWork(title: title, category: workType, location: location.textField.text ?? "", description: workDescription.text, visibility: visibility, mediaData: selectedMedia.first, mediaDatas: selectedMedia.isEmpty ? nil : selectedMedia, videoData: selectedMediaIsVideo ? selectedVideoData : nil) } else { DataRepository.shared.addCall(title: title, location: location.textField.text ?? "", date: date.text, budget: budget.textField.text ?? "", roles: roles.textField.text ?? "", deadline: deadline.text, description: projectDescription.text, mediaData: selectedMedia.first, mediaDatas: selectedMedia.isEmpty ? nil : selectedMedia, videoData: selectedMediaIsVideo ? selectedVideoData : nil) }; showMessage(title: "Published", message: "Your submission has been added.") }
}

extension PostViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard !results.isEmpty else { return }
        if results.first?.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) == true {
            let provider = results[0].itemProvider
            provider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, _ in
                guard let self, let url else { return }
                self.processVideo(from: url)
            }
            return
        }

        let replacingVideo = selectedMediaIsVideo
        let group = DispatchGroup()
        let lock = NSLock()
        var loaded: [Int: Data] = [:]
        for (index, result) in results.enumerated() {
            group.enter()
            result.itemProvider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
                if let data { lock.lock(); loaded[index] = data; lock.unlock() }
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            let images = loaded.keys.sorted().compactMap { loaded[$0] }
            if replacingVideo { self.selectedMedia = images } else { self.selectedMedia.append(contentsOf: images) }
            self.selectedMediaIsVideo = false
            self.selectedVideoData = nil
            self.renderForm()
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) {
            picker.dismiss(animated: true)
            if selectedMediaIsVideo { selectedMedia = [] }
            guard selectedMedia.count < 9 else {
                showMessage(title: "Image limit reached", message: "You can select up to 9 photos.")
                return
            }
            selectedMedia.append(data)
            selectedMediaIsVideo = false
            selectedVideoData = nil
            renderForm()
        } else if let url = info[.mediaURL] as? URL {
            processVideo(from: url)
            picker.dismiss(animated: true)
        } else {
            picker.dismiss(animated: true)
        }
    }
}

private final class PostMediaCell: UIControl {
    var onDelete: (() -> Void)?
    var onPreview: (() -> Void)?
    private let imageView = UIImageView()

    init(data: Data, isVideo: Bool) {
        super.init(frame: .zero)
        layer.cornerRadius = 12; layer.masksToBounds = true
        imageView.image = UIImage(data: data)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        if isVideo {
            let badge = UILabel.appLabel("VIDEO", size: 9, weight: .semibold, color: .white)
            badge.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            badge.textAlignment = .center
            badge.layer.cornerRadius = 8; badge.layer.masksToBounds = true
            addSubview(badge)
            badge.snp.makeConstraints { $0.leading.top.equalToSuperview().offset(6); $0.width.equalTo(42); $0.height.equalTo(18) }
        }
        let delete = UIButton(type: .system)
        delete.setImage(UIImage(systemName: "xmark"), for: .normal)
        delete.tintColor = .white
        delete.backgroundColor = UIColor.black.withAlphaComponent(0.58)
        delete.layer.cornerRadius = 11; delete.layer.masksToBounds = true
        delete.addAction(UIAction { [weak self] _ in self?.onDelete?() }, for: .touchUpInside)
        addSubview(delete)
        delete.snp.makeConstraints { $0.trailing.top.equalToSuperview().inset(6); $0.size.equalTo(22) }
        addAction(UIAction { [weak self] _ in self?.onPreview?() }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { nil }
}

private final class DashedMediaControl: UIControl {
    private let dashLayer = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        dashLayer.fillColor = UIColor.clear.cgColor
        dashLayer.strokeColor = UIColor(hex: 0xBFCBCD).cgColor
        dashLayer.lineWidth = 1
        dashLayer.lineDashPattern = [6, 5]
        layer.addSublayer(dashLayer)
    }
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashLayer.frame = bounds
        dashLayer.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 14).cgPath
    }
}

private final class PostMediaPreviewViewController: UIViewController {
    private let images: [UIImage]
    private let startIndex: Int
    init(images: [UIImage], startIndex: Int) { self.images = images; self.startIndex = startIndex; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let scroll = UIScrollView()
        scroll.isPagingEnabled = true; scroll.showsHorizontalScrollIndicator = false
        view.addSubview(scroll)
        scroll.snp.makeConstraints { $0.edges.equalToSuperview() }
        let stack = UIStackView(); stack.axis = .horizontal; stack.spacing = 0
        scroll.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalTo(scroll.contentLayoutGuide); $0.height.equalTo(scroll.frameLayoutGuide) }
        for image in images {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.isUserInteractionEnabled = true
            stack.addArrangedSubview(imageView)
            imageView.snp.makeConstraints { $0.width.equalTo(scroll.frameLayoutGuide) }
        }
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal); close.tintColor = .white
        close.backgroundColor = UIColor.black.withAlphaComponent(0.55); close.layer.cornerRadius = 18
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        view.addSubview(close)
        close.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(12); $0.trailing.equalToSuperview().inset(16); $0.size.equalTo(36) }
        view.layoutIfNeeded()
        scroll.setContentOffset(CGPoint(x: CGFloat(startIndex) * scroll.bounds.width, y: 0), animated: false)
    }
}
