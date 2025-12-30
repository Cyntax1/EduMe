import SwiftUI

// all your convos in one place
struct ChatsListView: View {
    let authViewModel: AuthViewModel
    @State private var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                if chatViewModel.chats.isEmpty {
                    EmptyChatStateView()
                } else {
                    List(chatViewModel.chats) { chat in
                        NavigationLink {
                            ChatView(
                                chat: chat,
                                authViewModel: authViewModel,
                                chatViewModel: chatViewModel
                            )
                        } label: {
                            ChatRowView(chat: chat, currentUserId: authViewModel.currentUser?.id ?? "")
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Messages")
            .onAppear {
                if let userId = authViewModel.currentUser?.id {
                    chatViewModel.loadChats(userId: userId)
                }
            }
        }
    }
}

struct ChatRowView: View {
    let chat: Chat
    let currentUserId: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.otherUserName(currentUserId: currentUserId))
                        .font(.headline)
                    
                    Text(chat.postTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if let timeAgo = chat.lastMessageTimeAgo {
                    Text(timeAgo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let lastMessage = chat.lastMessage {
                Text(lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyChatStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No messages yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Start a conversation by offering help on a post")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
