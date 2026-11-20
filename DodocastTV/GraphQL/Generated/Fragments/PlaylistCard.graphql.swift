// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct PlaylistCard: DCAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment PlaylistCard on Playlist { __typename id title itemCount coverUrl favorite }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Playlist }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", DCAPI.ID.self),
      .field("title", String.self),
      .field("itemCount", Int.self),
      .field("coverUrl", String?.self),
      .field("favorite", Bool.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      PlaylistCard.self
    ] }

    var id: DCAPI.ID { __data["id"] }
    var title: String { __data["title"] }
    var itemCount: Int { __data["itemCount"] }
    /// Обложка первого элемента, у которого она есть (как в кабинете).
    var coverUrl: String? { __data["coverUrl"] }
    var favorite: Bool { __data["favorite"] }
  }

}