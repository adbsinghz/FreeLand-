//
//  MainView.swift
//  SkyBlue
//
//  Created by Arshdeep Singh Brar on 1/25/23.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        // MARK: TabView with recent Posts and Profile Tabs
        TabView{
            PostsView()
                .tabItem{
                    Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled")
                    Text("Post's")
                }
            ProfileView()
                .tabItem{
                    Image(systemName: "gear")
                    Text("Profile")
                }
        }
        
        // Changing Tab Lable Tint to Block
        .tint(.black)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
