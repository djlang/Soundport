import Foundation

class RadioCategorySerivce {
    static let shared = RadioCategorySerivce()
    private init() {}

    private let hosts = [
        "https://de1.api.radio-browser.info/json",
        "https://at1.api.radio-browser.info/json",
        "https://nl1.api.radio-browser.info/json"
    ]
    func executeTask(_ task: RadioTask, retryCount: Int = 1) async throws -> [Station] {
        let maxAttempts = min(max(1, retryCount + 1), hosts.count)
        var lastError: Error = URLError(.unknown)

        for attempt in 0..<maxAttempts {
            let host = hosts[attempt]
            do {
                return try await executeTask(task, host: host)
            } catch {
                lastError = error
                if attempt < maxAttempts - 1 {
                    print("🔄 [Retry] 切换节点至: \(hosts[attempt + 1])")
                }
            }
        }

        throw lastError
    }

    private func executeTask(_ task: RadioTask, host: String) async throws -> [Station] {
        var components = URLComponents(string: host + task.path)
        components?.queryItems = task.parameters

        guard let url = components?.url else { throw URLError(.badURL) }
        print("📡 [Request] \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        request.setValue("Soundport/1.1", forHTTPHeaderField: "User-Agent")

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
    }
}
