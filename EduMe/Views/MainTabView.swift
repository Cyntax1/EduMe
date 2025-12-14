import SwiftUI

// the main app with tabs at the bottom
struct MainTabView: View {
    let authViewModel: AuthViewModel
    @State private var postViewModel = PostViewModel()
    @State private var chatViewModel = ChatViewModel()
    
    var body: some View {
        TabView {
            HomeView(
                postViewModel: postViewModel,
                authViewModel: authViewModel,
                chatViewModel: chatViewModel
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            ChatsListView(authViewModel: authViewModel)
            .tabItem {
                Label("Messages", systemImage: "bubble.left.and.bubble.right.fill")
            }
            
            ProfileView(authViewModel: authViewModel)
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
        }
        .onAppear {
            if let userId = authViewModel.currentUser?.id {
                chatViewModel.loadChats(userId: userId)
            }
        }
        .onDisappear {
            postViewModel.cleanup() // gotta clean up listeners
            chatViewModel.cleanup()
        }
    }
}
