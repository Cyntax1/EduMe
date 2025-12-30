import Foundation

// added a bunch of categories so theres something for everyone
enum Category: String, CaseIterable, Identifiable, Codable {
    case tutoring = "Tutoring"
    case errands = "Errands"
    case tech = "Tech"
    case cleaning = "Cleaning"
    case moving = "Moving"
    case pets = "Pets"
    case rides = "Rides"
    case handyman = "Handyman"
    case childcare = "Childcare"
    case fitness = "Fitness"
    case cooking = "Cooking"
    case other = "Other"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .tutoring: return "book.fill"
        case .errands: return "bag.fill"
        case .tech: return "laptopcomputer"
        case .cleaning: return "sparkles"
        case .moving: return "shippingbox.fill"
        case .pets: return "pawprint.fill"
        case .rides: return "car.fill"
        case .handyman: return "wrench.and.screwdriver.fill"
        case .childcare: return "figure.and.child.holdinghands"
        case .fitness: return "figure.run"
        case .cooking: return "fork.knife"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .tutoring: return "blue"
        case .errands: return "green"
        case .tech: return "purple"
        case .cleaning: return "cyan"
        case .moving: return "orange"
        case .pets: return "brown"
        case .rides: return "indigo"
        case .handyman: return "yellow"
        case .childcare: return "pink"
        case .fitness: return "red"
        case .cooking: return "mint"
        case .other: return "gray"
        }
    }
}

struct Post: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: Category
    let timestamp: Date
    let userId: String
    let userName: String
    let userLocation: String?
    var latitude: Double?
    var longitude: Double?
    var price: Double?
    var isPriceNegotiable: Bool
    var contactEmail: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, timestamp, userId, userName, userLocation, latitude, longitude, price, isPriceNegotiable, contactEmail
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decode(Category.self, forKey: .category)
        userId = try container.decode(String.self, forKey: .userId)
        userName = try container.decode(String.self, forKey: .userName)
        userLocation = try container.decodeIfPresent(String.self, forKey: .userLocation)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        isPriceNegotiable = try container.decodeIfPresent(Bool.self, forKey: .isPriceNegotiable) ?? false
        contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail)
        
        // Handle Firestore Timestamp
        if let date = try? container.decode(Date.self, forKey: .timestamp) {
            timestamp = date
        } else {
            timestamp = Date()
        }
    }
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var priceDisplay: String? {
        guard let price = price else { return nil }
        if price == 0 {
            return "Free"
        }
        let formatted = String(format: "$%.0f", price)
        return isPriceNegotiable ? "\(formatted) (negotiable)" : formatted
    }
    
    init(id: String = UUID().uuidString, title: String, description: String, category: Category, timestamp: Date = Date(), userId: String, userName: String, userLocation: String? = nil, latitude: Double? = nil, longitude: Double? = nil, price: Double? = nil, isPriceNegotiable: Bool = false, contactEmail: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.timestamp = timestamp
        self.userId = userId
        self.userName = userName
        self.userLocation = userLocation
        self.latitude = latitude
        self.longitude = longitude
        self.price = price
        self.isPriceNegotiable = isPriceNegotiable
        self.contactEmail = contactEmail
    }
}
