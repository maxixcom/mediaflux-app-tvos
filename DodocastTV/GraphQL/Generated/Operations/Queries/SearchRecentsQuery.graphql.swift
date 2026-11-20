// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct SearchRecentsQuery: GraphQLQuery {
    static let operationName: String = "SearchRecents"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query SearchRecents { searchRecents { __typename ...MediaCard } }"#,
        fragments: [MediaCard.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("searchRecents", [SearchRecent].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        SearchRecentsQuery.Data.self
      ] }

      /// Недавние поиски: материалы, на чьи карточки переходили из результатов поиска (тексты запросов не храним), — до 20,
      /// свежие первыми. Общие для всех устройств аккаунта. Скрытое не показывается.
      var searchRecents: [SearchRecent] { __data["searchRecents"] }

      /// SearchRecent
      ///
      /// Parent Type: `Media`
      nonisolated struct SearchRecent: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .fragment(MediaCard.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          SearchRecentsQuery.Data.SearchRecent.self,
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