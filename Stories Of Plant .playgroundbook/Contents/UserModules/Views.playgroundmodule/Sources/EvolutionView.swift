import LSystem
import UIKit

///绘制完整的`LSystem`并在重复应用生产规则时动画化演变的视图
public class EvolutionView: UIView {
    /// 系统本身及其图形描述
    private let system: LSystem
    private let drawing: LSystemEvolutionDrawingDescription

    private var currentGeneration: Int
    private var currentString: String

    private var isAnimating = false

    ///支持的最大世代数。
    ///这种限制显然是由于性能原因，因为L系统的指数（空间）变得越来越复杂
    private let maxGeneration: Int

    /// 显示和动画化路径的视图
    private let shapeLayer: EvolutionShapeLayer

    /// 动画完成后显示的“重播”按钮
    private let replayButton = UIButton(type: .system)

    /// 默认状态
    public init(drawing: LSystemEvolutionDrawingDescription) {
        self.system = drawing.system
        self.drawing = drawing

        maxGeneration = drawing.maxGeneration
        currentGeneration = drawing.startGeneration
        currentString = system.apply(count: currentGeneration, to: system.startString)

        shapeLayer = EvolutionShapeLayer(gradientColors: drawing.gradient.colors, lineWidthRange: drawing.lineWidthRange, animationDuration: 0.5, transitionDuration: 0.2)

        super.init(frame: .zero)
        addSubview(shapeLayer)
        backgroundColor = .black///自己的规则关卡背景颜色

        // 重播按钮
        replayButton.frame = CGRect(x: 0, y: 0, width: 120, height: 50)
        replayButton.tintColor = drawing.gradient.colors.last! // Outermost color
        replayButton.titleEdgeInsets.left = 20
        replayButton.setTitle("replay", for: .normal)
        replayButton.setImage(UIImage(systemName: "gobackward"), for: .normal)
        replayButton.alpha = 0
        replayButton.addTarget(self, action: #selector(replay), for: .touchUpInside)
        addSubview(replayButton)

        // 规划中的动画的时间r-=从v 
        Timing.perform(after: 1, identification: .object(self), block: beginAnimation)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 更新布局
    public override func layoutSubviews() {
        if bounds.isEmpty { return }

        // 大小更改时创建新的CGPath
        shapeLayer.frame = bounds.insetBy(dx: 15, dy: 15)
        updatePath(animated: false)

        // 重播按钮
        replayButton.frame.origin = CGPoint(x: bounds.width - 120, y: 0)

        // 重新安排动画的开始
        if !isAnimating {
            Timing.cancelTasks(withObject: self)
            Timing.perform(after: 1, identification: .object(self), block: beginAnimation)
        }
    }

    /// 开始动画
    private func beginAnimation() {
        isAnimating = true
        evolveAndAnimate()
    }

    /// 制定并计划下一步的发展步骤
    private func evolveAndAnimate() {
        guard currentGeneration < maxGeneration else {
            return animationFinished()
        }

        evolve()
        Timing.perform(after: 1) {
            self.evolveAndAnimate()
        }
    }

    /// 动画结束时调用
    private func animationFinished() {
        Timing.perform(after: 0.5) {
            UIView.animate(withDuration: 0.4) {
                self.replayButton.alpha = 1
            }
        }
    }

    /// 进化一代
    private func evolve() {
        guard currentGeneration < maxGeneration else { return }

        currentGeneration += 1
        currentString = system.apply(to: currentString)
        updatePath(animated: true)
    }

    /// 重置状态并重播动画
    @objc private func replay() {
        UIView.animate(withDuration: 0.2) {
            self.replayButton.alpha = 0
        }

        // 重置属性
        currentGeneration = drawing.startGeneration
        currentString = system.apply(count: currentGeneration, to: system.startString)

        // 重置数值
        shapeLayer.generation = -1
        updatePath(animated: true)

        // 安排动画
        Timing.perform(after: 1, block: beginAnimation)
    }

    /// 更新shapeLayer的路径
    private func updatePath(animated: Bool) {
        let path = LSystemPath(
            string: currentString,
            drawingRules: system.drawingRules,
            startDirection: drawing.startingAngle.angle(for: currentGeneration),
            size: shapeLayer.bounds.size
        )
        shapeLayer.set(path: path, animated: animated)
    }
}
