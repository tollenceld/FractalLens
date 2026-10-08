 //#-hidden-code
import PlaygroundSupport
var plant: LSystemEvolutionDrawingDescription
//#-end-hidden-code
/*:
 # Regarding the development of plants
  Now let’s look at something **more ornamental**.
 
  I will use a system specially designed for plant growth to show the real situation in the process of plant growth.

   Because the growth of plants is more complicated than the snowflakes we have seen before, we need to introduce more drawing rules.

   Some can generate simple plant and cell rules.
 
   You can try to uncomment the following four strings of codes, (then click **Run Code**) to observe different plant growth structures
 */
//#-editable-code
plant = Plants.weed
// plant = Plants.farn1
// plant = Plants.farn2
// plant = Plants.binaryTree
//#-end-editable-code
//: ![img](Plants.png)

/*:
 
  Of course, they don’t look like realistic plants or trees, because they are two-dimensional.

    The system also provides a method for drawing 3-dimensional fractals.
    To achieve this kind of effect, I added the rule of "rotating around different axes" in the 3D coordinate system.

    But generating actual 3D plants far exceeds the limit of computing power that all devices that can run playgrounds can withstand.
 */

/*:
 ### Specific logic
  Here you will see the code for one of the four plant types ("Plants.weed").
 
 go to[Next Page](@next) to end this playground.
 ```
 weed = LSystem(
     startString: "X",
     productionRules: [
         "F" ~> "FF",
         "X" ~> "F[+X]F[-X]+X"
     ],
     drawingRules: [
         "F": .draw,
         "X": .draw,
         "-": .turnLeft(angle: 25),
         "+": .turnRight(angle: 25),
         "[": .saveState,
         "]": .restoreState
     ]
 )
 ```
 */

//#-hidden-code
PlaygroundPage.current.liveView = EvolutionView(drawing: plant)
//#-end-hidden-code
