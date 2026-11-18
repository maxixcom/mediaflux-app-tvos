// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct LibraryQuery: GraphQLQuery {
    static let operationName: String = "Library"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Library($id: ID!, $page: PageInput) { library(id: $id) { __typename id title description itemCount items(page: $page) { __typename totalCount nodes { __typename ...MediaCard } } } }"#,
        fragments: [MediaCard.self]
      ))

    public var id: ID
    public var page: GraphQLNullable<PageInput>

    public init(
      id: ID,
      page: GraphQLNullable<PageInput>
    ) {
      self.id = id
      self.page = page
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "id": id,
      "page": page
    ] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("library", Library?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LibraryQuery.Data.self
      ] }

      var library: Library? { __data["library"] }

      /// Library
      ///
      /// Parent Type: `Library`
      nonisolated struct Library: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Library }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("id", DCAPI.ID.self),
          .field("title", String.self),
          .field("description", String?.self),
          .field("itemCount", Int.self),
          .field("items", Items.self, arguments: ["page": .variable("page")]),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LibraryQuery.Data.Library.self
        ] }

        var id: DCAPI.ID { __data["id"] }
        var title: String { __data["title"] }
        var description: String? { __data["description"] }
        var itemCount: Int { __data["itemCount"] }
        /// Медиа библиотеки, новые сверху.
        var items: Items { __data["items"] }

        /// Library.Items
        ///
        /// Parent Type: `MediaConnection`
        nonisolated struct Items: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.MediaConnection }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("totalCount", Int.self),
            .field("nodes", [Node].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LibraryQuery.Data.Library.Items.self
          ] }

          var totalCount: Int { __data["totalCount"] }
          var nodes: [Node] { __data["nodes"] }

          /// Library.Items.Node
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
              LibraryQuery.Data.Library.Items.Node.self,
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

}