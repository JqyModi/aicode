//
//  SyncService.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine

class SyncService: SyncServiceProtocol {
    // MARK: - 属性
    private let syncRepository: SyncDataRepositoryProtocol
    
    // MARK: - 初始化
    init(syncRepository: SyncDataRepositoryProtocol) {
        self.syncRepository = syncRepository
    }
    
    // MARK: - SyncServiceProtocol 实现
    func getSyncStatus() -> AnyPublisher<SyncStatusInfoDomain, SyncErrorDomain> {
        return syncRepository.getSyncStatus()
            .map { entity -> SyncStatusInfoDomain in
                return self.mapToSyncStatusInfoDomain(from: entity)
            }
            .mapError { error -> SyncErrorDomain in
                return self.mapToSyncError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func startSync(type: SyncTypeDomain) -> AnyPublisher<SyncOperationInfoDomain, SyncErrorDomain> {
        let entityType = mapToSyncTypeEntity(from: type)
        
        return syncRepository.startSync(type: entityType)
            .map { entity -> SyncOperationInfoDomain in
                return self.mapToSyncOperationInfoDomain(from: entity)
            }
            .mapError { error -> SyncErrorDomain in
                return self.mapToSyncError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfoDomain, SyncErrorDomain> {
        return syncRepository.getSyncProgress(operationId: operationId)
            .map { entity -> SyncProgressInfoDomain in
                return self.mapToSyncProgressInfoDomain(from: entity)
            }
            .mapError { error -> SyncErrorDomain in
                return self.mapToSyncError(error)
            }
            .eraseToAnyPublisher()
    }
    
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolutionDomain) -> AnyPublisher<Bool, SyncErrorDomain> {
        let entityResolution = mapToConflictResolutionEntity(from: resolution)
        
        return syncRepository.resolveSyncConflict(conflictId: conflictId, resolution: entityResolution)
            .mapError { error -> SyncErrorDomain in
                return self.mapToSyncError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // MARK: - 私有映射方法
    private func mapToSyncStatusInfoDomain(from entity: SyncStatusEntity) -> SyncStatusInfoDomain {
        return SyncStatusInfoDomain(
            lastSyncTime: entity.lastSyncTime,
            pendingChanges: entity.pendingChanges,
            syncStatus: entity.syncStatus,
            availableOffline: entity.availableOffline
        )
    }
    
    private func mapToSyncOperationInfoDomain(from entity: SyncOperationEntity) -> SyncOperationInfoDomain {
        return SyncOperationInfoDomain(
            syncId: entity.syncId,
            startedAt: entity.startedAt,
            status: entity.status,
            estimatedTimeRemaining: entity.estimatedTimeRemaining
        )
    }
    
    private func mapToSyncProgressInfoDomain(from entity: SyncProgressEntity) -> SyncProgressInfoDomain {
        return SyncProgressInfoDomain(
            syncId: entity.syncId,
            progress: entity.progress,
            status: entity.status,
            itemsSynced: entity.itemsSynced,
            totalItems: entity.totalItems,
            estimatedTimeRemaining: entity.estimatedTimeRemaining
        )
    }
    
    private func mapToSyncTypeEntity(from domainType: SyncTypeDomain) -> SyncTypeEntity {
        switch domainType {
        case .full:
            return .full
        case .favorites:
            return .favorites
        case .settings:
            return .settings
        }
    }
    
    private func mapToConflictResolutionEntity(from domainResolution: ConflictResolutionDomain) -> ConflictResolutionEntity {
        switch domainResolution {
        case .useLocal:
            return .useLocal
        case .useRemote:
            return .useRemote
        case .merge:
            return .merge
        }
    }
    
    private func mapToSyncError(_ error: Error) -> SyncErrorDomain {
        // 根据错误类型映射到业务层错误
        if let networkError = error as? URLError, networkError.code == .notConnectedToInternet {
            return .networkUnavailable
        } else if error.localizedDescription.contains("CloudKit") {
            return .cloudKitError
        } else if error.localizedDescription.contains("authentication") {
            return .authenticationRequired
        } else if error.localizedDescription.contains("conflict") {
            return .conflictDetected
        } else if error.localizedDescription.contains("in progress") {
            return .syncInProgress
        }
        
        // 默认返回云服务错误
        return .cloudKitError
    }
}