#import "APIConfig.h"
#import "NetworkService.h"

@implementation NetworkService

+ (instancetype)shared {
    static NetworkService *instance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        instance = [[NetworkService alloc] init];
    });
    return instance;
}

- (void)createRoomWithBotId:(NSString *)botId
                    voiceId:(NSString *)voiceId
                 completion:(void (^)(RoomResponse *response,
                         NSError *error))completion {
    NSString *path = @"/v1/audio/rooms";
    NSURL *url =
        [NSURL URLWithString:[API_BASE_URL stringByAppendingString:path]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    request.HTTPMethod = @"POST";
    [request      setValue:[NSString stringWithFormat:@"Bearer %@", API_ACCESS_TOKEN]
        forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *body = @{
            @"bot_id": botId,
            @"connector_id": @"1024",
            @"voice_id": voiceId ? : [NSNull null],
    };

    // for debug
    NSLog(@"[createRoom] Headers: %@", request.allHTTPHeaderFields);
    NSLog(@"[createRoom] Request: %@", body);

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:body
                                                       options:0
                                                         error:&error];

    if (error) {
        if (completion) {
            completion(nil, error);
        }

        return;
    }

    request.HTTPBody = jsonData;

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *data, NSURLResponse *response,
                                       NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }

            return;
        }

        NSError *jsonError;
        NSDictionary *json =
            [NSJSONSerialization JSONObjectWithData:data
                                            options:0
                                              error:&jsonError];

        if (jsonError) {
            if (completion) {
                completion(nil, jsonError);
            }

            return;
        }

        // for debug
        NSLog(@"[createRoom] Response: %@", json);

        RoomResponse *roomResponse = [[RoomResponse alloc] init];
        roomResponse.code = [json[@"code"] integerValue];
        roomResponse.msg = json[@"msg"];

        if (json[@"data"]) {
            RoomData *roomData = [[RoomData alloc] init];
            roomData.app_id = json[@"data"][@"app_id"];
            roomData.room_id = json[@"data"][@"room_id"];
            roomData.token = json[@"data"][@"token"];
            roomData.uid = json[@"data"][@"uid"];
            roomResponse.data = roomData;
        }

        if (json[@"detail"]) {
            Detail *detail = [[Detail alloc] init];
            detail.logid = json[@"detail"][@"logid"];
            roomResponse.detail = detail;
        }

        if (completion) {
            completion(roomResponse, nil);
        }
    }];

    [task resume];
}

@end
