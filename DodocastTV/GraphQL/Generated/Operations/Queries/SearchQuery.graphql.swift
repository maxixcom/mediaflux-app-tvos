// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct SearchQuery: GraphQLQuery {
    static let operationName: String = "Search"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Search($text: String!) { search(text: $text, page: { size: 40 }) { __typename totalCount nodes { __typename ...MediaCard } } }"#,
        fragments: [MediaCard.self]
      ))

    public var text: String

    public init(text: String) {
      self.text = text
    }

    @_spi(Unsafe) public var __variables: Variables? { ["text": text] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("search", Search.self, arguments: [
          "text": .variable("text"),
          "page": ["size": 40]
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchQuery.Data.self
      ] }

      /// Поиск по названию своих медиа.
      var search: Search { __data["search"] }

      /// Search
      ///
      /// Parent Type: `MediaConnection`
      nonisolated struct Search: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.MediaConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("totalCount", Int.self),
          .field("nodes", [Node].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchQuery.Data.Search.self
        ] }

        var totalCount: Int { __data["totalCount"] }
        var nodes: [Node] { __data["nodes"] }

        /// Search.Node
        ///
        /// Parent Type: `Media`
        nonisolated struct Node: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(MediaCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            SearchQuery.Data.Search.Node.self,
            MediaCard.self
          ] }

          var id: DCAPI.ID { __data["id"] }
          var title: String { __data["title"] }
          var durationMs: DCAPI.Long? { __data["durationMs"] }
          var coverUrl: String? { __data["coverUrl"] }
          var favorite: Bool { __data["favorite"] }
          /// Позиция просмотра; null — не начинал.
          var progress: Progress? { __data["progress"] }

          struct Fragments: FragmentContainer {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            var mediaCard: MediaCard { _toFragment() }
          }

          typealias Progress = MediaCard.Progress
        }
      }
    }
  }

}