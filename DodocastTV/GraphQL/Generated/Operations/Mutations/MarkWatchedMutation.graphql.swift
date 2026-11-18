// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct MarkWatchedMutation: GraphQLMutation {
    static let operationName: String = "MarkWatched"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation MarkWatched($mediaId: ID!, $watched: Boolean!) { markWatched(mediaId: $mediaId, watched: $watched) { __typename positionMs watched } }"#
      ))

    public var mediaId: ID
    public var watched: Bool

    public init(
      mediaId: ID,
      watched: Bool
    ) {
      self.mediaId = mediaId
      self.watched = watched
    }

    @_spi(Unsafe) public var __variables: Variables? { [
      "mediaId": mediaId,
      "watched": watched
    ] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("markWatched", MarkWatched.self, arguments: [
          "mediaId": .variable("mediaId"),
          "watched": .variable("watched")
        ]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MarkWatchedMutation.Data.self
      ] }

      /// Отметить просмотренным (или снять отметку — тогда позиция сбрасывается на начало).
      var markWatched: MarkWatched { __data["markWatched"] }

      /// MarkWatched
      ///
      /// Parent Type: `MediaProgress`
      nonisolated struct MarkWatched: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.MediaProgress }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("positionMs", DCAPI.Long.self),
          .field("watched", Bool.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          MarkWatchedMutation.Data.MarkWatched.self
        ] }

        var positionMs: DCAPI.Long { __data["positionMs"] }
        /// Досмотрено (с 95 %) или отмечено вручную.
        var watched: Bool { __data["watched"] }
      }
    }
  }

}