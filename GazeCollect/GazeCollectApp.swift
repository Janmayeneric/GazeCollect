//
//  GazeCollectApp.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 03/02/2022.
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
