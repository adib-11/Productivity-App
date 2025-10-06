//
//  LoginView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

/// View for user login with email and password
struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel
    @State private var showSignUp = false
    private let authManager: AuthManager
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Log in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)
            
            // Form
            VStack(spacing: 16) {
                // Email field
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .disabled(viewModel.isLoading)
                
                // Password field
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)
                    .disabled(viewModel.isLoading)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Log In button
                Button(action: {
                    _Concurrency.Task {
                        await viewModel.signIn()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(viewModel.isLoading)
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Link to Sign Up
            HStack {
                Text("Don't have an account?")
                    .foregroundColor(.secondary)
                
                Button("Sign Up") {
                    showSignUp = true
                }
                .fontWeight(.semibold)
            }
            .padding(.bottom)
        }
        .padding()
        .sheet(isPresented: $showSignUp) {
            SignUpView(authManager: authManager)
        }
    }
}

// MARK: - Preview
// Note: Using MockAuthManager to prevent Firebase initialization in previews
#if DEBUG
private class MockAuthManager: AuthManager {
    override init() {
        // Don't call super.init() to avoid Firebase initialization
    }
}

#Preview {
    LoginView(authManager: MockAuthManager())
}
#endif
