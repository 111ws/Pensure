import SwiftUI

public extension View {
    /// Adds a joystick recognizer to any SwiftUI view.
    func joystickGestureRecognizer(
        thumbPosition: Binding<CGPoint>,
        monitor: JoystickMonitor,
        width: CGFloat,
        shape: JoystickShape,
        locksInPlace locks: Bool = false
    ) -> some View {
        modifier(
            JoystickGestureRecognizer(
                thumbPosition: thumbPosition,
                monitor: monitor,
                width: width,
                type: shape,
                locksInPlace: locks
            )
        )
    }
}
