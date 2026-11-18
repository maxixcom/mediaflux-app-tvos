// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct MeQuery: GraphQLQuery {
    static let operationName: String = "Me"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Me { me { __typename id name email deviceLimit deliveryBlock device { __typename ...DeviceFields } } }"#,
        fragments: [DeviceFields.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("me", Me.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MeQuery.Data.self
      ] }

      /// Кто вошёл и с какого устройства. Доступно до регистрации устройства.
      var me: Me { __data["me"] }

      /// Me
      ///
      /// Parent Type: `Me`
      nonisolated struct Me: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Me }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DCAPI.ID.self),
          .field("name", String?.self),
          .field("email", String?.self),
          .field("deviceLimit", Int.self),
          .field("deliveryBlock", GraphQLEnum<DCAPI.DeliveryBlockReason>?.self),
          .field("device", Device?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MeQuery.Data.Me.self
        ] }

        var id: DCAPI.ID { __data["id"] }
        var name: String? { __data["name"] }
        var email: String? { __data["email"] }
        /// Сколько устройств можно подключить.
        var deviceLimit: Int { __data["deviceLimit"] }
        /// Почему отдача владельца закрыта; null — открыта (или data-service не ответил — тогда решит стример).
        var deliveryBlock: GraphQLEnum<DCAPI.DeliveryBlockReason>? { __data["deliveryBlock"] }
        /// Устройство, с которого пришёл запрос; null — ещё не зарегистрировано (или отключено).
        var device: Device? { __data["device"] }

        /// Me.Device
        ///
        /// Parent Type: `Device`
        nonisolated struct Device: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Device }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(DeviceFields.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            MeQuery.Data.Me.Device.self,
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

}