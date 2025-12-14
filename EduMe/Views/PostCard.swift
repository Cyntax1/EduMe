import SwiftUI

// each post on the feed looks like this
struct PostCard: View {
    let post: Post
    let authViewModel: AuthViewModel
    let chatViewModel: ChatViewModel
    let postViewModel: PostViewModel
    @State private var showingChat = false
    @State private var navigateToChat: Chat?
    @State private var showDeleteConfirmation = false
    
    var isOwnPost: Bool {
        post.userId == authViewModel.currentUser?.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CategoryBadge(category: post.category)
                Spacer()
                Text(post.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(post.title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(post.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "person.circle.fill")
                            .font(.caption)
                        Text(post.userName)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                    
                    if let location = post.userLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                            Text(location)
                                .font(.caption2)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let priceDisplay = post.priceDisplay {
                    Text(priceDisplay)
                        .font(.headline)
                        .foregroundStyle(.green)
                }
            }
            
            if !isOwnPost {
                Button {
                    startConversation() // starts a chat with the poster
                } label: {
                    HStack {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Message")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else {
                // your own post, show delete option
                HStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Your post")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundStyle(.red)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await postViewModel.deletePost(postId: post.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this post? This cannot be undone.")
        }
        .navigationDestination(item: $navigateToChat) { chat in
            ChatView(
                chat: chat,
                authViewModel: authViewModel,
                chatViewModel: chatViewModel
            )
        }
    }
    
    private func startConversation() {
        guard let currentUser = authViewModel.currentUser else { return }
        
        Task {
            let chat = await chatViewModel.createOrGetChat(
                postId: post.id,
                postTitle: post.title,
                postOwnerId: post.userId,
                postOwnerName: post.userName,
                currentUserId: currentUser.id,
                currentUserName: currentUser.name
            )
            
            if let chat = chat {
                navigateToChat = chat
            }
        }
    }
}

struct CategoryBadge: View {
    let category: Category
    
    var body: some View {
        Text(category.rawValue)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(badgeColor.opacity(0.2))
            .foregroundStyle(badgeColor)
            .clipShape(Capsule())
    }
    
    private var badgeColor: Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        default: return .gray
        }
    }
}
