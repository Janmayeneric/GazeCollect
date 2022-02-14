//
//  ContentView.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 03/02/2022.
//

import SwiftUI

/*
 it is a view page
 */
struct MenuView: View {
    
    @State private var isGameShowing = false
    
    var body: some View {
        VStack{
            if !isGameShowing {
                Text("Gaze Collection")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding()
                Spacer()
                Text("Start")
                    .padding()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        isGameShowing.toggle()
                    }
            }else{
                GameView(isGameShowing: $isGameShowing)
                    .transition(.scale)
            }
        }
    }
}

/*
 code for the preview
 */
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MenuView()
    }
}
