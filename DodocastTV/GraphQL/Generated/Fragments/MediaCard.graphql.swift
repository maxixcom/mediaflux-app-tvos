// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct MediaCard: DCAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment MediaCard on Media { __typename id title durationMs coverUrl favorite progress { __typename positionMs durationMs watched } }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", DCAPI.ID.self),
      .field("title", String.self),
      .field("durationMs", DCAPI.Long?.self),
      .field("coverUrl", String?.self),
      .field("favorite", Bool.self),
      .field("progress", Progress?.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      MediaCard.self
    ] }

    var id: DCAPI.ID { __data["id"] }
    var title: String { __data["title"] }
    var durationMs: DCAPI.Long? { __data["durationMs"] }
    var coverUrl: String? { __data["coverUrl"] }
    var favorite: Bool { __data["favorite"] }
    /// Позиция просмотра; null — не начинал.
    var progress: Progress? { __data["progress"] }

    /// Progress
    ///
    /// Parent Type: `MediaProgress`
    nonisolated struct Progress: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.MediaProgress }
      static var __selections: [ApolloAPI.Selection] { [
        .field("__typename", String.self),
        .field("positionMs", DCAPI.Long.self),
        .field("durationMs", DCAPI.Long?.self),
        .field("watched", Bool.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        MediaCard.Progress.self
      ] }

      var positionMs: DCAPI.Long { __data["positionMs"] }
      var durationMs: DCAPI.Long? { __data["durationMs"] }
      /// Досмотрено (с 95 %) или отмечено вручную.
      var watched: Bool { __data["watched"] }
    }
  }

}