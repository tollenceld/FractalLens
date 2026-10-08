import UIKit

///有关如何通过EvolutionView绘制L系统的完整说明
///改变的是自由关卡的颜色
public struct LSystemEvolutionDrawingDescription {
    public let system: LSystem

    ///命名渐变的颜色
    public let gradient: GradientColors

    ///命名用于绘图的起始角度
    public let startingAngle: StartingAngle

    ///初始和最大代数
    public let startGeneration: Int
    public let maxGeneration: Int

    ///线的宽度,线的宽度与迭代次数相关会越来越细
    public let lineWidthRange: Range<CGFloat>

    ///默认的初始值设定项
    public init(system: LSystem, gradient: GradientColors, startingAngle: StartingAngle, startGeneration: Int = 0, maxGeneration: Int, lineWidthRange: Range<CGFloat> = 1 ..< 5) {
        self.system = system
        self.gradient = gradient
        self.startingAngle = startingAngle
        self.startGeneration = startGeneration
        self.lineWidthRange = lineWidthRange
        self.maxGeneration = maxGeneration
    }
}

///描述用于绘制L系统的径向渐变的不同颜色
public enum GradientColors {
    case orange
    case green
    case snow
///一下为绘制图形中出现的渐变颜色,其具体数值为rgb色值
    public var colors: [UIColor] {
        switch self {
        case .orange:
            return [.yellow, .orange, .red, UIColor(red: 0.4, green: 0, blue: 0, alpha: 1), .black]

        case .green:
            return [UIColor(red: 0.4, green: 0.8, blue: 0, alpha: 1), UIColor(red: 0, green: 0.5, blue: 0, alpha: 1), .brown]

        case .snow:
            return [.blue, .blue, UIColor(red: 0.5, green: 0.5, blue: 1, alpha: 1), .blue, .blue]
        }
    }
}

///描述如何根据演变指数计算起始角度
public enum StartingAngle {
    case angle(Double)
    case even(Double, odd: Double)
    case block((Int) -> Double)

    public func angle(for evolution: Int) -> Double {
        switch self {
        case let .angle(angle):
            return angle

        case let .even(even, odd: odd):
            return evolution.isMultiple(of: 2) ? even : odd

        case let .block(block):
            return block(evolution)
        }
    }
}

