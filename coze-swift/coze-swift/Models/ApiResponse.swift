import Foundation

struct Detail: Codable {
  let logid: String
}

struct RoomData: Codable {
  let app_id: String
  let room_id: String
  let token: String
  let uid: String
}

struct RoomResponse: Codable {
  let code: Int
  let msg: String
  let data: RoomData?
  let detail: Detail?
}

// 消息数据结构，以下只是其中一种，具体请参考官方文档
struct MessageData: Codable {
  struct Data: Codable {
    let id: String?
    let conversation_id: String?
    let bot_id: String?
    let role: String?
    let type: String?
    let content: String?
    let content_type: String?
    let chat_id: String?
    let section_id: String?
  }

  let id: String?
  let event_type: String?
  let data: Data?
}
