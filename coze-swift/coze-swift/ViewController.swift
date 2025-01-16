import UIKit
import VolcEngineRTC

class ViewController: UIViewController, ByteRTCVideoDelegate, ByteRTCRoomDelegate {
    var rtcVideo: ByteRTCVideo?
    var rtcRoom: ByteRTCRoom?
    private var roomInfo: RoomData?
    private var messageList: [String] = []  // 用于实时消息
    private var lastEventType: String?  // 用于判断消息类型

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        // 创建UI视图
        self.createUI()
    }

    deinit {
        // 销毁房间
        self.rtcRoom?.leaveRoom()
        self.rtcRoom?.destroy()
        self.rtcRoom = nil
        // 销毁引擎
        ByteRTCVideo.destroyRTCVideo()
        self.rtcVideo = nil
    }

    // 建立连接
    @objc func connect() {
        Task {
            joinButton.isEnabled = false  // Disable the button
            joinButton.setTitle("连接中", for: .normal)  // Set the button title to "连接中"

            if joinButton.isSelected {
                // 离开房间逻辑
                joinButton.setTitle("连接", for: .normal)
                self.rtcRoom?.leaveRoom()
                joinButton.isSelected = false
                joinButton.backgroundColor = .blue

                self.showToast(message: "已断开")
            } else {
                do {
                    // 获取房间信息
                    let response = try await NetworkService.shared.createRoom(
                        botId: APIConfig.botId,
                        voiceId: APIConfig.voiceId
                    )

                    // 异常处理
                    if response.code != 0 {
                        throw NSError(
                            domain: "", code: Int(response.code),
                            userInfo: [NSLocalizedDescriptionKey: response.msg])
                    }
                    roomInfo = response.data

                    guard let roomInfo = roomInfo else { return }

                    // 创建引擎
                    self.buildRTCEngine()
                    // 绑定本地渲染视图
                    self.bindLocalRenderView()

                    // 创建房间
                    self.rtcRoom = self.rtcVideo?.createRTCRoom(roomInfo.room_id)
                    self.rtcRoom?.delegate = self

                    let userInfo = ByteRTCUserInfo()
                    userInfo.userId = roomInfo.uid

                    let roomCfg = ByteRTCRoomConfig()
                    roomCfg.isAutoPublish = true
                    roomCfg.isAutoSubscribeAudio = true
                    roomCfg.isAutoSubscribeVideo = true

                    // 加入房间
                    self.rtcRoom?.joinRoom(roomInfo.token, userInfo: userInfo, roomConfig: roomCfg)

                    joinButton.setTitle("断开", for: .normal)
                    joinButton.isSelected = true
                    joinButton.backgroundColor = .red

                    // Show success message
                    self.showToast(message: "连接成功，开始实时对话")

                } catch {
                    print("连接失败: \(error)")
                    // 在这里添加错误处理，比如显示一个警告框
                    let alert = UIAlertController(
                        title: "错误", message: "连接: \(error.localizedDescription)",
                        preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "确定", style: .default))
                    self.present(alert, animated: true)
                }
            }

            joinButton.isEnabled = true  // Re-enable the button after the process
        }
    }

    func buildRTCEngine() {
        guard let roomInfo = self.roomInfo else { return }

        self.rtcVideo = ByteRTCVideo.createRTCVideo(
            roomInfo.app_id, delegate: self, parameters: [:])

        //        self.rtcVideo?.startVideoCapture() 默认不打开摄像头
        self.rtcVideo?.startAudioCapture()
    }

    func bindLocalRenderView() {
        // 设置本地渲染视图
        let canvas = ByteRTCVideoCanvas.init()
        canvas.view = self.localView
        canvas.renderMode = .hidden
        self.rtcVideo?.setLocalVideoCanvas(.indexMain, withCanvas: canvas)
    }

    // 添加视图
    func createUI() {
        let width = self.view.bounds.size.width
        let height = self.view.bounds.size.height

        // 本地预览视图占上半部分
        let previewHeight = height * 0.4
        localView.frame = CGRect(x: 0, y: 0, width: width, height: previewHeight)
        self.view.addSubview(localView)

        // 按钮区域
        let buttonY = previewHeight + 10
        let buttonWidth = (width - 30) / 2

        joinButton.frame = CGRect(x: 10, y: buttonY, width: buttonWidth, height: 44)
        cameraButton.frame = CGRect(
            x: width - buttonWidth - 10, y: buttonY, width: buttonWidth, height: 44)

        muteButton.frame = CGRect(x: 10, y: buttonY + 54, width: buttonWidth, height: 44)
        interruptButton.frame = CGRect(
            x: width - buttonWidth - 10, y: buttonY + 54, width: buttonWidth, height: 44)

        self.view.addSubview(joinButton)
        self.view.addSubview(cameraButton)
        self.view.addSubview(muteButton)
        self.view.addSubview(interruptButton)

        // 消息列表视图
        let tableY = buttonY + 108  // 按钮区域下方
        let tableHeight = height - tableY - 20  // 底部留出一些安全距离
        messageTableView.frame = CGRect(x: 10, y: tableY, width: width - 20, height: tableHeight)
        self.view.addSubview(messageTableView)
    }

    // 连接（断开）按钮
    lazy var joinButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitle("连接", for: .normal)
        button.setTitle("断开", for: .selected)
        button.addTarget(self, action: #selector(connect), for: .touchUpInside)

        return button
    }()

    // 本地视频视图
    lazy var localView: UIView = {
        let view = UIView.init()
        view.backgroundColor = .lightGray
        return view
    }()

    // 静音（取消静音）按钮
    lazy var muteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitle("静音", for: .normal)
        button.setTitle("取消静音", for: .selected)
        button.addTarget(self, action: #selector(muteButtonTapped), for: .touchUpInside)
        return button
    }()

    // 打断按钮
    lazy var interruptButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitle("打断", for: .normal)
        button.addTarget(self, action: #selector(interruptButtonTapped), for: .touchUpInside)
        return button
    }()

    // 打开摄像头（关闭摄像头）按钮
    lazy var cameraButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .blue
        button.setTitle("打开摄像头", for: .normal)
        button.setTitle("关闭摄像头", for: .selected)
        button.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
        return button
    }()

    // 实时消息列表视图
    lazy var messageTableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .white
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MessageCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        return tableView
    }()

    // 切换麦克风状态
    @objc private func muteButtonTapped() {
        muteButton.isSelected = !muteButton.isSelected

        if muteButton.isSelected {
            self.rtcVideo?.stopAudioCapture()
            self.showToast(message: "已静音")
        } else {
            self.rtcVideo?.startAudioCapture()
            self.showToast(message: "已取消静音")
        }
    }

    // 打断，发送一条消息
    @objc private func interruptButtonTapped() {
        let message = [
            "id": "event_1",
            "event_type": "conversation.chat.cancel",
            "data": "{}",
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                self.rtcRoom?.sendUserMessage(
                    APIConfig.botId, message: jsonString,
                    config: ByteRTCMessageConfig.reliableOrdered)
            }
            self.showToast(message: "已打断")
        } catch {
            print("Error creating JSON: \(error)")
        }
    }

    // 切花摄像头状态
    @objc private func cameraButtonTapped() {
        cameraButton.isSelected = !cameraButton.isSelected

        if cameraButton.isSelected {
            self.rtcVideo?.startVideoCapture()
            self.showToast(message: "摄像头已打开")
        } else {
            self.rtcVideo?.stopVideoCapture()
            self.showToast(message: "摄像头已关闭")
        }
    }

    // 进房状态回调
    func rtcRoom(
        _ rtcRoom: ByteRTCRoom, onRoomStateChanged roomId: String, withUid uid: String, state: Int,
        extraInfo: String
    ) {
        print("房间状态变更 - 房间ID: \(roomId), 用户ID: \(uid), 状态码: \(state), 附加信息: \(extraInfo)")
    }

    // 收到 bot 消息回调
    func rtcRoom(_ rtcRoom: ByteRTCRoom, onUserMessageReceived uid: String, message: String) {
        print("收到用户消息 - 用户ID: \(uid), 消息: \(message)")

        do {
            if let jsonData = message.data(using: .utf8) {
                let messageData = try JSONDecoder().decode(MessageData.self, from: jsonData)

                if messageData.event_type == "conversation.message.delta"
                    || messageData.event_type == "conversation.message.completed"
                {
                    let content = messageData.data?.content ?? ""
                    self.addMessage(content, eventType: (messageData.event_type)!)
                }
            }
        } catch {
            print("JSON 解析错误: \(error)")
        }

    }

    // 消息提醒（3秒）
    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        let textSize = toastLabel.intrinsicContentSize
        let labelWidth = min(textSize.width + 40, view.frame.width - 40)

        toastLabel.frame = CGRect(
            x: 20,
            y: view.frame.height - 100,
            width: labelWidth,
            height: 35)
        toastLabel.center.x = view.center.x
        view.addSubview(toastLabel)

        UIView.animate(
            withDuration: 0.5, delay: 3.0, options: .curveEaseOut,
            animations: {
                toastLabel.alpha = 0.0
            },
            completion: { _ in
                toastLabel.removeFromSuperview()
            })
    }
}

// 在类的最后添加 UITableView 的代理方法
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.textLabel?.text = messageList[indexPath.row]
        cell.textLabel?.numberOfLines = 0  // 允许多行显示
        return cell
    }
}

// 添加一个方法用于添加新消息
extension ViewController {
    func addMessage(_ message: String, eventType: String) {
        // 在主线程更新 UI
        DispatchQueue.main.async {
            // 如果上一个事件是增量更新，则附加到最后一条消息
            if self.lastEventType == "conversation.message.delta"
                && eventType == "conversation.message.delta"
            {
                if var lastMessage = self.messageList.last {
                    lastMessage += message
                    self.messageList[self.messageList.count - 1] = lastMessage
                }
            }
            // 否则添加新消息
            else if eventType == "conversation.message.delta" {
                self.messageList.append(message)
            }

            self.lastEventType = eventType

            self.messageTableView.reloadData()
            // 滚动到最新消息
            if !self.messageList.isEmpty {
                let indexPath = IndexPath(row: self.messageList.count - 1, section: 0)
                self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        }
    }
}
