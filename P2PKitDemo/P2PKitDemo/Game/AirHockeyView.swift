//  Created by Paige Sun on 5/8/24.

import SwiftUI
import UIKit

struct AirHockeyView: UIViewRepresentable {
    typealias UIViewType = AirHockeyRootView
    
    private let instance = AirHockeyInstance()
    
    func makeUIView(context: Context) -> AirHockeyRootView {
        return instance.rootUIView
    }
    
    func updateUIView(_ uiView: AirHockeyRootView, context: Context) {
    }
}

class AirHockeyRootView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = #colorLiteral(red: 0.7988162041, green: 0.868170917, blue: 0.8175464272, alpha: 1)
    }
    
    func constrainSubviews(gameView: UIView, scoreView: UIView) {
        gameView.backgroundColor = #colorLiteral(red: 0.9941810966, green: 0.9735670686, blue: 0.9148231149, alpha: 1)
        gameView.layer.cornerRadius = 10
        
        addSubview(gameView)
        gameView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            gameView.topAnchor.constraint(equalTo: topAnchor, constant: 80),
            gameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            gameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            gameView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -80),
        ])
        
        addSubview(scoreView)
        scoreView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreView.topAnchor.constraint(equalTo: gameView.bottomAnchor, constant: 8),
            scoreView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 40),
            scoreView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -40),
            scoreView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AirHockeyScoreView: UIView {
    private var hStack = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        return stack
    }()
    
    private var labels = [UILabel]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(hStack)
        hStack.constrainTo(self)
    }
    
    func playersDidChange(_ players: [GamePlayer]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for subview in hStack.arrangedSubviews {
                subview.removeFromSuperview()
            }
            for player in players {
                let label = UILabel()
                label.textAlignment = .center
                label.text = "\(player.score)"
                label.textColor = player.color
                label.font = .boldSystemFont(ofSize: 46)
                hStack.addArrangedSubview(label)
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AirHockeyGameView: UIView {
    var didLayout: ((CGSize) -> Void)?
    
    weak var gestureDelegate: MultiGestureDetectorDelegate? {
        didSet {
            for gestureDetector in gestureDetectors.values {
                gestureDetector.delegate = gestureDelegate
            }
        }
    }
    
    private var gestureDetectors = [UIView: MultiGestureDetector]()

    private var holesView = UIView()
    private var pucksView = UIView()
    private var malletsView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(holesView)
        addSubview(pucksView)
        addSubview(malletsView)
        
        holesView.constrainTo(self)
        pucksView.constrainTo(self)
        malletsView.constrainTo(self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        didLayout?(frame.size)
    }
    
    func update(mallets: [Ball], pucks: [Ball], holes: [Ball], players: [GamePlayer]) {
        DispatchQueue.main.async {
            self.updateBalls(in: self.holesView, balls: holes, players: players)
            self.updateBalls(in: self.pucksView, balls: pucks, players: players)
            self.updateBalls(in: self.malletsView, balls: mallets, players: players)
        }
    }

    private func updateBalls(in parent: UIView, balls: [Ball], players: [GamePlayer]) {
        for (i, ball) in balls.enumerated() {
            if i > parent.subviews.count - 1 {
                let ballView = createBallView(ball, index: i)
                parent.addSubview(ballView)
            }
            
            let ballView = parent.subviews[i]
            ballView.center = ball.position
            switch ball.info {
            case .hole:
                break
            case .puck:
                if let puckOwnerID = ball.ownerID,
                   let player = players.first(where: { player in player.peerID == puckOwnerID }) {
                    ballView.layer.borderColor = player.color.cgColor
                }
            case .mallet:
                if let player = players.first(where: { player in player.peerID == ball.ownerID }) {
                    ballView.backgroundColor = player.color
                    ballView.layer.borderColor = ball.isGrabbed ? UIColor.black.cgColor : player.color.cgColor
                }
            }
        }
        
        // Remove unused ball views
        if parent.subviews.count > balls.count {
            for _ in balls.count..<parent.subviews.count {
                parent.subviews.last?.removeFromSuperview()
            }
        }
    }
    
    private func createBallView(_ ball: Ball, index: Int) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = ball.radius
        view.frame.size = CGSize(width: ball.radius * 2, height: ball.radius * 2)
        switch ball.info {
        case .hole:
            view.backgroundColor = .black
        case .puck:
            view.backgroundColor = .white
            view.layer.borderWidth = 10
        case .mallet:
            view.layer.borderWidth = 6
            
            let gestureDetector = MultiGestureDetector(tag: index)
            gestureDetectors[view] = gestureDetector
            gestureDetector.attachTo(view: view, relativeToView: self)
            gestureDetector.delegate = gestureDelegate
        }
        return view
    }
}

extension UIView {
    fileprivate func constrainTo(_ view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom),
        ])
    }
}
