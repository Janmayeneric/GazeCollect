//
//  GameScene.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 10/02/2022.
//

import SpriteKit
import SwiftUI
import CoreMotion

class GameScene: SKScene{
    /*
     an approach to control the process of the animation
     the animation will stop if user press the wrong side of the screem
     */
    @Binding var continueAnimation: Bool
    @Binding var success: Bool
    @Binding var printString: String
    
    /*
     the array to record the movement of the cycles
     it is public for output to the text file
     */
    @Published var times: [Double] = []
    @Published var locations: [CGPoint] = []
    @Published var folderURL: URL!
    @Published var accleration_x: CGFloat = 0
    @Published var accleration_y: CGFloat = 0
    @Published var r: Double!
    /*
     it is the starting time of the new session
     */
    @Published private var sessions: [CFTimeInterval] = []
    
    @Published var chooseSize:Double
    @Published var chooseLength:Double
    @Published var time: Int
    
    let motion = CMMotionManager()
    /*
     two variables to monitor the user's actions
     one is to make sure user point the the left side of the screen
     one is to make sure user touch the screen in the on second
     */
    @Published private var isLeft: Bool = true
    @Published private var touched: Bool = true
    
    @Published private var areLeftFlags: [Bool] = []
    /*
     it check if all the touch is in the right places
     if it is false at end, it mean the user might not fully focus on the touching
     and sessino is failed
     */
    @Published var goodSession:Bool = true
    
    
    /*
     this is a constructor for this scene
     */
    init(isStart isstart: Binding<Bool>, isSuccess success: Binding<Bool>, write printString: Binding<String>, for duration: Int, chooseSize choosesize: Double, chooselength: Double){
        _continueAnimation = isstart
        _success = success
        _printString =  printString
        time = duration
        chooseSize = choosesize
        chooseLength = chooselength
        super.init(
            size: CGSize(
                width: UIScreen.main.bounds.size.width,
                height: UIScreen.main.bounds.size.height))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    /*
     after view controller is called
     randomly generate a point on the screen
     */
    override func didMove(to view: SKView) {
        self.r = 1/2 * 1/10  * self.size.width * self.chooseSize
        // generate the points position
        let points = generatePoints(for: time + 1,length: self.chooseLength)
        // generate the arrows
        areLeftFlags = generateAreLeft(for: time + 1)
        
        var actions : [SKAction] = []
        
        var isRed = true
        
        for i in 0...time - 1{
            actions.append(SKAction.run({self.moveCycle(from: points[i], to: points[i+1],isLeft: self.areLeftFlags[i],isRed: isRed)}))
            
            // different colour to remind the user for next round
            actions.append(SKAction.run {
                isRed.toggle()
            })
            actions.append(SKAction.wait(forDuration: 1))
        }
        
        let finalCycle = SKAction.run {
            var cycle: Cycle // create a cycle
            let r = 1/2 * 1/10  * self.size.width // customized radius based on the screen size
            cycle = Cycle()
            cycle.configure(at: points[self.time], radius: r, left: true,red: isRed, size: self.chooseSize)
            cycle.name = "cycle"
            self.addChild(cycle)
            self.sessions.append(CACurrentMediaTime())
        }
        actions.append(finalCycle)
        actions.append(SKAction.run {self.success = true})
        actions.append(SKAction.run({self.continueAnimation = false}))
        actions.append(SKAction.run({self.turnOffAccelerometer()}))
        run(SKAction.sequence(actions))
        
    }
    
    /*
     similar function to the scene did load
     to initiate the acclerator to record the orientation
     */
    override func sceneDidLoad() {
        super.sceneDidLoad()
        
        if self.motion.isAccelerometerAvailable{
            self.motion.accelerometerUpdateInterval = 1.0/60.0
            self.motion.startAccelerometerUpdates()
        }
    }
    
    /*
     it is the update function, update 1 time perf rame in 60 HZ
     */
    override func update(_ currentTime: TimeInterval) {
        /*
         record the time and the position of the cycle in each frame
         */
        if let cycle = self.childNode(withName: "cycle"){
            locations.append(cycle.position)
            times.append(currentTime)
            printString += String(currentTime)
            printString += ","
            printString += cycle.position.x.description
            printString += ","
            printString += cycle.position.y.description
            
            // accelerometerdata is optional in default setting
            if let data = self.motion.accelerometerData{
                printString += ","
                printString += String(data.acceleration.x)
                printString += ","
                printString += String(data.acceleration.y)
            }else{
                // or just not print them in csv file
                printString += ",,"
            }
            
            printString += "\r"
            
            
        }
    }

    
    /*
     when the touches begin, reocord the time and the location of the touches
     now i only have the left right validatoin
     so only take account in the x coordinate
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        var isTouchLeft = false
        guard let touch = touches.first else {return}
        self.touched = true
        let location_x = touch.location(in: self).x
        if location_x < UIScreen.main.bounds.size.width/2 {
            isTouchLeft = true
        }else{
            isTouchLeft = false
        }
        
        if isTouchLeft != self.isLeft {
            continueAnimation.toggle()
            success = false
            print("wrong direction!!!!!")
        }
    }
    
    /*
     it create the cycle, move the cycle, and destroy it
     */
    func moveCycle(from start: CGPoint, to destination:CGPoint, isLeft left:Bool, isRed isred:Bool){
        // start of the new session
        self.sessions.append(CACurrentMediaTime())
        var cycle: Cycle // create a cycle
        
        
        if !self.touched {
            print("too long")
            self.continueAnimation.toggle()
            self.success = false
        }
        /*
         before the movement of the cycle
         change the direction guide for this intervals
         and then change the touch state to default = false
         */
        self.isLeft = left
        self.touched = false
        
        cycle = Cycle()
        cycle.configure(at: start, radius: self.r, left: left, red: isred, size: self.chooseSize)
        cycle.name = "cycle"
        addChild(cycle)
        
        /*
         two operation is carried out here
         one is move the cycle
         then destroy it
         */
        
        let move = SKAction.move(to: destination, duration: 1)
        let remove = SKAction.removeFromParent()
    
        cycle.run(SKAction.sequence([move,remove]))
    }
    
    /*
     create numbers of points before the animation
     it decide the path of the point
     can adjust the duration(second) and path length in parameter

     */
    func generatePoints(for duration: Int, length l:Double ) -> [CGPoint]{
        let length = l * (self.size.width-2*self.r)
        var points : [CGPoint] = []
        
        // add a point first
        points.append(
            CGPoint(x: CGFloat.random(in: self.r...self.size.width - self.r),
                    y: CGFloat.random(in: self.r...self.size.height - self.r)
                   )
        )
        
        // then move the cycle in a fixed length, but with the different angle
        for _ in 1...duration - 1 {
            if let point = points.last{
                points.append(self.findPoint(length: length, Point: point))
            }
        }
        return points
    }
    
    /*
     find the correct degree for the movement
     the wrong degree means the length may go out of the screen
     */
    func findPoint(length l:Double, Point p: CGPoint) -> CGPoint{
        print("find the point")
        // it is a infinite loop, to let the check complete
        while true{
            let degree = Double.random(in: 0...360)
            let change_x = l * cos(degree * Double.pi / 180)
            let change_y = l * -sin(degree * Double.pi / 180)
            let new_x = p.x + change_x
            let new_y = p.y + change_y
            
            // check if the new x and y position is in the bound of the screen
            
            if new_x < self.r || new_x > self.size.width - self.r{
                continue
            }
            if new_y < self.r || new_y > self.size.height - self.r{
                continue
            }
            return CGPoint(x: new_x, y: new_y)
        }
    }
    
    
    /*
     create numbers of the direction before the animation
     it decide where the user need to touch
     can adjust the duration(second) in parameter
     the result is boolean value for [isLeft]
     */
    func generateAreLeft(for duration: Int) -> [Bool]{
        var AreLeft :[Bool] = []
        for _ in 1...duration{
            AreLeft.append(Bool.random())
        }
        return AreLeft
    }
    
    // need to turn off the accelerometer after the caputre
    func turnOffAccelerometer(){
        if self.motion.isAccelerometerActive{
            self.motion.stopAccelerometerUpdates()
        }
    }
    
    /*
     it is recrod the position of the cycle with the time, for the timestamp for the video
     */
    func recordCycle(where position:CGPoint){
        times.append(CACurrentMediaTime())
        locations.append(position)
    }
    
    
}

class Cycle: SKNode{
    var isHit = false
    
    
    func configure(at position: CGPoint, radius r:CGFloat, left isLeft:Bool, red isRed:Bool, size real_size:Double){
        self.position = position
        self.zPosition = 1
        let cycle = SKShapeNode(circleOfRadius: r)
        cycle.zPosition = 2
        
        /*
         switch the color for two intervals
         easy for user to know when to tape the cycle
         */
        if isRed{
            cycle.strokeColor = UIColor.red
            cycle.fillColor = UIColor.red
        }else{
            cycle.strokeColor = UIColor.blue
            cycle.fillColor = UIColor.blue
        }
        addChild(cycle)
        
        /*
         it is the arrow for user to know where to touch the screen
         */
        let arrow = SKLabelNode()
        arrow.zPosition = 3
        arrow.verticalAlignmentMode = .center
        if(isLeft){
            arrow.text = "◀︎"
        }else{
            arrow.text = "▶︎"
        }
        arrow.fontSize = arrow.fontSize * real_size
        addChild(arrow)
    }
    
    
    func hit(){
        isHit = true
        
    }
}
