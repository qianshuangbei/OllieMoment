//
//  OllieMomentApp.swift
//  OllieMoment
//
//  Created by 钱双贝 on 2025/3/1.
//

import SwiftUI

import SwiftUI

@main
struct OllieMomentApp: App {
    init() {
        AlbumManager.checkAndCreateAlbum()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
