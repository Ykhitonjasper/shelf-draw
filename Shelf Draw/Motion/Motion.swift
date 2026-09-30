import SwiftUI

private struct PopValue {
    var scale: CGFloat = 1
}

private struct ShakeValue {
    var x: CGFloat = 0
}

extension View {
    /// Short entrance. One spring, then it stays.
    func riseIn() -> some View {
        modifier(RiseIn())
    }

    /// A small scale when `trigger` changes. For a saved result, not a loop.
    func pop<V: Equatable>(on trigger: V) -> some View {
        modifier(PopOnChange(trigger: trigger))
    }

    /// A short sideways kick when `trigger` changes. For a failed check.
    func shake<V: Equatable>(on trigger: V) -> some View {
        modifier(ShakeOnChange(trigger: trigger))
    }
}

private struct RiseIn: ViewModifier {
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .onAppear {
                withAnimation(.spring(duration: 0.45)) {
                    shown = true
                }
            }
    }
}

private struct PopOnChange<V: Equatable>: ViewModifier {
    var trigger: V

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: PopValue(), trigger: trigger) { view, value in
            view.scaleEffect(value.scale)
        } keyframes: { _ in
            KeyframeTrack(\.scale) {
                SpringKeyframe(1.06, duration: 0.16)
                SpringKeyframe(1, duration: 0.28)
            }
        }
    }
}

private struct ShakeOnChange<V: Equatable>: ViewModifier {
    var trigger: V

    func body(content: Content) -> some View {
        content.keyframeAnimator(initialValue: ShakeValue(), trigger: trigger) { view, value in
            view.offset(x: value.x)
        } keyframes: { _ in
            KeyframeTrack(\.x) {
                LinearKeyframe(7, duration: 0.05)
                LinearKeyframe(-7, duration: 0.08)
                LinearKeyframe(4, duration: 0.07)
                LinearKeyframe(0, duration: 0.08)
            }
        }
    }
}

/// A number that rolls when it changes. Put it on the result, not on a caption.
struct RollingValue: View {
    var text: String

    var body: some View {
        Text(text)
            .contentTransition(.numericText())
            .animation(.spring(duration: 0.35), value: text)
    }
}

extension Image {
    /// One bounce when `trigger` changes. System symbol only.
    func symbolBounce<V: Equatable>(trigger: V) -> some View {
        self.symbolEffect(.bounce, value: trigger)
    }
}

/// A single arc tied to a domain fraction. Not a set of activity rings.
struct ProgressArc: View {
    var fraction: Double
    var label: String

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.hairline, lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(1, max(0, fraction)))
                .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            RollingValue(text: label)
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .frame(width: 88, height: 88)
        .accessibilityElement(children: .combine)
    }
}

/// A passing shine for a value that is still loading. Do not leave it on a finished screen.
struct ShimmerBar: View {
    @State private var phase = false

    var body: some View {
        RoundedRectangle(cornerRadius: AppMetrics.controlRadius, style: .continuous)
            .fill(AppTheme.hairline)
            .overlay {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, AppTheme.bgElevated, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.4)
                    .offset(x: phase ? geo.size.width : -geo.size.width * 0.4)
                }
                .clipped()
            }
            .frame(height: 14)
            .onAppear {
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = true
                }
            }
            .accessibilityLabel("Loading")
    }
}

#Preview {
    MotionPreview()
}

private struct MotionPreview: View {
    @State private var saved = 0
    @State private var failed = 0

    var body: some View {
        ScreenScaffold {
            Image(systemName: "checkmark.circle.fill")
                .symbolBounce(trigger: saved)
                .font(.largeTitle)
                .foregroundStyle(AppTheme.accent)
                .pop(on: saved)
            RollingValue(text: "\(saved)")
                .font(.title.weight(.bold))
                .foregroundStyle(AppTheme.textPrimary)
            ProgressArc(fraction: 0.4, label: "40%")
            Text("Check")
                .shake(on: failed)
            Button("Save") { saved += 1 }
            Button("Reject") { failed += 1 }
        }
    }
}
