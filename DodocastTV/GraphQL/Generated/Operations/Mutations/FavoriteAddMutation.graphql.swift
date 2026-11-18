// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct FavoriteAddMutation: GraphQLMutation {
    static let operationName: String = "FavoriteAdd"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation FavoriteAdd($target: FavoriteTargetInput!) { favoriteAdd(target: $target) }"#
      ))

    public var target: FavoriteTargetInput

    public init(target: FavoriteTargetInput) {
      self.target = target
    }

    @_spi(Unsafe) public var __variables: Variables? { ["target": target] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("favoriteAdd", Bool.self, arguments: ["target": .variable("target")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        FavoriteAddMutation.Data.self
      ] }

      /// Добавить в избранное: ровно одно из полей цели. Повтор ничего не меняет.
      var favoriteAdd: Bool { __data["favoriteAdd"] }
    }
  }

}