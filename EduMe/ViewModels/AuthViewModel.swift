import Foundation
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

// google sign in was actually the easiest part surprisingly
@Observable
class AuthViewModel {
    var currentUser: User?
    var isAuthenticated = false
    var isLoading = false
    var errorMessage: String?
    var pendingGoogleUser: PendingGoogleUser?
    
    struct PendingGoogleUser: Identifiable, Hashable {
        var id: String { userId }
        let userId: String
        let name: String
        let email: String
        let profileImageURL: String?
    }
    
    private let db = Firestore.firestore()
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    init() {
        checkAuthState()
    }
    
    func checkAuthState() {
        if let firebaseUser = Auth.auth().currentUser {
            loadUserProfile(userId: firebaseUser.uid)
        }
    }
    
    func signInWithEmail(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            await loadUserProfileAsync(userId: result.user.uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUpWithEmail(name: String, email: String, password: String, location: User.UserLocation?) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = User(
                id: result.user.uid,
                name: name,
                email: email,
                location: location
            )
            
            try await saveUserProfile(user: user)
            currentUser = user
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase not configured"
            isLoading = false
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Cannot find root view controller"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            let user = result.user
            
            guard let idToken = user.idToken?.tokenString else {
                errorMessage = "Cannot get ID token"
                isLoading = false
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            let authResult = try await Auth.auth().signIn(with: credential)
            
            // Check if user already exists in Firestore
            let userDoc = try await db.collection("users").document(authResult.user.uid).getDocument()
            
            if userDoc.exists {
                // already signed up before, skip the onboarding stuff
                loadUserProfile(userId: authResult.user.uid)
            } else {
                // new user gotta do the whole flow
                pendingGoogleUser = PendingGoogleUser(
                    userId: authResult.user.uid,
                    name: user.profile?.name ?? "User",
                    email: user.profile?.email ?? "",
                    profileImageURL: user.profile?.imageURL(withDimension: 200)?.absoluteString
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateUserLocation(location: User.UserLocation) async {
        guard var user = currentUser else { return }
        user.location = location
        
        do {
            try await saveUserProfile(user: user)
            currentUser = user
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func loadUserProfile(userId: String) {
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorMessage = error.localizedDescription
                return
            }
            
            guard let data = snapshot?.data() else { return }
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: data)
                let user = try JSONDecoder().decode(User.self, from: jsonData)
                self.currentUser = user
                self.isAuthenticated = true
            } catch {
                self.errorMessage = "Failed to decode user profile"
            }
        }
    }
    
    // async version for sign in flow
    private func loadUserProfileAsync(userId: String) async {
        do {
            let snapshot = try await db.collection("users").document(userId).getDocument()
            guard let data = snapshot.data() else {
                errorMessage = "User profile not found"
                return
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            let user = try JSONDecoder().decode(User.self, from: jsonData)
            self.currentUser = user
            self.isAuthenticated = true
        } catch {
            errorMessage = "Failed to load user profile: \(error.localizedDescription)"
        }
    }
    
    func saveUserProfile(user: User) async throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        try await db.collection("users").document(user.id).setData(json)
    }
}
