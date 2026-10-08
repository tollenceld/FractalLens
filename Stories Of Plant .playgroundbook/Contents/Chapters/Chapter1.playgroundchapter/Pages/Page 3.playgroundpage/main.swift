//#-hidden-code
import PlaygroundSupport
var string: String = "A--A--A"
//#-end-hidden-code
/*:
 # Detailed introduction of the system
 
 After seeing more fractals and plants, we need to understand how it works, and then you can create your own plant growth rules! Now, let's take a quick look at the system.
 **System** describes two things: how to "grow" in a given period of time, and how to "grow from one stage to the next."


# **Plant growth**
 At any stage, the system is a string of different characters. Each of these characters corresponds to a specific action in growth.

 Imagine an arrow pointing in a certain direction from a certain point. These actions can now "rotate" the arrow, or move it in the direction of the current arrow when drawing a straight line. For example, look at the following actions:
```
actions = [
    "A": .Straight line drawing,
    "-": .Turn right 60 degrees,
    "+": .Turn left 60 degrees,
]
```
 E.g. "A" means to move along the arrow and draw a line, while "+" or "-" rotates the arrow by 60°.

   Now, let's start with the following simple string: `string = "A--A--A"`. **Run the code** and see what happens!
 */

/*:
 It is important to understand what is happening here. You can **replay** the simulation and watch it again as needed.

 Now that we see this simple string, we can try a longer and more complex string. Try this string of characters! Uncomment the code you want to view, and then click **Run Code" **.
*/
//#-editable-code
// string = "A+A--A+A+A+A--A+A--A+A--A+A+A+A--A+A--A+A--A+A+A+A--A+A--A+A--A+A+A+A--A+A--A+A--A+A+A+A--A+A--A+A--A+A+A+A--A+A"
//#-end-editable-code
/*:
 As you can see, these strings correspond to the snowflakes on the previous page! But the question remains: how do we convert one string to get the next string?

   # More expansion
   Therefore, we use *replacement rules*. In order to improve the efficiency of iteration, we replace some characters in the string with longer strings. For example, we can replace each `A` (ie each straight line) with `A+A--A+A` (a line with spikes). It looks like this:
 */
//:![img](Evolution.png)
/*:
 When applying it to **every** `A`, **every** line will be replaced with a thin line with spikes.

    In the code, we can express the rule as follows: `rule = "A" ~> "A+A--A+A"`.
  
   -Note:
   It is these components that constitute a complete plant growth system
 &nbsp;
 &nbsp;

 The introduction is over!go to[Next Page](@next) ，You can set a specific plant growth mechanism under the prompt
*/


//#-hidden-code
PlaygroundPage.current.liveView = CharByCharDrawingView(
    string: string,
    drawingRules: Fractals.snowflake.system.drawingRules,
    gradient: .snow,
    startDirection: 60
)
//#-end-hidden-code
