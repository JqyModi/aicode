//
//  NetworkManager.swift
//  ChineseBox
//
//  Created by J.qy on 2025/1/21.
//

import SwiftUI
import Combine

private var cancellables = Set<AnyCancellable>()

/// 支持的 HTTP 方法
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

/// 网络请求错误类型
enum APIError: Error, LocalizedError {
    case invalidURL
    case fileNotFound
    case requestFailed(Int)
    case decodingError(Error)
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .requestFailed(let statusCode): return "Request failed with status code: \(statusCode)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .unknown(let error): return "Unknown error: \(error.localizedDescription)"
        case .fileNotFound: return "file Not Found"
        }
    }
}

/// **通用网络管理器**
class NetworkManager {
    static let shared = NetworkManager()
    private init() {}

    /// 进行泛型网络请求
    func request<T: Decodable>(
        urlString: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) -> AnyPublisher<T, APIError> {
        
        guard var urlComponents = URLComponents(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        // 处理 GET 请求参数
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
        }

        guard let url = urlComponents.url else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        // 设置 Headers
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        // 处理 POST 请求参数
        if method == .post, let parameters = parameters {
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // 发送网络请求
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> Data in
                guard let response = result.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    throw APIError.requestFailed((result.response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                return result.data
            }
            .decode(type: T.self, decoder: JSONDecoder()) // 解析 JSON
            .mapError { error in
                return error is DecodingError ? APIError.decodingError(error) : APIError.unknown(error)
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension NetworkManager {
    /// **请求原始 Data (支持 ZIP 下载)**
    func requestData(urlString: String) -> AnyPublisher<Data, APIError> {
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { result -> Data in
                guard let response = result.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    throw APIError.requestFailed((result.response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                return result.data
            }
            .mapError { error in APIError.unknown(error) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension NetworkManager {
    /// **请求 JSON 数据 (适用于获取 GitHub Release 版本号)**
    func requestJSON(urlString: String, token: String) -> AnyPublisher<[String: Any], APIError> {
        guard let url = URL(string: urlString) else {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
//        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        request.addValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
//        request.addValue("2025-02-09", forHTTPHeaderField: "X-GitHub-Api-Version")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { result -> [String: Any] in
                guard let response = result.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    throw APIError.requestFailed((result.response as? HTTPURLResponse)?.statusCode ?? 0)
                }
                return try JSONSerialization.jsonObject(with: result.data) as? [String: Any] ?? [:]
            }
            .mapError { error in APIError.unknown(error) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}


extension NetworkManager {
    static func moji_request(urlPath: String, params: [AnyHashable:Any]) -> URLRequest? {
        guard let postData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted) else {
            return nil
        }

        #if DEBUG
        let host = "https://debugten.mojidict.com/parse/functions/"
        #else
        let host = "https://api.mojidict.com/parse/functions/"
        #endif
        
        var request = URLRequest(url: URL(string: host + urlPath)!,timeoutInterval: Double.infinity)
        request.addValue("E62VyFVLMiW7kvbtVq3p", forHTTPHeaderField: "X-Parse-Application-Id")
        request.addValue("2e082b25f9a55a25c0fd23c2e2999d9515f6e61d1b53e550", forHTTPHeaderField: "X-Parse-Session-Token")
        request.addValue("fbc7d898-96e2-4f72-b967-c624081908fa", forHTTPHeaderField: "X-Parse-Installation-Id")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpMethod = "POST"
        request.httpBody = postData
        
        return request
    }
}
