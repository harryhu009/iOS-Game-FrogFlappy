//
//  GameScene.swift
//  HHFlappyFrog
//
//  Created by hu on 2019/2/24.
//  Copyright © 2019年 hu. All rights reserved.
//

import SpriteKit
import GameplayKit
import UIKit

//game status
enum GameStatus {
    case idle // initialize
    case running // gaming
    case over // game over
}
class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var frog : SKSpriteNode!
    
    var skyColor:SKColor!
    
    //vertical pipe gap
    let verticalPipeGap = 150.0;
    //upward-pipetexture
    var pipeTextureUp:SKTexture!
    //downward-pipetexture
    var pipeTextureDown:SKTexture!
    
    var moving:SKNode!
    
    //Store all pipes
    var pipes:SKNode!
    //game status
    var gameStatus:GameStatus = .idle
    
    lazy var gameOverLabel:SKLabelNode = {
        let label = SKLabelNode(fontNamed: "Chalkduster")
        label.text = "Game Over"
        return label
    }()
    //score
    var score: NSInteger = 0
    //score label
    lazy var scoreLabelNode: SKLabelNode = {
       let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.zPosition = 100
        label.text = "0"
        return label
    }()
    lazy var xuminglabel: SKLabelNode = {
        let label = SKLabelNode(fontNamed: "MarkerFelt-Wide")
        label.zPosition = 100
        label.text = "寿命减少了   秒"
        return label
    }()
    
    lazy var sound = SoundManager()
    
    let frogCategory: UInt32 = 1 << 0
    let worldCategory: UInt32 = 1 << 1
    let pipeCategory: UInt32 = 1 << 2
    let scoreCategory: UInt32 = 1 << 3
    
    
    override func didMove(to view: SKView) {
        self.backgroundColor =  SKColor(red: 81.0/255.0, green: 192.0/255.0, blue: 201.0/255.0, alpha: 1.0)
        self.physicsBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
        self.physicsWorld.contactDelegate = self;
        self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
        //music
        self.addChild(sound)
        
        sound.playBackGround()
        
        moving = SKNode()
        self.addChild(moving)
        pipes = SKNode()
        moving.addChild(pipes)
        
        //ground
        let groundTexture = SKTexture(imageNamed: "land")
        groundTexture.filteringMode = .nearest
        for i in 0..<2 + Int(self.frame.size.width / (groundTexture.size().width * 2)) {
            let i = CGFloat(i)
            let sprite = SKSpriteNode(texture: groundTexture)
            sprite.setScale(1.0)
            sprite.anchorPoint = CGPoint(x: 0,y: 0)
            sprite.position = CGPoint(x: i * sprite.size.width, y: 0)
            self.moveGround(sprite:sprite, timer: 0.02)
            moving.addChild(sprite)
        }
        //sky
        let skyTexture = SKTexture(imageNamed: "sky")
            skyTexture.filteringMode = .nearest
            for i in 0..<2 + Int(self.frame.size.width / (skyTexture.size().width * 2)) {
                let i = CGFloat(i)
                let sprite = SKSpriteNode(texture: skyTexture)
                sprite.setScale(2.0)
                sprite.zPosition = -20
                sprite.anchorPoint = CGPoint(x:0, y:0)
                sprite.position = CGPoint(x: i * sprite.size.width, y: groundTexture.size().height * 1.0)
                self.moveGround(sprite: sprite, timer: 0.1)
                //self.addChild(sprite)
                moving.addChild(sprite)
            }
        //frog
            frog = SKSpriteNode(imageNamed: "frog-01")
            frog.setScale(1.0)
            frog.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
            addChild(frog)
        
        //set frog physical body
        frog.physicsBody = SKPhysicsBody(circleOfRadius: frog.size.height / 2.0)
        frog.physicsBody?.allowsRotation = false
        frog.physicsBody?.categoryBitMask = frogCategory
        frog.physicsBody?.contactTestBitMask = worldCategory | pipeCategory
        
        self.idleStatus()
        
    }
    
    func idleStatus() {
        gameStatus = .idle
        removeAllPipesNode()
        gameOverLabel.removeFromParent()
        scoreLabelNode.removeFromParent()
        frog.position = CGPoint(x: self.frame.size.width * 0.35, y: self.frame.size.height * 0.6)
        frog.physicsBody?.isDynamic = false
        
        self.frogStartFly()
        
        moving.speed = 1
    }
    func runningStatus() {
        gameStatus = .running
        
        // reset score
        score = 0
        scoreLabelNode.text = String(score)
        self.addChild(scoreLabelNode)
        self.addChild(xuminglabel)
        scoreLabelNode.position = CGPoint(x: self.frame.midX + 62, y: 3 * self.frame.size.height / 4)
        xuminglabel.position = CGPoint(x: self.frame.midX, y: 3 * self.frame.size.height / 4)
        frog.physicsBody?.isDynamic = true
        frog.physicsBody?.collisionBitMask = worldCategory | pipeCategory
        
        startCreateRandomPipes()
    }
    func overStatus() {
        gameStatus = .over
        
        frogStopFly()
        
        stopCreateRandomPipes()
        
        
        addChild(gameOverLabel)
        gameOverLabel.position = CGPoint(x: self.size.width * 0.5, y: self.size.height)
        isUserInteractionEnabled = false;
        // move gameover label action
        let delay = SKAction.wait(forDuration: TimeInterval(1))
        let move = SKAction.move(by: CGVector(dx: 0, dy: -self.size.height * 0.5), duration: 1)
        gameOverLabel.run(SKAction.sequence([delay,move]), completion:{
            //allow users to click the screen
            self.isUserInteractionEnabled = true
        })
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        sound.playHit()
        
        switch gameStatus {
        case .idle:
            runningStatus()
            
            break
        case .running:
            for _ in touches {
                
                frog.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
                // a vertical power to push the frog
                frog.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 10))
            }
            break
            
        case .over:
            idleStatus()
            break
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if gameStatus != .running {
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            
            score += 1
            print(score)
            scoreLabelNode.text = String(score)
            
            scoreLabelNode.run(SKAction.sequence([SKAction.scale(to: 1.5, duration: TimeInterval(0.1)),SKAction.scale(to: 1.0, duration: TimeInterval(0.1))]))
        }else{
            
            moving.speed = 0
            frog.physicsBody?.collisionBitMask = worldCategory
            
            overStatus()
        }
    }
    
    //background flashing
    func bgFlash() {
        let bgFlash = SKAction.run({
            self.backgroundColor = SKColor(red: 1, green: 0, blue: 0, alpha: 1.0)}
        )
        let bgNormal = SKAction.run({
            self.backgroundColor = self.skyColor;
        })
        let bgFlashAndNormal = SKAction.sequence([bgFlash,SKAction.wait(forDuration: (0.05)),bgNormal,SKAction.wait(forDuration: (0.05))])
        self.run(SKAction.sequence([SKAction.repeat(bgFlashAndNormal, count: 4)]), withKey: "falsh")
        self.removeAction(forKey: "flash")
    }
    
    
    
    
    //ground and skye moving
    func moveGround(sprite:SKSpriteNode, timer: CGFloat) {
        //left to right
        let moveGroupSprite = SKAction.moveBy(x: -sprite.size.width, y:0, duration: TimeInterval(timer * sprite.size.width))
        //right to left
        //let moveGroupSprite = SKAction.moveBy(x: sprite.size.width, y:0, duration: TimeInterval(timer * sprite.size.width))
        
        let resetGroupSprite = SKAction.moveBy(x: sprite.size.width, y: 0, duration: 0.0)
        //keep moving forward
        let moveGroundSpritesForever = SKAction.repeatForever(SKAction.sequence([moveGroupSprite, resetGroupSprite]))
        sprite.run(moveGroundSpritesForever)
    }
    // frog fly
    func frogStartFly() {
        let frogTexture1 = SKTexture(imageNamed: "frog-01")
        frogTexture1.filteringMode = .nearest
        let frogTexture2 = SKTexture(imageNamed: "frog-02")
        frogTexture2.filteringMode = .nearest
        let frogTexture3 = SKTexture(imageNamed: "frog-03")
        frogTexture3.filteringMode = .nearest
        let anim = SKAction.animate(with: [frogTexture1,frogTexture2,frogTexture3], timePerFrame: 0.2)
        frog.run(SKAction.repeatForever(anim), withKey:"fly")
    }
    func frogStopFly() {
        sound.stopBackGround()
        sound.playfinalsounds()
        frog.removeAction(forKey: "fly")
        
    }
    
    //cretae random pipes
    func startCreateRandomPipes() {
        let spawn = SKAction.run {
            self.creatSpawnPipes()
        }
        let delay = SKAction.wait(forDuration: TimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatForever(spawnThenDelay)
        self.run(spawnThenDelayForever, withKey:"createPipe")
    }
    //stop create pipes
    func stopCreateRandomPipes() {
        self.removeAction(forKey: "createPipe")
    }
    //deletes all existing pipes
    func removeAllPipesNode() {
        pipes.removeAllChildren()
    }
    //create the pipe
    func creatSpawnPipes() {
        //pipes' texture
        pipeTextureUp = SKTexture(imageNamed: "PipeUp")
        pipeTextureUp.filteringMode = .nearest
        pipeTextureDown = SKTexture(imageNamed: "PipeDown")
        pipeTextureDown.filteringMode = .nearest
        
        let pipePair = SKNode()
        pipePair.position = CGPoint(x: self.frame.size.width + pipeTextureUp.size().width * 2, y:0)
        pipePair.zPosition = -10;
        
        let height = UInt32(self.frame.size.height / 5)
        let y = Double(arc4random_uniform(height) + height)
        
        let pipeDown = SKSpriteNode(texture: pipeTextureDown)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPoint(x: 0.0, y: y + Double(pipeDown.size.height)+verticalPipeGap)
       
        pipeDown.physicsBody = SKPhysicsBody(rectangleOf: pipeDown.size)
        pipeDown.physicsBody?.isDynamic = false
        pipeDown.physicsBody?.categoryBitMask = pipeCategory
        pipeDown.physicsBody?.contactTestBitMask = frogCategory
        pipePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeTextureUp)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPoint(x: 0.0, y: y)
        pipeUp.physicsBody = SKPhysicsBody(rectangleOf: pipeUp.size)
        pipeUp.physicsBody?.isDynamic = false
        pipeUp.physicsBody?.categoryBitMask = pipeCategory
        pipeUp.physicsBody?.contactTestBitMask = frogCategory
        pipePair.addChild(pipeUp)
        
        let contactNode = SKNode()
        contactNode.position = CGPoint(x: pipeDown.size.width, y: self.frame.midY)
        contactNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeUp.size.width, height: self.frame.size.height))
        contactNode.physicsBody?.isDynamic = false
        contactNode.physicsBody?.categoryBitMask = scoreCategory
        contactNode.physicsBody?.contactTestBitMask = frogCategory
        pipePair.addChild(contactNode)
        
        //pipe moving
        let distanceToMove = CGFloat(self.frame.size.width + 2.0*pipeTextureUp.size().width)
        //from left to right
        let movePipes = SKAction.moveBy(x: -distanceToMove, y: 0.0, duration: TimeInterval(0.01 * distanceToMove))
        
        //from right to left
        //let movePipes = SKAction.moveBy(x: distanceToMove, y: 0.0, duration: TimeInterval(0.01 * distanceToMove))
        
        let removePipes = SKAction.removeFromParent()
        let movePipesAndRemove = SKAction.sequence([movePipes,removePipes])
        pipePair.run(movePipesAndRemove)
        
        pipes.addChild(pipePair)
    }
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        let value = frog.physicsBody!.velocity.dy * (frog.physicsBody!.velocity.dy < 0 ? 0.003 : 0.001)
        frog.zRotation = min(max(-1, value),0.5)
    }
}
