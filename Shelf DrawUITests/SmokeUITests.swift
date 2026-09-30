import XCTest

/// 3.3.0 walkthrough: after onboarding the graph publishes `smoke.nav.root`,
/// at least three `smoke.nav.destination` rooms, and `smoke.nav.settings`.
/// Older pipelines keep the tab-bar walk in Legacy/UITests/SmokeUITests.3.2.swift.
final class SmokeUITests: XCTestCase {

    private static let onboardingCTAs = [
        "Next", "Continue", "Get started", "Get Started", "Start", "Begin", "Let's go", "Done",
    ]
    private var app: XCUIApplication!
    private var shotIndex = 0

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-uiSmoke"]
        app.launch()
    }

    func testReviewerWalkthrough() {
        completeOnboarding()

        let root = identified("smoke.nav.root")
        XCTAssertTrue(
            root.waitForExistence(timeout: 10),
            "No smoke.nav.root after onboarding — the graph never published its main surface"
        )

        sweepDestinations(capture: true)
        sweepDestinations(capture: false)

        checkLegalLinks()
        checkDeleteAllData()

        XCTAssertEqual(app.state, .runningForeground, "App left the foreground during the walkthrough")
    }

    private func completeOnboarding() {
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15), "App never reached the foreground")
        _ = app.staticTexts.firstMatch.waitForExistence(timeout: 10)
        settle()
        capture(named: "launch")
        var page = 0
        for _ in 0..<8 {
            if identified("smoke.nav.root").exists { break }
            guard let cta = onboardingButton() else { break }
            if page > 0 { capture(named: "onboarding") }
            page += 1
            cta.tap()
            settle(1.0)
        }
        if !identified("smoke.nav.root").waitForExistence(timeout: 5) {
            XCTFail("Onboarding never hands off to smoke.nav.root — dead end at first launch")
        }
    }

    private func sweepDestinations(capture shouldCapture: Bool) {
        let rooms = app.descendants(matching: .any).matching(identifier: "smoke.nav.destination")
        XCTAssertGreaterThanOrEqual(
            rooms.count,
            3,
            "Need at least 3 smoke.nav.destination rooms, found \(rooms.count)"
        )
        for index in 0..<rooms.count {
            let room = rooms.element(boundBy: index)
            guard room.exists else { continue }
            if !room.isHittable {
                var guardCount = 0
                while !room.isHittable && guardCount < 6 {
                    app.swipeUp()
                    guardCount += 1
                }
            }
            guard room.isHittable else { continue }
            room.tap()
            settle(0.6)
            let density = app.staticTexts.count + app.cells.count + app.images.count
            XCTAssertGreaterThanOrEqual(
                density, 3,
                "Destination \(index) renders almost nothing — empty or dead room"
            )
            if shouldCapture {
                capture(named: "room-\(index)")
            }
            XCTAssertEqual(app.state, .runningForeground, "App died while opening destination \(index)")
        }
    }

    private func checkLegalLinks() {
        openSettings()
        capture(named: "settings")
        for title in ["Privacy", "Terms"] {
            let match = NSPredicate(format: "label CONTAINS[c] %@", title)
            let found = app.buttons.matching(match).firstMatch.exists
                || app.links.matching(match).firstMatch.exists
                || app.staticTexts.matching(match).firstMatch.exists
            XCTAssertTrue(found, "Settings has no \(title) entry")
        }
        // Close the sheet so the next openSettings() starts clean. On iPad a tap outside a form sheet dismisses it.
        let done = app.buttons["Done"]
        if done.exists && done.isHittable {
            done.tap()
            settle(0.6)
        }
    }

    private func checkDeleteAllData() {
        openSettings()
        let delete = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Delete All")
        ).firstMatch
        XCTAssertTrue(delete.waitForExistence(timeout: 5), "Settings offers no Delete All Data")
        delete.tap()
        confirmDestructiveAction()

        let rootGone = expectation(
            for: NSPredicate(format: "exists == false"),
            evaluatedWith: identified("smoke.nav.root")
        )
        let waited = XCTWaiter().wait(for: [rootGone], timeout: 10)
        if waited != .completed && onboardingButton() == nil {
            capture(named: "delete-failed")
            let visible = app.buttons.allElementsBoundByIndex.prefix(12).map(\.label)
            XCTFail(
                "Delete All Data did not return to onboarding — the completion flag survived the wipe. "
                    + "Visible buttons: \(visible)"
            )
        }
        XCTAssertEqual(app.state, .runningForeground, "App crashed on Delete All Data")
    }

    private func confirmDestructiveAction() {
        var dialog: XCUIElement?
        if app.sheets.firstMatch.waitForExistence(timeout: 3) {
            dialog = app.sheets.firstMatch
        } else if app.alerts.firstMatch.waitForExistence(timeout: 1) {
            dialog = app.alerts.firstMatch
        }
        guard let dialog else { return }
        let confirm = dialog.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@ AND NOT label CONTAINS[c] %@", "Delete", "Cancel")
        ).firstMatch
        if confirm.waitForExistence(timeout: 2) {
            confirm.tap()
        } else if dialog.buttons.count > 0 {
            dialog.buttons.element(boundBy: 0).tap()
        }
    }

    private func openSettings() {
        let settings = identified("smoke.nav.settings")
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "smoke.nav.settings is missing")
        if !settings.isHittable {
            var guardCount = 0
            while !settings.isHittable && guardCount < 6 {
                app.swipeUp()
                guardCount += 1
            }
        }
        settings.tap()
        settle(0.6)
    }

    private func onboardingButton() -> XCUIElement? {
        for title in Self.onboardingCTAs {
            let button = app.buttons[title]
            if button.exists && button.isHittable { return button }
        }
        return nil
    }

    private func identified(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func settle(_ seconds: TimeInterval = 1.2) {
        _ = XCTWaiter().wait(for: [XCTestExpectation(description: "settle")], timeout: seconds)
    }

    private func capture(named label: String) {
        shotIndex += 1
        let slug = label
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = String(format: "%02d-%@", shotIndex, slug.isEmpty ? "screen" : slug)
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
