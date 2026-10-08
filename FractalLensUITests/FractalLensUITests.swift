import XCTest

final class FractalLensUITests:XCTestCase {
    @MainActor func testPatternAtlasGenerationControlsAndNavigation() {
        let app=XCUIApplication();app.launchArguments=["--pattern=snow","--generation=2"];app.launch()
        XCTAssertTrue(app.staticTexts["Koch snowflake"].waitForExistence(timeout:15))
        XCTAssertTrue(app.staticTexts["Generation 2"].waitForExistence(timeout:5))
        app.buttons["nextGeneration"].tap()
        XCTAssertTrue(app.staticTexts["Generation 3"].waitForExistence(timeout:5))
        app.buttons["Look closer at pattern"].tap()
        XCTAssertTrue(app.staticTexts["Looking closer"].exists)
        app.buttons["Restart pattern"].tap()
        XCTAssertTrue(app.staticTexts["Generation 0"].waitForExistence(timeout:5))
        attach(app,"Native glass pattern controls")
        app.navigationBars.buttons.element(boundBy:0).tap()
        XCTAssertTrue(app.buttons["pattern-fern"].waitForExistence(timeout:5))
        app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.staticTexts["Your pattern collection"].waitForExistence(timeout:5))
        app.tabBars.buttons["Discover"].tap()
        XCTAssertTrue(app.buttons["findPattern"].waitForExistence(timeout:5))
    }
    @MainActor func testDiscoveryAndPersistentCollection() throws {
        let app=XCUIApplication();app.launch()
        XCTAssertTrue(app.buttons["findPattern"].waitForExistence(timeout:30))
        app.buttons["findPattern"].tap()
        XCTAssertTrue(app.buttons["trySpecimen"].waitForExistence(timeout:5))
        app.buttons["trySpecimen"].tap()
        let fern=app.buttons["choose-fern-study"]
        XCTAssertTrue(fern.waitForExistence(timeout:5));fern.tap()
        XCTAssertTrue(app.buttons["replayRule"].waitForExistence(timeout:30))
        XCTAssertTrue(app.staticTexts["A familiar pattern."].waitForExistence(timeout:5))
        Thread.sleep(forTimeInterval:3.2)
        attach(app,"Scale alignment")
        app.buttons["replayRule"].tap()
        XCTAssertTrue(app.buttons["alterRule"].waitForExistence(timeout:5))
        app.buttons["alterRule"].tap()
        let slider=app.sliders["Change Branch angle"]
        XCTAssertTrue(slider.waitForExistence(timeout:5));slider.adjust(toNormalizedSliderPosition:0.65)
        app.buttons["Regrow"].tap()
        Thread.sleep(forTimeInterval:3.2)
        attach(app,"Alter one rule")
        app.buttons["collectSpecimen"].tap()
        XCTAssertTrue(app.buttons["specimen-0"].waitForExistence(timeout:8))
        XCTAssertTrue(app.buttons["specimen-0"].waitForExistence(timeout:5))
        app.buttons["specimen-0"].tap()
        XCTAssertTrue(app.buttons["observeAgain"].waitForExistence(timeout:5))
        app.buttons["observeAgain"].tap()
        XCTAssertTrue(app.buttons["openPhoto"].waitForExistence(timeout:5))
        XCTAssertFalse(app.buttons["trySpecimen"].exists)
        app.terminate();app.launch()
        XCTAssertTrue(app.buttons["findPattern"].waitForExistence(timeout:30));app.tabBars.buttons["Collection"].tap()
        XCTAssertTrue(app.buttons["specimen-0"].waitForExistence(timeout:5))
    }
    @MainActor func testEarlyExitDoesNotResumeReveal() {
        let app=XCUIApplication();app.launch()
        XCTAssertTrue(app.buttons["findPattern"].waitForExistence(timeout:30));app.buttons["findPattern"].tap()
        app.buttons["trySpecimen"].tap();app.buttons["choose-fern-study"].tap()
        XCTAssertTrue(app.buttons["Return to collection"].waitForExistence(timeout:5));app.buttons["Return to collection"].tap()
        XCTAssertTrue(app.buttons["findPattern"].waitForExistence(timeout:5))
    }
    @MainActor func testContinuousLensAutomaticallyRevealsHonestRepetition() {
        let app=XCUIApplication();app.launchArguments=["--live-preview=windows"];app.launch()
        XCTAssertTrue(app.buttons["pauseLive"].waitForExistence(timeout:10))
        XCTAssertFalse(app.buttons["Hold this moment"].exists)
        XCTAssertTrue(app.buttons["replayTrace"].waitForExistence(timeout:30))
        XCTAssertTrue(app.staticTexts["A rhythm, repeated."].exists)
        XCTAssertTrue(app.staticTexts["Guided study · illustrated structure"].exists)
        XCTAssertFalse(app.staticTexts["Self similarity"].exists)
        app.buttons["evidence-Key points"].tap();attach(app,"Everyday repetition evidence")
        app.buttons["replayTrace"].tap()
        XCTAssertFalse(app.buttons["alterRule"].exists)
        XCTAssertTrue(app.staticTexts["Replaying the extracted paths. No growth rule is inferred."].exists)
        app.buttons["collectSpecimen"].tap()
        XCTAssertTrue(app.staticTexts["Your pattern collection"].waitForExistence(timeout:10))
    }
    @MainActor func testEmptyLiveSignalOpensExampleAndCanBePaused() {
        let app=XCUIApplication();app.launchArguments=["--live","--live-timeout"];app.launch()
        XCTAssertTrue(app.buttons["pauseLive"].waitForExistence(timeout:10))
        app.buttons["pauseLive"].tap()
        XCTAssertTrue(app.staticTexts["Take your time."].waitForExistence(timeout:3))
        app.buttons["pauseLive"].tap()
        XCTAssertTrue(app.staticTexts["Guided study · illustrated structure"].waitForExistence(timeout:25))
        XCTAssertTrue(app.buttons["replayRule"].waitForExistence(timeout:20))
    }
    @MainActor func testWorldLibraryExplainsSpiralWithoutClaimingFractal() {
        let app=XCUIApplication();app.launch()
        attach(app,"Revision 03 Discover")
        app.tabBars.buttons["Patterns"].tap()
        XCTAssertTrue(app.staticTexts["Patterns are\neverywhere."].waitForExistence(timeout:10))
        attach(app,"Revision 03 World atlas")
        let shell=app.buttons["world-shell"]
        for _ in 0..<4 { if shell.isHittable { break };app.swipeUp() }
        XCTAssertTrue(shell.waitForExistence(timeout:5));shell.tap()
        XCTAssertTrue(app.staticTexts["A spiral in a shell"].waitForExistence(timeout:5))
        attach(app,"Revision 03 Spiral study")
        XCTAssertTrue(app.staticTexts["The curve turns as it grows. A spiral alone is not evidence of a fractal."].exists)
        app.buttons["revealWorldStudy"].tap()
        XCTAssertTrue(app.staticTexts["A turning rhythm."].waitForExistence(timeout:15))
        attach(app,"Revision 03 Spiral evidence")
        XCTAssertTrue(app.buttons["replayTrace"].exists)
        XCTAssertFalse(app.buttons["replayRule"].exists)
    }
    @MainActor private func attach(_ app:XCUIApplication,_ title:String) {
        let attachment=XCTAttachment(screenshot:app.screenshot());attachment.name=title;attachment.lifetime = .keepAlways;add(attachment)
    }
}
