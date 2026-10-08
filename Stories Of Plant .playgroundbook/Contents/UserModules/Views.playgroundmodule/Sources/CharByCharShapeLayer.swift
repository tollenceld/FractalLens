import LSystem
import UIKit

/// CharByCharShapeLayer是CharByCharDrawingView的一部分，它为L系统路径绘制动画。
///这包括设置动画箭头，该箭头始终显示当前位置和方向
internal class CharByCharShapeLayer: UIView {
    var lpath: LSystemPath! {
        didSet {
            pathWasUpdated()
        }
    }

    var animationIndex = 0
    var isAnimating = false

    ///绘制完整路径的图层。 它充当渐变层的蒙版
    private let shapeLayer = CAShapeLayer()
    private let gradient = RadialGradientContainer()

    ///包含显示当前位置和方向的箭头的图层
    private let arrow = CAShapeLayer()

    /// 处理缓存
    init(gradient gradientColors: GradientColors) {
        super.init(frame: .zero)

        // 渐变层
        addSubview(gradient)
        gradient.colors = gradientColors.colors

        // 形状层
        gradient.layer.mask = shapeLayer
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.fillColor = .none
        shapeLayer.lineCap = .round
        shapeLayer.lineWidth = 3
        shapeLayer.strokeEnd = 0

        // 方向层
        layer.addSublayer(arrow)
        arrow.anchorPoint = .zero
        arrow.strokeColor = UIColor.gray.cgColor
        arrow.path = arrowPath
        arrow.fillColor = .none
        arrow.lineCap = .round
        arrow.lineWidth = 3
        arrow.lineDashPattern = [4, 4]
        arrow.opacity = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    ///创建箭头的路径，指向右边
    private var arrowPath: CGPath {
        let length: CGFloat = 40
        let radius: CGFloat = 10

        let arrowhead = CGPoint.zero.move(in: 0, by: length)
        let left: CGPoint = arrowhead.move(in: -CGFloat.pi * 1.25, by: 0.5 * length)
        let right: CGPoint = arrowhead.move(in: CGFloat.pi * 1.25, by: 0.5 * length)

        let path = CGMutablePath()
        path.addEllipse(in: CGRect.zero.insetBy(dx: -radius, dy: -radius))
        path.move(to: .zero)
        path.addLine(to: arrowhead)
        path.addLine(to: left)
        path.move(to: arrowhead)
        path.addLine(to: right)

        return path
    }

    //设置路径后，将箭头移动到正确的位置
    func pathWasUpdated() {
        shapeLayer.path = lpath.cgPath
        gradient.setGradientFrame(lpath.pathBoundingBox.insetBy(dx: -3, dy: -3))
    }

    ///根据当前动画索引更新箭头位置
    func updateArrowPosition() {
        guard let lpath = lpath, animationIndex < lpath.pathElements.count else { return }

        let element: PathElement = lpath.pathElements[animationIndex]
        let state: DrawingState = isAnimating ? element.toState : element.fromState

        let transform = CGAffineTransform(translationX: state.position.x, y: state.position.y).rotated(by: -state.direction)
        arrow.transform = CATransform3DMakeAffineTransform(transform)
        arrow.position = .zero
    }

    ///更新布局
    override func layoutSubviews() {
        gradient.frame = bounds
        shapeLayer.frame = bounds
        arrow.frame = bounds

        updateArrowPosition()
    }

    ///动态运动到下一个字符。
    ///仅在动画尚未完成时调用
    func animateNext(duration: Double) {
        let element = lpath.pathElements[animationIndex]

        //动画self.strokeEnd和arrow.transform
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .linear))

        shapeLayer.strokeEnd = element.pathStrokeEnd
        updateArrowPosition()

        CATransaction.commit()
        animationIndex += 1
    }

    ///在动画开始之前立即进行初步设置
    func beginAnimation() {
        arrow.opacity = 1
        isAnimating = true
    }

    /// 在动画完成之后清空缓存
    func finishAnimating() {
        arrow.opacity = 0
        isAnimating = false
    }

    /// 重置为开始状态
    func reset() {
        animationIndex = 0
        updateArrowPosition()

        //状态结束
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.duration = 1
        anim.fromValue = shapeLayer.strokeEnd
        anim.toValue = 0
        shapeLayer.strokeEnd = 0
        shapeLayer.add(anim, forKey: nil)
    }
}
