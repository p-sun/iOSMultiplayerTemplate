//
//  GameSounds.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/13/24.
//

import Foundation
import AudioToolbox

struct GameSounds {
    enum Sound:String {
        case ballEnteredHole = "/System/Library/Audio/UISounds/PINSubmit_AX.caf"
        case ballCollision = "/System/Library/Audio/UISounds/key_press_click.caf"
    }
    
    static private var loadedSounds = [Sound: SystemSoundID]()
    
    static func play(_ sound: Sound) {
        if let soundID = loadedSounds[sound] {
            AudioServicesPlaySystemSound(soundID);
        } else {
            let soundURL = URL(fileURLWithPath: sound.rawValue)
            var soundID: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
            loadedSounds[sound] = soundID
            AudioServicesPlaySystemSound(soundID)
        }
    }
}
