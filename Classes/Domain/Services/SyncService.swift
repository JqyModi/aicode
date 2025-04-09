import Foundation
import CloudKit
import Combine

protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfo, SyncError>
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperationInfo, SyncError>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfo, SyncError>
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, SyncError>
}

class SyncService: SyncServiceProtocol {
    private let syncRepository: SyncRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(syncRepository: SyncRepositoryProtocol = SyncRepository()) {
        self.syncRepository = syncRepository
    }
    
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfo, SyncError> {
        return syncRepository.getSyncStatus()
            .map { status -> SyncStatusInfo in
                return SyncStatusInfo(
                    lastSyncTime: status.lastSyncTime,
                    pendingChanges: self.countPendingChanges(),
                    syncStatus: status.currentOperation != nil ? "syncing" : "idle",
                    availableOffline: status.cloudKitAvailable
                )
            }
            .mapError { error -> SyncError in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 触发同步
    func startSync(type: SyncType) -> AnyPublisher<SyncOperationInfo, SyncError> {
        let repoSyncType: SyncOperationType
        
        switch type {
        case .full:
            repoSyncType = .full
        case .favorites:
            // 对应原来的incremental类型
            repoSyncType = .incremental
        case .settings:
            // 对应原来的download类型
            repoSyncType = .download
        }
        
        return syncRepository.startSync(type: repoSyncType)
            .map { operation -> SyncOperationInfo in
                return SyncOperationInfo(
                    syncId: operation.id,
                    startedAt: operation.startTime,
                    status: operation.status,
                    estimatedTimeRemaining: self.calculateEstimatedTime(operation)
                )
            }
            .mapError { error -> SyncError in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncProgressInfo, SyncError> {
        return syncRepository.getSyncProgress(operationId: operationId)
            .map { operation -> SyncProgressInfo in
                return SyncProgressInfo(
                    syncId: operation.id,
                    progress: operation.progress,
                    status: operation.status,
                    itemsSynced: operation.itemsProcessed,
                    totalItems: operation.totalItems,
                    estimatedTimeRemaining: self.calculateEstimatedTime(operation)
                )
            }
            .mapError { error -> SyncError in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 解决同步冲突
    func resolveSyncConflict(conflictId: String, resolution: ConflictResolution) -> AnyPublisher<Bool, SyncError> {
        let repoResolution: ConflictResolution
        
        switch resolution {
        case .useLocal:
            repoResolution = .useLocal
        case .useRemote:
            repoResolution = .useRemote
        case .merge:
            repoResolution = .merge
        case .manual:
            repoResolution = .manual
        }
        
        return syncRepository.resolveSyncConflict(conflictId: conflictId, resolution: repoResolution)
            .mapError { error -> SyncError in
                return self.mapError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 计算待同步的更改数量
    private func countPendingChanges() -> Int {
        // 这里应该查询Realm数据库中待同步的项目数量
        // 简化实现，返回一个固定值
        return 0
    }
    
    // 计算估计剩余时间（秒）
    private func calculateEstimatedTime(_ operation: SyncOperation) -> Int? {
        guard operation.progress > 0, operation.startTime != nil else {
            return nil
        }
        
        let elapsedTime = Date().timeIntervalSince(operation.startTime)
        let estimatedTotalTime = elapsedTime / operation.progress
        let remainingTime = estimatedTotalTime - elapsedTime
        
        return Int(remainingTime)
    }
    
    // 错误映射
    private func mapError(_ error: Error) -> SyncError {
        if let nsError = error as NSError? {
            if nsError.domain == "CloudKitErrorDomain" {
                return .cloudKitError
            } else if nsError.domain == "NSURLErrorDomain" {
                return .networkUnavailable
            }
        }
        
        // 根据错误类型映射到适当的SyncError
        if let _ = error as? CKError {
            return .cloudKitError
        } else if (error.localizedDescription.contains("conflict")) {
            return .conflictDetected
        } else if (error.localizedDescription.contains("sync")) {
            return .syncInProgress
        } else if (error.localizedDescription.contains("auth")) {
            return .authenticationRequired
        }
        
        return .cloudKitError
    }
}
