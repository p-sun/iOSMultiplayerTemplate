//  Created by Paige Sun on 5/8/24.

import SwiftUI

struct AirHockeyView: UIViewRepresentable {
    typealias UIViewType = GameBorderView
    
    func makeUIView(context: Context) -> GameBorderView {
        let playAreaView = AirHockeyGameView()
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

class AirHockeyGameView: UIView {
    private lazy var debugLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .title1)
        label.text = ""
        label.textAlignment = .center
        return label
    }()
    
    lazy var puckView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = GameConfig.ballRadius
        view.frame.size = CGSize(
            width: GameConfig.ballRadius * 2,
            height: GameConfig.ballRadius * 2)
        return view
    }()
    
    private var malletViews = [UIView]()
    private var gestureDetectors = [UIView: MultiGestureDetector]()
    
    weak var gestureDelegate: MultiGestureDetectorDelegate? {
        didSet {
            for gestureDetector in gestureDetectors.values {
                gestureDetector.delegate = gestureDelegate
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemMint
        
        addSubview(debugLabel)
        NSLayoutConstraint.activate([
            debugLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            debugLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            debugLabel.topAnchor.constraint(equalTo: topAnchor, constant: 20),
        ])
        
        addSubview(puckView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateMallets(_ mallets: [Ball]) {
        for (i, mallet) in mallets.enumerated() {
            if i > malletViews.count - 1 {
                let view = createMalletView()
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
        if AirHockeyController.shared == nil {
            AirHockeyController.shared = AirHockeyController(boardSize: frame.size, playAreaView: self)
        }
    }
    
    private func createMalletView() -> UIView {
        let view = UIView()
        view.backgroundColor = .blue
        view.layer.cornerRadius = GameConfig.malletRadius
        view.frame.size = CGSize(
            width: GameConfig.malletRadius * 2,
            height: GameConfig.malletRadius * 2)
        addSubview(view)
        return view
    }
}
