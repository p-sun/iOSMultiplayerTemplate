//
//  PongGameView.swift
//  P2PKitExample
//
//  Created by Paige Sun on 5/8/24.
//

import SwiftUI

struct AirHockeyGameView: UIViewRepresentable {
    typealias UIViewType = GameViewBorder
    
    func makeUIView(context: Context) -> GameViewBorder {
        GameViewBorder(PongGameBoardView())
    }
    
    func updateUIView(_ uiView: GameViewBorder, context: Context) {
    }
}

class GameViewBorder: UIView {
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
    
    private lazy var panGesture: UIPanGestureRecognizer = {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.maximumNumberOfTouches = 1
        return pan
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
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began, .changed:
            if let view = gesture.view {
                handle.center = CGPoint(
                    x: handle.center.x + translation.x,
                    y: handle.center.y + translation.y)
                gesture.setTranslation(.zero, in: gesture.view?.superview)
            }
        case .ended:
            break
        default:
            break
        }
    }
}
