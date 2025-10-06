//
//  SignUpView.swift
//  iOS-Productivity-App
//
//  Created on 2025-10-06.
//

import SwiftUI

/// View for user registration with email and password
struct SignUpView: View {
    @StateObject private var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign up to get started")
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
                    .textContentType(.newPassword)
                    .disabled(viewModel.isLoading)
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Sign Up button
                Button(action: {
                    _Concurrency.Task {
                        await viewModel.signUp()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Sign Up")
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
            
            // Link to Login
            HStack {
                Text("Already have an account?")
                    .foregroundColor(.secondary)
                
                Button("Log In") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
            .padding(.bottom)
        }
        .padding()
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
    SignUpView(authManager: MockAuthManager())
}
#endif
