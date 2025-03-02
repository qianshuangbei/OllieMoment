//
//  ContentView.swift
//  OllieMoment
//
//  Created by 钱双贝 on 2025/3/1.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        SwiftUI.TabView {
            ClipUIView()
                .tabItem {
                    Image(systemName: "scissors")
                    Text("Clip")
                }
            MeUIView()
                .tabItem{
                    Image(systemName: "person")
                    Text("Me")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
