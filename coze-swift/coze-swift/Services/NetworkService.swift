import Foundation

class NetworkService {
  static let shared = NetworkService()

  func createRoom(botId: String, voiceId: String?) async throws -> RoomResponse {
    let path = "/v1/audio/rooms"

    var request = URLRequest(url: URL(string: APIConfig.baseURL + path)!)
    request.httpMethod = "POST"
    request.addValue("Bearer \(APIConfig.accessToken)", forHTTPHeaderField: "Authorization")
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = [
      "bot_id": botId,
      "connector_id": "1024",
      "voice_id": voiceId,
    ]

    // for debug
    print("[createRoom] Headers: \(request.allHTTPHeaderFields)")
    print("[createRoom] Request: \(body)")

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)

    // for debug
    if let jsonString = String(data: data, encoding: .utf8) {
      print("[createRoom] Response: \(jsonString)")
    }

    return try JSONDecoder().decode(RoomResponse.self, from: data)
  }
}
