//
//  CreateNewPost.swift
//  FreedomLand
//
//  Created by Arshdeep Singh on 1/25/23.
//

import SwiftUI
import PhotosUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct CreateNewPost: View {
    // Callbacks
    var onPost: (Post)->()
    // Post Properties
    @State private var postText: String = ""
    @State private var postImageData: Data?
    // MARK: View Properties
    @Environment(\.dismiss) private var dismiss
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var showkeyboard: Bool
    // MARK: User Defaults
   
    @AppStorage("user_profile_url") private var profileURL: URL?
    @AppStorage("user_name") private var userName : String = ""
    @AppStorage("user_UID") private var userUID : String = ""
    // Stored User Data From UserDeafult(AppStorage)
    var body: some View {
        VStack{
            HStack{
                Menu{
                    Button("Cancel",role: .destructive){
                        dismiss()
                    }
                } label:{
                    Text("Cancel")
                        .font(.callout)
                        .foregroundColor(.black)
                    
                }
                .hAlign(.leading)
                
                Button(action: createPost){
                    Text("Post")
                        .font(.callout)
                        .foregroundColor(.white)
                        .padding(.horizontal,20)
                        .padding(.vertical,6)
                        .background(.black,in: Capsule())
                }
                .disableWithOpacity(postText == "")
            }
            .padding(.horizontal,15)
            .padding(.vertical,10)
            .background{
                Rectangle()
                    .fill(.gray.opacity(0.05))
                    .ignoresSafeArea()
            }
            ScrollView(.vertical, showsIndicators: false){
                VStack(spacing: 15){
                    TextField("What's happening", text: $postText, axis: .vertical)
                        .focused($showkeyboard)
                    
                    
                    if let postImageData, let image = UIImage(data: postImageData){
                        GeometryReader{
                            let size = $0.size
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio( contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            // Delete Button
                                .overlay(alignment: .topTrailing){
                                    Button{
                                        withAnimation(.easeInOut(duration: 0.25)){
                                            self.postImageData = nil
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                            .fontWeight(.bold)
                                            .tint(.red)
                                    }
                                    .padding(10)
                                }
                        }
                        .clipped()
                        .frame(height: 220)
                    }
                }
                .padding(15)
            }
            Divider()
            HStack{
                Button{
                    showImagePicker.toggle()
                } label: {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                }
                .hAlign(.leading)
                
                Button("Done"){
                    showkeyboard = false
                    
                }
            }
        }
        .vAlign(.top)
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem){
            newValue in
            if let newValue{
                Task{
                    if let rawImageData = try? await newValue.loadTransferable(type: Data.self),let image = UIImage(data: rawImageData), let compressedImageData = image.jpegData( compressionQuality: 0.5){
                        // UI must be done on Main Thread
                        await MainActor.run(body: {
                            postImageData = compressedImageData
                            photoItem = nil
                        })
                    }
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
        
        // Loading View
        .overlay(){
            LoadingView(show: $isLoading)
        }
    }
    
    // MARK: Post Content To Firebase
    func createPost(){
        isLoading = true
        showkeyboard = false
        Task{
            do{
                guard let profileURL = profileURL else{return}
                // step1 : Uploading Image if any
                // used to delete the post(later shwon in the video)
                
                let imageReferenceID = "\(userUID)\(Date())"
                let storageRef = Storage.storage().reference().child("Post_Images").child(imageReferenceID)
                if let postImageData{
                    let _ = try await storageRef.putDataAsync(postImageData)
                    let downloadURL = try await storageRef.downloadURL()
                    
                    // step3: Create Post Object with Image Id and URL
                    let post = Post(text: postText, imageURL: downloadURL,imageReferenceID: imageReferenceID, userName: userName, userUID: userUID , userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }else{
                    let post = Post(text: postText, userName: userName, userUID: userUID, userProfileURL: profileURL)
                    try await createDocumentAtFirebase(post)
                }
                
            }catch{
                await setError(error)
            }
        }
    }
    func createDocumentAtFirebase(_ post: Post)async throws{
        let doc = Firestore.firestore().collection("Posts").document()
        let _ = try doc.setData(from: post, completion: { error in if  error == nil{
            /// Post Successfully Stored at Firebase
                           isLoading = false
                           var updatedPost = post
                           updatedPost.id = doc.documentID
                           onPost (updatedPost)
                           dismiss()
        }
            
        })
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

struct CreateNewPost_Previews: PreviewProvider {
    static var previews: some View {
        CreateNewPost{_ in
        }
    }
}

