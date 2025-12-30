import SwiftUI

// ask if theyre offering or looking for help
struct UserTypeSelectionView: View {
    @Bindable var authViewModel: AuthViewModel
    let name: String
    let email: String
    let profileImageURL: String?
    let userId: String
    
    @State private var selectedType: UserType?
    @State private var showLocationView = false
    
    enum UserType {
        case serviceProvider
        case seeker
        
        var title: String {
            switch self {
            case .serviceProvider: return "I Offer Services"
            case .seeker: return "I Need Help"
            }
        }
        
        var description: String {
            switch self {
            case .serviceProvider: return "I can help others with tasks, tutoring, errands, and more"
            case .seeker: return "I'm looking for help in my community"
            }
        }
        
        var icon: String {
            switch self {
            case .serviceProvider: return "hand.raised.fill"
            case .seeker: return "magnifyingglass"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.blue)
                    
                    Text("How will you use EduMe?") // important question
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("You can always browse and use both features")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 60)
                
                VStack(spacing: 16) {
                    UserTypeCard(
                        type: .serviceProvider,
                        isSelected: selectedType == .serviceProvider
                    ) {
                        selectedType = .serviceProvider
                    }
                    
                    UserTypeCard(
                        type: .seeker,
                        isSelected: selectedType == .seeker
                    ) {
                        selectedType = .seeker
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button {
                    if selectedType != nil {
                        showLocationView = true
                    }
                } label: {
                    Text("Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(selectedType != nil ? Color.blue : Color.gray)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(selectedType == nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .navigationDestination(isPresented: $showLocationView) {
                GoogleLocationSharingView(
                    authViewModel: authViewModel,
                    name: name,
                    email: email,
                    profileImageURL: profileImageURL,
                    userId: userId,
                    isServiceProvider: selectedType == .serviceProvider
                )
            }
        }
    }
}

struct UserTypeCard: View {
    let type: UserTypeSelectionView.UserType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(type.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text(type.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .padding(20)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
