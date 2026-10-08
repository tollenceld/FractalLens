import LSystem
import UIKit

///`EvolutionShapeLayer`在不同的LSystemPaths之间设置动画。
///因此，如果可能的话，动画是通过对路径进行动画处理来完成的。 否则，它在路径之间消失
internal class EvolutionShapeLayer: UIView {
    /// The layer drawing the full path. It acts as a mask for a gradient layer.
    private var shapeLayer: CAShapeLayer!
    private let gradient = RadialGradientContainer()

    /// 包含shapeLayer的容器层。 这是淡入淡出动画所必需的
    private let maskContainer = CALayer()

    private var currentPath: LSystemPath!
    var generation = 0

    private let lineWidthRange: Range<CGFloat>
    private let animationDuration: Double
    private let transitionDuration: Double

    /// 默认状态
    init(gradientColors: [UIColor], lineWidthRange: Range<CGFloat> = 2 ..< 3.5, animationDuration: Double, transitionDuration: Double) {
        self.lineWidthRange = lineWidthRange
        self.animationDuration = animationDuration
        self.transitionDuration = transitionDuration

        super.init(frame: .zero)
        shapeLayer = createShapeLayer(generation: 0)

        // 渐变层
        addSubview(gradient)
        gradient.colors = gradientColors
        gradient.layer.mask = maskContainer
        maskContainer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///创建一个可用作渐变图层蒙版的形状图层
    func createShapeLayer(with path: CGPath? = nil, generation: Int) -> CAShapeLayer {
        shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.fillColor = .none
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = lineWidth(for: generation)
        shapeLayer.path = path
        return shapeLayer
    }

    func lineWidth(for generation: Int) -> CGFloat {
        let maxWidth = lineWidthRange.upperBound
        let diffPerGen = (lineWidthRange.upperBound - lineWidthRange.lowerBound) / 5
        return maxWidth - diffPerGen * CGFloat(max(0, min(5, generation - 1)))
    }

    /// 结束状态
    override func layoutSubviews() {
        gradient.frame = bounds
        gradient.setGradientFrame(currentPath?.pathBoundingBox?.insetBy(dx: -3, dy: -3) ?? bounds)
        maskContainer.frame = bounds
        shapeLayer.frame = bounds
    }

    /// 设置路径或为其设置动画
    func set(path: LSystemPath, animated: Bool) {
        defer { currentPath = path }

        guard animated else {
            shapeLayer.path = path.cgPath
            gradient.setGradientFrame(path.pathBoundingBox.insetBy(dx: -3, dy: -3))
            return
        }

        //确定是否可以通过对shapeLayer.path设置动画来完成动画。 否则，请混合过渡。
        //只有通过替换* drawing *线段而出现的路径才可以设置动画。
        let isMultiple = path.numberOfLines.isMultiple(of: currentPath.numberOfLines) || currentPath.numberOfLines.isMultiple(of: path.numberOfLines)
        let canAnimatePathDirectly = isMultiple && path.isSinglePath && currentPath.isSinglePath

        self.generation += 1
        if canAnimatePathDirectly {
            animatePathDirectly(to: path)
        } else {
            animatePathViaTransition(to: path)
        }
    }

    /// 通过对shapeLayer.path进行动画处理来执行路径动画
    private func animatePathDirectly(to path: LSystemPath) {
        shapeLayer.path = path.cgPath
        shapeLayer.lineWidth = lineWidth(for: generation)

        var fromPath = currentPath.cgPath!
        var toPath = path.cgPath!
        if path.numberOfLines > currentPath.numberOfLines {
            let factor = path.numberOfLines / max(1, currentPath.numberOfLines)
            fromPath = fromPath.splitAllLines(into: factor)
        } else {
            let factor = currentPath.numberOfLines / max(1, path.numberOfLines)
            toPath = toPath.splitAllLines(into: factor)
        }

        let anim = CABasicAnimation(keyPath: "path")
        anim.fromValue = fromPath
        anim.toValue = toPath
        anim.duration = animationDuration
        shapeLayer.add(anim, forKey: nil)

        let width = CABasicAnimation(keyPath: "lineWidth")
        width.fromValue = lineWidth(for: generation - 1)
        width.toValue = lineWidth(for: generation)
        width.duration = animationDuration
        shapeLayer.add(width, forKey: nil)

        gradient.animateGradientFrame(to: path.pathBoundingBox.insetBy(dx: -3, dy: -3), duration: animationDuration)
    }

    /// 通过使用过渡淡入另一个路径来执行路径动画
    private func animatePathViaTransition(to path: LSystemPath) {
        let old = shapeLayer!

        let new = createShapeLayer(with: path.cgPath, generation: generation)
        maskContainer.addSublayer(new)
        shapeLayer = new

        // 通过CABasicAnimation淡入new
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = transitionDuration
        new.add(anim, forKey: nil)

        // 淡出并通过CATransaction删除old
        CATransaction.begin()
        CATransaction.setAnimationDuration(transitionDuration)
        CATransaction.setCompletionBlock {
            old.removeFromSuperlayer()
        }
        old.opacity = 0
        CATransaction.commit()

        gradient.animateGradientFrame(to: path.pathBoundingBox.insetBy(dx: -3, dy: -3), duration: transitionDuration)
    }
}

// MARK: CGPath + SplitAllLines

private extension CGPath {
    ///通过将所有行拆分为较小的行，从此路径创建CGPath。 路径看起来相同，但是新路径具有更多的点，这对于设置动画很有用。
    ///路径应仅由“ moveToPoint”和“ addLineToPoint”元素组成，因为其他元素将被忽略并从结果路径中删除。
    func splitAllLines(into count: Int) -> CGPath {
        let result = CGMutablePath()

        var current = CGPoint.zero
        result.move(to: .zero)

        applyWithBlock { p in
            let element = p.pointee

            switch element.type {
            case .moveToPoint:
                current = element.points[0]
                result.move(to: current)

            case .addLineToPoint:
                let from = current
                current = element.points[0]

                for i in 1 ... count {
                    let point = interpolate(between: from, and: current, p: CGFloat(i) / CGFloat(count))
                    result.addLine(to: point)
                }

            default:
                ()
            }
        }

        return result
    }

    ///在两个CGPoint之间的直线内插。
    ///“ p = 0”产生第一个点，而“ p = 1”产生第二个点。
    private func interpolate(between first: CGPoint, and second: CGPoint, p: CGFloat) -> CGPoint {
        return CGPoint(
            x: first.x * (1-p) + second.x * p,
            y: first.y * (1-p) + second.y * p
        )
    }
}
