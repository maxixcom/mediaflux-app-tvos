// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct FavoriteTargetInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      mediaId: GraphQLNullable<ID> = nil,
      playlistId: GraphQLNullable<ID> = nil,
      channelId: GraphQLNullable<ID> = nil
    ) {
      __data = InputDict([
        "mediaId": mediaId,
        "playlistId": playlistId,
        "channelId": channelId
      ])
    }

    var mediaId: GraphQLNullable<ID> {
      get { __data["mediaId"] }
      set { __data["mediaId"] = newValue }
    }

    var playlistId: GraphQLNullable<ID> {
      get { __data["playlistId"] }
      set { __data["playlistId"] = newValue }
    }

    var channelId: GraphQLNullable<ID> {
      get { __data["channelId"] }
      set { __data["channelId"] = newValue }
    }
  }

}