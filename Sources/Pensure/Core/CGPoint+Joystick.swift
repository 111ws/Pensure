import SwiftUI

public extension CGPoint {
    internal static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    internal static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    internal static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    internal func distance(to point: CGPoint) -> CGFloat {
        sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }

    func getPointOnCircle(radius: CGFloat, radian: CGFloat) -> CGPoint {
        CGPoint(
            x: x + radius * cos(radian),
            y: y + radius * sin(radian)
        )
    }

    func getRadian(pointOnCircle: CGPoint) -> CGFloat {
        let originX = pointOnCircle.x - x
        let originY = pointOnCircle.y - y
        var radian = atan2(originY, originX)
        while radian < 0 {
            radian += CGFloat(2 * Double.pi)
        }
        return radian
    }

    func getPolarPoint(from origin: CGPoint = .zero) -> PolarPoint {
        let deltaX = x - origin.x
        let deltaY = y - origin.y
        let radians = -atan2(deltaY, deltaX)
        let degrees = radians * (180.0 / CGFloat.pi)
        let distance = self.distance(to: origin)

        guard degrees < 0 else {
            return PolarPoint(degrees: degrees, distance: distance)
        }
        return PolarPoint(degrees: degrees + 360.0, distance: distance)
    }
}
