//
//  SyncConflictResolver.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import RealmSwift
import CloudKit
import Combine

class SyncConflictResolver {
    // MARK: - Properties
    
    private let realm: Realm
    private let cloudKitService: CloudKitService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(cloudKitService: CloudKitService, realm: Realm? = nil) {
        self.cloudKitService = cloudKitService
        
        // 如果没有提供Realm实例，则创建一个默认的
        if let realm = realm {
            self.realm = realm
        } else {
            do {
                self.realm = try Realm()
            } catch {
                fatalError("无法初始化Realm: \(error)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    // 解决同步冲突
    func resolveConflict(conflict: SyncConflict, resolution: ConflictResolution) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            switch resolution {
            case .useLocal:
                // 使用本地版本
                self.resolveUsingLocalVersion(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case .useRemote:
                // 使用远程版本
                self.resolveUsingRemoteVersion(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case .merge:
                // 合并两个版本
                self.resolveMergingVersions(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }.eraseToAnyPublisher()
    }
    
    // 检测冲突
    func detectConflicts(localObject: SyncableObject, remoteRecord: CKRecord) -> Bool {
        // 如果本地对象有CloudKit系统字段，说明它之前已经同步过
        guard let cloudKitSystemFields = localObject.cloudKitSystemFields else {
            // 没有系统字段，说明是首次同步，不存在冲突
            return false
        }
        
        // 解码本地存储的CloudKit记录
        guard let localRecord = try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKRecord.self, from: cloudKitSystemFields) else {
            // 解码失败，无法比较，保守起见认为有冲突
            return true
        }
        
        // 比较修改时间
        if let localModTime = localRecord.modificationDate,
           let remoteModTime = remoteRecord.modificationDate {
            // 如果远程修改时间晚于本地修改时间，且本地有未同步的更改，则存在冲突
            return remoteModTime > localModTime && localObject.syncStatus == SyncStatus.pendingUpload.rawValue
        }
        
        // 无法确定，保守起见认为有冲突
        return true
    }
    
    // 创建冲突记录
    func createConflictRecord(recordType: String, recordId: String, localObject: Any, remoteRecord: CKRecord) -> SyncConflict {
        let conflict = SyncConflict()
        conflict.recordType = recordType
        conflict.recordId = recordId
        
        // 设置修改时间
        if let localObj = localObject as? SyncableObject {
            conflict.localModificationTime = localObj.lastModified
        } else {
            conflict.localModificationTime = Date()
        }
        
        conflict.remoteModificationTime = remoteRecord.modificationDate ?? Date()
        
        // 序列化数据
        do {
            let localData = try JSONEncoder().encode(localObject)
            conflict.localDataJson = String(data: localData, encoding: .utf8) ?? "{}"
            
            let remoteData = try JSONEncoder().encode(remoteRecord)
            conflict.remoteDataJson = String(data: remoteData, encoding: .utf8) ?? "{}"
        } catch {
            print("序列化冲突数据失败: \(error)")
            conflict.localDataJson = "{}"
            conflict.remoteDataJson = "{}"
        }
        
        return conflict
    }
    
    // MARK: - Private Methods
    
    // 使用本地版本解决冲突
    private func resolveUsingLocalVersion(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 根据记录类型获取本地对象
            switch conflict.recordType {
            case CloudKitService.folderRecordType:
                // 处理收藏夹冲突
                self.resolveLocalFolderConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case CloudKitService.favoriteItemRecordType:
                // 处理收藏项冲突
                self.resolveLocalFavoriteItemConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case CloudKitService.userSettingsRecordType:
                // 处理用户设置冲突
                self.resolveLocalUserSettingsConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            default:
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "未知的记录类型: \(conflict.recordType)"])))
            }
        }.eraseToAnyPublisher()
    }
    
    // 使用远程版本解决冲突
    private func resolveUsingRemoteVersion(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 根据记录类型获取远程对象
            switch conflict.recordType {
            case CloudKitService.folderRecordType:
                // 处理收藏夹冲突
                self.resolveRemoteFolderConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case CloudKitService.favoriteItemRecordType:
                // 处理收藏项冲突
                self.resolveRemoteFavoriteItemConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case CloudKitService.userSettingsRecordType:
                // 处理用户设置冲突
                self.resolveRemoteUserSettingsConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            default:
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "未知的记录类型: \(conflict.recordType)"])))
            }
        }.eraseToAnyPublisher()
    }
    
    // 合并两个版本解决冲突
    private func resolveMergingVersions(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 根据记录类型合并对象
            switch conflict.recordType {
            case CloudKitService.folderRecordType:
                // 处理收藏夹冲突
                self.resolveMergeFolderConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            case CloudKitService.favoriteItemRecordType:
                // 处理收藏项冲突
                self.resolveMergeFavoriteItemConflict(conflict: conflict)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { success in
                            promise(.success(success))
                        }
                    )
                    .store(in: &self.cancellables)
                
            default:
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "未知的记录类型: \(conflict.recordType)"])))
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - 具体冲突解决实现
    
    // 使用本地版本解决收藏夹冲突
    private func resolveLocalFolderConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let folder = try? JSONDecoder().decode(FolderDomain.self, from: localData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析本地收藏夹数据"])))
                return
            }
            
            // 2. 创建CloudKit记录
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let record = CKRecord(recordType: CloudKitService.folderRecordType, recordID: recordID)
            record["name"] = folder.name as CKRecordValue
            record["createdAt"] = folder.createdAt as CKRecordValue
            record["modifiedAt"] = Date() as CKRecordValue
            
            // 3. 上传到CloudKit
            self.cloudKitService.saveRecord(record)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 使用本地版本解决收藏项冲突
    private func resolveLocalFavoriteItemConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let favoriteItem = try? JSONDecoder().decode(FavoriteItemDomain.self, from: localData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析本地收藏项数据"])))
                return
            }
            
            // 2. 创建CloudKit记录
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let record = CKRecord(recordType: CloudKitService.favoriteItemRecordType, recordID: recordID)
            record["wordId"] = favoriteItem.wordId as CKRecordValue
            record["word"] = favoriteItem.word as CKRecordValue
            record["reading"] = favoriteItem.reading as CKRecordValue
            record["meaning"] = favoriteItem.meaning as CKRecordValue
            record["note"] = favoriteItem.note as CKRecordValue
            record["addedAt"] = favoriteItem.addedAt as CKRecordValue
            record["modifiedAt"] = Date() as CKRecordValue
            
            // 3. 上传到CloudKit
            self.cloudKitService.saveRecord(record)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 使用本地版本解决用户设置冲突
    private func resolveLocalUserSettingsConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let userSettings = try? JSONDecoder().decode(UserSettingsDomain.self, from: localData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析本地用户设置数据"])))
                return
            }
            
            // 2. 创建CloudKit记录
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let record = CKRecord(recordType: CloudKitService.userSettingsRecordType, recordID: recordID)
            record["darkMode"] = userSettings.darkMode as CKRecordValue
            record["fontSize"] = userSettings.fontSize as CKRecordValue
            record["autoSync"] = userSettings.autoSync as CKRecordValue
            record["modifiedAt"] = Date() as CKRecordValue
            
            // 3. 上传到CloudKit
            self.cloudKitService.saveRecord(record)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 使用远程版本解决收藏夹冲突
    private func resolveRemoteFolderConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取远程数据
            guard let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程收藏夹数据"])))
                return
            }
            
            // 2. 解析远程记录
            guard let record = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程CloudKit记录"])))
                return
            }
            
            // 3. 更新本地数据
            // 这里需要根据实际的Realm模型进行更新
            // 简化实现，实际项目中需要根据具体的数据模型进行实现
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // 使用远程版本解决收藏项冲突
    private func resolveRemoteFavoriteItemConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取远程数据
            guard let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程收藏项数据"])))
                return
            }
            
            // 2. 解析远程记录
            guard let record = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程CloudKit记录"])))
                return
            }
            
            // 3. 更新本地数据
            // 这里需要根据实际的Realm模型进行更新
            // 简化实现，实际项目中需要根据具体的数据模型进行实现
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // 使用远程版本解决用户设置冲突
    private func resolveRemoteUserSettingsConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取远程数据
            guard let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程用户设置数据"])))
                return
            }
            
            // 2. 解析远程记录
            guard let record = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析远程CloudKit记录"])))
                return
            }
            
            // 3. 更新本地数据
            // 这里需要根据实际的Realm模型进行更新
            // 简化实现，实际项目中需要根据具体的数据模型进行实现
            promise(.success(true))
        }.eraseToAnyPublisher()
    }
    
    // 合并解决收藏夹冲突
    private func resolveMergeFolderConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地和远程数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突数据"])))
                return
            }
            
            // 2. 解析数据
            guard let localFolder = try? JSONDecoder().decode(FolderDomain.self, from: localData),
                  let remoteRecord = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突对象"])))
                return
            }
            
            // 3. 合并数据
            // 这里采用简单的合并策略：保留最新的名称，但合并其他属性
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let mergedRecord = CKRecord(recordType: CloudKitService.folderRecordType, recordID: recordID)
            
            // 如果本地修改时间更晚，使用本地名称，否则使用远程名称
            if conflict.localModificationTime > conflict.remoteModificationTime {
                mergedRecord["name"] = localFolder.name as CKRecordValue
            } else {
                mergedRecord["name"] = remoteRecord["name"]
            }
            
            // 使用原始的创建时间
            mergedRecord["createdAt"] = remoteRecord["createdAt"]
            // 设置新的修改时间
            mergedRecord["modifiedAt"] = Date() as CKRecordValue
            
            // 4. 保存合并后的记录
            self.cloudKitService.saveRecord(mergedRecord)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        // 5. 更新本地数据
                        // 这里需要根据实际的Realm模型进行更新
                        // 简化实现，实际项目中需要根据具体的数据模型进行实现
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 合并解决收藏项冲突
    private func resolveMergeFavoriteItemConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地和远程数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突数据"])))
                return
            }
            
            // 2. 解析数据
            guard let localItem = try? JSONDecoder().decode(FavoriteItemDomain.self, from: localData),
                  let remoteRecord = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突对象"])))
                return
            }
            
            // 3. 合并数据
            // 对于收藏项，主要是合并笔记内容
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let mergedRecord = CKRecord(recordType: CloudKitService.favoriteItemRecordType, recordID: recordID)
            
            // 保持基本信息不变
            mergedRecord["wordId"] = localItem.wordId as CKRecordValue
            mergedRecord["word"] = localItem.word as CKRecordValue
            mergedRecord["reading"] = localItem.reading as CKRecordValue
            mergedRecord["meaning"] = localItem.meaning as CKRecordValue
            mergedRecord["addedAt"] = localItem.addedAt as CKRecordValue
            
            // 合并笔记内容
            let localNote = localItem.note ?? ""
            let remoteNote = remoteRecord["note"] as? String ?? ""
            
            if localNote.isEmpty && !remoteNote.isEmpty {
                // 如果本地笔记为空但远程有笔记，使用远程笔记
                mergedRecord["note"] = remoteNote as CKRecordValue
            } else if !localNote.isEmpty && remoteNote.isEmpty {
                // 如果远程笔记为空但本地有笔记，使用本地笔记
                mergedRecord["note"] = localNote as CKRecordValue
            } else if localNote != remoteNote {
                // 如果两者都有笔记且不同，合并它们
                let mergedNote = "【本地笔记】\n\(localNote)\n\n【远程笔记】\n\(remoteNote)"
                mergedRecord["note"] = mergedNote as CKRecordValue
            } else {
                // 如果笔记相同，直接使用
                mergedRecord["note"] = localNote as CKRecordValue
            }
            
            // 设置新的修改时间
            mergedRecord["modifiedAt"] = Date() as CKRecordValue
            
            // 4. 保存合并后的记录
            self.cloudKitService.saveRecord(mergedRecord)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        // 5. 更新本地数据
                        // 这里需要根据实际的Realm模型进行更新
                        // 简化实现，实际项目中需要根据具体的数据模型进行实现
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
    
    // 合并解决用户设置冲突
    private func resolveMergeUserSettingsConflict(conflict: SyncConflict) -> AnyPublisher<Bool, Error> {
        return Future<Bool, Error> { [weak self] promise in
            guard let self = self else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 500, userInfo: [NSLocalizedDescriptionKey: "Resolver instance is nil"])))
                return
            }
            
            // 1. 获取本地和远程数据
            guard let localData = conflict.localDataJson.data(using: .utf8),
                  let remoteData = conflict.remoteDataJson.data(using: .utf8) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突数据"])))
                return
            }
            
            // 2. 解析数据
            guard let localSettings = try? JSONDecoder().decode(UserSettingsDomain.self, from: localData),
                  let remoteRecord = try? JSONDecoder().decode(CKRecord.self, from: remoteData) else {
                promise(.failure(NSError(domain: "SyncConflictResolver", code: 400, userInfo: [NSLocalizedDescriptionKey: "无法解析冲突对象"])))
                return
            }
            
            // 3. 合并数据
            // 对于用户设置，采用最新优先的策略
            let recordID = CKRecord.ID(recordName: conflict.recordId)
            let mergedRecord = CKRecord(recordType: CloudKitService.userSettingsRecordType, recordID: recordID)
            
            // 如果本地修改时间更晚，使用本地设置，否则使用远程设置
            if conflict.localModificationTime > conflict.remoteModificationTime {
                mergedRecord["darkMode"] = localSettings.darkMode as CKRecordValue
                mergedRecord["fontSize"] = localSettings.fontSize as CKRecordValue
                mergedRecord["autoSync"] = localSettings.autoSync as CKRecordValue
            } else {
                mergedRecord["darkMode"] = remoteRecord["darkMode"]
                mergedRecord["fontSize"] = remoteRecord["fontSize"]
                mergedRecord["autoSync"] = remoteRecord["autoSync"]
            }
            
            // 设置新的修改时间
            mergedRecord["modifiedAt"] = Date() as CKRecordValue
            
            // 4. 保存合并后的记录
            self.cloudKitService.saveRecord(mergedRecord)
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            promise(.failure(error))
                        }
                    },
                    receiveValue: { _ in
                        // 5. 更新本地数据
                        // 这里需要根据实际的Realm模型进行更新
                        // 简化实现，实际项目中需要根据具体的数据模型进行实现
                        promise(.success(true))
                    }
                )
                .store(in: &self.cancellables)
        }.eraseToAnyPublisher()
    }
}