import UIKit

/// RadialGradientContainer包含一个RadialGradientLayer。
///它的目的是为基础渐变层的大小设置动画，同时保留有效的蒙版。
///因此，可以在此视图上设置遮罩（不设置其大小的动画），并且渐变可以执行其所需的任何操作
internal class RadialGradientContainer: UIView {
    let gradient = RadialGradientLayer()

    /// 默认初始化器
    init() {
        super.init(frame: .zero)
        layer.addSublayer(gradient)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 基础渐变层的颜色
    var colors: [UIColor] {
        get { gradient.colors }
        set {
            gradient.colors = newValue
            Timing.perform(after: 1) {
                self.backgroundColor = self.gradient.colors.last! // 绘制出超出边界图形时渐变颜色的处理
            }
        }
    }

    /// 在不改变`self`s框架的情况下设置基础渐变的框架
    func setGradientFrame(_ frame: CGRect) {
        gradient.frame = frame
    }

    /// Animate the frame of the underlying gradient without changing `self`s frame.
    func animateGradientFrame(to frame: CGRect, duration: Double) {
        let oldFrame = gradient.frame
        gradient.frame = frame

        let position = CABasicAnimation(keyPath: "position")
        position.duration = duration
        position.fromValue = CGPoint(x: oldFrame.midX, y: oldFrame.midY)
        gradient.add(position, forKey: nil)

        let bounds = CABasicAnimation(keyPath: "bounds")
        bounds.duration = duration
        bounds.fromValue = oldFrame.offsetBy(dx: -oldFrame.minX, dy: -oldFrame.minY)
        gradient.add(bounds, forKey: nil)
    }
}
