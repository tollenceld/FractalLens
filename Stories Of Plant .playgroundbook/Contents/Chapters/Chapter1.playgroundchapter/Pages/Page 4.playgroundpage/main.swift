//#-hidden-code
import PlaygroundSupport
var system: LSystemEvolutionDrawingDescription = Fractals.pentagon
//#-end-hidden-code
/*:
 # Plants and flowers🌹
   ![img](Sierpinski.png)
   Now you can see more fractals!
    The first one is **Sakura🌸**, click **Run Code** to see its actual effect.

   -Note:
   Remember, fractals are the most impressive when displayed in **full screen mode**
 */
/*:
 There is another shape that is also a reasonable fractal result. You can guess what kind of flower it corresponds to. **Uncomment** to observe another flower shape.
 */
//#-editable-code
//system = Fractals.sierpinski
//#-end-editable-code
/*:
 If you want to know how it is generated, please refer to the code at the bottom
 */
/*:
 ### eg:
 This is the code for the Sierpiński triangle before, if you want to know more

 
 The specific implementation principle is shown in the following code
```
sierpinski = LSystem(
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
)
```
*/



//#-hidden-code
PlaygroundPage.current.liveView = EvolutionView(drawing: system)
//#-end-hidden-code
