//
//  ImmersiveView.swift
//  Dinopedia
//
//  Created by Syrine Aidani on 26.04.25.
//

//from: https://github.com/sarangborude/Dinopedia


import SwiftUI
import RealityKit
import RealityKitContent
import AVFoundation

@MainActor
struct ImmersiveCulturalView: View {
    
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    @Environment(\.openWindow) var openWindow
    @Environment(\.dismissWindow) var dismissWindow
    
    @PhysicalMetric(from: .meters) var smallDinoWidth = 0.2
    
    @EnvironmentObject private var recorder: VoiceRecorder

    @State private var skyboxTextureURL: URL?

    
    var body: some View {
        RealityView { content, attachments in
            let skybox = await createSkyboxEntity(texture: "skybox")
            content.add(skybox)
            
            guard let infoCard = attachments.entity(for: "BrachioInfo") else {
                fatalError("Cannot load brachio info attachment")
            }
            content.add(infoCard)
            infoCard.position += [0, 1, -2] // meters
            
            
        } update: { content, attachments in
            
        } attachments: {
            Attachment(id: "BrachioInfo") {
                VStack {
                    AvatarView()
                    Button(action: {
                        Task {
                            await dismissImmersiveSpace()
                        }
                        
                    }, label: {
                        Image(systemName: "xmark")
                            .font(.largeTitle)
                            .padding()
                    })
                }
                .padding(50)
            }
            
            Attachment(id: "MiniBrachio") {
                Model3D(named: "Brachiosaurus", bundle: realityKitContentBundle) { model in
                    model
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
                .frame(depth: nil, alignment: .center)
                .frame(width: smallDinoWidth)
            }
        }
        .onAppear {
            dismissWindow(id: VisiolingoApp.homeView)
        }
        .onDisappear {
            openWindow(id: VisiolingoApp.homeView)
            recorder.stop()
        }
    }
    
    func createSkyboxEntity(texture: String) async -> Entity {
        guard let resource = try? await TextureResource(named: texture) else {
            fatalError("Unable to load the skybox")
        }
        
        var material = UnlitMaterial()
        material.color = .init(texture: .init(resource))
        
        let entity = Entity()
        entity.components.set(ModelComponent(mesh: .generateSphere(radius: 1000), materials: [material]))
        entity.scale *= .init(x: -1, y:1, z:1)
        return entity
    }
    
    func deg2rad(_ number: Float) -> Float {
        return number * .pi / 180
    }
}

#Preview(immersionStyle: .mixed) {
    ImmersiveCulturalView()
}
