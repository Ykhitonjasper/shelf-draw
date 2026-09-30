import SwiftUI

enum AppMotion {
    static var spatial: Animation {
        .spring(duration: PackCharacter.riseDuration, bounce: PackCharacter.spatialBounce)
    }

    /// Color and opacity. No bounce — a fading fill should not wobble.
    static var effects: Animation {
        .spring(duration: 0.25, bounce: 0)
    }
}

extension View {
    /// One entrance. The pack sets the spring. Reduced motion fades in place.
    func arrive() -> some View {
        modifier(Arrive())
    }

    func confirm<V: Equatable>(on trigger: V) -> some View {
        self.sensoryFeedback(.success, trigger: trigger)
            .pop(on: trigger)
    }

    func reject<V: Equatable>(on trigger: V) -> some View {
        self.sensoryFeedback(.warning, trigger: trigger)
            .shake(on: trigger)
    }
}

private struct Arrive: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: (shown || reduceMotion) ? 0 : 12)
            .onAppear {
                guard !shown else { return }
                if reduceMotion {
                    shown = true
                    return
                }
                withAnimation(AppMotion.spatial) {
                    shown = true
                }
            }
    }
}
