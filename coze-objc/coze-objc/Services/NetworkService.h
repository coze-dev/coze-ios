#import <Foundation/Foundation.h>
#import "ApiResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface NetworkService : NSObject

+ (instancetype)shared;
- (void)createRoomWithBotId:(NSString *)botId
                    voiceId:(nullable NSString *)voiceId
                 completion:(void (^)(RoomResponse *_Nullable response,
                         NSError *_Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
