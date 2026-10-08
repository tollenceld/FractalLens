///“ ProductionRule”描述了在演化阶段如何将单个字符演化为新字符串的规则。
///一条规则可能如下：（A-> A-B）。 您可以这样构造它：`let rule =“ A”〜>“ A-B”`.
public struct ProductionRule {
    public let predecessor: String
    public let successor: String

    ///创建一个ProductionRule，如下所示：`predecessor-> successor`。
    public init(predecessor: String, successor: String) {
        self.predecessor = predecessor
        self.successor = successor
    }
}

///`DrawingRule`描述如何绘制单个字符。
public enum DrawingRule {
    ///在当前绘制方向上绘制固定长度的线段。
    case draw

    //在当前绘制方向上移动固定长度的线段，而无需实际绘制
    case move

    ///停留在当前位置，并以“角度”（以度为单位）旋转绘图方向
    case turnLeft(angle: Double)

    ///停留在当前位置，并以“角度”（以度为单位）旋转绘图方向
    case turnRight(angle: Double)

    ///将当前状态（即位置和绘图方向）保存到堆栈中
    case saveState

    ///从堆栈中恢复并弹出最上面的状态（即位置和绘图方向)
    case restoreState

    /// 无意义,仅仅是觉得好看呢
    case ignore
}

/// “ LSystem”描述了[L-System]（https://en.wikipedia.org/wiki/L-system）的初始配置和规则
public struct LSystem {
    ///系统的起始字符串
    public let startString: String

    /// 所有生产规则。
    public let productionRules: [ProductionRule]

    ///所有绘图规则。
    ///这些**必须**包括在开始字符串和生产规则中使用的所有字符（否则，无法绘制系统）。
    public let drawingRules: [String: DrawingRule]

    ///从开始字符串和规则创建L系统配置。
    public init(startString: String,
                productionRules: [ProductionRule],
                drawingRules: [String: DrawingRule]) {
        self.startString = startString
        self.productionRules = productionRules
        self.drawingRules = drawingRules
    }
}

infix operator ~>

///构造如下生产规则：`let rule =“ A”〜>“ A-B”
public func ~>(predecessor: String, successor: String) -> ProductionRule {
    ProductionRule(predecessor: predecessor, successor: successor)
}
