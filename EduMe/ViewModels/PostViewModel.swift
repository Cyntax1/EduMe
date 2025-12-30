import Foundation
import SwiftUI
import FirebaseFirestore
import CoreLocation

// im pretty proud of this one ngl
@Observable
class PostViewModel {
    var posts: [Post] = []
    var selectedCategory: Category?
    var isLoading = false
    var errorMessage: String?
    var userLocation: CLLocation?
    var userRadius: Double = 80467.0 // 50 miles in meters, had to google the conversion lol
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    var filteredPosts: [Post] {
        var filtered = posts
        
        // Filter by user's location radius
        if let userLoc = userLocation {
            filtered = filtered.filter { post in
                guard let lat = post.latitude, let lon = post.longitude else {
                    return false // Don't show posts without location
                }
                let postLocation = CLLocation(latitude: lat, longitude: lon)
                let distance = userLoc.distance(from: postLocation)
                return distance <= userRadius
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    func loadPosts() {
        listener = db.collection("posts")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.posts = documents.compactMap { doc in
                    try? doc.data(as: Post.self) // dont touch this it works
                }
            }
    }
    
    func setUserLocation(latitude: Double, longitude: Double, radius: Double) {
        userLocation = CLLocation(latitude: latitude, longitude: longitude)
        userRadius = radius
    }
    
    func addPost(title: String, description: String, category: Category, price: Double?, isPriceNegotiable: Bool, contactEmail: String?, userId: String, userName: String, userLocationText: String?, latitude: Double?, longitude: Double?) async {
        isLoading = true
        errorMessage = nil
        
        let postId = UUID().uuidString
        
        var postData: [String: Any] = [
            "id": postId,
            "title": title,
            "description": description,
            "category": category.rawValue,
            "timestamp": Timestamp(date: Date()), // THIS IS THE FIX that took forever to figure out
            "userId": userId,
            "userName": userName,
            "isPriceNegotiable": isPriceNegotiable
        ]
        
        if let userLocationText = userLocationText {
            postData["userLocation"] = userLocationText
        }
        if let latitude = latitude {
            postData["latitude"] = latitude
        }
        if let longitude = longitude {
            postData["longitude"] = longitude
        }
        if let price = price {
            postData["price"] = price
        }
        if let contactEmail = contactEmail {
            postData["contactEmail"] = contactEmail
        }
        
        do {
            try await db.collection("posts").document(postId).setData(postData)
            print("Post created successfully with ID: \(postId)")
        } catch {
            print("Error creating post: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // delete a post, only works if you own it
    func deletePost(postId: String) async {
        do {
            try await db.collection("posts").document(postId).delete()
            print("Post deleted: \(postId)")
        } catch {
            print("Error deleting post: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
    }
    
    func cleanup() {
        listener?.remove()
        listener = nil
    }
}
