import Foundation
import AuthenticationServices
import Combine

class AppleAuthService: NSObject {
    // 单例模式
    static let shared = AppleAuthService()
    
    // 认证结果发布者
    private var authSubject = PassthroughSubject<ASAuthorizationAppleIDCredential, Error>()
    
    private override init() {
        super.init()
    }
    
    // 开始Apple登录流程
    func startSignInWithApple() -> AnyPublisher<ASAuthorizationAppleIDCredential, Error> {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        
        return authSubject.eraseToAnyPublisher()
    }
    
    // 验证Apple身份令牌
    func verifyIdentityToken(_ identityToken: Data) -> AnyPublisher<Bool, Error> {
        // 在实际应用中，这里应该向Apple服务器验证令牌
        // 对于MVP阶段，我们简单地返回成功
        return Just(true)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
    
    // 获取当前登录状态
    func getCredentialState(forUserID userID: String) -> AnyPublisher<ASAuthorizationAppleIDProvider.CredentialState, Error> {
        return Future<ASAuthorizationAppleIDProvider.CredentialState, Error> { promise in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userID) { state, error in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(state))
                }
            }
        }.eraseToAnyPublisher()
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            authSubject.send(appleIDCredential)
        } else {
            authSubject.send(completion: .failure(NSError(domain: "AppleAuthService", code: 1, userInfo: [NSLocalizedDescriptionKey: "未能获取有效的Apple ID凭证"])))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        authSubject.send(completion: .failure(error))
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleAuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // 在实际应用中，这里需要返回当前的窗口
        // 对于MVP阶段，我们使用一个临时解决方案
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIWindow()
    }
}