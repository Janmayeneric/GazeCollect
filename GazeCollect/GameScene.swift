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
     */
    @Published var times: [Double] = []
    @Published var locations: [CGPoint] = []
    
    /*
     after view controller is called
     randomly generate a point on the screen
     */
    override func didMove(to view: SKView) {
        
        let animationTime = 10// in second, left is duration time
        let points = generatePoints(for: animationTime + 1)
        var actions : [SKAction] = []
        
        for i in 0...animationTime - 1{
            actions.append(SKAction.run({self.moveCycle(from: points[i], to: points[i+1])}))
            actions.append(SKAction.wait(forDuration: 1))
        }
        
        let finalCycle = SKAction.run {
            var cycle: Cycle // create a cycle
            let r = 1/2 * 1/10 * self.size.width // customized radius based on the screen size
            cycle = Cycle()
            cycle.configure(at: points[animationTime], radius: r)
            cycle.name = "cycle"
            self.addChild(cycle)
        }
        actions.append(finalCycle)
        
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
    
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        
    }
    /*
     it create the cycle, move the cycle, and destroy it
     */
    func moveCycle(from start: CGPoint, to destination:CGPoint){
        
        var cycle: Cycle // create a cycle
        let r = 1/2 * 1/10 * self.size.width // customized radius based on the screen size
        cycle = Cycle()
        cycle.configure(at: start, radius: r)
        cycle.name = "cycle"
        addChild(cycle)
        
        /*
         two operation is carried out here
         one is move the cycle
         then destroy it
         */
        print("create a point: ", cycle.position)
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
     it is recrod the position of the cycle with the time, for the timestamp for the video
     */
    func recordCycle(where position:CGPoint){
        times.append(CACurrentMediaTime())
        locations.append(position)
    }
    
}

class Cycle: SKNode{
    var cycle: SKShapeNode!
    var isHit = false
    
    
    func configure(at position: CGPoint, radius r:CGFloat){
        self.position = position
        cycle = SKShapeNode(circleOfRadius:  r)
        cycle.strokeColor = UIColor.red
        cycle.fillColor = UIColor.red
        addChild(cycle)
    }
    
    
    func hit(){
        isHit = true
        
    }
}
