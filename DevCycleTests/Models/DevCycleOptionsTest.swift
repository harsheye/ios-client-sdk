//
//  DevCycleOptionsTest.swift
//  DevCycleTests
//

import XCTest
@testable import DevCycle

class DevCycleOptionsTest: XCTestCase {
    func testOptionsAreNil() {
        let options = DevCycleOptions()
        XCTAssertNil(options.disableEventLogging)
        XCTAssertNil(options.eventFlushIntervalMS)
    }
    
    func testBuilderReturnsOptions() {
        let options = DevCycleOptions.builder()
                .disableEventLogging(false)
                .eventFlushIntervalMS(1000)
                .enableEdgeDB(true)
                .configCacheTTL(172800000)
                .disableConfigCache(true)
                .disableRealtimeUpdates(true)
                .disableCustomEventLogging(true)
                .disableAutomaticEventLogging(true)
                .apiProxyURL("localhost:4000")
                .build()
        XCTAssertNotNil(options)
        XCTAssert(options.eventFlushIntervalMS == 1000)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssert(options.enableEdgeDB)
        XCTAssert(options.configCacheTTL == 172800000)
        XCTAssert(options.disableConfigCache)
        XCTAssert(options.disableRealtimeUpdates)
        XCTAssert(options.disableCustomEventLogging)
        XCTAssert(options.disableAutomaticEventLogging)
        XCTAssert(options.apiProxyURL == "localhost:4000")
    }
    
    func testBuilderReturnsOptionsAndSomeAreNil() {
        let options = DevCycleOptions.builder()
                .disableEventLogging(false)
                .build()
        XCTAssertNotNil(options)
        XCTAssertNil(options.eventFlushIntervalMS)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssertFalse(options.enableEdgeDB)
        XCTAssertFalse(options.disableRealtimeUpdates)
    }
    
    func testDeprecatedDVCOptions() {
        let options = DVCOptions.builder()
                .disableEventLogging(false)
                .flushEventsIntervalMs(2000)
                .build()
        XCTAssertNotNil(options)
        XCTAssert(options.eventFlushIntervalMS == 2000)
        XCTAssertFalse(options.disableEventLogging!)
        XCTAssertFalse(options.enableEdgeDB)
        XCTAssertFalse(options.disableRealtimeUpdates)
    }
}
