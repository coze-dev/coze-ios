#import <UIKit/UIKit.h>
#import <VolcEngineRTC/VolcEngineRTC.h>
#import "ApiResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface ViewController
    : UIViewController <ByteRTCVideoDelegate, ByteRTCRoomDelegate,
                        UITableViewDelegate, UITableViewDataSource>

@end

NS_ASSUME_NONNULL_END
