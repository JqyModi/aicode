import Foundation
import RealmSwift
import Combine

class RealmManager {
    // 单例模式
    static let shared = RealmManager()
    
    /// **本地 Realm 存储路径**
    private var localRealmPath: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("realm")
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("word-core.realm")
    }
    
    private init() {
        copyBundleRealmToDocuments()
        setupRealm()
    }
    
    // 将Bundle中的Realm文件复制到沙盒中
    private func copyBundleRealmToDocuments() {
        let fileManager = FileManager.default
        
        // 检查目标文件是否已存在
        if fileManager.fileExists(atPath: localRealmPath.path) {
            print("Realm文件已存在于沙盒中，无需复制")
            return
        }
        
        // 获取Bundle中的Realm文件路径
        guard let bundleRealmPath = Bundle.main.path(forResource: "word-core", ofType: "realm") else {
            print("在Bundle中找不到Realm文件")
            return
        }
        
        do {
            // 创建目录（如果不存在）
            let directory = localRealmPath.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
            }
            
            // 复制文件
            try fileManager.copyItem(atPath: bundleRealmPath, toPath: localRealmPath.path)
            print("成功将Realm文件从Bundle复制到沙盒: \(localRealmPath.path)")
        } catch {
            print("复制Realm文件失败: \(error.localizedDescription)")
        }
    }
    
    // 获取默认Realm实例
    func realm() throws -> Realm {
        return try Realm()
    }
    
    // 设置Realm配置
    private func setupRealm() {
        var config = Realm.Configuration(
            schemaVersion: 11,
            migrationBlock: { migration, oldSchemaVersion in
                if oldSchemaVersion < 1 {
                    // 未来版本升级时的迁移逻辑
                }
            },
            deleteRealmIfMigrationNeeded: false
        )
        config.fileURL = localRealmPath
//        config.objectTypes = [
//            DBWord.self,
//            DBWordDetail.self,
//            DBSubdetail.self,
//            DBExample.self,
//            DBConjugate.self,
//            DBFormData.self,
//            DBFormRow.self,
//            DBRelatedWord.self,
//            DBSynonym.self,
//            
//            DictionaryVersion.self,
//            DictEntry.self,
//            Definition.self,
//            Example.self,
//            UserSettings.self,
//            SearchHistoryItem.self,
//            Folder.self,
//            FavoriteItem.self,
//            User.self,
//            AuthToken.self,
//            SyncStatus.self,
//            SyncOperation.self,
//            SyncRecord.self,
//            SyncConflict.self,
//            FavoriteCategory.self,
//            LearningProgress.self,
//        ]
        
        Realm.Configuration.defaultConfiguration = config
        
        // 打印Realm文件位置，便于调试
        if let realmURL = config.fileURL {
            print("Realm数据库位置: \(realmURL)")
        }
    }
    
    // 在事务中执行写操作
    func write<T>(_ block: (Realm) throws -> T) -> Result<T, Error> {
        do {
            let realm = try self.realm()
            var result: T!
            
            try realm.write {
                result = try block(realm)
            }
            
            return .success(result)
        } catch {
            return .failure(error)
        }
    }
    
    // 异步写操作，返回Publisher
    func writeAsync<T>(_ block: @escaping (Realm) throws -> T) -> AnyPublisher<T, Error> {
        return Future<T, Error> { promise in
            DispatchQueue.global(qos: .background).async {
                let result = self.write(block)
                
                DispatchQueue.main.async {
                    switch result {
                    case .success(let value):
                        promise(.success(value))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // 清除特定类型的所有对象
    func deleteAll<T: Object>(_ type: T.Type) -> AnyPublisher<Void, Error> {
        return writeAsync { realm in
            let objects = realm.objects(type)
            realm.delete(objects)
        }
    }
    
    // 导入JSON数据到Realm
    func importJSON<T: Object & Decodable>(type: T.Type, jsonData: Data) -> AnyPublisher<Int, Error> {
        return Future<Int, Error> { promise in
            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                guard let jsonArray = json as? [[String: Any]] else {
                    throw NSError(domain: "RealmManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "无效的JSON格式"])
                }
                
                var importedCount = 0
                
                let realm = try self.realm()
                try realm.write {
                    for item in jsonArray {
                        let data = try JSONSerialization.data(withJSONObject: item, options: [])
                        let object = try JSONDecoder().decode(type, from: data)
                        realm.add(object, update: .modified)
                        importedCount += 1
                    }
                }
                
                promise(.success(importedCount))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}
