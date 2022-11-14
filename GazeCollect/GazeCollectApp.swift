//
//  GazeCollectApp.swift
//  GazeCollect
//
//  Created by eric on 03/02/2022.
//

import SwiftUI

@main
struct GazeCollectApp: App {
    @State private var isGameShowing = true
    var body: some Scene {
        WindowGroup {
            MenuView()
        }
    }
}
