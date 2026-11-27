//
//  BollyKaraokeApp.swift
//  BollyKaraoke
//
//  Created by Shounak Kulkarni on 11/26/26.
//

import SwiftUI

@main
struct BollyKaraokeApp: App {
    @State private var song = SampleSongPlayer()

    var body: some Scene {
        WindowGroup {
            ContentView(song: song)
        }
    }
}
