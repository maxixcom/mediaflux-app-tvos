import Apollo
import ApolloAPI
import XCTest
@testable import DodocastTV

/// Ядро клиента без сети: версии, сведения о сервере, коды ошибок.
final class CoreTests: XCTestCase {

    func testVersionCompareByNumbersNotStrings() {
        XCTAssertTrue(AppVersion.isBelow("0.3.0", minimum: "0.4.0"))
        XCTAssertTrue(AppVersion.isBelow("0.9", minimum: "0.10"))
        XCTAssertFalse(AppVersion.isBelow("0.10.0", minimum: "0.9.9"))
        XCTAssertFalse(AppVersion.isBelow("1.0", minimum: "1.0.0"))
        XCTAssertTrue(AppVersion.isBelow("1.0", minimum: "1.0.1"))
        XCTAssertFalse(AppVersion.isBelow("2.0-beta", minimum: "1.9"))
    }

    func testServerInfoDecodesAppApiAnswer() throws {
        let json = """
        {"stand":"tst","production":false,"issuer":"https://id.tst.media-flux.ru/realms/mediaflux",
         "clientId":"mediaflux-app-tvos","graphqlUrl":"https://app.tst.media-flux.ru/graphql","minAppVersion":null}
        """
        let info = try JSONDecoder().decode(ServerInfo.self, from: Data(json.utf8))
        XCTAssertEqual(info.stand, "tst")
        XCTAssertFalse(info.production)
        XCTAssertEqual(info.graphqlUrl.host(), "app.tst.media-flux.ru")
        XCTAssertNil(info.minAppVersion)
    }

    func testCustomServerKeepsHostAndPortInKey() {
        let a = ServerEntry.custom(URL(string: "http://localhost:17091")!)
        let b = ServerEntry.custom(URL(string: "http://localhost:17092")!)
        XCTAssertNotEqual(a.key, b.key, "токены двух локальных серверов не должны пересекаться")
        XCTAssertEqual(a.title, "localhost")
    }

    func testTypedAddressGetsSchemeByKindOfHost() {
        XCTAssertEqual(ServerAddress.url(from: "192.168.254.132:17091")?.absoluteString, "http://192.168.254.132:17091")
        XCTAssertEqual(ServerAddress.url(from: "localhost:17091")?.absoluteString, "http://localhost:17091")
        XCTAssertEqual(ServerAddress.url(from: "mac.local:17091")?.absoluteString, "http://mac.local:17091")
        XCTAssertEqual(ServerAddress.url(from: "app.tst.media-flux.ru")?.absoluteString, "https://app.tst.media-flux.ru")
        XCTAssertEqual(ServerAddress.url(from: " http://x.example ")?.absoluteString, "http://x.example")
        XCTAssertNil(ServerAddress.url(from: ""))
    }

    func testKnownCodesHaveOwnPhrase() {
        let unknown = AppError(.unknown).message
        for code: AppError.Code in [.serverUnavailable, .network, .signedOut, .accountNotReady, .deviceRevoked,
                                    .deviceLimitReached, .deliveryBlocked, .channelOffAir, .rateLimited] {
            XCTAssertNotEqual(AppError(code).message, unknown, "\(code) без своей фразы")
        }
    }

    func testParamsGoIntoPhrase() {
        XCTAssertTrue(AppError(.deviceLimitReached, params: ["limit": "3"]).message.contains("3"))
        XCTAssertTrue(AppError(.rateLimited, params: ["retryAfterSeconds": "5"]).message.contains("5"))
        let suspended = AppError(.deliveryBlocked, params: ["reason": "SUSPENDED"]).message
        let traffic = AppError(.deliveryBlocked, params: ["reason": "TRAFFIC_LIMIT"]).message
        XCTAssertNotEqual(suspended, traffic)
    }

    func testUnknownCodeIsShownToHuman() {
        XCTAssertTrue(AppError(code: "SOMETHING_NEW").message.contains("SOMETHING_NEW"))
    }

    func testSignInNeededOnRevokedOrSignedOut() {
        XCTAssertTrue(AppError(.signedOut).needsSignIn)
        XCTAssertTrue(AppError(.deviceRevoked).needsSignIn)
        XCTAssertFalse(AppError(.deviceLimitReached).needsSignIn)
    }

    func testAppsNotInTariffLeavesScreenWithoutSignIn() {
        // Приложения сняты с тарифа (MF-91): экран отдаёт ошибку наверх — экран проблемы с «Выйти», а вход не сбрасываем.
        XCTAssertTrue(AppError(.appsNotInTariff).isAppWide)
        XCTAssertFalse(AppError(.appsNotInTariff).needsSignIn)
        XCTAssertTrue(AppError(.deviceRevoked).isAppWide)
        XCTAssertFalse(AppError(.playbackFailed).isAppWide)
    }

    func testGraphQLErrorExtensionsBecomeAppError() throws {
        // Как ошибка приходит от сервера: JSON → JSONObject, так же разбирает его Apollo.
        let body = #"{"message":"limit","extensions":{"code":"DEVICE_LIMIT_REACHED","params":{"limit":"3"}}}"#
        let error = GraphQLError(try JSONSerialization.jsonObject(with: Data(body.utf8)) as! JSONObject)
        XCTAssertEqual(API.appError(error), AppError(.deviceLimitReached, params: ["limit": "3"]))
        XCTAssertEqual(API.appError(GraphQLError(["message": "boom"])), AppError(.unknown))
    }

    func testNetworkFailureIsNetworkCode() {
        XCTAssertEqual(AppError.from(URLError(.notConnectedToInternet)), AppError(.network))
    }
}
