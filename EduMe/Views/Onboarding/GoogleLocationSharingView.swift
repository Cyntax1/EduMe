import SwiftUI
import MapKit
import CoreLocation
import Combine

// same as LocationSharingView but for google signups
struct GoogleLocationSharingView: View {
    @Bindable var authViewModel: AuthViewModel
    let name: String
    let email: String
    let profileImageURL: String?
    let userId: String
    let isServiceProvider: Bool
    
    @StateObject private var locationManager = LocationManager()
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @State private var areaRadius: Double = 8046.72
    @State private var tempRadius: Double = 8046.72
    
    var circleSize: CGFloat {
        let minSize: CGFloat = 40
        let maxSize: CGFloat = 160
        let minRadius: Double = 1609.34
        let maxRadius: Double = 80467.0
        let normalized = (tempRadius - minRadius) / (maxRadius - minRadius)
        return minSize + CGFloat(normalized) * (maxSize - minSize) // math is hard
    }
    @State private var isLocationShared = false
    
    var radiusInMiles: Double {
        tempRadius / 1609.34
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        
                        Text("Share Your Location")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Help people find local help near them")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    if let location = locationManager.location {
                        VStack(spacing: 20) {
                            Map(position: .constant(.region(region))) {
                                Annotation("", coordinate: location.coordinate) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.2))
                                            .frame(width: circleSize, height: circleSize)
                                            .animation(.easeInOut(duration: 0.15), value: circleSize)
                                        Circle()
                                            .stroke(Color.blue, lineWidth: 2)
                                            .frame(width: circleSize, height: circleSize)
                                            .animation(.easeInOut(duration: 0.15), value: circleSize)
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title)
                                            .foregroundStyle(.blue)
                                    }
                                }
                            }
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Approximate Area Radius")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                VStack(spacing: 8) {
                                    HStack {
                                        Text(String(format: "%.0f miles", radiusInMiles))
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                        
                                        Spacer()
                                    }
                                    
                                    Slider(value: $tempRadius, in: 1609.34...80467.0, step: 1609.34)
                                        .tint(.blue)
                                        .onChange(of: tempRadius) { _, newValue in
                                            areaRadius = newValue
                                        }
                                    
                                    HStack {
                                        Text("1 mi")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        Text("50 mi")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text("Your exact location is never shown publicly")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(20)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            if let city = locationManager.city, let state = locationManager.state {
                                HStack {
                                    Image(systemName: "location.fill")
                                        .foregroundStyle(.blue)
                                    Text("\(city), \(state)")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(.horizontal, 24)
                        .onAppear {
                            region.center = location.coordinate
                            isLocationShared = true
                            tempRadius = areaRadius
                        }
                    } else {
                        VStack(spacing: 20) {
                            Image(systemName: "location.slash")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("Location Access Needed")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("We need your location to connect you with local help in your community")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button {
                                locationManager.requestLocation()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "location.fill")
                                    Text("Enable Location")
                                }
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.vertical, 40)
                    }
                    
                    Spacer()
                        .frame(height: 120)
                }
            }
            
            VStack(spacing: 12) {
                Button {
                    completeGoogleSignUp()
                } label: {
                    Text(isLocationShared ? "Complete Sign Up" : "Continue Without Location")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                
                if !isLocationShared {
                    Text("You can add your location later in settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(
                Color(.systemBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: -5)
            )
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            locationManager.requestLocation()
        }
    }
    
    private func completeGoogleSignUp() {
        Task {
            let userLocation: User.UserLocation? = if let location = locationManager.location {
                User.UserLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    areaRadius: areaRadius,
                    city: locationManager.city,
                    state: locationManager.state
                )
            } else {
                nil
            }
            
            let user = User(
                id: userId,
                name: name,
                email: email,
                profileImageURL: profileImageURL,
                location: userLocation,
                isServiceProvider: isServiceProvider
            )
            
            authViewModel.currentUser = user
            authViewModel.isAuthenticated = true
            
            do {
                try await authViewModel.saveUserProfile(user: user)
            } catch {
                print("Warning: Could not save user profile: \(error.localizedDescription)")
            }
        }
    }
}
