import SwiftUI

/// A reusable SwiftUI joystick with caller-provided background and thumb views.
public struct JoystickBuilder<Background: View, Foreground: View>: View {
    private(set) public var width: CGFloat
    private(set) public var controlShape: JoystickShape

    @ObservedObject private(set) public var joystickMonitor: JoystickMonitor
    @State private(set) public var thumbPosition: CGPoint = .zero

    @ViewBuilder public var controlBackground: () -> Background
    @ViewBuilder public var controlThumb: () -> Foreground

    private let locksInPlace: Bool

    public init(
        monitor: JoystickMonitor,
        width: CGFloat,
        shape: JoystickShape,
        @ViewBuilder background: @escaping () -> Background,
        @ViewBuilder foreground: @escaping () -> Foreground,
        locksInPlace locks: Bool
    ) {
        self.joystickMonitor = monitor
        self.width = width
        self.controlShape = shape
        self.controlBackground = background
        self.controlThumb = foreground
        self.locksInPlace = locks
    }

    public var body: some View {
        controlBackground()
            .frame(width: width, height: width)
            .joystickGestureRecognizer(
                thumbPosition: $thumbPosition,
                monitor: joystickMonitor,
                width: width,
                shape: controlShape,
                locksInPlace: locksInPlace
            )
            .overlay(
                controlThumb()
                    .frame(width: width / 4, height: width / 4)
                    .position(x: thumbPosition.x, y: thumbPosition.y)
                    .joystickGestureRecognizer(
                        thumbPosition: $thumbPosition,
                        monitor: joystickMonitor,
                        width: width,
                        shape: controlShape,
                        locksInPlace: locksInPlace
                    )
            )
            .onAppear {
                let midPoint = width / 2
                thumbPosition = CGPoint(x: midPoint, y: midPoint)
            }
            .onReceive(joystickMonitor.$xyPoint) { newXY in
                let midPoint = width / 2
                thumbPosition = CGPoint(x: newXY.x + midPoint, y: newXY.y + midPoint)
            }
    }
}
