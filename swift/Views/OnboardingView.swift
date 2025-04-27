//
//  OnboardingView.swift
//  Visiolingo
//
//  Created by Syrine Aidani on 26.04.25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasSeenOnboarding: Bool
    @State private var page = 0

    private let totalPages = 2

    private let gradients: [LinearGradient] = [
        LinearGradient(colors: [.yellow, .pink], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [.mint, .teal], startPoint: .top, endPoint: .bottom),
        LinearGradient(colors: [.pink, .orange], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.cyan, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    var body: some View {
        ZStack {
            gradients[page]
                .ignoresSafeArea()
                .animation(.easeInOut, value: page)

            VStack(spacing: 24) {
                TabView(selection: $page) {
                    OnboardingGlobePage(
                        obj: "Globe",
                        title: "Hola! Hello! こんにちは!",
                        subtitle: "Visiolingo immerses you in 20+ languages. Pick yours & dive in.",
                        welcome: true)
                        .tag(0)
            
                    // 2 ▸ Language switching
                    OnboardingGlobePage(
                        obj: "Message",
                        title: "Learn languages on the fly",
                        subtitle: "Master vocabulary, grammar, and pronunciation—all in your field of view.",
                        welcome: false)
                        .tag(1)

                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
                .frame(maxHeight: .infinity)

                Button(action: advance) {
                    Text(page == totalPages - 1 ? "Let’s Start!" : "Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
            .padding()
        }
        .glassBackgroundEffect(displayMode: .always)
    }

    private func advance() {
        if page < totalPages - 1 {
            withAnimation { page += 1 }
        } else {
            hasSeenOnboarding = true
        }
    }
}
#Preview("Onboarding", windowStyle: .plain) {
    OnboardingView(hasSeenOnboarding: .constant(false))
}


