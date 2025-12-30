//
//  EduMeApp.swift
//  EduMe
//
//  Created by Rishith Chennupati on 12/14/25.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

// app entry point
@main
struct EduMeApp: App {
    init() {
        FirebaseApp.configure() // firebase setup
        
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings() // offline mode works now
        Firestore.firestore().settings = settings
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
