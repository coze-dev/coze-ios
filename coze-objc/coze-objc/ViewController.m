#import "ViewController.h"
#import "APIConfig.h"
#import "NetworkService.h"

@interface ViewController ()

@property(nonatomic, strong) ByteRTCVideo *rtcVideo;
@property(nonatomic, strong) ByteRTCRoom *rtcRoom;
@property(nonatomic, strong) RoomData *roomInfo;
@property(nonatomic, strong) NSMutableArray<NSString *> *messageList;
@property(nonatomic, copy) NSString *lastEventType;

@property(nonatomic, strong) UIView *localView;
@property(nonatomic, strong) UIButton *joinButton;
@property(nonatomic, strong) UIButton *muteButton;
@property(nonatomic, strong) UIButton *interruptButton;
@property(nonatomic, strong) UIButton *cameraButton;
@property(nonatomic, strong) UITableView *messageTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  self.view.backgroundColor = [UIColor whiteColor];
  // 实时语音回复列表
  self.messageList = [NSMutableArray array];
  [self createUI];
}

- (void)dealloc {
  [self.rtcRoom leaveRoom];
  [self.rtcRoom destroy];
  self.rtcRoom = nil;
  [ByteRTCVideo destroyRTCVideo];
  self.rtcVideo = nil;
}

// UI创建和布局代码
- (void)createUI {
  CGFloat width = self.view.bounds.size.width;
  CGFloat height = self.view.bounds.size.height;

  // 本地预览视图
  CGFloat previewHeight = height * 0.4;

  self.localView =
      [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, previewHeight)];
  self.localView.backgroundColor = [UIColor lightGrayColor];
  [self.view addSubview:self.localView];

  // 按钮区域
  CGFloat buttonY = previewHeight + 10;
  CGFloat buttonWidth = (width - 30) / 2;

  self.joinButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.joinButton.frame = CGRectMake(10, buttonY, buttonWidth, 44);
  self.joinButton.backgroundColor = [UIColor blueColor];
  [self.joinButton setTitle:@"连接" forState:UIControlStateNormal];
  [self.joinButton setTitle:@"断开" forState:UIControlStateSelected];
  [self.joinButton addTarget:self
                      action:@selector(connectButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];

  self.cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.cameraButton.frame =
      CGRectMake(width - buttonWidth - 10, buttonY, buttonWidth, 44);
  self.cameraButton.backgroundColor = [UIColor blueColor];
  [self.cameraButton setTitle:@"打开摄像头" forState:UIControlStateNormal];
  [self.cameraButton setTitle:@"关闭摄像头" forState:UIControlStateSelected];
  [self.cameraButton addTarget:self
                        action:@selector(cameraButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];

  self.muteButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.muteButton.frame = CGRectMake(10, buttonY + 54, buttonWidth, 44);
  self.muteButton.backgroundColor = [UIColor blueColor];
  [self.muteButton setTitle:@"静音" forState:UIControlStateNormal];
  [self.muteButton setTitle:@"取消静音" forState:UIControlStateSelected];
  [self.muteButton addTarget:self
                      action:@selector(muteButtonTapped)
            forControlEvents:UIControlEventTouchUpInside];

  self.interruptButton = [UIButton buttonWithType:UIButtonTypeCustom];
  self.interruptButton.frame =
      CGRectMake(width - buttonWidth - 10, buttonY + 54, buttonWidth, 44);
  self.interruptButton.backgroundColor = [UIColor blueColor];
  [self.interruptButton setTitle:@"打断" forState:UIControlStateNormal];
  [self.interruptButton addTarget:self
                           action:@selector(interruptButtonTapped)
                 forControlEvents:UIControlEventTouchUpInside];

  [self.view addSubview:self.joinButton];
  [self.view addSubview:self.cameraButton];
  [self.view addSubview:self.muteButton];
  [self.view addSubview:self.interruptButton];

  // 消息列表视图
  CGFloat tableY = buttonY + 108;
  CGFloat tableHeight = height - tableY - 20;
  self.messageTableView = [[UITableView alloc]
      initWithFrame:CGRectMake(10, tableY, width - 20, tableHeight)
              style:UITableViewStylePlain];
  self.messageTableView.delegate = self;
  self.messageTableView.dataSource = self;
  [self.messageTableView registerClass:[UITableViewCell class]
                forCellReuseIdentifier:@"MessageCell"];
  [self.view addSubview:self.messageTableView];
}

// 按钮事件处理
- (void)connectButtonTapped {
  self.joinButton.enabled = NO;
  [self.joinButton setTitle:@"连接中" forState:UIControlStateNormal];

  if (self.joinButton.isSelected) {
    [self.joinButton setTitle:@"连接" forState:UIControlStateNormal];
    [self.rtcRoom leaveRoom];
    self.joinButton.selected = NO;
    self.joinButton.backgroundColor = [UIColor blueColor];
    [self showToast:@"已断开"];
    self.joinButton.enabled = YES;
  } else {
    [[NetworkService shared]
        createRoomWithBotId:API_BOT_ID
                    voiceId:API_VOICE_ID
                 completion:^(RoomResponse *response, NSError *error) {
                   dispatch_async(dispatch_get_main_queue(), ^{
                     if (error || response.code != 0) {
                       NSString *errorMsg =
                           error.localizedDescription ?: response.msg;
                       UIAlertController *alert = [UIAlertController
                           alertControllerWithTitle:@"错误"
                                            message:[NSString
                                                        stringWithFormat:
                                                            @"连接失败: %@",
                                                            errorMsg]
                                     preferredStyle:
                                         UIAlertControllerStyleAlert];
                       [alert addAction:
                                  [UIAlertAction
                                      actionWithTitle:@"确定"
                                                style:UIAlertActionStyleDefault
                                              handler:nil]];
                       [self presentViewController:alert
                                          animated:YES
                                        completion:nil];
                     } else {
                       self.roomInfo = response.data;
                       [self buildRTCEngine];
                       [self bindLocalRenderView];
                       [self joinRoom];

                       [self.joinButton setTitle:@"断开"
                                        forState:UIControlStateNormal];
                       self.joinButton.selected = YES;
                       self.joinButton.backgroundColor = [UIColor redColor];
                       [self showToast:@"连接成功，开始实时对话"];
                     }

                     self.joinButton.enabled = YES;
                   });
                 }];
  }
}

// RTC相关方法
- (void)buildRTCEngine {
  if (!self.roomInfo) {
    return;
  }

  self.rtcVideo = [ByteRTCVideo createRTCVideo:self.roomInfo.app_id
                                      delegate:self
                                    parameters:@{}];
  [self.rtcVideo startAudioCapture];
}

- (void)bindLocalRenderView {
  ByteRTCVideoCanvas *canvas = [[ByteRTCVideoCanvas alloc] init];

  canvas.view = self.localView;
  canvas.renderMode = ByteRTCRenderModeHidden;
  [self.rtcVideo setLocalVideoCanvas:ByteRTCStreamIndexMain withCanvas:canvas];
}

- (void)joinRoom {
  self.rtcRoom = [self.rtcVideo createRTCRoom:self.roomInfo.room_id];
  self.rtcRoom.delegate = self;

  ByteRTCUserInfo *userInfo = [[ByteRTCUserInfo alloc] init];
  userInfo.userId = self.roomInfo.uid;

  ByteRTCRoomConfig *roomConfig = [[ByteRTCRoomConfig alloc] init];
  roomConfig.isAutoPublish = YES;
  roomConfig.isAutoSubscribeAudio = YES;
  roomConfig.isAutoSubscribeVideo = YES;

  [self.rtcRoom joinRoom:self.roomInfo.token
                userInfo:userInfo
              roomConfig:roomConfig];
}

// 其他按钮事件
- (void)muteButtonTapped {
  self.muteButton.selected = !self.muteButton.selected;

  if (self.muteButton.selected) {
    [self.rtcVideo stopAudioCapture];
    [self showToast:@"已静音"];
  } else {
    [self.rtcVideo startAudioCapture];
    [self showToast:@"已取消静音"];
  }
}

// 打断
- (void)interruptButtonTapped {
  NSDictionary *message = @{
    @"id" : @"event_1",
    @"event_type" : @"conversation.chat.cancel",
    @"data" : @"{}"
  };

  NSError *error;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                     options:0
                                                       error:&error];

  if (!error) {
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    [self.rtcRoom sendUserMessage:API_BOT_ID
                          message:jsonString
                           config:ByteRTCMessageConfigReliableOrdered];
    [self showToast:@"已打断"];
  }
}

// 控制摄像头
- (void)cameraButtonTapped {
  self.cameraButton.selected = !self.cameraButton.selected;

  if (self.cameraButton.selected) {
    [self.rtcVideo startVideoCapture];
    [self showToast:@"摄像头已打开"];
  } else {
    [self.rtcVideo stopVideoCapture];
    [self showToast:@"摄像头已关闭"];
  }
}

// 消息处理
- (void)addMessage:(NSString *)message eventType:(NSString *)eventType {
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([self.lastEventType isEqualToString:@"conversation.message.delta"] &&
        [eventType isEqualToString:@"conversation.message.delta"]) {
      if (self.messageList.count > 0) {
        NSString *lastMessage = [self.messageList lastObject];
        [self.messageList removeLastObject];
        [self.messageList
            addObject:[lastMessage stringByAppendingString:message]];
      }
    } else if ([eventType isEqualToString:@"conversation.message.delta"]) {
      [self.messageList addObject:message];
    }

    self.lastEventType = eventType;

    [self.messageTableView reloadData];

    if (self.messageList.count > 0) {
      NSIndexPath *indexPath =
          [NSIndexPath indexPathForRow:self.messageList.count - 1 inSection:0];
      [self.messageTableView
          scrollToRowAtIndexPath:indexPath
                atScrollPosition:UITableViewScrollPositionBottom
                        animated:YES];
    }
  });
}

// UITableView代理方法
- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
  return self.messageList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell =
      [tableView dequeueReusableCellWithIdentifier:@"MessageCell"
                                      forIndexPath:indexPath];

  cell.textLabel.text = self.messageList[indexPath.row];
  cell.textLabel.numberOfLines = 0;
  return cell;
}

// 工具方法
- (void)showToast:(NSString *)message {
  dispatch_async(dispatch_get_main_queue(), ^{
    UILabel *toastLabel = [[UILabel alloc] init];
    toastLabel.backgroundColor =
        [[UIColor blackColor] colorWithAlphaComponent:0.7];
    toastLabel.textColor = [UIColor whiteColor];
    toastLabel.textAlignment = NSTextAlignmentCenter;
    toastLabel.font = [UIFont systemFontOfSize:14];
    toastLabel.text = message;
    toastLabel.alpha = 1.0;
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds = YES;

    CGSize textSize = [toastLabel intrinsicContentSize];
    CGFloat labelWidth =
        MIN(textSize.width + 40, self.view.frame.size.width - 40);

    toastLabel.frame =
        CGRectMake(20, self.view.frame.size.height - 100, labelWidth, 35);
    toastLabel.center = CGPointMake(self.view.center.x, toastLabel.center.y);
    [self.view addSubview:toastLabel];

    [UIView animateWithDuration:0.5
        delay:3.0
        options:UIViewAnimationOptionCurveEaseOut
        animations:^{
          toastLabel.alpha = 0.0;
        }
        completion:^(BOOL finished) {
          [toastLabel removeFromSuperview];
        }];
  });
}

// ByteRTCVideoDelegate & ByteRTCRoomDelegate
- (void)rtcRoom:(ByteRTCRoom *)rtcRoom
    onRoomStateChanged:(NSString *)roomId
               withUid:(NSString *)uid
                 state:(NSInteger)state
             extraInfo:(NSString *)extraInfo {
  NSLog(@"房间状态变更 - 房间ID: %@, 用户ID: %@, 状态码: %ld, 附加信息: %@",
        roomId, uid, (long)state, extraInfo);
}

- (void)rtcRoom:(ByteRTCRoom *)rtcRoom
    onUserMessageReceived:(NSString *)uid
                  message:(NSString *)message {
  NSLog(@"收到用户消息 - 用户ID: %@, 消息: %@", uid, message);

  NSError *error;
  NSData *jsonData = [message dataUsingEncoding:NSUTF8StringEncoding];
  NSDictionary *messageDict = [NSJSONSerialization JSONObjectWithData:jsonData
                                                              options:0
                                                                error:&error];

  if (!error) {
    NSString *eventType = messageDict[@"event_type"];

    if ([eventType isEqualToString:@"conversation.message.delta"] ||
        [eventType isEqualToString:@"conversation.message.completed"]) {
      NSString *content = messageDict[@"data"][@"content"] ?: @"";
      [self addMessage:content eventType:eventType];
    }
  }
}

@end
