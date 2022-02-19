//
//  GameScene.swift
//  GazeCollect
//
//  Created by 胡欣宇 on 10/02/2022.
//

import SpriteKit

class GameScene: SKScene{
    /*
     the array to record the movement of the cycles
     it is public for output to the text file
     */
    @Published var times: [Double] = []
    @Published var locations: [CGPoint] = []
    
    /*
     it is the starting time of the new session
     */
    @Published private var sessions: [CFTimeInterval] = []
    
    /*
     this is the x coordinate of the touching
     and time intervals of touching
     */
    @Published private var touchesLocations_x: [CGFloat] = []
    @Published private var touchesTime: [CFTimeInterval] = []
    
    @Published private var areLeftFlags: [Bool] = []
    /*
     it check if all the touch is in the right places
     if it is false at end, it mean the user might not fully focus on the touching
     and sessino is failed
     */
    @Published var goodSession:Bool = true
    
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
        actions.append(checkTouches)
        run(SKAction.sequence(actions))
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        /*
         record the time and the position of the cycle in each frame
         */
        times.append(currentTime)
        //print("Time: ",currentTime)
        if let cycle = self.childNode(withName: "cycle"){
            locations.append(cycle.position)
            //print("Position: ", cycle.position)
        }
    }
    
    
    
    /*
     when the touches begin, reocord the time and the location of the touches
     now i only have the left right validatoin
     so only take account in the x coordinate
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        for touch in touches{
            let location_x = touch.location(in: self).x
            touchesLocations_x.append(location_x)
            touchesTime.append(CACurrentMediaTime())
        }
    }
    
    /*
     it create the cycle, move the cycle, and destroy it
     */
    func moveCycle(from start: CGPoint, to destination:CGPoint, isLeft left:Bool, isRed isred:Bool){
        // start of the new session
        self.sessions.append(CACurrentMediaTime())
        var cycle: Cycle // create a cycle
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
    
    /*
     every second count as one session(e.g. 60s animation have 60 sessions)
     for every sessino, user need at least one correct action
     touch the right side of the screen
     two senario lead to failure:
        1, user touch the wrong side in this session
        2, user did not touch any time in this sessino
     */
    func checkTouches() -> Bool{
        // every session need one check
        var session_checked = true
        
        // this is the index for the touches
        var checked_touches = 0
        
        /*
         i need to check the touches among the session
         the logic of this for loop switching is depend on the inner while loop
         the while loop check every touches among the sessions
         it check the next sessions when
            the touches time is in the next session
            there are no further touches
         */
        for i in 0...sessions.count-2{
            // it mean there is no touch in last session return false
            if !session_checked{
                return false
            }
            session_checked = false
            
            /*
             now check the touch
             to make sure the user are touching the which side of the screen
             use the x coordinate of the touching compare to the screen width to validate
             */
            while(checked_touches < touchesTime.count){
                
                // check if the touch is still in the session
                if touchesTime[checked_touches] < sessions[i + 1] {
                    
                    // check where user touches
                    var touchLeft: Bool
                    if touchesLocations_x[checked_touches] > 1/2 * self.size.width{
                        touchLeft = true
                    }else{
                        touchLeft = false
                    }
                    
                    /*
                     check the user actual action and the supposed actions
                     */
                    if areLeftFlags[i] == touchLeft{
                        session_checked = true
                        checked_touches += 1
                    }else{
                        return false
                    }
                    
                }else{
                    break
                }
            }
        }
        if session_checked {
            return true
        }
        return false
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
