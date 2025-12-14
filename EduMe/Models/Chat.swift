import Foundation

// chat and message models for dms
struct Chat: Identifiable, Codable, Hashable {
    let id: String
    let postId: String
    let postTitle: String
    let participants: [String]
    let participantNames: [String: String]
    var lastMessage: String?
    var lastMessageTime: Date?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, postId, postTitle, participants, participantNames, lastMessage, lastMessageTime, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        postId = try container.decode(String.self, forKey: .postId)
        postTitle = try container.decode(String.self, forKey: .postTitle)
        participants = try container.decode([String].self, forKey: .participants)
        participantNames = try container.decode([String: String].self, forKey: .participantNames)
        lastMessage = try container.decodeIfPresent(String.self, forKey: .lastMessage)
        
        if let date = try? container.decode(Date.self, forKey: .lastMessageTime) {
            lastMessageTime = date
        } else {
            lastMessageTime = nil
        }
        
        if let date = try? container.decode(Date.self, forKey: .createdAt) {
            createdAt = date
        } else {
            createdAt = Date()
        }
    }
    
    init(id: String, postId: String, postTitle: String, participants: [String], participantNames: [String: String], lastMessage: String? = nil, lastMessageTime: Date? = nil, createdAt: Date = Date()) {
        self.id = id
        self.postId = postId
        self.postTitle = postTitle
        self.participants = participants
        self.participantNames = participantNames
        self.lastMessage = lastMessage
        self.lastMessageTime = lastMessageTime
        self.createdAt = createdAt
    }
    
    func otherUserName(currentUserId: String) -> String {
        participantNames.first { $0.key != currentUserId }?.value ?? "User"
    }
    
    func otherUserId(currentUserId: String) -> String {
        participants.first { $0 != currentUserId } ?? ""
    }
    
    var lastMessageTimeAgo: String? {
        guard let time = lastMessageTime else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: time, relativeTo: Date())
    }
}

struct Message: Identifiable, Codable {
    let id: String
    let chatId: String
    let senderId: String
    let senderName: String
    let text: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, chatId, senderId, senderName, text, timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        chatId = try container.decode(String.self, forKey: .chatId)
        senderId = try container.decode(String.self, forKey: .senderId)
        senderName = try container.decode(String.self, forKey: .senderName)
        text = try container.decode(String.self, forKey: .text)
        
        if let date = try? container.decode(Date.self, forKey: .timestamp) {
            timestamp = date
        } else {
            timestamp = Date()
        }
    }
    
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    init(id: String = UUID().uuidString, chatId: String, senderId: String, senderName: String, text: String, timestamp: Date = Date()) {
        self.id = id
        self.chatId = chatId
        self.senderId = senderId
        self.senderName = senderName
        self.text = text
        self.timestamp = timestamp
    }
}
