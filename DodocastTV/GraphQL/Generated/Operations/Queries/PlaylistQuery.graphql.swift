// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct PlaylistQuery: GraphQLQuery {
    static let operationName: String = "Playlist"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Playlist($id: ID!) { playlist(id: $id) { __typename ...PlaylistCard description items { __typename ...MediaCard } } }"#,
        fragments: [MediaCard.self, PlaylistCard.self]
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
        .field("playlist", Playlist?.self, arguments: ["id": .variable("id")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PlaylistQuery.Data.self
      ] }

      var playlist: Playlist? { __data["playlist"] }

      /// Playlist
      ///
      /// Parent Type: `Playlist`
      nonisolated struct Playlist: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Playlist }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("description", String?.self),
          .field("items", [Item].self),
          .fragment(PlaylistCard.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PlaylistQuery.Data.Playlist.self,
          PlaylistCard.self
        ] }

        var description: String? { __data["description"] }
        /// Элементы в порядке плейлиста.
        var items: [Item] { __data["items"] }
        var id: DCAPI.ID { __data["id"] }
        var title: String { __data["title"] }
        var itemCount: Int { __data["itemCount"] }
        /// Обложка первого элемента, у которого она есть (как в кабинете).
        var coverUrl: String? { __data["coverUrl"] }
        var favorite: Bool { __data["favorite"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var playlistCard: PlaylistCard { _toFragment() }
        }

        /// Playlist.Item
        ///
        /// Parent Type: `Media`
        nonisolated struct Item: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(MediaCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PlaylistQuery.Data.Playlist.Item.self,
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