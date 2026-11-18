// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DeviceRenameMutation: GraphQLMutation {
    static let operationName: String = "DeviceRename"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeviceRename($id: ID!, $name: String!) { deviceRename(id: $id, name: $name) { __typename ...DeviceFields } }"#,
        fragments: [DeviceFields.self]
      ))

    public var id: ID
    public var name: String

    public init(
      id: ID,
      name: String
    ) {
      self.id = id
      self.name = name
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "name": name
    ] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deviceRename", DeviceRename.self, arguments: [
          "id": .variable("id"),
          "name": .variable("name")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeviceRenameMutation.Data.self
      ] }

      var deviceRename: DeviceRename { __data["deviceRename"] }

      /// DeviceRename
      ///
      /// Parent Type: `Device`
      nonisolated struct DeviceRename: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Device }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(DeviceFields.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          DeviceRenameMutation.Data.DeviceRename.self,
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