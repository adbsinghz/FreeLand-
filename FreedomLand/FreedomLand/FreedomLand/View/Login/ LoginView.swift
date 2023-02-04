
import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct _LoginView: View {
// MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    // MARK: View Properties
    @State var createAccount: Bool = false
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: User Defaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored : String = ""
    @AppStorage("user_UID") var userUID : String = ""   
    
    var body: some View {
        VStack(spacing: 10){
            Text( "Lets Sign you in")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome Back, \nYou have been missed")
                .font(.title)
                .hAlign(.leading)
            
            VStack(spacing: 12){
                TextField("Enter your Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top,25)
                SecureField("Enter your Password", text: $password)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                Button("Reset password", action: resetPassword)
                    .font(.callout)
                    .fontWeight(.bold)
                    .tint(.black)
                    .hAlign(.trailing)
                
                Button (action: loginUser) {
                    // MARK: Login Button
                    Text("Sign in")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .padding(.top,10)

            }
            
            HStack{
                Text("Don't have an account")
                    .foregroundColor(.gray)
                Button("Register Now"){
                    createAccount.toggle()
                    
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            .vAlign(.bottom)
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        // MARK: Register View VIA Sheets
        .fullScreenCover(isPresented: $createAccount){
            RegisterView()
        }
        // MARK: Displaying Alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }

    func loginUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                //With the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().signIn(withEmail: emailID, password: password)
                print("User Found")
                try await fetchUser()
            }
            catch{
                await setError(error)
            }
        }
    }
    // MARK: If user is found then fetch user data from firestore
    func fetchUser()async throws{
        guard let userID = Auth.auth().currentUser?.uid else{return}
        let user = try await Firestore.firestore().collection("Users").document(userID).getDocument(as: User.self)
        // MARK: UI Upadting Must be run on the main thread
        await MainActor.run(body: {
            // Setting UserDefaults data and changing Apps Auth Status
            userUID = userID
            userNameStored = user.username
            profileURL = user.userProfileURL
            logStatus = true
        })
    }
    // MARK: Reseting PASSWORD
    func resetPassword(){
        Task{
            do{
                //With the help of Swift Concurrency Auth can be done with Single Line
                try await Auth.auth().sendPasswordReset(withEmail: emailID)
                print("Link Sent")
            }
            catch{
                await setError(error)
                isLoading = false
            }
        }
        
    }
    
    // MARK: Displaying Errors VIA Alert
    func setError(_ error: Error)async{
        // MARK: UI Must be Updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}


struct _LoginView_Previews: PreviewProvider {
    static var previews: some View {
        _LoginView()
    }
}

