//
//  MultiGestureDetector.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import UIKit

protocol MultiGestureDetectorDelegate: AnyObject {
    func gestureDidStart(_ location: CGPoint)
    func gestureDidMoveTo(_ location: CGPoint, velocity: CGPoint)
    func gesturePanDidEnd(_ location: CGPoint, velocity: CGPoint)
    func gesturePressDidEnd(_ location: CGPoint)
}

class MultiGestureDetector: NSObject {
    weak var delegate: MultiGestureDetectorDelegate?
        
    private lazy var panGesture: UIGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(malletPan))
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        return gesture
    }()
    
    private lazy var longPressGesture: UIGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(malletLongPress))
        gesture.cancelsTouchesInView = false
        gesture.minimumPressDuration = 0.01
        gesture.delegate = self
        return gesture
    }()
    
    func attachTo(view: UIView) {
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(longPressGesture)
    }
    
    @objc func malletPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        switch gesture.state {
        case .began, .changed:
            delegate?.gestureDidMoveTo(location, velocity: gesture.velocity(in: gesture.view))
        case .ended:
            delegate?.gesturePanDidEnd(location, velocity: gesture.velocity(in: gesture.view))
        default:
            break
        }
    }
    
    @objc func malletLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        switch gesture.state {
        case .began:
            delegate?.gestureDidStart(location)
        case .ended:
            delegate?.gesturePressDidEnd(location)
        default:
            break
        }
    }
}

extension MultiGestureDetector: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

