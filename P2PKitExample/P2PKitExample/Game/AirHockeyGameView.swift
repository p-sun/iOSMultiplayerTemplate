//  Created by Paige Sun on 5/8/24.

import SwiftUI

struct AirHockeyGameView: UIViewRepresentable {
    typealias UIViewType = GameBorderView
    
    func makeUIView(context: Context) -> GameBorderView {
        let playAreaView = AirHockeyPlayAreaView()
        return GameBorderView(gameView: playAreaView)
    }
    
    func updateUIView(_ uiView: GameBorderView, context: Context) {
    }
}

class GameBorderView: UIView {
    private var gameView: UIView
    
    init(gameView: UIView) {
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

class AirHockeyPlayAreaView: UIView {
    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = "Hello!"
        label.textAlignment = .center
        return label
    }()
    
    lazy var ball: UIView = {
        let view = UIView()
        view.backgroundColor = .green
        view.layer.borderWidth = 6
        view.layer.cornerRadius = GameConfig.ballRadius
        view.frame.size = CGSize(
            width: GameConfig.ballRadius * 2,
            height: GameConfig.ballRadius * 2)
        return view
    }()
    
    lazy var handle: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.borderWidth = 6
        view.layer.cornerRadius = GameConfig.handleSize/2
        view.frame.size = CGSize(width: GameConfig.handleSize, height: GameConfig.handleSize)
        return view
    }()
    
    private lazy var gestureDetector = {
        let gestureDetector = MultiGestureDetector()
        return gestureDetector
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemMint
        
        addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            debugLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            debugLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
        ])
        
        addSubview(ball)
        addSubview(handle)
        handle.frame.origin = CGPoint(x: 0, y: 50)
        
        gestureDetector.attachTo(view: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        if AirHockeyController.shared == nil {
            AirHockeyController.shared = AirHockeyController(boardSize: frame.size, playAreaView: self)
        }
    }
}

extension AirHockeyPlayAreaView: MultiGestureDetectorDelegate {
    func touchesDidMoveTo(_ location: CGPoint) {
        handle.center = location
    }
}
