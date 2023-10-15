//
//  CoreDataStack.swift
//  Cryptor
//
//  Created by Иван Гришин on 15.10.2023.
//

import CoreData

// Протокол для работы с базой данных (Core Data)
protocol CoreDataStorage: AnyObject {
    
    /// Сохранить текущие изменения в контексте
    /// - Returns: Успешность операции
    @discardableResult
    func saveChanges() -> Bool
    
    /// Метод создает новый объект в Context
    /// - Parameter entity: Класс объекта, который нужно создать
    /// - Returns: Созданный объект
    func createObject<T: NSManagedObject>(from entity: T.Type) -> T
    
    /// Получить объекты из БД
    /// - Parameters:
    ///   - entity: Класс объектов, которые нужно получить
    ///   - predicate: Опциональный предикат для фильтрации результатов
    ///   - sortDescriptors: Опциональный массив сорт дескрипторов для сортировки результатов
    ///   - limit: Опционально ограничить количество объектов указанным числом
    ///   - offset: Опционально игнорировать первые `offset` объектов
    /// - Returns: Массив объектов, удовлетворяющих условиям
    func fetchObjects<T: NSManagedObject>(
        ofType entity: T.Type,
        filterBy predicate: NSPredicate?,
        sortBy sortDescriptors: [NSSortDescriptor]?,
        limitBy limit: Int?,
        offsetBy offset: Int?
    ) -> [T]
    
    /// Удалить все объекты заданного типа, удовлетворяющие предикату
    /// - Parameters:
    ///   - entity: Тип объектов, которые нужно удалить
    ///   - predicate: Опциональный предикат
    /// - Returns: Успешность операции
    @discardableResult
    func deleteAllObjects<T: NSManagedObject>(
        ofType entity: T.Type,
        filterBy predicate: NSPredicate?
    ) -> Bool
}

// MARK: - Method Overloads

extension CoreDataStorage {
    /// Получить объекты из БД
    /// - Parameter entity: Класс объектов, которые нужно получить
    /// - Returns: Массив объектов
    func fetchObjects<T: NSManagedObject>(ofType entity: T.Type) -> [T] {
        return fetchObjects(ofType: entity, filterBy: nil, sortBy: nil, limitBy: nil, offsetBy: nil)
    }
}

// MARK: - Implementation

final class CoreDataStack: CoreDataStorage {
    
    // MARK: - Private Properties

    private let persistentContainer: NSPersistentContainer
    private lazy var context = persistentContainer.viewContext
    private let modelURL = Bundle(identifier: "Ivan.Grishin.Cryptor")?.url(forResource: "DataModel", withExtension: "momd")
    
    // MARK: - Initializers
    
    init(modelName: String) {
        guard let modelURL else {
            fatalError("Failed to locate data model file.")
        }
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load data model.")
        }
        
        persistentContainer = NSPersistentContainer(name: "DataModel", managedObjectModel: managedObjectModel)
        setupPersistentContainer()
    }
    
    // MARK: - Public Methods
    
    func createObject<T: NSManagedObject>(from entity: T.Type) -> T {
        let object = NSEntityDescription.insertNewObject(
            forEntityName: String(describing: entity),
            into: context
        ) as! T // swiftlint:disable:this force_cast
        return object
    }
    
    public func saveChanges() -> Bool {
        guard context.hasChanges else { return false }
        do {
            try context.save()
            return true
        } catch let saveError {
            print("‼️Failed to save context. Error: \(saveError.localizedDescription)")
            return false
        }
    }
    
    public func fetchObjects<T: NSManagedObject>(
        ofType entity: T.Type,
        filterBy predicate: NSPredicate?,
        sortBy sortDescriptors: [NSSortDescriptor]?,
        limitBy limit: Int?,
        offsetBy offset: Int?
    ) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: String(describing: entity))
        
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        if let fetchLimit = limit {
            fetchRequest.fetchLimit = fetchLimit
        }
        
        if let fetchOffset = offset {
            fetchRequest.fetchOffset = fetchOffset
        }
        
        do {
            return try context.fetch(fetchRequest)
        } catch let fetchError {
            print("‼️Error while fetching objects, error: \(fetchError.localizedDescription)")
            return []
        }
    }
    
    @discardableResult
    func deleteAllObjects<T>(
        ofType entity: T.Type,
        filterBy predicate: NSPredicate?
    ) -> Bool where T: NSManagedObject {
        let request = entity.fetchRequest()
        request.includesSubentities = false
        request.predicate = predicate

        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        deleteRequest.resultType = .resultTypeObjectIDs

        do {
             try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch {
            print(error)
            return false
        }
        return true
    }
    
    // MARK: - Private Methods
    
    private func setupPersistentContainer() {
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("‼️Loading of core data store failed: \(error.localizedDescription)")
            }
        }
    }
}
