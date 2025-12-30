import Foundation
import CoreLocation

// user data stuff
struct User: Identifiable, Codable {
    let id: String
    var name: String
    var email: String
    var profileImageURL: String?
    var location: UserLocation?
    var isServiceProvider: Bool
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, profileImageURL, location, isServiceProvider, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        profileImageURL = try container.decodeIfPresent(String.self, forKey: .profileImageURL)
        location = try container.decodeIfPresent(UserLocation.self, forKey: .location)
        isServiceProvider = try container.decodeIfPresent(Bool.self, forKey: .isServiceProvider) ?? false
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    struct UserLocation: Codable {
        let latitude: Double
        let longitude: Double
        let areaRadius: Double
        var city: String?
        var state: String?
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        
        var displayText: String {
            if let city = city, let state = state {
                return "\(city), \(state)"
            } else if let city = city {
                return city
            }
            return "Location shared"
        }
        
        var areaDescription: String {
            let miles = areaRadius / 1609.34
            return String(format: "~%.0f mile radius", miles)
        }
    }
    
    init(id: String, name: String, email: String, profileImageURL: String? = nil, location: UserLocation? = nil, isServiceProvider: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImageURL = profileImageURL
        self.location = location
        self.isServiceProvider = isServiceProvider
        self.createdAt = createdAt
    }
}
