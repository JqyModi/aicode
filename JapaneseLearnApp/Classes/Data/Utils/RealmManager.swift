//
//  RealmManager.swift
//  JapaneseLearnApp
//
//  Created by J.qy on 2025/4/18.
//

import Foundation
import RealmSwift
import Combine
import ZIPFoundation

class RealmManager {
    // 单例模式
    static let shared = RealmManager()
    
    private let githubMyRealmDBToken = "Bearer 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"
    private var cancellables = Set<AnyCancellable>()
    /// **GitHub Releases API (获取最新版本)**
    private let releasesAPI = "https://api.github.com/repos/JqyModi/my-realm-db/releases/latest"
    
    /// **远程 Realm ZIP 数据库文件 URL (GitHub Releases 直链)**
    private let realmDownloadBaseURL = "https://github.com/JqyModi/my-realm-db/releases/download"
    
    /// **本地 ZIP 存储路径**
    private var localZipPath: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("word-core.realm.zip")
    }
    
    /// **本地存储的数据库版本**
    private var localVersion: String? {
        get { UserDefaults.standard.string(forKey: "realm_db_version") }
        set { UserDefaults.standard.setValue(newValue, forKey: "realm_db_version") }
    }
    
    /// **本地 Realm 存储路径**
    private var localRealmPath: URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("realm")
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        return directory.appendingPathComponent("word-core.realm")
    }
    
    private init() {
//        copyBundleRealmToDocuments()
        checkAndUpdateDatabase()
        
        if FileManager.default.fileExists(atPath: localRealmPath.path) {
            print("Realm数据库已存在于沙盒中")
            setupRealm()
        }
    }
    
    // 将Bundle中的Realm文件复制到沙盒中
//    private func copyBundleRealmToDocuments() {
//        let fileManager = FileManager.default
//
//        // 检查目标文件是否已存在
//        if fileManager.fileExists(atPath: localRealmPath.path) {
//            print("Realm文件已存在于沙盒中，无需复制")
//            return
//        }
//
//        // 获取Bundle中的Realm文件路径
//        guard let bundleRealmPath = Bundle.main.path(forResource: "word-core", ofType: "realm") else {
//            print("在Bundle中找不到Realm文件")
//            return
//        }
//
//        do {
//            // 创建目录（如果不存在）
//            let directory = localRealmPath.deletingLastPathComponent()
//            if !fileManager.fileExists(atPath: directory.path) {
//                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
//            }
//
//            // 复制文件
//            try fileManager.copyItem(atPath: bundleRealmPath, toPath: localRealmPath.path)
//            print("成功将Realm文件从Bundle复制到沙盒: \(localRealmPath.path)")
//        } catch {
//            print("复制Realm文件失败: \(error.localizedDescription)")
//        }
//    }
    
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

extension RealmManager {
    /// **检查并更新 Realm 数据库**
    func checkAndUpdateDatabase() {
        getLatestVersion()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("❌ 获取最新数据库版本失败: \(error)")
                }
            }, receiveValue: { [weak self] latestVersion in
                guard let self = self else { return }
                
                // 1️⃣ **版本比较**：如果是相同版本，直接返回
                if self.localVersion == latestVersion {
                    print("✅ 当前数据库已是最新版本: \(latestVersion)，无需更新")
                    setupRealm()
                    return
                }
                
                // 2️⃣ **版本更新**：下载 & 解压
                print("⬇️ 发现新版本 \(latestVersion)，开始更新数据库...")
                self.downloadAndUnzipRealmDatabase(version: latestVersion)
            })
            .store(in: &cancellables)
    }
    
    /// **获取最新数据库版本 (GitHub Releases API)**
    private func getLatestVersion() -> AnyPublisher<String, APIError> {
        NetworkManager.shared.requestJSON(urlString: releasesAPI, token: githubMyRealmDBToken)
            .compactMap { json -> String? in
                return json["tag_name"] as? String  // GitHub Release 版本号
            }
            .mapError { error in APIError.unknown(error) }
            .eraseToAnyPublisher()
    }
    
    /// **下载并解压 Realm 数据库**
    private func downloadAndUnzipRealmDatabase(version: String) {
        let downloadURL = "\(realmDownloadBaseURL)/\(version)/word-core.realm.zip"
        
        NetworkManager.shared.requestData(urlString: downloadURL)
            .sink(receiveCompletion: { completionStatus in
                if case .failure(let error) = completionStatus {
                    print("❌ 下载数据库失败: \(error)")
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                do {
                    // 1️⃣ **写入 ZIP 文件**
                    try data.write(to: self.localZipPath)
                    
                    // 2️⃣ **解压**
                    try self.unzipRealmFile()
                    
                    // 3️⃣ **更新版本号**
                    self.localVersion = version
                    print("✅ 数据库更新成功! 版本: \(version)")
                    setupRealm()
                } catch {
                    print("❌ 解压失败: \(error)")
                }
            })
            .store(in: &cancellables)
    }
    
    /// **解压 ZIP 并获取 `.realm` 文件**
    private func unzipRealmFile() throws {
        let fileManager = FileManager.default
        
        // 确保 ZIP 文件存在
        guard fileManager.fileExists(atPath: localZipPath.path) else {
            throw APIError.fileNotFound
        }
        
        // 目标解压目录
        let destinationURL = localRealmPath.deletingLastPathComponent()
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(atPath: destinationURL.path)
        }
        
        // 解压 ZIP
        try fileManager.unzipItem(at: localZipPath, to: destinationURL)
        
        // 删除 ZIP
        try fileManager.removeItem(at: localZipPath)
        
        print("✅ 解压完成，Realm 数据库路径: \(localRealmPath.path)")
    }
}
