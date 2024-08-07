@testable import AlertToast
import XCTest

final class AlertToastTests: XCTestCase {

    func testInit() {
        let toast = AlertToast(type: .regular, title: "Title", subtitle: "Subtitle", style: .init(alertShape: .banner))
        XCTAssertEqual(toast.type, .regular)
    }

    static var allTests = [
        ("testInit", testInit)
    ]
}
