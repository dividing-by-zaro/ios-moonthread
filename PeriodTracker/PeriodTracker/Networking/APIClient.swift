import Foundation

enum APIError: Error, LocalizedError {
    case unauthorized
    case notFound
    case conflict(String)
    case badRequest(String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .unauthorized: return "Invalid API key"
        case .notFound: return "Not found"
        case .conflict(let msg): return msg
        case .badRequest(let msg): return msg
        case .networkError(let err): return err.localizedDescription
        case .decodingError(let err): return "Decoding error: \(err.localizedDescription)"
        }
    }
}

actor APIClient {
    static let shared = APIClient()

    #if DEBUG
    private var baseURL = "http://localhost:8000"
    #else
    private var baseURL = "https://YOUR-RAILWAY-URL.railway.app"
    #endif

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]

        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)

            if let date = dateFormatter.date(from: str) { return date }
            if let date = isoFormatter.date(from: str) { return date }
            if let date = isoFallback.date(from: str) { return date }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(str)"
            )
        }
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        e.dateEncodingStrategy = .formatted(formatter)
        return e
    }()

    private func apiKey() -> String? {
        KeychainHelper.load()
    }

    private func request(_ method: String, path: String, body: Encodable? = nil) async throws -> Data {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.badRequest("Invalid URL")
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let key = apiKey() {
            req.setValue(key, forHTTPHeaderField: "X-API-Key")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        switch http.statusCode {
        case 200...201: return data
        case 401: throw APIError.unauthorized
        case 404: throw APIError.notFound
        case 409:
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Conflict"
            throw APIError.conflict(detail)
        default:
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"] ?? "Request failed"
            throw APIError.badRequest(detail)
        }
    }

    // MARK: - Endpoints

    func fetchPeriods() async throws -> [Period] {
        let data = try await request("GET", path: "/periods")
        do {
            return try decoder.decode([Period].self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func startPeriod(date: Date) async throws -> Period {
        struct Body: Encodable { let start_date: Date }
        let data = try await request("POST", path: "/periods", body: Body(start_date: date))
        do {
            return try decoder.decode(Period.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func endPeriod(id: Int, date: Date) async throws -> Period {
        struct Body: Encodable { let end_date: Date }
        let data = try await request("PATCH", path: "/periods/\(id)", body: Body(end_date: date))
        do {
            return try decoder.decode(Period.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func fetchStats() async throws -> PeriodStats {
        let data = try await request("GET", path: "/periods/stats")
        do {
            return try decoder.decode(PeriodStats.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}
