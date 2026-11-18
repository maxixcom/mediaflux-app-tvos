// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct DeviceRevokeMutation: GraphQLMutation {
    static let operationName: String = "DeviceRevoke"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation DeviceRevoke($id: ID!) { deviceRevoke(id: $id) }"#
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("deviceRevoke", Bool.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        DeviceRevokeMutation.Data.self
      ] }

      /// Отключить устройство (в том числе текущее — «Выйти»). Новые токены оно больше не получит, а уже выданные
      /// перестают приниматься в пределах минуты.
      var deviceRevoke: Bool { __data["deviceRevoke"] }
    }
  }

}