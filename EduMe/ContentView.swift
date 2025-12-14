//
//  ContentView.swift
//  EduMe
//
//  Created by Rishith Chennupati on 12/14/25.
//

import SwiftUI

// decides if user sees login or main app
struct ContentView: View {
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated && authViewModel.currentUser != nil {
                MainTabView(authViewModel: authViewModel) // logged in
            } else {
                WelcomeView(authViewModel: authViewModel) // not logged in
            }
        }
    }
}

#Preview {
    ContentView()
}
