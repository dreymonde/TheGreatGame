/**
 *  Alba
 *
 *  Copyright (c) 2016 Oleg Dreyman. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation
import XCTest
@testable import Alba

var isBureauWorking = false

class AlbaTests: XCTestCase {
    
    override func setUp() {
        if !isBureauWorking {
            print("Alba Inform Bureau on")
            Alba.InformBureau.isEnabled = true
            Alba.InformBureau.Logger.enable()
//            Alba.InformBureau.didPublish.listen(with: { print($0) })
            isBureauWorking = true
            print("Now working")
        }
    }
    
    func testSimplest() {
        let pub = Publisher<Int>(label: "testSimplest.pub")
        let expectation = self.expectation(description: "On Sub")
        pub.proxy.listen { (number) in
            XCTAssertEqual(number, 5)
            expectation.fulfill()
        }
        pub.publish(5)
        waitForExpectations(timeout: 5.0)
    }
    
    class SignedThing {
        
        var expectation: XCTestExpectation
        
        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }
        
        func handle(_ a: (number: Int, submittedBySelf: Bool)) {
            if a.submittedBySelf {
                if a.number == 7 {
                    XCTFail()
                }
            } else {
                if a.number == 5 {
                    XCTFail()
                }
                if a.number == 7 {
                    expectation.fulfill()
                }
            }
        }
        
        func handle_filtered(_ number: Int) {
            if number == 10 {
                XCTFail()
            } else if number == 5 {
                expectation.fulfill()
            }
        }
        
    }
    
    func testSigned() {
        let pub = SignedPublisher<Int>()
        let expectation = self.expectation(description: "On sub")
        let sub = SignedThing(expectation: expectation)
        pub.proxy.subscribe(sub, with: SignedThing.handle)
        pub.publish(5, submittedBy: sub)
        pub.publish(7, submittedBy: nil)
        waitForExpectations(timeout: 5.0)
    }
    
    func testFilterSigned() {
        let pub = SignedPublisher<Int>()
        let expectation = self.expectation(description: "on sub")
        let sub = SignedThing(expectation: expectation)
        pub.proxy.drop(eventsSignedBy: sub).unsigned.subscribe(sub, with: SignedThing.handle_filtered)
        pub.publish(10, submittedBy: sub)
        pub.publish(5, submittedBy: nil)
        waitForExpectations(timeout: 5.0)
    }
    
    class SignedThing2 {
        
        var expectation: XCTestExpectation
        
        init(expectation: XCTestExpectation) {
            self.expectation = expectation
        }
        
        func handle(a: (number: Int, identifier: ObjectIdentifier?)) {
            if a.identifier?.belongsTo(self) == true {
                if a.number == 7 {
                    XCTFail()
                }
            } else {
                if a.number == 5 {
                    XCTFail()
                }
                if a.number == 7 {
                    expectation.fulfill()
                }
            }
        }
        
    }
    
    func testSigned2() {
        let pub = SignedPublisher<Int>()
        let expectation = self.expectation(description: "On sub")
        let sub = SignedThing2(expectation: expectation)
        pub.proxy.subscribe(sub, with: SignedThing2.handle)
        pub.publish(5, submittedBy: sub)
        pub.publish(7, submittedBy: nil)
        waitForExpectations(timeout: 5.0)
    }
    
    class DEA {
        let proxy: Subscribe<Int>
        let sproxy: SignedSubscribe<Int>
        let deinitBlock: () -> ()
        init(proxy: Subscribe<Int>, sproxy: SignedSubscribe<Int>, signed: Bool = false, deinitBlock: @escaping () -> ()) {
            self.proxy = proxy
            self.sproxy = sproxy
            self.deinitBlock = deinitBlock
            proxy.subscribe(self, with: DEA.handle)
            if signed {
                sproxy.subscribe(self, with: DEA.handleSigned)
            } else {
                sproxy.unsigned.subscribe(self, with: DEA.handle)
            }
        }
        deinit {
            print("Dealloc")
            deinitBlock()
        }
        func handle(_ int: Int) {
            print(int)
            XCTAssertNotEqual(int, 10)
        }
        func handleSigned(a: (int: Int, submitter: ObjectIdentifier?)) {
            print(a.int)
            XCTAssertNotEqual(a.int, 10)
        }
    }
    
    func testDealloc() {
        let pub = Publisher<Int>()
        let spub = SignedPublisher<Int>()
        let expectation = self.expectation(description: "Deinit wait")
        var dea: DEA? = DEA.init(proxy: pub.proxy, sproxy: spub.proxy, deinitBlock: { expectation.fulfill() })
        print(dea!)
        pub.publish(5)
        spub.publish(5, submittedBy: nil)
        dea = nil
        pub.publish(10)
        spub.publish(10, submittedBy: nil)
        waitForExpectations(timeout: 5.0)
    }
    
    func testDealloc2() {
        let pub = Publisher<Int>()
        let spub = SignedPublisher<Int>()
        let expectation = self.expectation(description: "Deinit wait")
        var dea: DEA? = DEA.init(proxy: pub.proxy, sproxy: spub.proxy, signed: true, deinitBlock: { expectation.fulfill() })
        print(dea!)
        pub.publish(5)
        spub.publish(5, submittedBy: nil)
        dea = nil
        pub.publish(10)
        spub.publish(10, submittedBy: nil)
        waitForExpectations(timeout: 5.0)
    }
    
    func testFilter() {
        let pub = Publisher<Int>()
        let pospub = pub.proxy.filter({ $0 > 0 })
        let expectation = self.expectation(description: "on sub")
        pospub.listen { (number) in
            XCTAssertGreaterThan(number, 0)
            if number == 10 { expectation.fulfill() }
        }
        [-1, -3, 5, 7, 9, 4, 3, -2, 0, 10].forEach(pub.publish)
        waitForExpectations(timeout: 5.0)
    }
    
    func testMap() {
        let pub = Publisher<Int>()
        let strpub = pub.proxy.map(String.init)
        let expectation = self.expectation(description: "onsub")
        strpub.listen { (string) in
            debugPrint(string)
            if string == "10" { expectation.fulfill() }
        }
        [-1, 2, 3, 9, 7, 4, 2, 57, 10].forEach(pub.publish)
        waitForExpectations(timeout: 5.0)
    }
    
    func testFlatMap() {
        let pub = Publisher<String>()
        let intpub = pub.proxy.flatMap({ Int($0) })
        let expectation = self.expectation(description: "onsub")
        intpub.listen { (number) in
            if number == 10 { expectation.fulfill() }
        }
        ["Abba", "Babbaa", "-7", "3", "10"].forEach(pub.publish)
        waitForExpectations(timeout: 5.0)
    }
    
    func testRedirect() {
        let pubOne = Publisher<Int>()
        let pubTwo = Publisher<String>(label: "testRedirect.pubTwo")
        let expectation = self.expectation(description: "onsubtwo")
        pubOne.proxy
            .map({ $0 - 1 })
            .map(String.init)
            .redirect(to: pubTwo)
        pubTwo.proxy.listen { (number) in
            debugPrint(number)
            if number == "10" { expectation.fulfill() }
        }
        pubOne.publish(3)
        pubOne.publish(5)
        pubOne.publish(11)
        waitForExpectations(timeout: 5.0)
    }
    
    func testIntercept() {
        let pub = Publisher<Int>()
        let expectation = self.expectation(description: "onsub")
        let proxy = pub.proxy
            .interrupted(with: {
                if $0 == 10 { expectation.fulfill() }
            })
        proxy.listen { (_) in
            print("Yay")
        }
        pub.publish(5)
        pub.publish(7)
        pub.publish(10)
        waitForExpectations(timeout: 5.0)
    }
    
    func testListen() {
        let pub = Publisher<Int>()
        let expectation = self.expectation(description: "onlis")
        pub.proxy.listen { (number) in
            if number == 10 { expectation.fulfill() }
        }
        [0, 3, 4, -1, 5, 10].forEach(pub.publish)
        waitForExpectations(timeout: 5.0)
    }
    
    func testMapValue() {
//        let signed = SignedPublisher<Int>()
//        let strsgn = signed.proxy.mod_mapValue(String.init)
    }
    
    class Hand {
        
        func handle(_ int: Int) {
            print(int)
        }
        
    }
    
    func testBureau() {
        let hand = Hand()
        let publisher = Publisher<String>(label: "Then-What")
        publisher.proxy
            .flatMap({ Int.init($0) })
            .subscribe(hand, with: Hand.handle)
    }
    
    func testWarning() {
        let proxy = Subscribe<Int>.empty()
        let obj = Hand()
        let expectation = self.expectation(description: "on warning")
        Alba.InformBureau.didSubscribe
            .flatMap({ $0.entries.first })
            .listen { (logEntry) in
                if case .publisherLabel(let name, _) = logEntry, name == "WARNING: Empty proxy" {
                    expectation.fulfill()
                }
        }
        proxy.subscribe(obj, with: Hand.handle)
        waitForExpectations(timeout: 5.0)
    }
    
    func testMerged() {
        let first = Publisher<Int>(label: "testMerged.first")
        let second = Publisher<Int>(label: "testMerged.second")
        let merged = first.proxy.merged(with: second.proxy)
        
        let expectation = self.expectation(description: "on merged")
        var is5Present = false
        merged.listen { (number) in
            if number == 5 {
                is5Present = true
            }
            if number == 10 {
                XCTAssertTrue(is5Present)
                expectation.fulfill()
            }
        }
        first.publish(5)
        second.publish(10)
        waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    class Filter {
        
        var numbers = [1, 2, 3, 4, 5]
        
        func subscribe(to publisher: Subscribe<String>) {
            publisher
                .weak(self)
                .map({ $0.fromString })
                .filter({ !$0.numbers.contains })
                .subscribe(with: Filter.printNonExisting)
        }
        
        func printNonExisting(_ number: Int) {
            if number == 15 {
                XCTFail("Filter should be deallocated at this point")
            }
            if numbers.contains(number) {
                XCTFail("Where is actual filtering?")
            }
            print(number)
        }
        
        func fromString(_ string: String) -> Int {
            return Int(string)!
        }
        
        deinit {
            print("Deinit!")
        }
        
    }
    
    func testWeak() {
        let publisher = Publisher<String>(label: "testWeakFilter.publisher")
        var filter: Filter? = Filter()
        filter!.subscribe(to: publisher.proxy)
        [1, 2, 3, 10, 12].map(String.init).forEach(publisher.publish)
        filter = nil
        publisher.publish("15")
    }
    
    class VoidTest {
        
        var tested = false
        
        init() { }
        
        func sub(sub: Subscribe<Void>) {
            sub.subscribe(self, with: VoidTest.test)
        }
        
        func test() {
            tested = true
        }
        
    }
    
    func testVoid() {
        let pub = Publisher<Void>()
        let voidTest = VoidTest()
        voidTest.sub(sub: pub.proxy)
        pub.publish()
        XCTAssertTrue(voidTest.tested)
    }
    
}
