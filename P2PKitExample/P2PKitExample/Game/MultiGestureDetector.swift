//
//  MultiGestureDetector.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/9/24.
//

import Foundation
import UIKit

protocol MultiGestureDetectorDelegate: AnyObject {
    func touchesDidMoveTo(_ location: CGPoint)
}

class MultiGestureDetector: NSObject {
    private weak var delegate: MultiGestureDetectorDelegate?
    
    private let handleSize: CGFloat = 80
    
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
    
    func attachTo<T>(view: T) where T: MultiGestureDetectorDelegate, T: UIView {
        delegate = view
        
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(longPressGesture)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        switch gesture.state {
        case .began, .changed:
            delegate?.touchesDidMoveTo(location)
        case .ended:
            break
        default:
            break
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: gesture.view)
        switch gesture.state {
        case .began:
            delegate?.touchesDidMoveTo(location)
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

