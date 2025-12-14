import SwiftUI

// i like how clean this form turned out
enum PostType: String, CaseIterable {
    case offering = "I'm Offering a Service"
    case seeking = "I'm Looking for Help"
    
    var icon: String {
        switch self {
        case .offering: return "hand.raised.fill"
        case .seeking: return "magnifyingglass"
        }
    }
}

struct CreatePostView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: PostViewModel
    let authViewModel: AuthViewModel
    var initialPostType: PostType? = nil
    
    @State private var postType: PostType?
    @State private var title = ""
    @State private var description = ""
    @State private var selectedCategory: Category = .tutoring
    @State private var contact = ""
    @State private var priceText = ""
    @State private var isPriceNegotiable = false
    @State private var hasPrice = false
    @State private var isChecking = false
    @State private var showModerationAlert = false
    @State private var moderationMessage = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case title, description, contact, price
    }
    
    var isFormValid: Bool {
        postType != nil &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !description.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(PostType.allCases, id: \.self) { type in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                postType = type
                            }
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: type.icon)
                                    .font(.title2)
                                    .foregroundStyle(postType == type ? .blue : .secondary)
                                    .frame(width: 30)
                                
                                Text(type.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if postType == type {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("What would you like to do?")
                }
                
                if postType != nil {
                    Section {
                        TextField(postType == .offering ? "What are you offering?" : "What do you need?", text: $title)
                            .focused($focusedField, equals: .title)
                        
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(Category.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                    } header: {
                        Text(postType == .offering ? "Your Service" : "Your Request")
                    }
                    
                    Section {
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text(postType == .offering ? "Describe the service you're offering..." : "Describe what help you need...")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                            TextEditor(text: $description)
                                .focused($focusedField, equals: .description)
                                .frame(minHeight: 100)
                        }
                    } header: {
                        Text("Description")
                    }
                    
                    if postType == .offering {
                        Section {
                            Toggle("Set a price", isOn: $hasPrice)
                            
                            if hasPrice {
                                HStack {
                                    Text("$")
                                        .foregroundStyle(.secondary)
                                    TextField("0", text: $priceText)
                                        .keyboardType(.numberPad)
                                        .focused($focusedField, equals: .price)
                                }
                                
                                Toggle("Price is negotiable", isOn: $isPriceNegotiable)
                            }
                        } header: {
                            Text("Pricing")
                        } footer: {
                            Text("Set your rate for this service. Leave at $0 if it's free.")
                        }
                    }
                    
                    Section {
                        TextField("Email (optional)", text: $contact)
                            .focused($focusedField, equals: .contact)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    } header: {
                        Text("Contact Info")
                    } footer: {
                        Text("People can message you through the app. Email is optional.")
                    }
                }
            }
            .navigationTitle("New Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        submitPost()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid || isChecking)
                }
            }
            .overlay {
                if isChecking {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Checking content...")
                                .font(.subheadline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .alert("Content Warning", isPresented: $showModerationAlert) {
                Button("OK") {
                    showModerationAlert = false
                }
            } message: {
                Text(moderationMessage)
            }
            .onAppear {
                if let initial = initialPostType {
                    postType = initial
                }
            }
        }
    }
    
    private func submitPost() {
        guard let currentUser = authViewModel.currentUser else { return }
        
        let price: Double? = if hasPrice {
            Double(priceText) ?? 0
        } else {
            nil
        }
        
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedDescription = description.trimmingCharacters(in: .whitespaces)
        
        isChecking = true
        
        Task {
            do {
                // gotta make sure nobody posts anything weird
                _ = try await ModerationService.shared.moderateContent(
                    title: trimmedTitle,
                    description: trimmedDescription
                )
                
                // Content is appropriate, create the post
                await viewModel.addPost(
                    title: trimmedTitle,
                    description: trimmedDescription,
                    category: selectedCategory,
                    price: price,
                    isPriceNegotiable: isPriceNegotiable,
                    contactEmail: contact.trimmingCharacters(in: .whitespaces).isEmpty ? nil : contact.trimmingCharacters(in: .whitespaces),
                    userId: currentUser.id,
                    userName: currentUser.name,
                    userLocationText: currentUser.location?.displayText,
                    latitude: currentUser.location?.latitude,
                    longitude: currentUser.location?.longitude
                )
                
                await MainActor.run {
                    isChecking = false
                    dismiss()
                }
            } catch let error as ModerationService.ModerationError {
                await MainActor.run {
                    isChecking = false
                    moderationMessage = error.localizedDescription ?? "Your post contains inappropriate content and cannot be submitted."
                    showModerationAlert = true
                }
            } catch {
                await MainActor.run {
                    isChecking = false
                    moderationMessage = "Unable to verify content. Please try again."
                    showModerationAlert = true
                }
            }
        }
    }
}
