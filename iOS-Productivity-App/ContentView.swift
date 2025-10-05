//
//  ContentView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-05.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var firebaseStatus = "Checking Firebase services..."
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "flame.fill")
                .imageScale(.large)
                .foregroundStyle(.orange)
                .font(.system(size: 60))
            
            Text("Firebase Integration Test")
                .font(.headline)
            
            Text(firebaseStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .onAppear {
            verifyFirebaseServices()
        }
    }
    
    private func verifyFirebaseServices() {
        var status: [String] = []
        
        // Check Firebase Auth
        if Auth.auth().app != nil {
            status.append("✅ Authentication: Ready")
        } else {
            status.append("❌ Authentication: Not configured")
        }
        
        // Check Firestore
        let db = Firestore.firestore()
        if db.app != nil {
            status.append("✅ Firestore: Ready")
            
            // Test Firestore write/read
            let testRef = db.collection("_test").document("verification")
            testRef.setData(["timestamp": Date(), "test": true]) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        firebaseStatus = status.joined(separator: "\n") + "\n⚠️ Firestore Write Test: Failed - \(error.localizedDescription)"
                    }
                } else {
                    DispatchQueue.main.async {
                        firebaseStatus = status.joined(separator: "\n") + "\n✅ Firestore Write Test: Success"
                    }
                }
            }
        } else {
            status.append("❌ Firestore: Not configured")
        }
        
        firebaseStatus = status.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
