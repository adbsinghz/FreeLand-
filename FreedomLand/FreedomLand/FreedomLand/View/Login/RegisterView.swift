//
//  RegisterView.swift
//  SkyBlue
//
//  Created by Arshdeep Singh Brar on 1/25/23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

//MARK: Register View
struct RegisterView: View{
    // MARK: User Details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userBio: String = ""
    @State var userBioLink: String = ""
    @State var userProfileData: Data?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // MARK: View Properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    // MARK: UserDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored : String = ""
    @AppStorage("user_UID") var userUID : String = ""   
    
    var body: some View{
        VStack(spacing: 10){
            Text( "Lets Register\nAccount")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            Text("Welcome User, \nYour Freedom starts from here.")
                .font(.title2)
                .hAlign(.leading)
            
            
            // MARK: For smaller size Optimization
            ViewThatFits {
                ScrollView(.vertical, showsIndicators: false){
                    HelperView()
                }
                
                HelperView()
                
            }
            
            
            
            // MARK: Register Button
            HStack{
                Text("Already have an account")
                    .foregroundColor(.gray)
                Button("Login Now"){
                    dismiss()
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
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){
            newValue in
            // MARK: Extracting UIIamge from PhotoItem
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else{return}
                        // MARK: UI Must Be Updated on Main Thread
                        await MainActor.run(body: {
                            userProfileData = imageData
                        })
                                
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
               
    }
    @ViewBuilder
        func HelperView()->some View{
            VStack(spacing: 12){
                ZStack{
                    if let userProfileData, let image = UIImage(data: userProfileData){
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                    else{
                        Image(systemName: "person.circle")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .frame(width: 85, height: 85)
                .clipShape(Circle())
                .contentShape(Circle())
                .onTapGesture {
                    showImagePicker.toggle()
                }
                .padding(.top,25)
                TextField("Enter your Username", text: $userName)
                    .textContentType(.username)
                    .border(1, .gray.opacity(0.5))
                    .padding(.top,25)
                TextField("Enter your Email", text: $emailID)
                    .textContentType(.emailAddress)
                    .border(1, .gray.opacity(0.5))
                    
                SecureField("Enter your Password", text: $password)
                    .textContentType(.password)
                    .border(1, .gray.opacity(0.5))
                TextField("Let poeple know about yourself", text: $userBio, axis: .vertical)
                    .frame(minHeight: 100, alignment: .top)
                    .textContentType(.none)
                    .border(1, .gray.opacity(0.5))
                TextField("Bio Link (Optional)", text: $userBioLink)
                    .textContentType(.none)
                    .border(1, .gray.opacity(0.5))
                Button (action: registerUser){
                    // MARK: Signup Button
                    Text("Sign up")
                        .foregroundColor(.white)
                        .hAlign(.center)
                        .fillView(.black)
                }
                .disableWithOpacity(userName == "" || userBio == "" || emailID == "" || password == "" || userProfileData == nil)
                .padding(.top,10)
    
            }
    }

    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                //Step 1: Creating Firebase Account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                // Step 2: Uploading Profile Photo Into Firebase Storage
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfileData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                //step 3: Downloading Photos URL
                let downloadURL = try await storageRef.downloadURL()
                //Step 4: Creating a User Firestone Object
                let user = User(username: userName, userBio: userBio, userBioLink: userBioLink, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                //step 5: Saving User Doc into Firestore Database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {error in
                    if error == nil{
                        print("Saved Successfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                        
                })
            }
            catch{
               
                await setError(error)
            }
        }
        
    }
    // MARK: Displaying Errors VIA Alert
    func setError(_ error: Error)async{
        // MARK: UI Must be Updated on Main Thread
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
