//
//  CoreDataManager.swift
//  Cryptor
//
//  Created by Иван Гришин on 15.10.2023.
//

import Foundation

final class CoreDataManager {
    
    // MARK: - Private Properties
    
    private var coreDataStorage: CoreDataStorage
    
    // MARK: - Initializers
    
    init(coreDataStorage: CoreDataStorage) {
        self.coreDataStorage = coreDataStorage
    }
    
    // MARK: - Public Methods
    
    /// Полностью удаляет все объекты из CoreData
    func deleteObjects() {
        coreDataStorage.deleteAllObjects(ofType: CoreDataCryptor.self, filterBy: nil)
    }
}

// MARK: - Cryptor

extension CoreDataManager {
    func fetchCryptors() -> [Data] {
        let fetchResult = coreDataStorage.fetchObjects(ofType: CoreDataCryptor.self)
        return fetchResult.map({ $0.data ?? Data() })
    }
    
    func addCryptor(_ data: Data) {
        let coreDataCryptor = coreDataStorage.createObject(from: CoreDataCryptor.self)
        coreDataCryptor.data = data
        coreDataStorage.saveChanges()
    }
}
