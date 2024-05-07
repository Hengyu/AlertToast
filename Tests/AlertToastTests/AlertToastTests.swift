@testable import AlertToast
import XCTest

final class AlertToastTests: XCTestCase {

    func testInit() {
        let toast = AlertToast(type: .regular, title: "Title", subtitle: "Subtitle")
        XCTAssertEqual(toast.type, .regular)
        XCTAssertEqual(toast.displayMode, .alert)
    }

    static var allTests = [
        ("testInit", testInit)
    ]
}
