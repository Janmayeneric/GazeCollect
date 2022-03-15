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
    let TITLE = "Time,X,Y,\"X accleration\", \"Y accleration \"\r"
    @State private var isPaused = false
    @Binding var isGameShowing: Bool
    @State private var isAnimated = true
    @State private var success = false
    @State private var cameraManager: CameraManager!
    @State private var folderUrl: URL!
    @State private var fileManager: FileManager!
    @State private var printString = ""
    @State var time: Int
    @State var length: Double
    @State var size: Double
    
    var game:  SKScene{
        
        let scene = GameScene(isStart: $isAnimated, isSuccess: $success, write: $printString, for: time, chooseSize: size, chooselength: length)
       
        scene.size = CGSize(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height)
        //scene.scaleMode = .fill
        return scene
    }
    
    
    var body: some View{
        if(isAnimated){
            ZStack(alignment: .top){
                SpriteView(scene: game, isPaused: isPaused)
                    .frame(width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height).ignoresSafeArea()
                    .onAppear{
                        printString = TITLE
                        fileManager = FileManager.default
                        /*
                         find the directory for the app
                         */
                        let appPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        
                        /*
                         then create the folder for this session
                         name is the time before the recording
                         */
                        let folderName = String(Int(Date().timeIntervalSince1970*1000))
                        
                        folderUrl = appPath.appendingPathComponent(folderName,isDirectory: true)
                        
                        if !fileManager.fileExists(atPath: folderUrl.path){
                            try! fileManager.createDirectory(at: folderUrl, withIntermediateDirectories: true, attributes: nil)
                        }
                        
                        
                        // start the camera when the session begin
                        cameraManager = CameraManager(at: folderUrl)
                        /*
                         in the block of onAppear
                         i use the dispatch queue only allow the scene to appear for set time (project plan is 1 minute)
                         */
                        cameraManager.start()
                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + Double(time)){
                                cameraManager.end()
                            }
                    }
            }
        }else{
            if success {
                MenuView().onAppear{
                    let textpath = folderUrl.appendingPathComponent("output.csv")
                    
                    do{
                        try printString.write(to: textpath,atomically: true, encoding: String.Encoding.utf8)
                    }catch{
                        
                    }
                    isGameShowing.toggle()
                }
            }else{
                VStack{
                    Text("Please try again")
                        .font(.largeTitle)
                        .foregroundColor(.black)
                        .padding()
                    Spacer()
                    Button("back to menu",action: {isGameShowing.toggle()}).padding()
                    
                }.onAppear{
                    cameraManager.end()
                    if fileManager.fileExists(atPath: folderUrl.path){
                        try! fileManager.removeItem(at: folderUrl)
                    }
                }
            }
        }
    }
}


/*
 camera model for the video recording
 */
class CameraManager: NSObject, AVCaptureFileOutputRecordingDelegate{
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    }
    
    
    /*
     it is the root directory of the file for this session
     */
    var root:URL
    
    init(at directory: URL){
        self.root = directory
    }
    
    
    let movieOutput = AVCaptureMovieFileOutput()
    /*
     the status code
     */
    enum Status{
        case unconfigured
        case configured
        case unauthorized
        case failed
        
    }
    
    /*
     error handling code
     */
    enum CameraError: Error{
        case denied
        case restricted
        case unknown
        case unavailable
        case canNotAddInput
        case cannotAddOutput
    }
    
    @Published var error: CameraError?
    
    let captureSession = AVCaptureSession()
    
    private let captureSessionQueue = DispatchQueue(label: "video")
    
    private var status = Status.unconfigured
    
    /*
     checck for permission
     configure the capture session
     and start it
     */
     func start(){
        let videoPath = root.appendingPathComponent("video.mov")
        checkPermissions()
        captureSessionQueue.async {
            self.configureCaptureSession()
            self.captureSession.startRunning()
            self.movieOutput.startRecording(to: videoPath, recordingDelegate: self)
            print("start recording : ", videoPath)
        }
    }
    
    func end(){
        captureSessionQueue.async {
            self.movieOutput.stopRecording()
            self.captureSession.stopRunning()
        }
    }
    
    
    private func set(error: CameraError?){
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    /*
     check the permission from the device
     */
    private func checkPermissions(){
        switch AVCaptureDevice.authorizationStatus(for: .video){
        case .notDetermined:
            
            captureSessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video){authorized in
                if !authorized{
                    self.status = .unauthorized
                    self.set(error: .denied)
                }
                self.captureSessionQueue.resume()
            }
        
        case .restricted:
            status = .unauthorized
            set(error: .restricted)
        
        case .denied:
            status = .unauthorized
            set(error: .denied)
        
        case .authorized:
            print("authorized")
            break
            
        @unknown default:
            status = .unauthorized
            set(error: . unknown)
        }
    }
    
    
    private func configureCaptureSession(){
        guard status == .unconfigured else{
            return
        }
        captureSession.beginConfiguration()
        
        // get the capture device, need the front camera and for video purpose
        let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        
        // if he request device do not have the front camera, return
        
        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
            captureSession.canAddInput(videoDeviceInput)
            else {
                status = .unconfigured
                set(error:.canNotAddInput)
                return }
        captureSession.addInput(videoDeviceInput)
        
        guard captureSession.canAddOutput(movieOutput) else {
            status = .unconfigured
            set(error:.cannotAddOutput)
            return
        }
        captureSession.addOutput(movieOutput)
        
        status = .configured
        
        captureSession.commitConfiguration()
        print("configured")
        return
    }
}


