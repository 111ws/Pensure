import SwiftUI

/// A ViewModifier that makes a SwiftUI view behave like a joystick surface.
public struct JoystickGestureRecognizer: ViewModifier {
    @ObservedObject public var joystickMonitor: JoystickMonitor

    private var width: CGFloat
    private var shapeType: JoystickShape
    private let midPoint: CGPoint
    private let locksInPlace: Bool

    @Binding private(set) public var thumbPosition: CGPoint

    public init(
        thumbPosition: Binding<CGPoint>,
        monitor: JoystickMonitor,
        width: CGFloat,
        type: JoystickShape,
        locksInPlace locks: Bool
    ) {
        self.joystickMonitor = monitor
        self._thumbPosition = thumbPosition
        self.width = width
        self.midPoint = CGPoint(x: width / 2, y: width / 2)
        self.shapeType = type
        self.locksInPlace = locks
    }

    public func body(content: Content) -> some View {
        switch shapeType {
        case .rect:
            rectBody(content)
        case .circle:
            circleBody(content)
        }
    }

    internal func getValidThumbCoordinate(for value: inout CGFloat) {
        if value <= 0 {
            value = 0
        } else if value > width {
            value = width
        }
    }

    internal func validateCoordinate(_ emitPoint: inout CGPoint) {
        emitPoint = emitPoint * 2
        emitPoint.x = min(max(emitPoint.x, -width), width)
        emitPoint.y = min(max(emitPoint.y, -width), width)
    }

    internal func emitPosition(for xyPoint: CGPoint) {
        var emitPoint = xyPoint
        validateCoordinate(&emitPoint)
        joystickMonitor.xyPoint = emitPoint
        joystickMonitor.polarPoint = emitPoint.getPolarPoint(from: midPoint)
    }

    public func rectBody(_ content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        var thumbX = value.location.x
                        var thumbY = value.location.y
                        getValidThumbCoordinate(for: &thumbX)
                        getValidThumbCoordinate(for: &thumbY)
                        thumbPosition = CGPoint(x: thumbX, y: thumbY)
                        emitPosition(for: value.location - midPoint)
                    }
                    .onEnded { _ in
                        guard !locksInPlace else { return }
                        thumbPosition = midPoint
                        emitPosition(for: .zero)
                    }
                    .exclusively(
                        before: LongPressGesture(minimumDuration: 0.0, maximumDistance: 0.0)
                            .onEnded { _ in
                                guard !locksInPlace else { return }
                                thumbPosition = midPoint
                                emitPosition(for: .zero)
                            }
                    )
            )
    }

    public func circleBody(_ content: Content) -> some View {
        content
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let distance = midPoint.distance(to: value.location)
                        if distance > width / 2 {
                            let k = (width / 2) / distance
                            let position = (value.location - midPoint) * k
                            thumbPosition = position + midPoint
                            emitPosition(for: position)
                        } else {
                            thumbPosition = value.location
                            emitPosition(for: value.location - midPoint)
                        }
                    }
                    .onEnded { _ in
                        guard !locksInPlace else { return }
                        thumbPosition = midPoint
                        emitPosition(for: .zero)
                    }
                    .exclusively(
                        before: LongPressGesture(minimumDuration: 0.0, maximumDistance: 0.0)
                            .onEnded { _ in
                                guard !locksInPlace else { return }
                                thumbPosition = midPoint
                                emitPosition(for: .zero)
                            }
                    )
            )
    }
}
