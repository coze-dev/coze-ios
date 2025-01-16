#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Detail : NSObject
@property (nonatomic, copy, nullable) NSString *logid;
@end

@interface RoomData : NSObject
@property (nonatomic, copy, nullable) NSString *app_id;
@property (nonatomic, copy, nullable) NSString *room_id;
@property (nonatomic, copy, nullable) NSString *token;
@property (nonatomic, copy, nullable) NSString *uid;
@end

@interface RoomResponse : NSObject
@property (nonatomic, assign) NSInteger code;
@property (nonatomic, copy, nullable) NSString *msg;
@property (nonatomic, strong, nullable) RoomData *data;
@property (nonatomic, strong, nullable) Detail *detail;
@end

@interface MessageData : NSObject
@property (nonatomic, copy, nullable) NSString *id;
@property (nonatomic, copy, nullable) NSString *event_type;
@property (nonatomic, strong, nullable) NSDictionary *data;
@end

NS_ASSUME_NONNULL_END 