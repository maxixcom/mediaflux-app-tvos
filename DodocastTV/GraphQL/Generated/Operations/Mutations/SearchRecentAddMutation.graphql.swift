// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct SearchRecentAddMutation: GraphQLMutation {
    static let operationName: String = "SearchRecentAdd"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation SearchRecentAdd($mediaId: ID!) { searchRecentAdd(mediaId: $mediaId) }"#
      ))

    public var mediaId: ID

    public init(mediaId: ID) {
      self.mediaId = mediaId
    }

    @_spi(Unsafe) public var __variables: Variables? { ["mediaId": mediaId] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchRecentAdd", Bool.self, arguments: ["mediaId": .variable("mediaId")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchRecentAddMutation.Data.self
      ] }

      /// Выбор из поиска (переход на карточку): материал — первым в недавних поисках. Только своё и видимое.
      var searchRecentAdd: Bool { __data["searchRecentAdd"] }
    }
  }

}