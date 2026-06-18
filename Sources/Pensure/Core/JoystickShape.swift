import Foundation

/// The hitbox shape used by a SwiftUI joystick.
public enum JoystickShape {
    /// Allows the thumb to move through the full square control area.
    case rect

    /// Limits the thumb to the circular area around the joystick center.
    case circle
}
