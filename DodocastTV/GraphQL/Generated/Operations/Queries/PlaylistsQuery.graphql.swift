// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct PlaylistsQuery: GraphQLQuery {
    static let operationName: String = "Playlists"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Playlists { playlists(page: { size: 100 }) { __typename nodes { __typename ...PlaylistCard } } }"#,
        fragments: [PlaylistCard.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("playlists", Playlists.self, arguments: ["page": ["size": 100]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PlaylistsQuery.Data.self
      ] }

      var playlists: Playlists { __data["playlists"] }

      /// Playlists
      ///
      /// Parent Type: `PlaylistConnection`
      nonisolated struct Playlists: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.PlaylistConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("nodes", [Node].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PlaylistsQuery.Data.Playlists.self
        ] }

        var nodes: [Node] { __data["nodes"] }

        /// Playlists.Node
        ///
        /// Parent Type: `Playlist`
        nonisolated struct Node: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Playlist }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(PlaylistCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PlaylistsQuery.Data.Playlists.Node.self,
            PlaylistCard.self
          ] }

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
        }
      }
    }
  }

}