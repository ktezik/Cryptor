//
//  CryptorTests.swift
//  CryptorTests
//
//  Created by Иван Гришин on 15.10.2023.
//

import XCTest
@testable import Cryptor

final class CryptorTests: XCTestCase {

    func testStorage() async throws {
        Cryptor.resetCryptor()
        
        let inputStrings = (0..<100).map { _ in UUID().uuidString }

        for string in inputStrings {
            try await Cryptor.store(string: string)
        }

        let storedStrings = await Cryptor.strings

        XCTAssertEqual(inputStrings, storedStrings)
    }
}
