//
//  MultiGestureDetector.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import UIKit

protocol MultiGestureDetectorDelegate: AnyObject {
    func gestureDidStart(_ location: CGPoint, tag: Int)
    func gestureDidMoveTo(_ location: CGPoint, velocity: CGPoint, tag: Int)
    func gesturePanDidEnd(_ location: CGPoint, velocity: CGPoint, tag: Int)
    func gesturePressDidEnd(_ location: CGPoint, tag: Int)
}

class MultiGestureDetector: NSObject {
    weak var delegate: MultiGestureDetectorDelegate?
    
    private lazy var panGesture: UIGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        gesture.maximumNumberOfTouches = 1
        gesture.delegate = self
        return gesture
    }()
    
    private lazy var longPressGesture: UIGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        gesture.cancelsTouchesInView = false
        gesture.minimumPressDuration = 0.01
        gesture.delegate = self
        return gesture
    }()
    
    private weak var relativeToView: UIView?
    private let tag: Int
    
    init(tag: Int) {
        self.tag = tag
    }
    
    func attachTo(view: UIView, relativeToView: UIView) {
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(longPressGesture)
        self.relativeToView = relativeToView
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: relativeToView)
        switch gesture.state {
        case .began, .changed:
            delegate?.gestureDidMoveTo(location, velocity: gesture.velocity(in: relativeToView), tag: tag)
        case .ended:
            delegate?.gesturePanDidEnd(location, velocity: gesture.velocity(in: relativeToView), tag: tag)
        default:
            break
        }
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: relativeToView)
        switch gesture.state {
        case .began:
            delegate?.gestureDidStart(location, tag: tag)
        case .ended:
            delegate?.gesturePressDidEnd(location, tag: tag)
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

