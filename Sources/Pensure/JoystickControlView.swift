import SwiftUI

/// Single entry point for choosing either joystick style.
public struct JoystickControlView: View {
    @ObservedObject public var joystickMonitor: JoystickMonitor
    @ObservedObject public var pencilState: PencilJoystickState
    @ObservedObject private var pencilOverlayState = PencilJoystickOverlayState.shared

    private let style: PensureStyle
    private let width: CGFloat
    private let showsPencilReadout: Bool
    private let pencilConfiguration: PencilJoystickConfiguration

    public init(
        style: PensureStyle,
        monitor: JoystickMonitor = JoystickMonitor(),
        pencilState: PencilJoystickState = PencilJoystickState(),
        width: CGFloat = 120,
        showsPencilReadout: Bool = true,
        pencilConfiguration: PencilJoystickConfiguration = .init()
    ) {
        self.style = style
        self.joystickMonitor = monitor
        self.pencilState = pencilState
        self.width = width
        self.showsPencilReadout = showsPencilReadout
        self.pencilConfiguration = pencilConfiguration
    }

    public var body: some View {
        ZStack {
            if style.supportsFloatingJoystick || style.supportsPencilJoystick {
                JoystickTouchCaptureView(
                    joystickMonitor: joystickMonitor,
                    dragDiameter: width,
                    style: style
                )
                .allowsHitTesting(true)
                .zIndex(0)
            }

            if style.supportsFloatingJoystick {
                FloatingJoystickView(
                    monitor: joystickMonitor,
                    width: width,
                    shape: style.floatingShape
                )
                .zIndex(1)
            }

            if style == .pencilVertical {
                PencilVerticalJoystickView(
                    state: pencilState,
                    showsReadout: showsPencilReadout,
                    configuration: pencilConfiguration
                )
                .zIndex(2)
            } else if style.supportsPencilJoystick, pencilOverlayState.isVisible {
                PencilVerticalJoystickView(
                    state: pencilState,
                    showsReadout: showsPencilReadout,
                    configuration: pencilConfiguration
                )
                .position(
                    x: pencilOverlayState.position.x,
                    y: pencilOverlayState.position.y - 80
                )
                .zIndex(2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    public func getPencilAngleRadians() -> CGFloat {
        pencilState.angleRadians
    }

    public func getPencilAngleDegrees() -> CGFloat {
        pencilState.angleDegrees
    }
}
