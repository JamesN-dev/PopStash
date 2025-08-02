//
//  PopButtonStyle.swift
//  PopStash
//
//  Created by atetraxx on 8/2/25.
//

import SwiftUI

struct PopButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PopButtonStyleView(configuration: configuration)
    }

    private struct PopButtonStyleView: View {
        let configuration: Configuration
        @State private var isHovered = false
        @Environment(PreferencesManager.self) private var preferences
        @Environment(\.isHoverEffectEnabled) private var isHoverEffectEnabled

        var body: some View {
            let hoverEnabled = preferences.enableHoverEffect && isHoverEffectEnabled
            configuration.label
                .padding(10)
                .background(backgroundForState(isPressed: configuration.isPressed))
                .cornerRadius(8)
                .foregroundColor(.primary)
                .scaleEffect(scaleForState(isPressed: configuration.isPressed))
                .shadow(color: (isHovered && hoverEnabled) ? Color.blue.opacity(0.3) : Color.clear, radius: isHovered && hoverEnabled ? 8 : 0, x: 0, y: isHovered && hoverEnabled ? 4 : 0)
                .onHover { hovering in
                    if hoverEnabled { isHovered = hovering } else { isHovered = false }
                }
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
        }

        private func backgroundForState(isPressed: Bool) -> Color {
            if isPressed {
                return Color.gray.opacity(0.4)
            } else if isHovered {
                return Color.gray.opacity(0.15)
            } else {
                return Color.clear
            }
        }

        private func scaleForState(isPressed: Bool) -> CGFloat {
            if isPressed {
                return 0.95
            } else if isHovered {
                return 1.02
            } else {
                return 1.0
            }
        }
    }

    // ...existing code...
}
