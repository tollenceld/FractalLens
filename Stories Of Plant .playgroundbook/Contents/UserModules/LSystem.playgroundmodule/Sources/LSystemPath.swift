import CoreGraphics

///包含描述使用绘制规则完整绘制的字符串的路径。
///此类还描述了绘制过程中的局部状态，以允许对路径进行动画处理
public class LSystemPath {
    private let string: String
    private let drawingRules: [String: DrawingRule]

    ///最终路径，将其大小调整为指定的大小
    public private(set) var cgPath: CGPath!
    public private(set) var pathBoundingBox: CGRect!

    ///各个路径元素，每个路径元素对应于字符串中的一个字符
    public private(set) var pathElements: [PathElement]!

    ///说明该路径是仅包含单个（`true`）还是多个（`false`）子路径
    public private(set) var isSinglePath: Bool!

    ///路径组成的绘制线数
    public private(set) var numberOfLines: Int!

    ///默认的初始值设定项。
    ///前提条件：字符串中的所有字母必须具有关联的规则
    public init(string: String, drawingRules: [String: DrawingRule], startDirection: Double, size: CGSize) {
        self.string = string
        self.drawingRules = drawingRules
        createPath(containerSize: size, startDirection: startDirection)
    }

    ///使用self的字符串和绘图规则创建路径
    private func createPath(containerSize: CGSize, startDirection: Double) {
        pathElements = [PathElement]()
        pathElements.reserveCapacity(string.count)

        var path = CGMutablePath()
        path.move(to: .zero)

        isSinglePath = true
        numberOfLines = 0

        var state = DrawingState(position: CGPoint.zero, direction: CGFloat(startDirection) * CGFloat.pi / 180.0)
        var stack = [DrawingState]()

        for character in string {
            let rule = drawingRules[String(character)] ?? .ignore
            let oldState = state

            switch rule {
            case .draw:
                let nextPosition = state.position.move(in: state.direction, by: 1)
                path.addLine(to: nextPosition)
                numberOfLines += 1
                state = DrawingState(position: nextPosition, direction: state.direction)

            case .move:
                let nextPosition = state.position.move(in: state.direction, by: 1)
                path.move(to: nextPosition)
                isSinglePath = false
                state = DrawingState(position: nextPosition, direction: state.direction)

            case .ignore:
                ()

            case .turnLeft(angle: let angle):
                state = DrawingState(position: state.position, direction: state.direction + CGFloat(angle) * CGFloat.pi / 180.0)

            case .turnRight(angle: let angle):
                state = DrawingState(position: state.position, direction: state.direction - CGFloat(angle) * CGFloat.pi / 180.0)

            case .saveState:
                stack.append(state)

            case .restoreState:
                isSinglePath = false
                state = stack.removeLast()
                path.move(to: state.position)
            }

            pathElements.append(PathElement(fromState: oldState, toState: state, rule: rule))
        }

        ///转换路径以适合容器
        let container = CGRect(origin: .zero, size: containerSize).insetBy(dx: 10, dy: 10)
        var pathRect = path.boundingBoxOfPath.insetBy(dx: -0.001, dy: -0.001) // Bugfix for empty paths

        var transform = CGAffineTransform(translationX: -pathRect.minX, y: -pathRect.minY)
        let scale = min(container.width / pathRect.width, container.height / pathRect.height)
        transform = transform.concatenating(CGAffineTransform(scaleX: scale, y: scale))
        pathRect = pathRect.applying(transform)
        transform = transform.concatenating(CGAffineTransform(translationX: container.midX - pathRect.width * 0.5, y: container.midY - pathRect.height * 0.5))

        path = path.mutableCopy(using: &transform) ?? CGMutablePath()

        for i in 0 ..< pathElements.count {
            pathElements[i].fromState.position = pathElements[i].fromState.position.applying(transform)
            pathElements[i].toState.position = pathElements[i].toState.position.applying(transform)
        }

        ///设置pathStrokeFrom和pathStrokeEnd
        var current: CGFloat = 0
        for i in 0 ..< pathElements.count {
            pathElements[i].pathStrokeFrom = current / CGFloat(numberOfLines)
            if case .draw = pathElements[i].rule { current += 1 }
            pathElements[i].pathStrokeEnd = current / CGFloat(numberOfLines)
        }

        self.cgPath = path
        self.pathBoundingBox = path.boundingBoxOfPath
    }
}

///路径的单个元素，仅与一个字符相关联
public struct PathElement {
    public fileprivate(set) var fromState: DrawingState
    public fileprivate(set) var toState: DrawingState
    public let rule: DrawingRule

    ///使该path元素动画化意味着绘制从`pathStrokeFrom`到`pathStrokeTo`的完整路径
    public fileprivate(set) var pathStrokeFrom: CGFloat!
    public fileprivate(set) var pathStrokeEnd: CGFloat!
}

///绘制路径元素之前/之后的状态
public struct DrawingState {
    public fileprivate(set) var position: CGPoint
    public fileprivate(set) var direction: CGFloat // 0 means right, going counterclockwise until 360
}

// MARK: CoreGraphics扩展

public extension CGPoint {
    ///在给定方向上移动“长度”单位。
    ///因此，0表示向右，逆时针旋转直到2pi
    func move(in direction: CGFloat, by length: CGFloat) -> CGPoint {
        let dx = cos(direction) * length
        let dy = -sin(direction) * length
        return CGPoint(x: x + dx, y: y + dy)
    }
}

private extension CGRect {
    ///找到将“ self”转换为“ destination”的转换
    func transform(to destination: CGRect) -> CGAffineTransform {
        CGAffineTransform.identity
            .translatedBy(x: destination.midX - self.midX, y: destination.midY - self.midY)
            .scaledBy(x: destination.width / self.width, y: destination.height / self.height)
    }
}
