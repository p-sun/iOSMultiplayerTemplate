//  Created by Paige Sun on 5/8/24.

import SwiftUI

struct AirHockeyView: UIViewRepresentable {
    typealias UIViewType = AirHockeyRootView
    
    let instance = AirHockeyInstance()
        
    func makeUIView(context: Context) -> AirHockeyRootView {
        return instance.rootUIView
    }
    
    func updateUIView(_ uiView: AirHockeyRootView, context: Context) {
    }
}

class AirHockeyRootView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = UIColor(red: 10.0/255.0, green: 39.0/255.0, blue: 89.0/255.0, alpha: 1)
    }
    
    func constrainSubviews(gameView: UIView, scoreView: UIView) {
        gameView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(gameView)
        NSLayoutConstraint.activate([
            gameView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            gameView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            gameView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            gameView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
        ])
        
        addSubview(scoreView)
        scoreView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scoreView.leadingAnchor.constraint(equalTo: gameView.leadingAnchor, constant: 10),
            scoreView.bottomAnchor.constraint(equalTo: gameView.bottomAnchor, constant: -10),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class AirHockeyScoreView: UILabel {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        font = .systemFont(ofSize: 24)
        numberOfLines = 0
    }
    
    func playersDidChange(_ players: [GamePlayer]) {
        text = players.map { player in "\(player.displayName): \(player.score)" }.joined(separator: "\n")
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
