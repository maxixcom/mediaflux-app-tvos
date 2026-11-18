import Foundation
import Observation

/// Вход по коду на экране телевизора: код и QR, опрос Keycloak, новый код взамен истёкшего.
@MainActor
@Observable
final class LoginModel {
    enum Phase: Equatable {
        case preparing
        case waiting(DeviceCode)
        case failed(AppError)
    }

    private(set) var phase: Phase = .preparing
    private var task: Task<Void, Never>?

    func start(session: Session, onSignedIn: @escaping @MainActor (TokenSet) async -> Void) {
        task?.cancel()
        task = Task { [weak self] in
            await self?.run(session: session, onSignedIn: onSignedIn)
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }

    private func run(session: Session, onSignedIn: @escaping @MainActor (TokenSet) async -> Void) async {
        let oidc = session.tokens.oidc
        while !Task.isCancelled {
            phase = .preparing
            do {
                let ep = try await session.tokens.endpoints()
                let code = try await oidc.startDeviceLogin(ep)
                phase = .waiting(code)
                Log.line("вход: показан код, ждём подтверждения")
                var interval = UInt64(code.interval)
                while !Task.isCancelled, Date() < code.expires {
                    try await Task.sleep(nanoseconds: interval * 1_000_000_000)
                    switch try await oidc.poll(ep, code) {
                    case .pending: continue
                    case .slowDown: interval += 5
                    case let .tokens(tokens):
                        await onSignedIn(tokens)
                        return
                    }
                }
                // Код истёк, а человек так и не подошёл — тихо выдать новый.
                Log.line("вход: код истёк, новый")
            } catch is CancellationError {
                return
            } catch let e as AppError where e.is(.loginExpired) {
                continue
            } catch {
                phase = .failed(AppError.from(error))
                return
            }
        }
    }
}
