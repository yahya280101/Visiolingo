//
//  OnboardingGlobePage.swift
//  Dinopedia
//
//  Created by Syrine Aidani on 26.04.25.
//

import SwiftUI
import AVKit
import RealityKit

struct OnboardingGlobePage: View {
    let obj: String
    let title: String
    let subtitle: String
    let welcome: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            if(welcome) {
                Text("Welcome to Visiolingo")
                    .font(.extraLargeTitle).bold()
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
            }
            TimelineView(.animation) { context in
                Model3D(named: obj) { model in
                    model
                        .resizable()
                        .scaledToFit()
                    //.rotation3DEffect(.degrees(90 ) , axis: .y)
                        .rotation3DEffect(.degrees(context.date.timeIntervalSinceReferenceDate * 10 ), axis: .y)
                } placeholder: {
                    ProgressView()
                }
                .frame(depth: 200, alignment: .center)
                .frame(height: 200)
                .padding(.bottom, 40)
            }
            
            Text(title)
                .font(.title2).bold()
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
        }
        
    }
}
            
