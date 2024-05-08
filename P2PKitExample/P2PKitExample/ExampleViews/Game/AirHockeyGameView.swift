//
//  PongGameView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/8/24.
//

import SwiftUI

struct AirHockeyGameView: UIViewRepresentable {
    typealias UIViewType = GameViewBorderView
    
    func makeUIView(context: Context) -> GameViewBorderView {
        GameViewBorderView(PongGameBoardView())
    }
    
    func updateUIView(_ uiView: GameViewBorderView, context: Context) {
    }
}

class GameViewBorderView: UIView {
    private var gameView: UIView
    
    init(_ gameView: UIView) {
        self.gameView = gameView
        gameView.translatesAutoresizingMaskIntoConstraints = false
        gameView.backgroundColor = .systemMint
        
        super.init(frame: .zero)
        backgroundColor = .darkText
        
        addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            gameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            gameView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            gameView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class PongGameBoardView: UIView {
    private let handleSize: CGFloat = 80
    
    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = "Hello!"
        label.textAlignment = .center
        return label
    }()
    
    private lazy var handle: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 6
        view.layer.cornerRadius = handleSize/2
        view.frame.size = CGSize(width: handleSize, height: handleSize)
        return view
    }()
    
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
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .systemMint
        
        addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            debugLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            debugLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
        ])
        
        addSubview(handle)
        handle.frame.origin = CGPoint(x: 0, y: 50)
        
        addGestureRecognizer(panGesture)
        addGestureRecognizer(longPressGesture)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: handle.superview)
        switch gesture.state {
        case .began, .changed:
            handle.center = location
        case .ended:
            break
        default:
            break
        }
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: handle.superview)
        switch gesture.state {
        case .began:
            handle.center = location
        default:
            break
        }
    }
}

extension PongGameBoardView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
