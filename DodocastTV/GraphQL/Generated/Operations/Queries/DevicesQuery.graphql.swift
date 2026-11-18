// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DevicesQuery: GraphQLQuery {
    static let operationName: String = "Devices"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Devices { devices { __typename ...DeviceFields } }"#,
        fragments: [DeviceFields.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("devices", [Device].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DevicesQuery.Data.self
      ] }

      /// Подключённые устройства пользователя (отключённые не показываются).
      var devices: [Device] { __data["devices"] }

      /// Device
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
          DevicesQuery.Data.Device.self,
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