import Foundation

// this took me way too long to figure out lol
class ModerationService {
    static let shared = ModerationService()
    
    private let apiKey = Secrets.openAIAPIKey
    private let moderationURL = "https://api.openai.com/v1/moderations"
    
    // openai doesnt catch everything so i had to add my own filter too smh
    
    struct ModerationResponse: Codable {
        let results: [ModerationResult]
    }
    
    struct ModerationResult: Codable {
        let flagged: Bool
        let categories: ModerationCategories
    }
    
    struct ModerationCategories: Codable {
        let sexual: Bool
        let hate: Bool
        let harassment: Bool
        let selfHarm: Bool
        let sexualMinors: Bool
        let hateThreatening: Bool
        let violenceGraphic: Bool
        let selfHarmIntent: Bool
        let selfHarmInstructions: Bool
        let harassmentThreatening: Bool
        let violence: Bool
        
        enum CodingKeys: String, CodingKey {
            case sexual, hate, harassment, violence
            case selfHarm = "self-harm"
            case sexualMinors = "sexual/minors"
            case hateThreatening = "hate/threatening"
            case violenceGraphic = "violence/graphic"
            case selfHarmIntent = "self-harm/intent"
            case selfHarmInstructions = "self-harm/instructions"
            case harassmentThreatening = "harassment/threatening"
        }
    }
    
    enum ModerationError: Error, LocalizedError {
        case inappropriate(String)
        case networkError
        case invalidResponse
        
        var errorDescription: String? {
            switch self {
            case .inappropriate(let reason):
                return "Content flagged: \(reason)"
            case .networkError:
                return "Unable to verify content. Please try again."
            case .invalidResponse:
                return "Unable to verify content. Please try again."
            }
        }
    }
    
    // Keywords for illegal or prohibited activities
    private let illegalKeywords = [
        // Theft/Stealing
        "steal", "stealing", "stolen", "rob", "robbing", "robbery", "burglary", "burglar",
        "shoplift", "shoplifting", "pickpocket", "theft", "thief", "loot", "looting",
        // Drugs
        "drugs", "cocaine", "heroin", "meth", "weed", "marijuana", "dealer", "dealing",
        // Weapons
        "gun", "weapon", "firearm", "explosive", "bomb",
        // Fraud
        "scam", "fraud", "counterfeit", "fake id", "identity theft", "phishing",
        // Other illegal
        "illegal", "hack", "hacking", "pirate", "piracy", "smuggle", "smuggling",
        "human trafficking", "prostitution", "escort service"
    ]
    
    func moderateContent(title: String, description: String) async throws -> Bool {
        let contentToCheck = "\(title)\n\(description)"
        let contentLower = contentToCheck.lowercased()
        
        // First check for illegal keywords
        // big brain moment right here
        for keyword in illegalKeywords {
            if contentLower.contains(keyword) {
                throw ModerationError.inappropriate("illegal or prohibited activity (\(keyword))")
            }
        }
        
        guard let url = URL(string: moderationURL) else {
            throw ModerationError.networkError
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["input": contentToCheck]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request) // calling the api lets goooo
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Moderation API error: \(response)")
                throw ModerationError.networkError
            }
            
            let moderationResponse = try JSONDecoder().decode(ModerationResponse.self, from: data)
            
            guard let result = moderationResponse.results.first else {
                throw ModerationError.invalidResponse
            }
            
            if result.flagged {
                let flaggedCategories = getFlaggedCategories(result.categories)
                throw ModerationError.inappropriate(flaggedCategories)
            }
            
            return true
        } catch let error as ModerationError {
            throw error
        } catch {
            print("Moderation error: \(error)")
            // If moderation fails, allow the post but log it
            return true
        }
    }
    
    private func getFlaggedCategories(_ categories: ModerationCategories) -> String {
        var flagged: [String] = []
        
        if categories.sexual || categories.sexualMinors { flagged.append("sexual content") }
        if categories.hate || categories.hateThreatening { flagged.append("hate speech") }
        if categories.harassment || categories.harassmentThreatening { flagged.append("harassment") }
        if categories.violence || categories.violenceGraphic { flagged.append("violence") }
        if categories.selfHarm || categories.selfHarmIntent || categories.selfHarmInstructions { flagged.append("self-harm") }
        
        return flagged.isEmpty ? "inappropriate content" : flagged.joined(separator: ", ")
    }
}
