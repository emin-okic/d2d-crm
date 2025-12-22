//
//  ExpandableOptionsMenu.swift
//  d2d-studio
//
//  Created by Emin Okic on 12/22/25.
//

import SwiftUI

struct ExpandableOptionsMenu<Content: View>: View {
    @Binding var isExpanded: Bool

    let content: Content

    @GestureState private var dragOffset: CGFloat = 0

    init(
        isExpanded: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) {
        self._isExpanded = isExpanded
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 12) {
            if isExpanded {
                content
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            optionsButton
        }
        .padding(10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .shadow(radius: 6)
        )
        .offset(x: dragOffset)
        .gesture(dragGesture)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isExpanded)
    }

    private var optionsButton: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: 18, weight: .semibold))
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.blue))
            .foregroundColor(.white)
            .onTapGesture {
                withAnimation {
                    isExpanded.toggle()
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($dragOffset) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                withAnimation {
                    if value.translation.width < -40 {
                        // Drag left → collapse
                        isExpanded = false
                    } else if value.translation.width > 40 {
                        // Drag right → expand
                        isExpanded = true
                    }
                }
            }
    }
}
