import SwiftUI
import UIKit

/// Visual floating joystick shown at the active finger touch location.
public struct FloatingJoystickView: View {
    @ObservedObject private var visibilityManager = FloatingJoystickVisibility.shared
    @ObservedObject public var joystickMonitor: JoystickMonitor

    @Environment(\.colorScheme) private var colorScheme

    private let dragDiameter: CGFloat
    private let shape: JoystickShape

    private var dynamicColor: Color {
        colorScheme == .light ? .white : .white
    }

    public init(monitor: JoystickMonitor, width: CGFloat, shape: JoystickShape = .circle) {
        self.joystickMonitor = monitor
        self.dragDiameter = width
        self.shape = shape
    }

    public var body: some View {
        JoystickBuilder(
            monitor: joystickMonitor,
            width: dragDiameter,
            shape: shape,
            background: {
                Circle()
                    .stroke(dynamicColor, lineWidth: 3)
            },
            foreground: {
                Circle()
                    .fill(dynamicColor)
                    .scaleEffect(1.5)
            },
            locksInPlace: false
        )
        .position(visibilityManager.joystickPosition)
        .opacity(visibilityManager.isVisible ? 1.0 : 0.0)
    }
}

internal struct JoystickTouchCaptureView: UIViewRepresentable {
    var joystickMonitor: JoystickMonitor
    var dragDiameter: CGFloat
    var style: PensureStyle

    func makeUIView(context: Context) -> TouchCaptureUIView {
        let view = TouchCaptureUIView(frame: .zero)
        view.joystickMonitor = joystickMonitor
        view.dragDiameter = dragDiameter
        view.style = style
        return view
    }

    func updateUIView(_ uiView: TouchCaptureUIView, context: Context) {
        uiView.joystickMonitor = joystickMonitor
        uiView.dragDiameter = dragDiameter
        uiView.style = style
    }

    final class TouchCaptureUIView: UIView {
        var joystickMonitor: JoystickMonitor?
        var dragDiameter: CGFloat = 0
        var style: PensureStyle = .automaticCircle

        private var joystickBasePosition: CGPoint = .zero

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)

            if touch.type == .direct, style.supportsFloatingJoystick {
                joystickBasePosition = touchLocation
                FloatingJoystickVisibility.shared.joystickPosition = touchLocation
                FloatingJoystickVisibility.shared.isVisible = true
            } else if touch.type == .stylus, style.supportsPencilJoystick {
                PencilJoystickOverlayState.shared.position = touchLocation
                PencilJoystickOverlayState.shared.isVisible = true
                PencilJoystickOverlayState.shared.canvasView?.touchesBegan(touches, with: event)
            }
        }

        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesMoved(touches, with: event)
            guard let touch = touches.first else { return }

            if touch.type == .stylus, style.supportsPencilJoystick {
                PencilJoystickOverlayState.shared.canvasView?.touchesMoved(touches, with: event)
                return
            }

            guard touch.type == .direct, style.supportsFloatingJoystick else { return }
            guard FloatingJoystickVisibility.shared.isVisible else { return }

            let currentTouchLocation = touch.location(in: self)
            let radius = dragDiameter / 2
            var knobPosition = currentTouchLocation - joystickBasePosition
            let distance = joystickBasePosition.distance(to: currentTouchLocation)

            if distance > radius {
                let k = radius / max(distance, 0.0001)
                knobPosition = knobPosition * k
            }

            joystickMonitor?.xyPoint = knobPosition
            joystickMonitor?.polarPoint = knobPosition.getPolarPoint()
        }

        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            endTouches(touches, event: event)
        }

        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            endTouches(touches, event: event)
        }

        private func endTouches(_ touches: Set<UITouch>, event: UIEvent?) {
            guard let touch = touches.first else { return }

            if touch.type == .direct {
                FloatingJoystickVisibility.shared.isVisible = false
                joystickMonitor?.reset()
            } else if touch.type == .stylus, style.supportsPencilJoystick {
                if event == nil {
                    PencilJoystickOverlayState.shared.canvasView?.touchesCancelled(touches, with: event)
                } else {
                    PencilJoystickOverlayState.shared.canvasView?.touchesEnded(touches, with: event)
                }
                PencilJoystickOverlayState.shared.isVisible = false
            }
        }
    }
}
