//
//  ContentView.swift
//  FreedomLand
//
//  Created by Arshdeep Singh on 1/23/23.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("log_status") var logStatus: Bool = false
    var body: some View {
        // MARK: Redirecting User Based on log Status
        if logStatus{
            MainView()
        }
        else{
            _LoginView()
        }

    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
