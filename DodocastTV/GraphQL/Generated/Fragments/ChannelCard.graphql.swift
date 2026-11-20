// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct ChannelCard: DCAPI.SelectionSet, Fragment {
    static var fragmentDefinition: StaticString {
      #"fragment ChannelCard on Channel { __typename id title onAir coverUrl favorite }"#
    }

    let __data: DataDict
    init(_dataDict: DataDict) { __data = _dataDict }

    static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Channel }
    static var __selections: [ApolloAPI.Selection] { [
      .field("__typename", String.self),
      .field("id", DCAPI.ID.self),
      .field("title", String.self),
      .field("onAir", Bool.self),
      .field("coverUrl", String?.self),
      .field("favorite", Bool.self),
    ] }
    static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
      ChannelCard.self
    ] }

    var id: DCAPI.ID { __data["id"] }
    var title: String { __data["title"] }
    /// Канал сейчас вещает: запущен, не остановлен, программа не пуста.
    var onAir: Bool { __data["onAir"] }
    /// Своей обложки у канала нет: обложка первого ролика текущей программы, у которого она есть (как в кабинете).
    var coverUrl: String? { __data["coverUrl"] }
    var favorite: Bool { __data["favorite"] }
  }

}