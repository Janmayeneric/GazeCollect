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
    @State private var selectedTime: Duration = .five
    @State private var selectedSize: Size = .normal
    @State private var selectedSpeed: Speed = .normal
    
    
    
    var body: some View {
        ZStack{
            Color.white.edgesIgnoringSafeArea(.all)
        VStack{
            if !isGameShowing {
                Text("Gaze Collection")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                    .padding()
                Spacer()
                Text("Speed")
                    .padding()
                    .foregroundColor(.black)
                Picker("Speed", selection: $selectedSpeed){
                    ForEach(Speed.allCases){speed in
                        Text(speed.rawValue.capitalized).foregroundColor(.black)
                    }
                }.colorMultiply(.black)
                Text("Size")
                    .padding()
                    .foregroundColor(.black)
                Picker("Size", selection: $selectedSize){
                    ForEach(Size.allCases){size in
                        Text(size.rawValue.capitalized).foregroundColor(.black)
                    }
                }.colorMultiply(.black)
                Text("Duration(second)")
                    .padding()
                    .foregroundColor(.black)
                Picker("Duration", selection: $selectedTime){
                    ForEach(Duration.allCases, id: \.self){duration in
                        Text(String(duration.value)).foregroundColor(.black)
                    }
                }.colorMultiply(.black)
                Spacer()
                Text("Start")
                    .padding()
                    .foregroundColor(.blue)
                    .onTapGesture {
                        isGameShowing.toggle()
                    }

            }else{
                GameView(isGameShowing: $isGameShowing, time: selectedTime.value, length: selectedSpeed.value, size: selectedSize.value)
                    .transition(.scale)
            }
                
        }
        .pickerStyle(.segmented)
        }
    }
}

/*
 the selection cases
 */
enum Speed: String, CaseIterable, Identifiable{
    case slow, normal, fast
    var id: Self{self}
    
    var value: Double{
        switch self{
        case .slow: return 1/2
        case .normal: return 1
        case .fast: return 1.5
        }
    }
}

enum Size: String, CaseIterable, Identifiable{
    
    case small, normal, big
    var id: Self{self}
    
    var value: Double{
        switch self{
        case .small: return 1/2
        case .normal: return 1
        case .big: return UIScreen.main.bounds.size.height/UIScreen.main.bounds.size.width
        }
    }
}

enum Duration: String, CaseIterable, Identifiable{
    case five, ten, fifteen
    var id: Self{self}
    
    var value: Int{
        switch self{
        case .five: return 5
        case .ten: return 10
        case .fifteen: return 15
        }
    }
}

