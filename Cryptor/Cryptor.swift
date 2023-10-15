//
//  Cryptor.swift
//  Cryptor
//
//  Created by Иван Гришин on 15.10.2023.
//

import Foundation

enum CryptorError: Error {
    case invalidInputData
    case algorithmNotSupported
    case encryptionFailed(Error?)
    case decryptionFailed(Error?)
    case invalidDecryptedData
    case keyGenerationFailed(Error?)
    case publicKeyGenerationFailed
    case publicKeyAbsent
}

public final class Cryptor {
    
    // MARK: - Public Properties
    
    static var strings: [String] {
        get async {
            guard let privateKey = privateKey else { return [] }
            let coreDataManager = CoreDataManager(coreDataStorage: CoreDataStack(modelName: "DataModel"))
            var stringArray: [String] = []
            for data in coreDataManager.fetchCryptors() {
                do {
                    let decryptString = try decryptData(data, privateKey: privateKey)
                    stringArray.append(decryptString)
                } catch let error {
                    print(error.localizedDescription)
                }
            }
            return stringArray
        }
    }
    
    // MARK: - Private Properties
    
    private static let coreDataManager = CoreDataManager(coreDataStorage: CoreDataStack(modelName: "DataModel"))
    private static var publicKey: SecKey?
    private static var privateKey: SecKey?
    
    // MARK: - Public Methods
    
    static func store(string: String) async throws {
        try updateKeysIfNeeded()
        guard let publicKey = publicKey else { throw CryptorError.publicKeyAbsent }
        let data = try encryptString(string, publicKey: publicKey)
        coreDataManager.addCryptor(data)
        
    }
    
    static func resetCryptor() {
        coreDataManager.deleteObjects()
    }
    
    // MARK: - Private Methods

    private static func updateKeysIfNeeded() throws {
        guard privateKey == nil, publicKey == nil else { return }
        
        let keyPairAttr: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeySizeInBits as String: 2048
        ]

        var error: Unmanaged<CFError>?

        guard let privateKey = SecKeyCreateRandomKey(keyPairAttr as CFDictionary, &error) else {
            throw CryptorError.keyGenerationFailed(error?.takeRetainedValue())
        }
        
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CryptorError.publicKeyGenerationFailed
        }
        
        self.publicKey = publicKey
        self.privateKey = privateKey
    }
    
    private static func encryptString(_ string: String, publicKey: SecKey) throws -> Data {
        guard let inputData = string.data(using: .utf8) else {
            throw CryptorError.invalidInputData
        }

        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm) else {
            throw CryptorError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(
            publicKey,
            algorithm,
            inputData as CFData,
            &error
        ) as Data? else {
            throw CryptorError.encryptionFailed(error?.takeRetainedValue())
        }

        return encryptedData
    }

    private static func decryptData(_ encryptedData: Data, privateKey: SecKey) throws -> String {
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA512

        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, algorithm) else {
            throw CryptorError.algorithmNotSupported
        }

        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            algorithm,
            encryptedData as CFData,
            &error
        ) as Data? else {
            throw CryptorError.decryptionFailed(error?.takeRetainedValue())
        }

        guard let decryptedString = String(data: decryptedData, encoding: .utf8) else {
            throw CryptorError.invalidDecryptedData
        }

        return decryptedString
    }
}
