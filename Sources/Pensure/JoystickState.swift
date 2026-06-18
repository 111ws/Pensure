import SwiftUI

/// Observable state for the Apple Pencil vertical joystick.
public final class PencilJoystickState: ObservableObject {
    @Published public var pressure: CGFloat
    @Published public var angleDegrees: CGFloat
    @Published public var knobColor: UIColor

    public var angleRadians: CGFloat {
        angleDegrees * .pi / 180
    }

    public init(
        pressure: CGFloat = 0,
        angleDegrees: CGFloat = 0,
        knobColor: UIColor = .white
    ) {
        self.pressure = pressure
        self.angleDegrees = angleDegrees
        self.knobColor = knobColor
    }
}

internal final class FloatingJoystickVisibility: ObservableObject {
    @MainActor static let shared = FloatingJoystickVisibility()

    @Published var isVisible = false
    @Published var joystickPosition: CGPoint = .zero

    private init() {}
}

internal final class PencilJoystickOverlayState: ObservableObject {
    @MainActor static let shared = PencilJoystickOverlayState()

    @Published var isVisible = false
    @Published var position: CGPoint = .zero

    weak var canvasView: PencilJoystickCanvasView?

    private init() {}
}
