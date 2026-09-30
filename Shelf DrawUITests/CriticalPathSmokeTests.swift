import XCTest

final class CriticalPathSmokeTests: XCTestCase {
    private static let onboardingCTAs = ["Next", "Continue", "Get started", "Get Started", "Start", "Begin", "Let's go", "Done"]
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testCriticalInteractions() {
        completeOnboarding()
        let control1 = element("smoke.draw.slot")
        XCTAssertTrue(control1.waitForExistence(timeout: 8), "Critical control 1 is unavailable")
        XCTAssertFalse(element("smoke.draw.slotset").exists, "Critical result 1 already exists before its action")
        var scrollGuard1 = 0
        while !control1.isHittable && scrollGuard1 < 6 {
            app.swipeUp()
            scrollGuard1 += 1
        }
        XCTAssertTrue(control1.isHittable, "Critical control 1 never scrolled into view")
        control1.tap()
        XCTAssertTrue(element("smoke.draw.slotset").waitForExistence(timeout: 8), "Critical result 1 did not appear")
        let control2 = element("smoke.draw.commit")
        XCTAssertTrue(control2.waitForExistence(timeout: 8), "Critical control 2 is unavailable")
        XCTAssertFalse(element("smoke.draw.result").exists, "Critical result 2 already exists before its action")
        var scrollGuard2 = 0
        while !control2.isHittable && scrollGuard2 < 6 {
            app.swipeUp()
            scrollGuard2 += 1
        }
        XCTAssertTrue(control2.isHittable, "Critical control 2 never scrolled into view")
        control2.tap()
        XCTAssertTrue(element("smoke.draw.result").waitForExistence(timeout: 8), "Critical result 2 did not appear")
        let control3 = element("smoke.draw.place")
        XCTAssertTrue(control3.waitForExistence(timeout: 8), "Critical control 3 is unavailable")
        XCTAssertFalse(element("smoke.draw.placed").exists, "Critical result 3 already exists before its action")
        var scrollGuard3 = 0
        while !control3.isHittable && scrollGuard3 < 6 {
            app.swipeUp()
            scrollGuard3 += 1
        }
        XCTAssertTrue(control3.isHittable, "Critical control 3 never scrolled into view")
        control3.tap()
        XCTAssertTrue(element("smoke.draw.placed").waitForExistence(timeout: 8), "Critical result 3 did not appear")
        XCTAssertEqual(app.state, .runningForeground, "App left the foreground during critical interactions")
    }

    private func completeOnboarding() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App never reached the foreground")
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
        settle()
        for _ in 0..<8 {
            if element("smoke.nav.root").exists { break }
            guard let button = onboardingButton() else { break }
            button.tap()
            settle(0.5)
        }
        XCTAssertTrue(element("smoke.nav.root").waitForExistence(timeout: 8), "Onboarding did not reach smoke.nav.root")
    }

    private func onboardingButton() -> XCUIElement? {
        for title in Self.onboardingCTAs {
            let button = app.buttons[title]
            if button.exists && button.isHittable { return button }
        }
        return nil
    }

    private func settle(_ seconds: TimeInterval = 0.8) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }
}
