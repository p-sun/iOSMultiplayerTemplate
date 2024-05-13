//  Created by Paige Sun on 5/8/24.

import SwiftUI

struct AirHockeyView: UIViewRepresentable {
    typealias UIViewType = AirHockeyRootUIView
    
    func makeUIView(context: Context) -> AirHockeyRootUIView {
        let playAreaView = AirHockeyGameView()
        return AirHockeyRootUIView(gameView: playAreaView)
    }
    
    func updateUIView(_ uiView: AirHockeyRootUIView, context: Context) {
    }
}

class AirHockeyRootUIView: UIView {
    private var gameView: UIView
    
    private var scoreLabel: UILabel = {
        let label = UILabel()
        label.text = "hello"
        label.font = .systemFont(ofSize: 24)
        label.numberOfLines = 0
        return label
    }()
    
    init(gameView: AirHockeyGameView) {
        self.gameView = gameView
        super.init(frame: .zero)
        
        gameView.backgroundColor = .systemMint
        backgroundColor = UIColor(red: 10.0/255.0, green: 39.0/255.0, blue: 89.0/255.0, alpha: 1)
        
        gameView.didLayout = { size in
            if AirHockeyController.shared == nil {
                AirHockeyController.shared = AirHockeyController(boardSize: size, gameView: gameView, scoreView: self)
            }
        }
        constrainSubviews()
    }
    
    func playersDidChange(_ players: [GamePlayer]) {
        scoreLabel.text = players.map { player in "\(player.id): \(player.score)" }.joined(separator: "\n")
    }
    
    private func constrainSubviews() {
        gameView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            gameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            gameView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            gameView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
        
        addSubview(scoreLabel)
        scoreLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreLabel.leadingAnchor.constraint(equalTo: gameView.leadingAnchor, constant: 10),
            scoreLabel.bottomAnchor.constraint(equalTo: gameView.bottomAnchor, constant: -10),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        print("Game border layout")
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
        backgroundColor = .systemMint
        
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
    
    func update(mallets: [Ball], puck: Ball, hole: Ball) {
        updateMallets(mallets)
        holeView.center = hole.position
        puckView.center = puck.position
    }
    
    private func updateMallets(_ mallets: [Ball]) {
        for (i, mallet) in mallets.enumerated() {
            if i > malletViews.count - 1 {
                let view = createCircleView(radius: GameConfig.malletRadius)
                malletViews.append(view)
                
                let gestureDetector = MultiGestureDetector(tag: i)
                gestureDetectors[view] = gestureDetector
                gestureDetector.attachTo(view: view, relativeToView: self)
                gestureDetector.delegate = gestureDelegate
            }
            
            malletViews[i].center = mallet.position
            malletViews[i].backgroundColor = mallet.isGrabbed ? .systemOrange : .systemIndigo
        }
        // TODO: Move other malletViews out of view. Keep a reusable pool of malletViews
    }
    
    override func layoutSubviews() {
        didLayout?(frame.size)
    }
    
    private func createCircleView(radius: CGFloat) -> UIView {
        let view = UIView()
        view.backgroundColor = .blue
        view.layer.cornerRadius = radius
        view.frame.size = CGSize(width: radius * 2, height: radius * 2)
        addSubview(view)
        return view
    }
}
