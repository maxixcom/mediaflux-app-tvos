// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DeviceFields: DCAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment DeviceFields on Device { __typename id name platform appVersion lastSeenAt createdAt current }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Device }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", DCAPI.ID.self),
      .field("name", String.self),
      .field("platform", GraphQLEnum<DCAPI.Platform>.self),
      .field("appVersion", String?.self),
      .field("lastSeenAt", DCAPI.DateTime?.self),
      .field("createdAt", DCAPI.DateTime.self),
      .field("current", Bool.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
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
  }

}