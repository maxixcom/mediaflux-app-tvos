// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct SearchRecentsClearMutation: GraphQLMutation {
    static let operationName: String = "SearchRecentsClear"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SearchRecentsClear { searchRecentsClear }"#
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchRecentsClear", Bool.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchRecentsClearMutation.Data.self
      ] }

      /// Очистить недавние поиски — на всех устройствах аккаунта.
      var searchRecentsClear: Bool { __data["searchRecentsClear"] }
    }
  }

}