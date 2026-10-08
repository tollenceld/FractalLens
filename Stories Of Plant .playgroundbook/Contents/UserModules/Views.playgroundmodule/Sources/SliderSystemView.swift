import LSystem
import UIKit

///`SliderSystemView`显示一个由单个值参数化的L系统。
///可以使用滑块更改此值，该滑块将实时更新L系统
public class SliderSystemView: UIView {
    /// 确定给定滑块值的LSystem的块
    private let block: (Double) -> LSystem

    private let evolutions: Int
    private var currentSystem: LSystem

    /// 用于绘制的起始角度，取决于滑块的值
    private let startingAngle: (Double) -> Double

    /// 滑块和显示当前进度的标签
    private let slider = UISlider()
    private let label = UILabel()
    private let labelFormat: String
    private let gradientColors: [UIColor]

    /// 形状层
    private let shapeLayer: EvolutionShapeLayer
    private var initialPathWasSet = false

    private var eventDamper: EventDamper<Double>!

    /// 默认初始化器
    public init(valueRange: Range<Double>, startValue: Double, labelFormat: String, gradient gradientColors: GradientColors, startingAngleForDrawing: @escaping (Double) -> Double, evolutions: Int, system: @escaping (Double) -> LSystem) {
        self.block = system
        self.evolutions = evolutions
        self.startingAngle = startingAngleForDrawing
        self.labelFormat = labelFormat

        currentSystem = block(startValue)

        shapeLayer = EvolutionShapeLayer(gradientColors: gradientColors.colors, lineWidthRange: 2 ..< 2, animationDuration: 0.15, transitionDuration: 0.05)
        self.gradientColors = gradientColors.colors

        super.init(frame: .zero)
        addSubview(shapeLayer)
        backgroundColor = .black

        // 滑块和文本
        addSubview(slider)
        slider.setGradient(with: gradientColors.colors)
        slider.minimumValue = Float(valueRange.lowerBound)
        slider.maximumValue = Float(valueRange.upperBound)
        slider.value = Float(startValue)
        slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)

        addSubview(label)
        label.textAlignment = .center
        label.textColor = gradientColors.colors.last!
        label.text = String(format: labelFormat, startValue)

        // 事件阻尼器
        eventDamper = EventDamper<Double>(delayBetweenEvents: 0.15) { value in
            self.updateSystemWithSliderValue(value)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        if bounds.isEmpty { return }

        // 滑块和文本
        slider.frame = CGRect(x: 20, y: bounds.height - 90, width: bounds.width - 40, height: 30)
        slider.setGradient(with: gradientColors)
        label.frame = CGRect(x: 0, y: slider.frame.maxY + 5, width: 200, height: 40)
        label.center.x = bounds.width / 2

        // 形状约束
        shapeLayer.frame = CGRect(x: 0, y: 0, width: bounds.width, height: slider.frame.minY).insetBy(dx: 15, dy: 15)

        // 初始路径或更新路径
        if !initialPathWasSet {
            initialPathWasSet = true
            shapeLayer.set(path: currentPath, animated: false)
        } else {
            updateSystemWithSliderValue(Double(slider.value))
        }
    }

    /// 根据当前L系统和大小生成当前L系统路径
    private var currentPath: LSystemPath {
        LSystemPath(
            string: currentSystem.apply(count: evolutions, to: currentSystem.startString),
            drawingRules: currentSystem.drawingRules,
            startDirection: startingAngle(Double(slider.value)),
            size: shapeLayer.bounds.size
        )
    }

    @objc private func sliderValueChanged() {
        eventDamper.newValue(Double(slider.value))
    }

    /// 实际更新系统。
    private func updateSystemWithSliderValue(_ value: Double) {
        label.text = String(format: labelFormat, value)
        if bounds.isEmpty { return }
        currentSystem = block(Double(slider.value))
        shapeLayer.set(path: currentPath, animated: true)
    }
}

// MARK: 拓展

private extension UISlider {
    /// 用渐变填充滑块的左侧部分
    func setGradient(with colors: [UIColor]) {
        let gradient = RadialGradientLayer()
        gradient.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 5)
        gradient.colors = colors

        UIGraphicsBeginImageContextWithOptions(gradient.frame.size, false, 0)
        gradient.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        setMinimumTrackImage(image,  for: .normal)
    }
}

/// 事件抑制器用于过滤和扩展传入的事件，因此它们在给定的时间间隔内不会发生得太频繁
private class EventDamper<Value> {
    private let delayBetweenEvents: Double
    private let eventCallback: (Value) -> Void

    /// 默认初始化器
    init(delayBetweenEvents: Double, eventCallback: @escaping (Value) -> Void) {
        self.delayBetweenEvents = delayBetweenEvents
        self.eventCallback = eventCallback
    }

    /// 经过足够时间后将发送的值
    private var waitingValue: Value?
    private var timerForWaitingValue: Timer?

    private var timeOfLatestEvent: Double?

    ///当出现新值时调用。
    ///当此值有效或将变为有效（按时间）时，将调用`eventCallback`
    func newValue(_ value: Value) {
        let time = CACurrentMediaTime()
        timerForWaitingValue?.invalidate()

        guard let latest = timeOfLatestEvent else { // 第一个值
            timeOfLatestEvent = time
            return eventCallback(value)
        }

        // Fire new value
        if time - latest >= delayBetweenEvents {
            waitingValue = nil
            timeOfLatestEvent = time
            eventCallback(value)
        }

        // 将当前值设置为等待
        else {
            waitingValue = value
            timerForWaitingValue = Timer.scheduledTimer(timeInterval: delayBetweenEvents - (time - latest), target: self, selector: #selector(fire), userInfo: nil, repeats: false)
            RunLoop.main.add(timerForWaitingValue!, forMode: .common)
        }
    }

    @objc private func fire() {
        if let value = waitingValue {
            timeOfLatestEvent = CACurrentMediaTime()
            waitingValue = nil
            eventCallback(value)
        }
    }
}
