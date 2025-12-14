import Foundation
import FirebaseFirestore

// real time messaging was such a pain to get working
@Observable
class ChatViewModel {
    var chats: [Chat] = []
    var messages: [String: [Message]] = [:]
    var isLoading = false
    
    private let db = Firestore.firestore()
    private var chatListeners: [String: ListenerRegistration] = [:]
    
    func loadChats(userId: String) {
        db.collection("chats")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading chats: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.chats = documents.compactMap { doc in
                    try? doc.data(as: Chat.self)
                }
            }
    }
    
    // finally got this working after like 2 hours of debugging timestamps
    func loadMessages(chatId: String) {
        // Remove existing listener if any to refresh
        chatListeners[chatId]?.remove()
        chatListeners[chatId] = nil
        
        let listener = db.collection("messages")
            .whereField("chatId", isEqualTo: chatId)
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error loading messages: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.messages[chatId] = documents.compactMap { doc in
                    do {
                        return try doc.data(as: Message.self)
                    } catch {
                        print("Error decoding message: \(error)")
                        return nil
                    }
                }
                print("Loaded \(self.messages[chatId]?.count ?? 0) messages for chat \(chatId)")
            }
        
        chatListeners[chatId] = listener
    }
    
    func createOrGetChat(postId: String, postTitle: String, postOwnerId: String, postOwnerName: String, currentUserId: String, currentUserName: String) async -> Chat? {
        let chatQuery = db.collection("chats")
            .whereField("postId", isEqualTo: postId)
            .whereField("participants", arrayContains: currentUserId)
        
        do {
            let snapshot = try await chatQuery.getDocuments()
            
            if let existingChat = snapshot.documents.first {
                return try existingChat.data(as: Chat.self) // ez already exists
            }
            
            let chatId = UUID().uuidString
            let now = Date()
            
            let chatData: [String: Any] = [
                "id": chatId,
                "postId": postId,
                "postTitle": postTitle,
                "participants": [currentUserId, postOwnerId],
                "participantNames": [
                    currentUserId: currentUserName,
                    postOwnerId: postOwnerName
                ],
                "createdAt": Timestamp(date: now)
            ]
            
            try await db.collection("chats").document(chatId).setData(chatData) // IM SUCH A GENIUS NO WAY THIS WORKED
            
            let chat = Chat(
                id: chatId,
                postId: postId,
                postTitle: postTitle,
                participants: [currentUserId, postOwnerId],
                participantNames: [
                    currentUserId: currentUserName,
                    postOwnerId: postOwnerName
                ],
                createdAt: now
            )
            
            return chat
        } catch {
            print("Error creating chat: \(error)")
            return nil
        }
    }
    
    @MainActor
    func sendMessage(chatId: String, senderId: String, senderName: String, text: String) async {
        let messageId = UUID().uuidString
        let now = Date()
        
        // Optimistic UI update - show message immediately
        let newMessage = Message(
            id: messageId,
            chatId: chatId,
            senderId: senderId,
            senderName: senderName,
            text: text,
            timestamp: now
        )
        
        if messages[chatId] == nil {
            messages[chatId] = []
        }
        messages[chatId]?.append(newMessage)
        
        let messageData: [String: Any] = [
            "id": messageId,
            "chatId": chatId,
            "senderId": senderId,
            "senderName": senderName,
            "text": text,
            "timestamp": Timestamp(date: now)
        ]
        
        do {
            try await db.collection("messages").document(messageId).setData(messageData)
            
            try await db.collection("chats").document(chatId).updateData([
                "lastMessage": text,
                "lastMessageTime": Timestamp(date: now)
            ])
        } catch {
            print("Error sending message: \(error)")
            // Remove the optimistic message on failure
            messages[chatId]?.removeAll { $0.id == messageId }
        }
    }
    
    func cleanup() {
        for (_, listener) in chatListeners {
            listener.remove()
        }
        chatListeners.removeAll()
    }
}
