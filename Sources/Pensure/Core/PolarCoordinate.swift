import SwiftUI

public protocol PolarCoordinate {
    /// Direction in degrees.
    var degrees: CGFloat { get set }

    /// Distance from the center/origin.
    var distance: CGFloat { get set }
}

public struct PolarPoint: PolarCoordinate, Equatable, Sendable, Sendable {
    public var degrees: CGFloat
    public var distance: CGFloat

    public static let  zero = PolarPoint(degrees: 0, distance: 0)

    public init(degrees: CGFloat, distance: CGFloat) {
        self.degrees = degrees
        self.distance = distance
    }
}
