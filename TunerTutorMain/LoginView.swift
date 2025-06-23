import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthenticationService
    
    @State private var username = ""
    @State private var password = ""
    @State private var showingAlert = false
    @State private var isLoading = false
    @State private var errorMessage = "Invalid credentials"
    
    var body: some View {
        VStack(spacing: 20) {
            // App Logo
            Image(systemName: "music.note.list")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding(.bottom, 20)
            
            Text("TuneTutor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 30)
            
            // Login Form
            VStack(spacing: 15) {
                TextField("Username", text: $username)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: {
                    isLoading = true
                    // Using our auth service for login
                    authService.login(username: username, password: password) { result in
                        isLoading = false
                        switch result {
                        case .success(let user):
                            // Update app state with logged in user
                            appState.isLoggedIn = true
                            appState.currentUser = user
                        case .failure(let error):
                            // Show error alert
                            errorMessage = (error as? AuthenticationService.AuthError)?.errorDescription ?? "Login failed"
                            showingAlert = true
                        }
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    } else {
                        Text("Login")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }
                .disabled(username.isEmpty || password.isEmpty || isLoading)
                .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1)
            }
            .padding(.horizontal)
            
            Text("Use username: 'user' and password: 'password' to login")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top)
            
            Spacer()
        }
        .padding(.top, 50)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Login Failed"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
        .environmentObject(AuthenticationService())
}