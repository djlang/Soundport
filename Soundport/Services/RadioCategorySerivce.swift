import Foundation
import Combine
import SwiftUI


class RadioCategorySerivce {
    static let shared = RadioCategorySerivce()
    private init() {}

    private let hosts = [
        "https://de1.api.radio-browser.info/json",
        "https://at1.api.radio-browser.info/json",
        "https://nl1.api.radio-browser.info/json"
    ]
    private var currentHostIndex = 0
    private var baseURL: String { hosts[currentHostIndex] }

    func executeTask(_ task: RadioTask, retryCount: Int = 1) async throws -> [Station] {
        var components = URLComponents(string: baseURL + task.path)
        components?.queryItems = task.parameters
        
        guard let url = components?.url else { throw URLError(.badURL) }

        // 打印请求，方便真机调试自测
        print("📡 [Request] \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("Soundport/1.1", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }
            
            let rawStations = try JSONDecoder().decode([RawStation].self, from: data)
            return rawStations.map { raw in
                Station(
                    changeuuid: raw.changeuuid,
                    name: raw.name,
                    frequency: raw.state.isEmpty ? "网络广播" : raw.state,
                    logoUrl: raw.favicon,
                    streamUrl: raw.url_resolved,
                    tags: raw.tags,
                    state: raw.state
                )
            }
            
        } catch {
            if retryCount > 0 {
                currentHostIndex = (currentHostIndex + 1) % hosts.count
                print("🔄 [Retry] 切换节点至: \(baseURL)")
                return try await executeTask(task, retryCount: retryCount - 1)
            }
            throw error
        }
    }
}
