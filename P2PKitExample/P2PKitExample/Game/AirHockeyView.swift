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
        for subview in hStack.arrangedSubviews {
            subview.removeFromSuperview()
        }
        for player in players {
            let label = UILabel()
            label.text = "\(player.score)"
            label.textColor = player.color
            label.font = .boldSystemFont(ofSize: 46)
            hStack.addArrangedSubview(label)
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
    
    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = ""
        label.textAlignment = .center
        return label
    }()
    
    private lazy var puckView: UIView = {
        let view = createCircleView(radius: GameConfig.ballRadius)
        view.backgroundColor = .white
        view.layer.borderWidth = 10
        return view
    }()
    
    private lazy var holeView: UIView = {
        let view = createCircleView(radius: GameConfig.holeRadius)
        view.backgroundColor = .black
        return view
    }()
    
    private var malletViews = [UIView]()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(holeView)
        addSubview(puckView)
        addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            debugLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            debugLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(mallets: [Ball], puck: Ball, hole: Ball, players: [GamePlayer]) {
        updateMallets(mallets, players: players)
        holeView.center = hole.position
        puckView.center = puck.position
        if let puckOwnerID = puck.ownerID {
            if let player = players.first(where: { player in player.id == puckOwnerID }) {
                puckView.layer.borderColor = player.color.cgColor
            }
        }
    }
    
    private func updateMallets(_ mallets: [Ball], players: [GamePlayer]) {
        for (i, mallet) in mallets.enumerated() {
            if i > malletViews.count - 1 {
                let view = createCircleView(radius: GameConfig.malletRadius)
                addSubview(view)
                malletViews.append(view)
                
                let gestureDetector = MultiGestureDetector(tag: i)
                gestureDetectors[view] = gestureDetector
                gestureDetector.attachTo(view: view, relativeToView: self)
                gestureDetector.delegate = gestureDelegate
            }
            let malletView = malletViews[i]
            malletView.center = mallet.position
            
            malletView.layer.borderWidth = 6
            if let player = players.first(where: { player in player.id == mallet.ownerID }) {
                malletView.backgroundColor = player.color
                malletView.layer.borderColor = mallet.isGrabbed ? UIColor.black.cgColor : player.color.cgColor
            }
        }
        
        // Remove unused malletViews.
        if malletViews.count > mallets.count {
            for i in mallets.count - 1..<malletViews.count {
                malletViews[i].removeFromSuperview()
            }
        }
    }
    
    override func layoutSubviews() {
        didLayout?(frame.size)
    }
    
    private func createCircleView(radius: CGFloat) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = radius
        view.frame.size = CGSize(width: radius * 2, height: radius * 2)
        addSubview(view)
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
