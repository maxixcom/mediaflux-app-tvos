// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct PlaybackStartMutation: GraphQLMutation {
    static let operationName: String = "PlaybackStart"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation PlaybackStart($input: PlaybackStartInput!) { playbackStart(input: $input) { __typename url expiresAt title durationMs chapters { __typename startMs title } coverUrl previewManifestUrl resumePositionMs } }"#
      ))

    public var input: PlaybackStartInput

    public init(input: PlaybackStartInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("playbackStart", PlaybackStart.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        PlaybackStartMutation.Data.self
      ] }

      /// Адрес потока для своего медиа или канала. Ровно одно из полей входа.
      /// Ошибки: NOT_FOUND; CHANNEL_OFF_AIR; CHANNELS_NOT_IN_TARIFF; DELIVERY_BLOCKED {reason}.
      var playbackStart: PlaybackStart { __data["playbackStart"] }

      /// PlaybackStart
      ///
      /// Parent Type: `Playback`
      nonisolated struct PlaybackStart: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Playback }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("url", String.self),
          .field("expiresAt", DCAPI.DateTime.self),
          .field("title", String.self),
          .field("durationMs", DCAPI.Long?.self),
          .field("chapters", [Chapter].self),
          .field("coverUrl", String?.self),
          .field("previewManifestUrl", String?.self),
          .field("resumePositionMs", DCAPI.Long?.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          PlaybackStartMutation.Data.PlaybackStart.self
        ] }

        /// Мастер-плейлист HLS (fMP4) с токеном в пути.
        var url: String { __data["url"] }
        /// До какого времени действует токен в адресе; позже — снова playbackStart.
        var expiresAt: DCAPI.DateTime { __data["expiresAt"] }
        var title: String { __data["title"] }
        /// Длительность медиа; у канала — null.
        var durationMs: DCAPI.Long? { __data["durationMs"] }
        /// Главы медиа (если включены владельцем).
        var chapters: [Chapter] { __data["chapters"] }
        var coverUrl: String? { __data["coverUrl"] }
        var previewManifestUrl: String? { __data["previewManifestUrl"] }
        /// С какой позиции продолжить (начато и не досмотрено); null — с начала. У канала всегда null.
        var resumePositionMs: DCAPI.Long? { __data["resumePositionMs"] }

        /// PlaybackStart.Chapter
        ///
        /// Parent Type: `Chapter`
        nonisolated struct Chapter: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Chapter }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("startMs", DCAPI.Long.self),
            .field("title", String.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            PlaybackStartMutation.Data.PlaybackStart.Chapter.self
          ] }

          var startMs: DCAPI.Long { __data["startMs"] }
          var title: String { __data["title"] }
        }
      }
    }
  }

}