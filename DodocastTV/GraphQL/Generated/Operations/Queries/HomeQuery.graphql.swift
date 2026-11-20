// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct HomeQuery: GraphQLQuery {
    static let operationName: String = "Home"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Home { home { __typename continueWatching { __typename ...MediaCard } recent { __typename ...MediaCard } favorites { __typename ... on Media { ...MediaCard } ... on Playlist { ...PlaylistCard } ... on Channel { ...ChannelCard } } shelves { __typename library { __typename id title itemCount } items { __typename ...MediaCard } } channels { __typename ...ChannelCard } } }"#,
        fragments: [ChannelCard.self, MediaCard.self, PlaylistCard.self]
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("home", Home.self),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        HomeQuery.Data.self
      ] }

      /// Главный экран: недавно добавленные, полка на библиотеку, каналы. «Продолжить просмотр» — в Э2.
      var home: Home { __data["home"] }

      /// Home
      ///
      /// Parent Type: `Home`
      nonisolated struct Home: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Home }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("continueWatching", [ContinueWatching].self),
          .field("recent", [Recent].self),
          .field("favorites", [Favorite].self),
          .field("shelves", [Shelf].self),
          .field("channels", [Channel].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          HomeQuery.Data.Home.self
        ] }

        var continueWatching: [ContinueWatching] { __data["continueWatching"] }
        var recent: [Recent] { __data["recent"] }
        var favorites: [Favorite] { __data["favorites"] }
        var shelves: [Shelf] { __data["shelves"] }
        var channels: [Channel] { __data["channels"] }

        /// Home.ContinueWatching
        ///
        /// Parent Type: `Media`
        nonisolated struct ContinueWatching: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(MediaCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            HomeQuery.Data.Home.ContinueWatching.self,
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

        /// Home.Recent
        ///
        /// Parent Type: `Media`
        nonisolated struct Recent: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(MediaCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            HomeQuery.Data.Home.Recent.self,
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

        /// Home.Favorite
        ///
        /// Parent Type: `FavoriteItem`
        nonisolated struct Favorite: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Unions.FavoriteItem }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .inlineFragment(AsMedia.self),
            .inlineFragment(AsPlaylist.self),
            .inlineFragment(AsChannel.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            HomeQuery.Data.Home.Favorite.self
          ] }

          var asMedia: AsMedia? { _asInlineFragment() }
          var asPlaylist: AsPlaylist? { _asInlineFragment() }
          var asChannel: AsChannel? { _asInlineFragment() }

          /// Home.Favorite.AsMedia
          ///
          /// Parent Type: `Media`
          nonisolated struct AsMedia: DCAPI.InlineFragment {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            typealias RootEntityType = HomeQuery.Data.Home.Favorite
            static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Media }
            static var __selections: [ApolloAPI.Selection] { [
              .fragment(MediaCard.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              HomeQuery.Data.Home.Favorite.self,
              HomeQuery.Data.Home.Favorite.AsMedia.self,
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

          /// Home.Favorite.AsPlaylist
          ///
          /// Parent Type: `Playlist`
          nonisolated struct AsPlaylist: DCAPI.InlineFragment {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            typealias RootEntityType = HomeQuery.Data.Home.Favorite
            static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Playlist }
            static var __selections: [ApolloAPI.Selection] { [
              .fragment(PlaylistCard.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              HomeQuery.Data.Home.Favorite.self,
              HomeQuery.Data.Home.Favorite.AsPlaylist.self,
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

          /// Home.Favorite.AsChannel
          ///
          /// Parent Type: `Channel`
          nonisolated struct AsChannel: DCAPI.InlineFragment {
            let __data: DataDict
            init(_dataDict: DataDict) { __data = _dataDict }

            typealias RootEntityType = HomeQuery.Data.Home.Favorite
            static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Channel }
            static var __selections: [ApolloAPI.Selection] { [
              .fragment(ChannelCard.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              HomeQuery.Data.Home.Favorite.self,
              HomeQuery.Data.Home.Favorite.AsChannel.self,
              ChannelCard.self
            ] }

            var id: DCAPI.ID { __data["id"] }
            var title: String { __data["title"] }
            /// Канал сейчас вещает: запущен, не остановлен, программа не пуста.
            var onAir: Bool { __data["onAir"] }
            /// Своей обложки у канала нет: обложка первого ролика текущей программы, у которого она есть (как в кабинете).
            var coverUrl: String? { __data["coverUrl"] }
            var favorite: Bool { __data["favorite"] }

            struct Fragments: FragmentContainer {
              let __data: DataDict
              init(_dataDict: DataDict) { __data = _dataDict }

              var channelCard: ChannelCard { _toFragment() }
            }
          }
        }

        /// Home.Shelf
        ///
        /// Parent Type: `Shelf`
        nonisolated struct Shelf: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Shelf }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("library", Library.self),
            .field("items", [Item].self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            HomeQuery.Data.Home.Shelf.self
          ] }

          var library: Library { __data["library"] }
          var items: [Item] { __data["items"] }

          /// Home.Shelf.Library
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
              .field("itemCount", Int.self),
            ] }
            static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
              HomeQuery.Data.Home.Shelf.Library.self
            ] }

            var id: DCAPI.ID { __data["id"] }
            var title: String { __data["title"] }
            var itemCount: Int { __data["itemCount"] }
          }

          /// Home.Shelf.Item
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
              HomeQuery.Data.Home.Shelf.Item.self,
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

        /// Home.Channel
        ///
        /// Parent Type: `Channel`
        nonisolated struct Channel: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Channel }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .fragment(ChannelCard.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            HomeQuery.Data.Home.Channel.self,
            ChannelCard.self
          ] }

          var id: DCAPI.ID { __data["id"] }
          var title: String { __data["title"] }
          /// Канал сейчас вещает: запущен, не остановлен, программа не пуста.
          var onAir: Bool { __data["onAir"] }
          /// Своей обложки у канала нет: обложка первого ролика текущей программы, у которого она есть (как в кабинете).
          var coverUrl: String? { __data["coverUrl"] }
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

}