import Foundation

/// High-level styles exposed by the package.
public enum PensureStyle: Equatable {
    /// Finger-controlled floating joystick with a circular hitbox.
    case floatingCircle

    /// Finger-controlled floating joystick with a rectangular hitbox.
    case floatingRect

    /// Apple Pencil vertical pressure/angle joystick.
    case pencilVertical

    /// Finger uses floating circle, Apple Pencil uses vertical pressure/angle joystick.
    case automaticCircle

    /// Finger uses floating rect, Apple Pencil uses vertical pressure/angle joystick.
    case automaticRect

    public var supportsFloatingJoystick: Bool {
        switch self {
        case .floatingCircle, .floatingRect, .automaticCircle, .automaticRect:
            return true
        case .pencilVertical:
            return false
        }
    }

    public var supportsPencilJoystick: Bool {
        switch self {
        case .pencilVertical, .automaticCircle, .automaticRect:
            return true
        case .floatingCircle, .floatingRect:
            return false
        }
    }

    public var floatingShape: JoystickShape {
        switch self {
        case .floatingRect, .automaticRect:
            return .rect
        case .floatingCircle, .automaticCircle, .pencilVertical:
            return .circle
        }
    }
}
