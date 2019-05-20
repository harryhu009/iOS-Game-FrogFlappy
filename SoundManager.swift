//
//  SoundManager.swift
//  HHFlappyFrog
//
//  Created by hu on 2019/2/24.
//  Copyright © 2019年 hu. All rights reserved.
//

import Foundation
import SpriteKit
import AVFoundation

class SoundManager :SKNode{
    var bgMusicPlayer = AVAudioPlayer()
    
    let hitAct = SKAction.playSoundFileNamed("flap.mp3", waitForCompletion: false)
   // let finalact = SKAction.playSoundFileNamed("score10.mp3", waitForCompletion: false)//“我很生气”
    let finalact = SKAction.playSoundFileNamed("gameover.mp3", waitForCompletion: false)//“别看现在闹得欢”
    
    func playBackGround(){
        
        
       
        let bgMusicURL =  Bundle.main.url(forResource: "bgm", withExtension: "mp3")!
        
        try! bgMusicPlayer = AVAudioPlayer (contentsOf: bgMusicURL)
        
        bgMusicPlayer.numberOfLoops = -1
        
        bgMusicPlayer.prepareToPlay()
        
        bgMusicPlayer.play()
        
    }
    
    func stopBackGround() {
        let bgMusicURL =  Bundle.main.url(forResource: "bgm", withExtension: "mp3")!
      
        try! bgMusicPlayer = AVAudioPlayer (contentsOf: bgMusicURL)
        
        bgMusicPlayer.numberOfLoops = -1
        
        bgMusicPlayer.prepareToPlay()
        
        bgMusicPlayer.stop()
    }
    
    func playHit(){
            print("播放音效!")
            self.run(hitAct)
        }
    func playfinalsounds() {
        self.run(finalact)
    }
}
