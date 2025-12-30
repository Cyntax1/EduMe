import SwiftUI

// the liquid glass menu was fun to make
struct HomeView: View {
    @Bindable var postViewModel: PostViewModel
    let authViewModel: AuthViewModel
    let chatViewModel: ChatViewModel
    @State private var showingCreatePost = false
    @State private var showingPostTypeMenu = false
    @State private var selectedPostType: PostType?
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 16) {
                        CategoryFilter(selectedCategory: $postViewModel.selectedCategory)
                            .padding(.horizontal)
                        
                        if postViewModel.filteredPosts.isEmpty {
                            EmptyStateView()
                        } else {
                            ForEach(postViewModel.filteredPosts) { post in
                                PostCard(
                                    post: post,
                                    authViewModel: authViewModel,
                                    chatViewModel: chatViewModel,
                                    postViewModel: postViewModel
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .background(Color(.systemGroupedBackground))
                
                // Liquid Glass Overlay
                if showingPostTypeMenu {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                showingPostTypeMenu = false
                            }
                        }
                    
                    LiquidGlassMenu(
                        isShowing: $showingPostTypeMenu,
                        onSelect: { postType in
                            selectedPostType = postType
                            showingPostTypeMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                showingCreatePost = true
                            }
                        }
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .navigationTitle("Community Board")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showingPostTypeMenu = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreatePost) {
                CreatePostView(viewModel: postViewModel, authViewModel: authViewModel, initialPostType: selectedPostType)
            }
            .onAppear {
                postViewModel.loadPosts()
                // Set user location for filtering posts by area
                if let location = authViewModel.currentUser?.location {
                    postViewModel.setUserLocation(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        radius: location.areaRadius
                    )
                }
            }
        }
    }
}

// ngl this looks so clean
struct LiquidGlassMenu: View {
    @Binding var isShowing: Bool
    let onSelect: (PostType) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Text("What would you like to do?")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.top, 24)
                .padding(.bottom, 20)
            
            VStack(spacing: 12) {
                LiquidGlassButton(
                    title: "Offer a Service",
                    subtitle: "Help someone in your community",
                    icon: "hand.raised.fill",
                    color: .green
                ) {
                    onSelect(.offering)
                }
                
                LiquidGlassButton(
                    title: "Get Help",
                    subtitle: "Find someone to assist you",
                    icon: "magnifyingglass",
                    color: .blue
                ) {
                    onSelect(.seeking)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: 320)
        .background {
            RoundedRectangle(cornerRadius: 28)
                .fill(.ultraThinMaterial) // frosted glass effect yessss
                .shadow(color: .black.opacity(0.2), radius: 30, y: 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.5), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

struct LiquidGlassButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .opacity(isPressed ? 0.8 : 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            }
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct CategoryFilter: View {
    @Binding var selectedCategory: Category?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(Category.allCases) { category in
                    FilterChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No posts yet")
                .font(.title3)
                .fontWeight(.semibold)
            Text("Be the first to ask for or offer help!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 60)
    }
}
