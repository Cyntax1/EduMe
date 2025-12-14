import SwiftUI

// first thing users see when they open the app
struct WelcomeView: View {
    @Bindable var authViewModel: AuthViewModel
    @State private var showEmailSignUp = false
    @State private var showSignIn = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "hands.and.sparkles.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    Text("Welcome to EduMe") // had to pick a good name lol
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Connect with your community to give and receive help")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await authViewModel.signInWithGoogle()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "g.circle.fill")
                                .font(.title2)
                            Text("Continue with Google")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
                    }
                    
                    Button {
                        showEmailSignUp = true
                    } label: {
                        Text("Sign up with Email")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        showSignIn = true
                    } label: {
                        Text("Already have an account? Sign In")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 8)
                    
                    Text("By continuing, you agree to our Terms & Privacy Policy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
            .navigationDestination(isPresented: $showEmailSignUp) {
                EmailSignUpView(authViewModel: authViewModel)
            }
            .navigationDestination(isPresented: $showSignIn) {
                SignInView(authViewModel: authViewModel)
            }
            .navigationDestination(item: $authViewModel.pendingGoogleUser) { pendingUser in
                UserTypeSelectionView(
                    authViewModel: authViewModel,
                    name: pendingUser.name,
                    email: pendingUser.email,
                    profileImageURL: pendingUser.profileImageURL,
                    userId: pendingUser.userId
                )
            }
        }
        .overlay {
            if authViewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .alert("Error", isPresented: .constant(authViewModel.errorMessage != nil)) {
            Button("OK") {
                authViewModel.errorMessage = nil
            }
        } message: {
            if let error = authViewModel.errorMessage {
                Text(error)
            }
        }
    }
}
