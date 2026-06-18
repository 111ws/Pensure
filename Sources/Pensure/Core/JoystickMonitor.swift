import SwiftUI

/// Shared observable output for joystick movement.
public final class JoystickMonitor: ObservableObject {
    /// Relative thumb position from the joystick center.
    @Published public var xyPoint: CGPoint = .zero

    /// Relative thumb position expressed as angle and distance.
    @Published public var polarPoint: PolarPoint = .zero

    public init() {}

    public func reset() {
        xyPoint = .zero
        polarPoint = .zero
    }
}
