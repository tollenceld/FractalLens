/// 一些描述分形的L系统,包括所有的形状绘制函数
public enum Fractals {
    /// 由三角形组成的分形雪花
    public static let snowflake = LSystemEvolutionDrawingDescription(
        system: LSystem(
            startString: "A--A--A",
            productionRules: [
                "A" ~> "A+A--A+A"
            ],
            //此时的“-”已被赋值,之后的draw值与之类似
            drawingRules: [
                "A": .draw,
                "-": .turnRight(angle: 60),
                "+": .turnLeft(angle: 60)
            ]
        ),//修改绘制多边形的的边数和线条出发的角度
        gradient: .snow,
        startingAngle: .angle(60),
        //整体图形的偏转角度
        startGeneration: 0,
        maxGeneration: 5,
        //图形循环绘制次数的最大值
        lineWidthRange: 1 ..< 2
    )

    /// sierpinski箭头曲线，近似于sierpinski三角形
    public static let sierpinski = LSystemEvolutionDrawingDescription(
        system: LSystem(
            startString: "A",
            productionRules: [
                "A" ~> "B-A-B",
                "B" ~> "A+B+A"
            ],
            drawingRules: [
                "A": .draw,
                "B": .draw,
                "-": .turnRight(angle: 60),
                "+": .turnLeft(angle: 60)
            ]
        ),
        gradient: .orange,
        startingAngle: .even(0, odd: 60),
        startGeneration: 0,
        maxGeneration: 9,
        lineWidthRange: 1.5 ..< 3.5
    )

    /// 龙形的曲线绘制
    /// 更多分型绘制中,默认注释的 system = Fractals.dragon 代码的实际作用
    public static let dragon = Self.dragon(angle: 30)

    /// 使用不同的角度的曲线绘制
    public static func dragon(angle: Double) -> LSystemEvolutionDrawingDescription {
        let angleFromEvolution: (Int) -> Double = { evolution -> Double in
            angle * Double(evolution) * 0.5
        }

        return LSystemEvolutionDrawingDescription(
            system: LSystem(
                startString: "FX",
                productionRules: [
                    "X" ~> "X+YF+",
                    "Y" ~> "-FX-Y"
                ],
                drawingRules: [
                    "F": .draw,
                    "X": .ignore,
                    "Y": .ignore,
                    "-": .turnLeft(angle: angle),
                    "+": .turnRight(angle: angle),
                ]
            ),
            gradient: .orange,
            startingAngle: .block(angleFromEvolution),
            startGeneration: 0,
            maxGeneration: 13
        )
    }

    /// 由嵌套矩形组成的模版。 并不是真正的布局
    public static let chessboard = LSystemEvolutionDrawingDescription(
        system: LSystem(
            startString: "F+F+F+F",
            productionRules: [
                "F" ~> "FF+F+F+F+FF"
            ],
            drawingRules: [
                "F": .draw,
                "-": .turnLeft(angle: 90),
                "+": .turnRight(angle: 90),
            ]
        ),
        gradient: .orange,
        startingAngle: .angle(0),
        startGeneration: 0,
        maxGeneration: 4
    )

    /// 嵌套的五边形结构
    public static let pentagon = LSystemEvolutionDrawingDescription(
        system: LSystem(
            startString: "F++F++F++F++F",
            productionRules: [
                "F" ~> "F++F++F|F-F++F"
            ],
            drawingRules: [
                "F": .draw,
                "|": .turnLeft(angle: 180),
                "+": .turnRight(angle: 36),
                "-": .turnLeft(angle: 36),
            ]
        ),
        gradient: .orange,
        startingAngle: .angle(180),
        startGeneration: 0,
        maxGeneration: 4,
        lineWidthRange: 1.5 ..< 2.5
    )


    /// LévyC曲线
    public static var levyCurve = LSystemEvolutionDrawingDescription(
        system: LSystem(
            startString: "F",
            productionRules: [
                "F" ~> "-F++F-"
            ],
            drawingRules: [
                "F": .draw,
                "+": .turnRight(angle: 45),
                "-": .turnLeft(angle: 45),
            ]
        ),
        gradient: .orange,
        startingAngle: .angle(180),
        startGeneration: 0,
        maxGeneration: 12
    )
}
