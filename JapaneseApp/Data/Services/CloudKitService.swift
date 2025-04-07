//
//  CloudKitService.swift
//  JapaneseApp
//
//  Created by Modi on 2023/10/15.
//

import Foundation
import CloudKit
import Combine

class CloudKitService {
    // MARK: - Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let sharedDatabase: CKDatabase
    
    // 记录类型常量
    static let folderRecordType = "Folder"
    static let favoriteItemRecordType = "FavoriteItem"
    static let userRecordType = "User"
    static let userSettingsRecordType = "UserSettings"
    
    // MARK: - Initialization
    
    init(containerIdentifier: String = "iCloud.com.modi.japaneseapp") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.privateDatabase = container.privateCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }
    
    // MARK: - User Account Status
    
    func checkAccountStatus() -> AnyPublisher<CKAccountStatus, Error> {
        return Future<CKAccountStatus, Error> { promise in
            self.container.accountStatus { status, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(status))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Record Operations
    
    func fetchRecord(recordType: String, recordID: String) -> AnyPublisher<CKRecord, Error> {
        return Future<CKRecord, Error> { promise in
            let recordID = CKRecord.ID(recordName: recordID)
            self.privateDatabase.fetch(withRecordID: recordID) { record, error in
                if let error = error {
                    promise(.failure(error))
                } else if let record = record {
                    promise(.success(record))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Record not found"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func saveRecord(_ record: CKRecord) -> AnyPublisher<CKRecord, Error> {
        return Future<CKRecord, Error> { promise in
            self.privateDatabase.save(record) { savedRecord, error in
                if let error = error {
                    promise(.failure(error))
                } else if let savedRecord = savedRecord {
                    promise(.success(savedRecord))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to save record"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteRecord(recordType: String, recordID: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            let recordID = CKRecord.ID(recordName: recordID)
            self.privateDatabase.delete(withRecordID: recordID) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func performQuery(recordType: String, predicate: NSPredicate = NSPredicate(value: true), sortDescriptors: [NSSortDescriptor]? = nil) -> AnyPublisher<[CKRecord], Error> {
        return Future<[CKRecord], Error> { promise in
            let query = CKQuery(recordType: recordType, predicate: predicate)
            query.sortDescriptors = sortDescriptors
            
            self.privateDatabase.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    promise(.failure(error))
                } else if let records = records {
                    promise(.success(records))
                } else {
                    promise(.success([]))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Batch Operations
    
    func saveRecords(_ records: [CKRecord]) -> AnyPublisher<[CKRecord], Error> {
        return Future<[CKRecord], Error> { promise in
            let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
            operation.savePolicy = .changedKeys
            operation.qualityOfService = .userInitiated
            
            var savedRecords: [CKRecord] = []
            var operationError: Error?
            
            operation.perRecordCompletionBlock = { record, error in
                if let error = error {
                    operationError = error
                } else if let record = record {
                    savedRecords.append(record)
                }
            }
            
            operation.modifyRecordsCompletionBlock = { _, _, error in
                if let error = error {
                    promise(.failure(error))
                } else if let operationError = operationError {
                    promise(.failure(operationError))
                } else {
                    promise(.success(savedRecords))
                }
            }
            
            self.privateDatabase.add(operation)
        }.eraseToAnyPublisher()
    }
    
    func deleteRecords(recordIDs: [String]) -> AnyPublisher<[String], Error> {
        return Future<[String], Error> { promise in
            let recordIDs = recordIDs.map { CKRecord.ID(recordName: $0) }
            let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
            operation.qualityOfService = .userInitiated
            
            var deletedRecordIDs: [String] = []
            var operationError: Error?
            
            operation.perRecordCompletionBlock = { recordID, error in
                if let error = error {
                    operationError = error
                } else if let recordID = recordID {
                    deletedRecordIDs.append(recordID.recordName)
                }
            }
            
            operation.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
                if let error = error {
                    promise(.failure(error))
                } else if let operationError = operationError {
                    promise(.failure(operationError))
                } else {
                    promise(.success(deletedRecordIDs?.map { $0.recordName } ?? []))
                }
            }
            
            self.privateDatabase.add(operation)
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Subscription Operations
    
    func createSubscription(recordType: String, predicate: NSPredicate = NSPredicate(value: true), subscriptionID: String, options: CKQuerySubscription.Options = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]) -> AnyPublisher<CKSubscription, Error> {
        return Future<CKSubscription, Error> { promise in
            let subscription = CKQuerySubscription(recordType: recordType, predicate: predicate, subscriptionID: subscriptionID, options: options)
            
            let notificationInfo = CKSubscription.NotificationInfo()
            notificationInfo.shouldSendContentAvailable = true
            subscription.notificationInfo = notificationInfo
            
            self.privateDatabase.save(subscription) { subscription, error in
                if let error = error {
                    promise(.failure(error))
                } else if let subscription = subscription {
                    promise(.success(subscription))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create subscription"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func deleteSubscription(subscriptionID: String) -> AnyPublisher<Void, Error> {
        return Future<Void, Error> { promise in
            self.privateDatabase.delete(withSubscriptionID: subscriptionID) { _, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Zone Operations
    
    func createCustomZone(zoneID: CKRecordZone.ID) -> AnyPublisher<CKRecordZone, Error> {
        return Future<CKRecordZone, Error> { promise in
            let zone = CKRecordZone(zoneID: zoneID)
            self.privateDatabase.save(zone) { zone, error in
                if let error = error {
                    promise(.failure(error))
                } else if let zone = zone {
                    promise(.success(zone))
                } else {
                    promise(.failure(NSError(domain: "CloudKitService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to create zone"])))
                }
            }
        }.eraseToAnyPublisher()
    }
    
    // MARK: - Change Token Operations
    
    func fetchChanges(recordType: String, databaseTokenKey: String, recordZoneTokenKey: String? = nil) -> AnyPublisher<([RecordChange], Data?), Error> {
        return Future<([RecordChange], Data?), Error> { promise in
            // 获取上次同步的服务器更改令牌
            let previousServerChangeToken = UserDefaults.standard.data(forKey: databaseTokenKey).flatMap { try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: $0) }
            
            // 创建变更操作
            let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousServerChangeToken)
            
            var changedZoneIDs: [CKRecordZone.ID] = []
            var deletedZoneIDs: [CKRecordZone.ID] = []
            var newDatabaseChangeToken: CKServerChangeToken?
            
            // 设置回调
            operation.recordZoneWithIDChangedBlock = { zoneID in
                changedZoneIDs.append(zoneID)
            }
            
            operation.recordZoneWithIDWasDeletedBlock = { zoneID in
                deletedZoneIDs.append(zoneID)
            }
            
            operation.changeTokenUpdatedBlock = { token in
                newDatabaseChangeToken = token
            }
            
            operation.fetchDatabaseChangesCompletionBlock = { token, moreComing, error in
                if let error = error {
                    promise(.failure(error))
                    return
                }
                
                newDatabaseChangeToken = token
                
                // 如果没有变更的区域，直接返回空结果
                if changedZoneIDs.isEmpty {
                    if let token = newDatabaseChangeToken, let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                        UserDefaults.standard.set(tokenData, forKey: databaseTokenKey)
                    }
                    promise(.success(([], newDatabaseChangeToken?.data)))
                    return
                }
                
                // 获取区域内的变更
                self.fetchZoneChanges(recordType: recordType, zoneIDs: changedZoneIDs, recordZoneTokenKey: recordZoneTokenKey) { result in
                    switch result {
                    case .success((let changes, _)):
                        // 保存新的数据库变更令牌
                        if let token = newDatabaseChangeToken, let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) {
                            UserDefaults.standard.set(tokenData, forKey: databaseTokenKey)
                        }
                        promise(.success((changes, newDatabaseChangeToken?.data)))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
            
            self.privateDatabase.add(operation)
        }.eraseToAnyPublisher()
    }
    
    private func fetchZoneChanges(recordType: String, zoneIDs: [CKRecordZone.ID], recordZoneTokenKey: String?, completion: @escaping (Result<([RecordChange], [CKRecordZone.ID: CKServerChangeToken]), Error>) -> Void) {
        // 获取每个区域的上次同步令牌
        var previousChangeTokens: [CKRecordZone.ID: CKServerChangeToken] = [:]
        
        if let tokenKey = recordZoneTokenKey, let tokensData = UserDefaults.standard.data(forKey: tokenKey) {
            if let tokens = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, CKRecordZone.ID.self, CKServerChangeToken.self], from: tokensData) as? [CKRecordZone.ID: CKServerChangeToken] {
                previousChangeTokens = tokens
            }
        }
        
        // 创建区域变更操作的配置
        let optionsByRecordZoneID = zoneIDs.reduce(into: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()) { result, zoneID in
            let token = previousChangeTokens[zoneID]
            let config = CKFetchRecordZoneChangesOperation.ZoneConfiguration(previousServerChangeToken: token, resultsLimit: nil, desiredKeys: nil)
            result[zoneID] = config
        }
        
        // 创建区域变更操作
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID)
        operation.fetchAllChanges = true
        
        var changes: [RecordChange] = []
        var changeTokens: [CKRecordZone.ID: CKServerChangeToken] = [:]
        
        // 设置回调
        operation.recordChangedBlock = { record in
            if record.recordType == recordType {
                changes.append(RecordChange(recordType: record.recordType, recordId: record.recordID.recordName, changeType: .updated, record: record))
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            if recordType == recordType {
                changes.append(RecordChange(recordType: recordType, recordId: recordID.recordName, changeType: .deleted, record: nil))
            }
        }
        
        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, token, _ in
            if let token = token {
                changeTokens[zoneID] = token
            }
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneID, token, _, _, error in
            if let token = token {
                changeTokens[zoneID] = token
            }
        }
        
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 保存新的区域变更令牌
            if let tokenKey = recordZoneTokenKey, !changeTokens.isEmpty {
                if let tokensData = try? NSKeyedArchiver.archivedData(withRootObject: changeTokens, requiringSecureCoding: true) {
                    UserDefaults.standard.set(tokensData, forKey: tokenKey)
                }
            }
            
            completion(.success((changes, changeTokens)))
        }
        
        self.privateDatabase.add(operation)
    }
    
    // MARK: - Error Handling
    
    func handleCloudKitError(_ error: Error) -> Error {
        let nsError = error as NSError
        
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "用户未登录iCloud，请在设置中登录"])
            case .quotaExceeded:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "iCloud存储空间已满，请清理空间"])
            case .networkFailure, .networkUnavailable, .serviceUnavailable, .serverResponseLost:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "网络连接失败，请检查网络设置"])
            case .zoneBusy, .requestRateLimited:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "服务器繁忙，请稍后再试"])
            case .incompatibleVersion:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "应用版本不兼容，请更新应用"])
            case .badDatabase, .internalError:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "iCloud服务出错，请稍后再试"])
            case .assetFileNotFound, .assetFileModified:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "文件资源错误，请重试"])
            case .participantMayNeedVerification:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "需要验证iCloud账户，请在设置中检查"])
            default:
                return NSError(domain: "CloudKitService", code: ckError.errorCode, userInfo: [NSLocalizedDescriptionKey: "iCloud同步错误: \(ckError.localizedDescription)"])
            }
        }
        
        return nsError
    }
}