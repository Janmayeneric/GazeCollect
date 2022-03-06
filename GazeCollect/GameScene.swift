//
//  GameScene.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 10/02/2022.
//

import SpriteKit
import SwiftUI

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
    
    /*
     it is the starting time of the new session
     */
    @Published private var sessions: [CFTimeInterval] = []
    
    
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
     this is a constructor 
     */
    init(isStart isstart: Binding<Bool>, isSuccess success: Binding<Bool>, write printString: Binding<String>){
        _continueAnimation = isstart
        _success = success
        _printString =  printString
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
        
        let animationTime = 10// in second, left is duration time
        let points = generatePoints(for: animationTime + 1)
        areLeftFlags = generateAreLeft(for: animationTime + 1)
        
        var actions : [SKAction] = []
        var isRed = true
        for i in 0...animationTime - 1{
            actions.append(SKAction.run({self.moveCycle(from: points[i], to: points[i+1],isLeft: self.areLeftFlags[i],isRed: isRed)}))
            
            // different colour to remind the user for next round
            actions.append(SKAction.run {
                isRed.toggle()
            })
            actions.append(SKAction.wait(forDuration: 1))
        }
        
        let finalCycle = SKAction.run {
            var cycle: Cycle // create a cycle
            let r = 1/2 * 1/10 * self.size.width // customized radius based on the screen size
            cycle = Cycle()
            cycle.configure(at: points[animationTime], radius: r, left: true,red: isRed)
            cycle.name = "cycle"
            self.addChild(cycle)
            self.sessions.append(CACurrentMediaTime())
        }
        actions.append(finalCycle)
        actions.append(SKAction.run {self.success = true})
        actions.append(SKAction.run({self.continueAnimation = false}))
        run(SKAction.sequence(actions))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        /*
         record the time and the position of the cycle in each frame
         */
        if let cycle = self.childNode(withName: "cycle"){
            locations.append(cycle.position)
            times.append(currentTime)
            printString += String(cycle.position) + ","+String(currentTime) + "\n"
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
        
        let r = 1/2 * 1/10 * self.size.width // customized radius based on the screen size
        cycle = Cycle()
        cycle.configure(at: start, radius: r, left: left, red: isred)
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
     can adjust the duration(second) in parameter
     */
    func generatePoints(for duration: Int) -> [CGPoint]{
        let r = 1/2 * 1/10 * self.size.width
        var points : [CGPoint] = []
        for _ in 1...duration {
            let random_x = CGFloat.random(in: r...self.size.width-r)
            let random_y = CGFloat.random(in: r...self.size.height-r)
            points.append(CGPoint(x: random_x, y:random_y))
        }
        return points
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
    
    func configure(at position: CGPoint, radius r:CGFloat, left isLeft:Bool, red isRed:Bool){
        self.position = position
        self.zPosition = 1
        let cycle = SKShapeNode(circleOfRadius:  r)
        cycle.zPosition = 2
        if isRed{
            cycle.strokeColor = UIColor.red
            cycle.fillColor = UIColor.red
        }else{
            cycle.strokeColor = UIColor.blue
            cycle.fillColor = UIColor.blue
        }
        
        addChild(cycle)
        let pointer = SKLabelNode()
        pointer.zPosition = 3
        pointer.verticalAlignmentMode = .center
        if(isLeft){
            pointer.text = "◀︎"
        }else{
            pointer.text = "▶︎"
        }
        addChild(pointer)
    }
    
    
    func hit(){
        isHit = true
        
    }
}
