import UIKit
import SnapKit
import AVFoundation
import PhotosUI

final class ChatViewController: BaseViewController {
    private let participantID: UUID
    private let tableView = UITableView()
    private let inputBar = UIView()
    private let imageButton = UIButton(type: .system)
    private let voiceButton = UIButton(type: .system)
    private let textField = UITextField()
    private let sendButton = UIButton(type: .system)

    private var messages: [ChatMessage] = []
    private var recorder: AVAudioRecorder?
    private var recordURL: URL?
    private var isRecording = false
    private var permissionRequested = false
    private var player: AVAudioPlayer?
    private var playingMessageID: UUID?
    private var progressTimer: Timer?

    init(participantID: UUID) {
        self.participantID = participantID
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppTheme.canvas
        scrollView.isHidden = true
        setupNav()
        setupTable()
        setupInputBar()
        NotificationCenter.default.addObserver(forName: .repositoryDidChange, object: nil, queue: .main) { [weak self] _ in self?.reload() }
        reload()
    }

    private func setupNav() {
        navigationController?.setNavigationBarHidden(true, animated: false)

        let navBar = UIView()
        view.addSubview(navBar)
        navBar.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide); $0.leading.trailing.equalToSuperview(); $0.height.equalTo(56) }

        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = AppTheme.ink
        back.backgroundColor = .white
        back.layer.cornerRadius = 22
        back.layer.masksToBounds = true
        back.addAction(UIAction { [weak self] _ in self?.navigationController?.popViewController(animated: true) }, for: .touchUpInside)
        navBar.addSubview(back)
        back.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }

        let user = DataRepository.shared.user(participantID)
        let avatar = UIImageView()
        avatar.contentMode = .scaleAspectFill
        avatar.layer.cornerRadius = 20
        avatar.layer.masksToBounds = true
        avatar.backgroundColor = UIColor(hex: 0xE0E0E8)
        if let data = user?.avatarData { avatar.image = UIImage(data: data) }
        else { avatar.image = UIImage(systemName: "person.crop.circle.fill"); avatar.tintColor = AppTheme.lavender }
        navBar.addSubview(avatar)
        avatar.snp.makeConstraints { $0.leading.equalTo(back.snp.trailing).offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(40) }

        let name = UILabel()
        name.text = user?.name ?? "Creator"
        name.font = .systemFont(ofSize: 17, weight: .semibold)
        name.textColor = AppTheme.ink
        navBar.addSubview(name)
        name.snp.makeConstraints { $0.leading.equalTo(avatar.snp.trailing).offset(10); $0.top.equalTo(avatar).offset(2) }

        let role = UILabel()
        role.text = user?.role ?? "Photographer"
        role.font = .systemFont(ofSize: 13, weight: .regular)
        role.textColor = AppTheme.secondary
        navBar.addSubview(role)
        role.snp.makeConstraints { $0.leading.equalTo(name); $0.bottom.equalTo(avatar).offset(-2) }

        let more = UIButton(type: .system)
        more.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        more.tintColor = AppTheme.ink
        more.backgroundColor = .white
        more.layer.cornerRadius = 22
        more.layer.masksToBounds = true
        more.addAction(UIAction { [weak self] _ in self?.showMore() }, for: .touchUpInside)
        navBar.addSubview(more)
        more.snp.makeConstraints { $0.trailing.equalToSuperview().inset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
    }

    private func showMore() {
        let sheet = CustomSheetView(items: ["Report", "Block", "Cancel"]) { [weak self] item in
            guard let self else { return }
            if item == "Report" {
                self.push(ReportViewController(targetID: self.participantID))
            } else if item == "Block" {
                self.blockUserAndReturnToRoot(self.participantID)
            }
        }
        sheet.present(in: view.window ?? view)
    }

    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.reuseID)
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.reuseID)
        tableView.register(VoiceMessageCell.self, forCellReuseIdentifier: VoiceMessageCell.reuseID)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide).offset(56); $0.leading.trailing.equalToSuperview() }

        // "Today" header
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 36))
        let today = UILabel()
        today.text = "Today"
        today.font = .systemFont(ofSize: 13, weight: .regular)
        today.textColor = AppTheme.muted
        today.textAlignment = .center
        header.addSubview(today)
        today.snp.makeConstraints { $0.edges.equalToSuperview() }
        tableView.tableHeaderView = header
    }

    private func setupInputBar() {
        inputBar.backgroundColor = .white
        view.addSubview(inputBar)
        inputBar.snp.makeConstraints { $0.top.equalTo(tableView.snp.bottom); $0.leading.trailing.equalToSuperview(); $0.bottom.equalTo(view.safeAreaLayoutGuide); $0.height.equalTo(64) }

        let topLine = UIView()
        topLine.backgroundColor = AppTheme.divider
        inputBar.addSubview(topLine)
        topLine.snp.makeConstraints { $0.top.leading.trailing.equalToSuperview(); $0.height.equalTo(1) }

        // Image button (circle outline)
        imageButton.setImage(UIImage(systemName: "photo"), for: .normal)
        imageButton.tintColor = AppTheme.ink
        imageButton.layer.cornerRadius = 22
        imageButton.layer.masksToBounds = true
        imageButton.layer.borderWidth = 1
        imageButton.layer.borderColor = AppTheme.divider.cgColor
        imageButton.addAction(UIAction { [weak self] _ in self?.showMediaSheet() }, for: .touchUpInside)
        inputBar.addSubview(imageButton)
        imageButton.snp.makeConstraints { $0.leading.equalToSuperview().offset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }

        // Voice button (circle outline) - hold to record
        voiceButton.setImage(UIImage(systemName: "mic"), for: .normal)
        voiceButton.tintColor = AppTheme.ink
        voiceButton.layer.cornerRadius = 22
        voiceButton.layer.masksToBounds = true
        voiceButton.layer.borderWidth = 1
        voiceButton.layer.borderColor = AppTheme.divider.cgColor
        voiceButton.addTarget(self, action: #selector(voiceDown), for: .touchDown)
        voiceButton.addTarget(self, action: #selector(voiceUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        inputBar.addSubview(voiceButton)
        voiceButton.snp.makeConstraints { $0.leading.equalTo(imageButton.snp.trailing).offset(10); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }

        // Text field
        textField.placeholder = "Write a message..."
        textField.font = .systemFont(ofSize: 15)
        textField.backgroundColor = .white
        textField.layer.cornerRadius = 22
        textField.layer.masksToBounds = true
        textField.layer.borderWidth = 1
        textField.layer.borderColor = AppTheme.divider.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        textField.leftViewMode = .always
        textField.returnKeyType = .send
        textField.delegate = self
        inputBar.addSubview(textField)
        textField.snp.makeConstraints { $0.leading.equalTo(voiceButton.snp.trailing).offset(10); $0.centerY.equalToSuperview(); $0.height.equalTo(44) }

        // Send button (dark filled circle)
        sendButton.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        sendButton.tintColor = .white
        sendButton.backgroundColor = AppTheme.ink
        sendButton.layer.cornerRadius = 22
        sendButton.layer.masksToBounds = true
        sendButton.addAction(UIAction { [weak self] _ in self?.sendText() }, for: .touchUpInside)
        inputBar.addSubview(sendButton)
        sendButton.snp.makeConstraints { $0.leading.equalTo(textField.snp.trailing).offset(10); $0.trailing.equalToSuperview().inset(15); $0.centerY.equalToSuperview(); $0.size.equalTo(44) }
    }

    // MARK: - Data

    private func reload() {
        messages = DataRepository.shared.visibleConversations.first { $0.participantID == participantID }?.messages ?? []
        tableView.reloadData()
        if !messages.isEmpty {
            tableView.scrollToRow(at: IndexPath(row: messages.count - 1, section: 0), at: .bottom, animated: false)
        }
    }

    private func sendText() {
        guard let text = textField.text, !text.isEmpty else { return }
        DataRepository.shared.send(.init(id: UUID(), senderID: DataRepository.shared.currentUserID, text: text, kind: .text), to: participantID)
        textField.text = ""
    }

    // MARK: - Media sheet

    @objc private func showMediaSheet() {
        view.endEditing(true)
        let sheet = CustomSheetView(items: ["Choose from Photos", "Take Photo", "Cancel"]) { [weak self] item in
            if item.hasPrefix("Choose") { self?.openPhotoLibrary() }
            else if item.hasPrefix("Take") { self?.openCamera() }
        }
        sheet.present(in: view)
    }

    private func openPhotoLibrary() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            let alert = UIAlertController(title: "Camera Unavailable", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }

    private func sendImageData(_ data: Data) {
        DataRepository.shared.send(.init(id: UUID(), senderID: DataRepository.shared.currentUserID, text: "Photo", kind: .image, mediaData: data), to: participantID)
    }

    // MARK: - Recording

    @objc private func voiceDown() {
        if !permissionRequested {
            permissionRequested = true
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if !granted { self?.showMicDeniedAlert() }
                }
            }
            return
        }
        guard AVAudioSession.sharedInstance().recordPermission == .granted else { showMicDeniedAlert(); return }
        startRecording()
    }

    @objc private func voiceUp() {
        guard isRecording else { return }
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        isRecording = false
        voiceButton.backgroundColor = .clear
        voiceButton.tintColor = AppTheme.ink
        if let url = recordURL, let data = try? Data(contentsOf: url), duration > 0.5 {
            DataRepository.shared.send(.init(id: UUID(), senderID: DataRepository.shared.currentUserID, text: "Voice", kind: .voice, duration: duration, mediaData: data), to: participantID)
        }
    }

    private func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).m4a")
        recordURL = url
        recorder = try? AVAudioRecorder(url: url, settings: [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ])
        recorder?.record()
        isRecording = true
        voiceButton.backgroundColor = AppTheme.lavender
        voiceButton.tintColor = .white
    }

    private func showMicDeniedAlert() {
        let alert = UIAlertController(title: "Microphone Access Required", message: "Please enable microphone access in Settings to send voice messages.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Playback

    fileprivate func togglePlay(_ message: ChatMessage, cell: VoiceMessageCell) {
        guard let data = message.mediaData else { return }
        if playingMessageID == message.id {
            player?.stop()
            stopProgress()
            playingMessageID = nil
            cell.setPlaying(false, progress: 0)
            return
        }
        player?.stop()
        stopProgress()
        do {
            player = try AVAudioPlayer(data: data)
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player?.play()
            playingMessageID = message.id
            cell.setPlaying(true, progress: 0)
            progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self, let player = self.player else { return }
                let progress = player.currentTime / max(player.duration, 0.01)
                cell.setPlaying(true, progress: Float(progress))
                if !player.isPlaying {
                    self.stopProgress()
                    self.playingMessageID = nil
                    cell.setPlaying(false, progress: 1)
                }
            }
        } catch {
            cell.setPlaying(false, progress: 0)
        }
    }

    private func stopProgress() {
        progressTimer?.invalidate()
        progressTimer = nil
        tableView.visibleCells.compactMap { $0 as? VoiceMessageCell }.forEach { $0.setPlaying(false, progress: 0) }
    }
}

// MARK: - TextField

extension ChatViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendText()
        return true
    }
}

// MARK: - Pickers

extension ChatViewController: PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        result.itemProvider.loadDataRepresentation(forTypeIdentifier: "public.image") { [weak self] data, _ in
            guard let data else { return }
            DispatchQueue.main.async { self?.sendImageData(data) }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage, let data = image.jpegData(compressionQuality: 0.9) else { return }
        sendImageData(data)
    }
}

// MARK: - Table

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { messages.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let isMine = message.senderID == DataRepository.shared.currentUserID
        switch message.kind {
        case .image:
            let cell = tableView.dequeueReusableCell(withIdentifier: ImageMessageCell.reuseID, for: indexPath) as! ImageMessageCell
            cell.configure(message: message, isMine: isMine)
            return cell
        case .voice:
            let cell = tableView.dequeueReusableCell(withIdentifier: VoiceMessageCell.reuseID, for: indexPath) as! VoiceMessageCell
            cell.configure(message: message, isMine: isMine)
            cell.onTogglePlay = { [weak self, weak cell] in
                guard let self, let cell else { return }
                self.togglePlay(message, cell: cell)
            }
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: TextMessageCell.reuseID, for: indexPath) as! TextMessageCell
            cell.configure(message: message, isMine: isMine)
            return cell
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}

// MARK: - Text cell

private final class TextMessageCell: UITableViewCell {
    static let reuseID = "TextMessageCell"
    private let bubble = UIView()
    private let messageLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubble.layer.cornerRadius = 16
        bubble.layer.masksToBounds = true
        contentView.addSubview(bubble)
        bubble.snp.makeConstraints { $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8); $0.width.lessThanOrEqualTo(280) }

        messageLabel.font = .systemFont(ofSize: 15, weight: .regular)
        messageLabel.numberOfLines = 0
        bubble.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)) }
    }
    required init?(coder: NSCoder) { nil }

    func configure(message: ChatMessage, isMine: Bool) {
        messageLabel.text = message.text
        messageLabel.textColor = isMine ? .white : AppTheme.ink
        bubble.backgroundColor = isMine ? AppTheme.ink : .white
        bubble.layer.borderWidth = isMine ? 0 : 1
        bubble.layer.borderColor = AppTheme.divider.cgColor
        bubble.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8); $0.width.lessThanOrEqualTo(280)
            if isMine { $0.trailing.equalToSuperview().inset(15) } else { $0.leading.equalToSuperview().offset(15) }
        }
    }
}

// MARK: - Image cell

private final class ImageMessageCell: UITableViewCell {
    static let reuseID = "ImageMessageCell"
    private let photoView = UIImageView()
    private var heightConstraint: Constraint?
    private var widthConstraint: Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.layer.cornerRadius = 16
        photoView.backgroundColor = UIColor(hex: 0xE8E8F0)
        contentView.addSubview(photoView)
        photoView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8)
            $0.leading.equalToSuperview().offset(15)
            $0.width.lessThanOrEqualTo(220)
            $0.height.lessThanOrEqualTo(280)
            self.heightConstraint = $0.height.equalTo(180).constraint
            self.widthConstraint = $0.width.equalTo(180).constraint
        }
    }
    required init?(coder: NSCoder) { nil }

    func configure(message: ChatMessage, isMine: Bool) {
        photoView.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8)
            $0.width.lessThanOrEqualTo(220); $0.height.lessThanOrEqualTo(280)
            if isMine { $0.trailing.equalToSuperview().inset(15) } else { $0.leading.equalToSuperview().offset(15) }
            if let data = message.mediaData, let image = UIImage(data: data) {
                let maxW: CGFloat = 220, maxH: CGFloat = 280
                let ratio = image.size.height / max(image.size.width, 1)
                var w = maxW
                var h = w * ratio
                if h > maxH { h = maxH; w = h / max(ratio, 0.01) }
                self.widthConstraint = $0.width.equalTo(w).constraint
                self.heightConstraint = $0.height.equalTo(h).constraint
            } else {
                self.widthConstraint = $0.width.equalTo(180).constraint
                self.heightConstraint = $0.height.equalTo(180).constraint
            }
        }
        if let data = message.mediaData { photoView.image = UIImage(data: data) }
        else { photoView.image = UIImage(systemName: "photo"); photoView.tintColor = AppTheme.lavender }
    }
}

// MARK: - Voice cell

final class VoiceMessageCell: UITableViewCell {
    static let reuseID = "VoiceMessageCell"
    var onTogglePlay: (() -> Void)?

    private let bubble = UIView()
    private let playButton = UIButton(type: .system)
    private let progressTrack = UIView()
    private let progressFill = UIView()
    private let durationLabel = UILabel()
    private var fillWidth: Constraint?
    private var isMine = false

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubble.layer.cornerRadius = 20
        bubble.layer.masksToBounds = true
        contentView.addSubview(bubble)
        bubble.snp.makeConstraints { $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8); $0.height.equalTo(48); $0.width.equalTo(200) }

        playButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playButton.tintColor = .white
        playButton.addAction(UIAction { [weak self] _ in self?.onTogglePlay?() }, for: .touchUpInside)
        bubble.addSubview(playButton)
        playButton.snp.makeConstraints { $0.leading.equalToSuperview().offset(14); $0.centerY.equalToSuperview(); $0.size.equalTo(24) }

        progressTrack.backgroundColor = UIColor.white.withAlphaComponent(0.35)
        progressTrack.layer.cornerRadius = 2
        progressTrack.layer.masksToBounds = true
        bubble.addSubview(progressTrack)
        progressTrack.snp.makeConstraints { $0.leading.equalTo(playButton.snp.trailing).offset(12); $0.centerY.equalToSuperview(); $0.height.equalTo(4); $0.width.equalTo(78) }

        progressFill.backgroundColor = .white
        progressFill.layer.cornerRadius = 2
        progressTrack.addSubview(progressFill)
        progressFill.snp.makeConstraints { $0.leading.top.bottom.equalToSuperview(); self.fillWidth = $0.width.equalTo(0).constraint }

        durationLabel.font = .systemFont(ofSize: 15, weight: .medium)
        durationLabel.textColor = .white
        durationLabel.textAlignment = .right
        bubble.addSubview(durationLabel)
        durationLabel.snp.makeConstraints { $0.leading.equalTo(progressTrack.snp.trailing).offset(10); $0.trailing.equalToSuperview().inset(14); $0.centerY.equalToSuperview() }
    }
    required init?(coder: NSCoder) { nil }

    func configure(message: ChatMessage, isMine: Bool) {
        self.isMine = isMine
        bubble.backgroundColor = isMine ? AppTheme.lavender : .white
        playButton.tintColor = isMine ? .white : AppTheme.lavender
        durationLabel.textColor = isMine ? .white : AppTheme.ink
        progressTrack.backgroundColor = (isMine ? UIColor.white : AppTheme.lavender).withAlphaComponent(0.3)
        progressFill.backgroundColor = isMine ? .white : AppTheme.lavender

        let duration = Int(message.duration ?? 0)
        durationLabel.text = String(format: "%02d:%02d", duration / 60, duration % 60)
        setPlaying(false, progress: 0)

        bubble.snp.remakeConstraints {
            $0.top.equalToSuperview().offset(8); $0.bottom.equalToSuperview().inset(8); $0.height.equalTo(48); $0.width.equalTo(200)
            if isMine { $0.trailing.equalToSuperview().inset(15) } else { $0.leading.equalToSuperview().offset(15) }
        }
    }

    func setPlaying(_ playing: Bool, progress: Float) {
        playButton.setImage(UIImage(systemName: playing ? "pause.fill" : "play.fill"), for: .normal)
        let fill = CGFloat(max(0, min(1, progress))) * 78
        fillWidth?.update(offset: fill)
    }
}
