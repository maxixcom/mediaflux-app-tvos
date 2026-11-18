// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct ChannelsQuery: GraphQLQuery {
    static let operationName: String = "Channels"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Channels { channels { __typename ...ChannelCard description } }"#,
        fragments: [ChannelCard.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("channels", [Channel].self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ChannelsQuery.Data.self
      ] }

      /// Каналы владельца. Пусто, если каналы закрыты тарифом.
      var channels: [Channel] { __data["channels"] }

      /// Channel
      ///
      /// Parent Type: `Channel`
      nonisolated struct Channel: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Channel }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("description", String?.self),
          .fragment(ChannelCard.self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          ChannelsQuery.Data.Channel.self,
          ChannelCard.self
        ] }

        var description: String? { __data["description"] }
        var id: DCAPI.ID { __data["id"] }
        var title: String { __data["title"] }
        /// Канал сейчас вещает: запущен, не остановлен, программа не пуста.
        var onAir: Bool { __data["onAir"] }
        var favorite: Bool { __data["favorite"] }

        struct Fragments: FragmentContainer {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          var channelCard: ChannelCard { _toFragment() }
        }
      }
    }
  }

}