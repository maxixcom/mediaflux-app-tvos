// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct MediaQuery: GraphQLQuery {
    static let operationName: String = "Media"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Media($id: ID!) { media(id: $id) { __typename ...MediaCard description createdAt } }"#,
        fragments: [MediaCard.self]
      ))

    public var id: ID

    public init(id: ID) {
      self.id = id
    }

    @_spi(Unsafe) public var __variables: Variables? { ["id": id] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("media", Media?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MediaQuery.Data.self
      ] }

      var media: Media? { __data["media"] }

      /// Media
      ///
      /// Parent Type: `Media`
      nonisolated struct Media: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("description", String?.self),
          .field("createdAt", DCAPI.DateTime.self),
          .fragment(MediaCard.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MediaQuery.Data.Media.self,
          MediaCard.self
        ] }

        var description: String? { __data["description"] }
        var createdAt: DCAPI.DateTime { __data["createdAt"] }
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