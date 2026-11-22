// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DeviceRegisterMutation: GraphQLMutation {
    static let operationName: String = "DeviceRegister"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeviceRegister($input: DeviceRegisterInput!) { deviceRegister(input: $input) { __typename ...DeviceFields } }"#,
        fragments: [DeviceFields.self]
      ))

    public var input: DeviceRegisterInput

    public init(input: DeviceRegisterInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deviceRegister", DeviceRegister.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeviceRegisterMutation.Data.self
      ] }

      /// Подключить устройство. Повтор для той же установки обновляет запись и слот не тратит.
      /// Ошибки: DEVICE_LIMIT_REACHED {limit}; DEVICE_REVOKED — это устройство отключено, нужен новый вход;
      /// APPS_NOT_IN_TARIFF — приложения закрыты тарифом (тогда работают только `me` и `deviceRevoke`).
      var deviceRegister: DeviceRegister { __data["deviceRegister"] }

      /// DeviceRegister
      ///
      /// Parent Type: `Device`
      nonisolated struct DeviceRegister: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Device }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(DeviceFields.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DeviceRegisterMutation.Data.DeviceRegister.self,
          DeviceFields.self
        ] }

        var id: DCAPI.ID { __data["id"] }
        var name: String { __data["name"] }
        var platform: GraphQLEnum<DCAPI.Platform> { __data["platform"] }
        var appVersion: String? { __data["appVersion"] }
        var lastSeenAt: DCAPI.DateTime? { __data["lastSeenAt"] }
        var createdAt: DCAPI.DateTime { __data["createdAt"] }
        /// Это устройство, с которого пришёл запрос.
        var current: Bool { __data["current"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var deviceFields: DeviceFields { _toFragment() }
        }
      }
    }
  }

}