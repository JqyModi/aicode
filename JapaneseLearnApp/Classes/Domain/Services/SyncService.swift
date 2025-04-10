import Foundation
import CloudKit
import Combine

protocol SyncServiceProtocol {
    // 获取同步状态
    func getSyncStatus() -> AnyPublisher<SyncStatusInfo, SyncError>
    
    // 触发同步
    func startSync() -> AnyPublisher<SyncOperationInfo, SyncError>
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncOperationInfo, SyncError>
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, SyncError>
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
                let operationInfo = status.currentOperation.map { self.mapToOperationInfo($0) }
                
                return SyncStatusInfo(
                    lastSyncTime: status.lastSyncTime,
                    isCloudKitAvailable: status.cloudKitAvailable,
                    isAutoSyncEnabled: status.autoSyncEnabled,
                    currentOperation: operationInfo
                )
            }
            .mapError { error -> SyncError in
                return .repositoryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 触发同步
    func startSync() -> AnyPublisher<SyncOperationInfo, SyncError> {
        return syncRepository.startSync()
            .map { operation -> SyncOperationInfo in
                return self.mapToOperationInfo(operation)
            }
            .mapError { error -> SyncError in
                if let nsError = error as NSError? {
                    if nsError.domain == "SyncRepository" && nsError.code == 409 {
                        return .operationInProgress
                    } else if nsError.domain == "CloudKitService" && nsError.code == 503 {
                        return .notAvailable
                    }
                }
                return .repositoryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 获取同步进度
    func getSyncProgress(operationId: String) -> AnyPublisher<SyncOperationInfo, SyncError> {
        return syncRepository.getSyncProgress(operationId: operationId)
            .map { operation -> SyncOperationInfo in
                return self.mapToOperationInfo(operation)
            }
            .mapError { error -> SyncError in
                if let nsError = error as NSError?, nsError.domain == "SyncRepository" && nsError.code == 404 {
                    return .operationNotFound
                }
                return .repositoryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 启用/禁用自动同步
    func setAutoSync(enabled: Bool) -> AnyPublisher<Bool, SyncError> {
        return syncRepository.setAutoSync(enabled: enabled)
            .mapError { error -> SyncError in
                return .repositoryError(error)
            }
            .eraseToAnyPublisher()
    }
    
    // 将数据层的SyncOperation映射为业务层的SyncOperationInfo
    private func mapToOperationInfo(_ operation: SyncOperation) -> SyncOperationInfo {
        return SyncOperationInfo(
            id: operation.id,
            type: operation.type,
            status: operation.status,
            startTime: operation.startTime,
            endTime: operation.endTime,
            progress: operation.progress,
            itemsProcessed: operation.itemsProcessed,
            totalItems: operation.totalItems,
            errorMessage: operation.errorMessage
        )
    }
}
