import Foundation
import RealmSwift
import Combine

class RealmManager {
    // MARK: - 单例模式
    static let shared = RealmManager()
    
    // MARK: - 属性
    private var realm: Realm?
    private let configuration: Realm.Configuration
    private let schemaVersion: UInt64 = 1
    
    // MARK: - 初始化
    private init() {
        // 配置Realm数据库
        configuration = Realm.Configuration(
            schemaVersion: schemaVersion,
            migrationBlock: { migration, oldSchemaVersion in
                // 处理数据库迁移
                if oldSchemaVersion < self.schemaVersion {
                    // 在这里处理模型变更
                }
            },
            deleteRealmIfMigrationNeeded: false // 生产环境设为false
        )
        
        // 设置默认配置
        Realm.Configuration.defaultConfiguration = configuration
        
        do {
            realm = try Realm()
            print("Realm数据库初始化成功: \(realm!.configuration.fileURL?.absoluteString ?? "未知路径")")
        } catch {
            print("Realm数据库初始化失败: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 公共方法
    
    /// 获取Realm实例
    func getRealm() -> Realm? {
        if let realm = realm {
            return realm
        }
        
        do {
            let realm = try Realm()
            return realm
        } catch {
            print("获取Realm实例失败: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 在事务中执行写操作
    func write(_ block: @escaping (Realm) -> Void) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let realm = self.getRealm() else {
                promise(.failure(NSError(domain: "RealmManager", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm实例"])))
                return
            }
            
            do {
                try realm.write {
                    block(realm)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 删除Realm数据库文件
    func deleteRealmFile() -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let fileURL = self.realm?.configuration.fileURL else {
                promise(.failure(NSError(domain: "RealmManager", code: 1002, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm文件路径"])))
                return
            }
            
            do {
                try FileManager.default.removeItem(at: fileURL)
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 获取Realm文件大小（单位：字节）
    func getRealmFileSize() -> Int {
        guard let fileURL = realm?.configuration.fileURL else { return 0 }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int {
                return fileSize
            }
        } catch {
            print("获取Realm文件大小失败: \(error.localizedDescription)")
        }
        
        return 0
    }
    
    /// 备份Realm数据库
    func backupRealm() -> AnyPublisher<URL, Error> {
        return Future<URL, Error> { promise in
            guard let fileURL = self.realm?.configuration.fileURL else {
                promise(.failure(NSError(domain: "RealmManager", code: 1003, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm文件路径"])))
                return
            }
            
            let backupFolderURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Backups", isDirectory: true)
            
            do {
                // 创建备份文件夹（如果不存在）
                if !FileManager.default.fileExists(atPath: backupFolderURL.path) {
                    try FileManager.default.createDirectory(at: backupFolderURL, withIntermediateDirectories: true)
                }
                
                // 创建备份文件名（使用当前日期时间）
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
                let dateString = dateFormatter.string(from: Date())
                let backupFileURL = backupFolderURL.appendingPathComponent("japanese_app_backup_\(dateString).realm")
                
                // 复制Realm文件到备份位置
                try FileManager.default.copyItem(at: fileURL, to: backupFileURL)
                
                promise(.success(backupFileURL))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
    
    /// 从备份恢复Realm数据库
    func restoreFromBackup(backupURL: URL) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            guard let fileURL = self.realm?.configuration.fileURL else {
                promise(.failure(NSError(domain: "RealmManager", code: 1004, userInfo: [NSLocalizedDescriptionKey: "无法获取Realm文件路径"])))
                return
            }
            
            do {
                // 关闭当前Realm实例
                self.realm?.close()
                self.realm = nil
                
                // 删除当前Realm文件
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    try FileManager.default.removeItem(at: fileURL)
                }
                
                // 复制备份文件到Realm文件位置
                try FileManager.default.copyItem(at: backupURL, to: fileURL)
                
                // 重新初始化Realm实例
                self.realm = try Realm()
                
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }
}