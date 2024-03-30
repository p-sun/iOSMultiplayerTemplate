//
//  CardViewModel.swift
//  CardVision
//
//  Created by John Haney (Lextech) on 3/29/24.
//

import ARKit
import RealityKit

@Observable
@MainActor
class CardViewModel: ARUnderstandingModel {
    let imageTracking = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "CardDeck20")
    )
    
    var imageAnchors: [UUID: ImageAnchor] = [:]
    var entityMap: [UUID: Entity] = [:]
    
    init() {
        super.init(providers: [.image(imageTracking)])
    }
    
    override func processImageUpdates() async {
        for await update in imageTracking.anchorUpdates {
            await self.update(update.anchor)
        }
    }
    
    func update(_ anchor: ImageAnchor) async {
        if imageAnchors[anchor.id] == nil {
            let entity = ModelEntity(mesh: .generateSphere(radius: 0.025))
            entity.name = anchor.id.uuidString
            entityMap[anchor.id] = entity
            contentEntity.addChild(entity)
            self.imageAnchors[anchor.id] = anchor
        }
        
        if anchor.isTracked {
            entityMap[anchor.id]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
}
