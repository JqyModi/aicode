//
//  SyncViewModel.swift
//  JapaneseLearnApp
//
//  Created by AI on 2023/10/01.
//

import Foundation
import Combine
import SwiftUI

// MARK: - 同步视图模型协议
protocol SyncViewModelProtocol: ObservableObject {
    // 输出属性
    var lastSyncTime: Date? { get }
    var syncStatus: String { get }
    var pendingChanges: Int { get }
    var isAvailableOffline: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    var currentProgress: SyncProgressViewModel? { get }
    
    // 方法
    func getSyncStatus()
    func startSync(type: SyncTypeViewModel)
    func resolveConflict(conflictId: String, resolution: ConflictResolutionViewModel)
    func cancelSync()
}

class SyncViewModel: SyncViewModelProtocol {
    // MARK: - 属性
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var syncStatus: String = ""
    @Published private(set) var pendingChanges: Int = 0
    @Published private(set) var isAvailableOffline: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentProgress: SyncProgressViewModel?
    
    private let syncService: SyncServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var currentSyncId: String?
    private var progressTimer: Timer?
    
    // MARK: - 初始化
    init(syncService: SyncServiceProtocol) {
        self.syncService = syncService
        getSyncStatus()
    }
    
    deinit {
        progressTimer?.invalidate()
    }
    
    // MARK: - 公共方法
    func getSyncStatus() {
        isLoading = true
        errorMessage = nil
        
        syncService.getSyncStatus()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] statusInfo in
                self?.updateSyncStatus(from: statusInfo)
            }
            .store(in: &cancellables)
    }
    
    func startSync(type: SyncTypeViewModel) {
        guard currentSyncId == nil else {
            errorMessage = "同步已在进行中"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let domainType = mapToDomainSyncType(type)
        
        syncService.startSync(type: domainType)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.isLoading = false
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] operationInfo in
                self?.handleSyncStarted(operationInfo)
            }
            .store(in: &cancellables)
    }
    
    func resolveConflict(conflictId: String, resolution: ConflictResolutionViewModel) {
        isLoading = true
        errorMessage = nil
        
        let domainResolution = mapToDomainConflictResolution(resolution)
        
        syncService.resolveSyncConflict(conflictId: conflictId, resolution: domainResolution)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] success in
                if success {
                    self?.getSyncStatus()
                } else {
                    self?.errorMessage = "解决冲突失败"
                }
            }
            .store(in: &cancellables)
    }
    
    func cancelSync() {
        progressTimer?.invalidate()
        progressTimer = nil
        currentSyncId = nil
        currentProgress = nil
        getSyncStatus()
    }
    
    // MARK: - 私有方法
    private func handleSyncStarted(_ operationInfo: SyncOperationInfoDomain) {
        currentSyncId = operationInfo.syncId
        
        // 创建初始进度视图模型
        currentProgress = SyncProgressViewModel(
            progress: 0.0,
            status: operationInfo.status,
            itemsSynced: 0,
            totalItems: 0,
            estimatedTimeRemaining: operationInfo.estimatedTimeRemaining
        )
        
        // 启动定时器监控同步进度
        startProgressMonitoring()
    }
    
    private func startProgressMonitoring() {
        // 取消现有定时器
        progressTimer?.invalidate()
        
        // 创建新定时器，每秒更新一次进度
        progressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSyncProgress()
        }
    }
    
    private func updateSyncProgress() {
        guard let syncId = currentSyncId else { return }
        
        syncService.getSyncProgress(operationId: syncId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    // 进度获取失败，但不中断同步
                    print("获取同步进度失败: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] progressInfo in
                self?.updateProgressViewModel(from: progressInfo)
                
                // 如果同步完成，停止监控
                if progressInfo.progress >= 1.0 || progressInfo.status.lowercased() == "completed" {
                    self?.syncCompleted()
                }
            }
            .store(in: &cancellables)
    }
    
    private func syncCompleted() {
        progressTimer?.invalidate()
        progressTimer = nil
        currentSyncId = nil
        
        // 延迟一秒后刷新同步状态，确保服务器状态已更新
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.getSyncStatus()
            self?.currentProgress = nil
        }
    }
    
    private func updateSyncStatus(from statusInfo: SyncStatusInfoDomain) {
        lastSyncTime = statusInfo.lastSyncTime
        syncStatus = statusInfo.syncStatus
        pendingChanges = statusInfo.pendingChanges
        isAvailableOffline = statusInfo.availableOffline
    }
    
    private func updateProgressViewModel(from progressInfo: SyncProgressInfoDomain) {
        currentProgress = SyncProgressViewModel(
            progress: progressInfo.progress,
            status: progressInfo.status,
            itemsSynced: progressInfo.itemsSynced,
            totalItems: progressInfo.totalItems,
            estimatedTimeRemaining: progressInfo.estimatedTimeRemaining
        )
    }
    
    private func handleError(_ error: SyncErrorDomain) {
        switch error {
        case .networkUnavailable:
            errorMessage = "网络不可用，请检查网络连接"
        case .cloudKitError:
            errorMessage = "云服务错误，请稍后再试"
        case .authenticationRequired:
            errorMessage = "需要登录才能同步数据"
        case .conflictDetected:
            errorMessage = "检测到数据冲突，请解决冲突"
        case .syncInProgress:
            errorMessage = "同步已在进行中"
        }
    }
    
    private func mapToDomainSyncType(_ viewModelType: SyncTypeViewModel) -> SyncTypeDomain {
        switch viewModelType {
        case .full:
            return .full
        case .favorites:
            return .favorites
        case .settings:
            return .settings
        }
    }
    
    private func mapToDomainConflictResolution(_ viewModelResolution: ConflictResolutionViewModel) -> ConflictResolutionDomain {
        switch viewModelResolution {
        case .useLocal:
            return .useLocal
        case .useRemote:
            return .useRemote
        case .merge:
            return .merge
        }
    }
}

// MARK: - 表现层枚举类型
enum SyncTypeViewModel {
    case full       // 全量同步
    case favorites  // 仅同步收藏
    case settings   // 仅同步设置
}

enum ConflictResolutionViewModel {
    case useLocal   // 使用本地版本
    case useRemote  // 使用远程版本
    case merge      // 合并两个版本
}

// MARK: - 表现层数据模型
struct SyncProgressViewModel {
    let progress: Double
    let status: String
    let itemsSynced: Int
    let totalItems: Int
    let estimatedTimeRemaining: Int?
    
    var progressPercentage: Int {
        return Int(progress * 100)
    }
    
    var remainingTimeText: String {
        guard let seconds = estimatedTimeRemaining else {
            return "计算中..."
        }
        
        if seconds < 60 {
            return "\(seconds)秒"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)分钟"
        } else {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            return "\(hours)小时\(minutes)分钟"
        }
    }
}