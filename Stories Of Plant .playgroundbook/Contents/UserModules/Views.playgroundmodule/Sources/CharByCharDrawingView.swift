import LSystem
import UIKit

///一个视图绘制一个字符串和相关的`DrawingRules`，一个字符一个字符地显示每个应用的`DrawingRule`的视图。
///它由一个用于绘制路径的CharByCharShapeLayer和一个用于显示当前进度的CharByCharStringView组成
public class CharByCharDrawingView: UIView {
    private let string: String
    private let drawingRules: [String: DrawingRule]
    private let startDirection: Double

    ///包含字符串的视图
    private let stringView: CharByCharStringView

    ///设置路径动画的图层
    private let shapeLayer: CharByCharShapeLayer
    private var lpath: LSystemPath!

    ///动画结束后显示的“重播”按钮
    private let replayButton = UIButton(type: .system)

    private var animationIndex = 0
    private var isAnimating = false

    /// 默认初始化器
    public init(string: String, drawingRules: [String: DrawingRule], gradient: GradientColors, startDirection: Double = 0) {
        self.string = string
        self.drawingRules = drawingRules
        self.startDirection = startDirection

        shapeLayer = CharByCharShapeLayer(gradient: gradient)
        stringView = CharByCharStringView(string: string)

        super.init(frame: .zero)
        backgroundColor = .black///系统介绍页面的背景颜色

        addSubview(stringView)
        addSubview(shapeLayer)

        // 重播按钮
        replayButton.frame = CGRect(x: 0, y: 0, width: 120, height: 50)
        replayButton.tintColor = .gray // Outermost color
        replayButton.titleEdgeInsets.left = 20
        replayButton.setTitle("replay", for: .normal)
        replayButton.setImage(UIImage(systemName: "gobackward"), for: .normal)
        replayButton.alpha = 0
        replayButton.addTarget(self, action: #selector(replay), for: .touchUpInside)
        addSubview(replayButton)

        Timing.perform(after: 0.5, identification: .object(self), block: beginAnimation)
    }

    public required init(coder: NSCoder) {
        fatalError("Not implemented!")
    }

    public override func layoutSubviews() {
        if bounds.isEmpty { return }

        updateFrames()

        //创建新的路径对象（因为它取决于图层大小）
        lpath = LSystemPath(string: string, drawingRules: drawingRules, startDirection: startDirection, size: shapeLayer.bounds.size)
        shapeLayer.lpath = lpath

        //重新安排动画的开始
        if !isAnimating {
            Timing.cancelTasks(withObject: self)
            Timing.perform(after: 0.5, identification: .object(self), block: beginAnimation)
        }
    }

    func updateFrames() {
        //由于playground的傻逼属性，在底部保留80px的空间
        stringView.frame = CGRect(x: 0, y: bounds.height - 120, width: bounds.width, height: 70)
        shapeLayer.frame = CGRect(x: 40, y: 90, width: bounds.width - 80, height: stringView.frame.minY - 120)

        // 重播按钮
        replayButton.frame.origin = CGPoint(x: bounds.width - 120, y: 0)
    }

    /// 开始播放的值
    private func beginAnimation() {
        isAnimating = true

        shapeLayer.beginAnimation()
        stringView.beginAnimation()

        let totalDuration = min(12, 1.2 * Double(lpath.pathElements.count))
        let elementDuration = totalDuration / Double(lpath.pathElements.count)
        Timing.perform(after: 0.5 * elementDuration) {
            self.animateCurrentCharacter(duration: 0.6 * elementDuration, delay: 0.4 * elementDuration)
        }
    }

    /// 在当前动画索引处对角色进行动画处理
    private func animateCurrentCharacter(duration: Double, delay: Double) {
        guard animationIndex < lpath.pathElements.count else {
            return animationFinished()
        }

        shapeLayer.animateNext(duration: duration)
        stringView.animateNext(duration: 0.9 * duration)

        // 安排下一个动画
        Timing.perform(after: duration + delay) {
            self.animationIndex += 1
            self.animateCurrentCharacter(duration: duration, delay: delay)
        }
    }

    /// 动画完成后，关闭当前的playground
    private func animationFinished() {
        isAnimating = false
        shapeLayer.finishAnimating()
        stringView.finishAnimating()

        Timing.perform(after: 0.5) {
            UIView.animate(withDuration: 0.4) {
                self.replayButton.alpha = 1
            }
        }
    }

    /// 重置状态并重播动画
    @objc private func replay() {
        UIView.animate(withDuration: 0.2) {
            self.replayButton.alpha = 0
        }

        animationIndex = 0
        shapeLayer.reset()
        stringView.reset()

        // 把动画给安排上
        Timing.perform(after: 2, block: beginAnimation)
    }
}
