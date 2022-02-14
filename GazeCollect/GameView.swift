//
//  CollectionView.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 03/02/2022.
//

import SwiftUI
import SpriteKit
import AVFoundation

struct GameView: View {
    @State private var isPaused = false
    @Binding var isGameShowing: Bool
    @StateObject var camera = cameraModel()
    var game:  SKScene{
        let scene = GameScene()
        print("screen size: ", UIScreen.main.bounds.size.width, "|||", UIScreen.main.bounds.size.height)
        scene.size = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        scene.scaleMode = .fill
        return scene
    }
    
    
    var body: some View{
        if(isGameShowing){
            ZStack(alignment: .top){
                SpriteView(scene: game, isPaused: isPaused)
                    .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height).ignoresSafeArea()
                    .onAppear{
                        camera.Check()
                        /*
                         in the block of onAppear
                         i use the dispatch queue only allow the scene to appear for set time (project plan is 1 minute)
                         */
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + 10){
                                withAnimation(.easeIn){ // some fancy animation, more Apple, you know
                                    isGameShowing.toggle() // trigger the end tag, back to menu
                                }
                            }
                        
                    }
            }
        }else{
            MenuView()
        }
    }
}


/*
 camera model for the video recording
 */
class cameraModel: ObservableObject{
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    
    @Published var output = AVCaptureVideoDataOutput()
    
    func Check(){
        
        // check for the permission
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .authorized:
            // start the session after the permission
            setUp()
            return
        case .notDetermined:
            // reasking
            AVCaptureDevice.requestAccess(for: .video){
                [weak self] granted in guard granted else{
                    return
                }
                DispatchQueue.main.async{
                    self?.setUp()
                }
            }
        case .denied:
            self.alert.toggle()
            return
            
        default:
            return
        }
    }
    
    func setUp(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video){
            do{
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input){
                    session.addInput(input)
                }
                
                if session.canAddOutput(output){
                    session.addOutput(output)
                }
                
                session.startRunning()
                self.session = session
                
            }catch{
                
            }
        }
        
    }
    
    func startRecording(){
        DispatchQueue.global(qos:.background).async{
            self.session.startRunning()
            
        }
    }
}



