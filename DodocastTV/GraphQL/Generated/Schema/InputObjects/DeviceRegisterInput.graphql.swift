// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DeviceRegisterInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      installationId: UUID,
      name: String,
      platform: GraphQLEnum<Platform>,
      appVersion: String
    ) {
      __data = InputDict([
        "installationId": installationId,
        "name": name,
        "platform": platform,
        "appVersion": appVersion
      ])
    }

    /// Постоянный идентификатор установки: приложение хранит его в Keychain и не стирает при выходе.
    var installationId: UUID {
      get { __data["installationId"] }
      set { __data["installationId"] = newValue }
    }

    /// Имя для списка устройств, например «Гостиная».
    var name: String {
      get { __data["name"] }
      set { __data["name"] = newValue }
    }

    var platform: GraphQLEnum<Platform> {
      get { __data["platform"] }
      set { __data["platform"] = newValue }
    }

    var appVersion: String {
      get { __data["appVersion"] }
      set { __data["appVersion"] = newValue }
    }
  }

}