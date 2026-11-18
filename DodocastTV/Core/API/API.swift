import Apollo
import ApolloAPI
import Foundation

/// GraphQL app-api одного сервера (Apollo iOS 2.x). Токен ставит HTTP-перехватчик; ошибки приходят как `AppError`.
///
/// Кэш Apollo в памяти: при смене сервера весь `API` выбрасывается вместе с ним (APPS.md §5.1). Чтение — с сервера
/// (`networkOnly`): каталог и позиция должны быть свежими, а кэш app-api стоит на сервере (§9).
final class API: Sendable {
    let client: ApolloClient
    let tokens: TokenStore

    init(graphqlURL: URL, tokens: TokenStore) {
        self.tokens = tokens
        let store = ApolloStore(cache: InMemoryNormalizedCache())
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        let transport = RequestChainNetworkTransport(
            urlSession: URLSession(configuration: config),
            interceptorProvider: Interceptors(tokens: tokens),
            store: store,
            endpointURL: graphqlURL
        )
        client = ApolloClient(networkTransport: transport, store: store)
    }

    func fetch<Q: GraphQLQuery>(_ query: Q) async throws -> Q.Data where Q.ResponseFormat == SingleResponseFormat {
        try await call { try await client.fetch(query: query, cachePolicy: .networkOnly) }
    }

    func perform<M: GraphQLMutation>(_ mutation: M) async throws -> M.Data where M.ResponseFormat == SingleResponseFormat {
        try await call { try await client.perform(mutation: mutation) }
    }

    private func call<O: GraphQLOperation>(_ body: () async throws -> GraphQLResponse<O>) async throws -> O.Data {
        let response: GraphQLResponse<O>
        do {
            response = try await body()
        } catch {
            // Ушли с экрана, не дождавшись ответа: это не ошибка, экрану показывать нечего.
            if Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled {
                throw CancellationError()
            }
            throw Self.unwrap(error)
        }
        if let error = response.errors?.first {
            throw Self.appError(error)
        }
        guard let data = response.data else { throw AppError(.unknown) }
        return data
    }

    /// `extensions.code` и `extensions.params` (ERROR_HANDLING.md); ошибка без кода — `UNKNOWN` с записью в журнал.
    static func appError(_ error: GraphQLError) -> AppError {
        let ext = error.extensions ?? [:]
        guard let code = ext["code"] as? String else {
            Log.line("GraphQL: ошибка без кода — \(error.message ?? "")")
            return AppError(.unknown)
        }
        let params = (ext["params"] as? [String: Any] ?? [:]).compactMapValues { "\($0)" }
        return AppError(code: code, params: params)
    }

    /// Ошибку из глубины цепочки Apollo — к нашей: перехватчик бросает `AppError`, Apollo может обернуть его.
    private static func unwrap(_ error: any Error) -> AppError {
        if let e = error as? AppError { return e }
        let mirror = Mirror(reflecting: error)
        for child in mirror.children {
            if let e = child.value as? AppError { return e }
        }
        return AppError.from(error)
    }
}

/// Перехватчики: штатные Apollo плюс наш HTTP — токен, обновление на 401, разбор отказов 403.
private struct Interceptors: InterceptorProvider {
    let tokens: TokenStore

    func httpInterceptors<Operation: GraphQLOperation>(for operation: Operation) -> [any HTTPInterceptor] {
        [AuthInterceptor(tokens: tokens)]
    }
}

private struct AuthInterceptor: HTTPInterceptor {
    let tokens: TokenStore

    func intercept(request: URLRequest, next: NextHTTPInterceptorFunction) async throws -> HTTPResponse {
        let first = try await next(Self.authorized(request, try await tokens.accessToken()))
        guard first.response.statusCode == 401 else { return await Self.checked(first) }
        // Access истёк раньше, чем мы думали (часы, отзыв): одно обновление и один повтор.
        let retry = try await next(Self.authorized(request, try await tokens.accessToken(forceRefresh: true)))
        return await Self.checked(retry)
    }

    private static func authorized(_ request: URLRequest, _ token: String) -> URLRequest {
        var r = request
        r.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return r
    }

    /// Не 2xx:
    /// - 403 входа несёт причину в теле (`{"error": "account_not_ready"}`) — в `AppError`;
    /// - 401 после обновления — вход больше не действует;
    /// - прочие 4xx с ответом GraphQL — дальше, разбору Apollo. Apollo 2 просит `application/graphql-response+json`, а
    ///   по GraphQL over HTTP ответ без `data` (отказ привратника: `RATE_LIMITED`, `OPERATION_NOT_REGISTERED`…) приходит
    ///   с 4xx. Код ошибки — в `extensions` тела, выбросить тело — значит показать «сервер недоступен» вместо причины;
    /// - 5xx и не-JSON — сервер недоступен.
    private static func checked(_ response: consuming HTTPResponse) async -> HTTPResponse {
        await response.mapChunks { http, chunk in
            let status = http.statusCode
            guard !(200..<300).contains(status) else { return chunk }
            let body = try? JSONSerialization.jsonObject(with: chunk) as? [String: Any]
            if status == 403, let reason = body?["error"] as? String {
                throw AppError(code: reason)
            }
            if status == 401 { throw AppError(.signedOut) }
            if (400..<500).contains(status), body?["errors"] != nil { return chunk }
            Log.line("GraphQL: HTTP \(status)")
            throw AppError(.serverUnavailable)
        }
    }
}
