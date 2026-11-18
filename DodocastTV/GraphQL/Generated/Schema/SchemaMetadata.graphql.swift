// @generated
// This file was automatically generated and should not be edited.

import ApolloAPI

nonisolated protocol DCAPI_SelectionSet: ApolloAPI.SelectionSet & ApolloAPI.RootSelectionSet
where Schema == DCAPI.SchemaMetadata {}

nonisolated protocol DCAPI_InlineFragment: ApolloAPI.SelectionSet & ApolloAPI.InlineFragment
where Schema == DCAPI.SchemaMetadata {}

nonisolated protocol DCAPI_MutableSelectionSet: ApolloAPI.MutableRootSelectionSet
where Schema == DCAPI.SchemaMetadata {}

nonisolated protocol DCAPI_MutableInlineFragment: ApolloAPI.MutableSelectionSet & ApolloAPI.InlineFragment
where Schema == DCAPI.SchemaMetadata {}

extension DCAPI {
  typealias SelectionSet = DCAPI_SelectionSet

  typealias InlineFragment = DCAPI_InlineFragment

  typealias MutableSelectionSet = DCAPI_MutableSelectionSet

  typealias MutableInlineFragment = DCAPI_MutableInlineFragment

  nonisolated enum SchemaMetadata: ApolloAPI.SchemaMetadata {
    static let configuration: any ApolloAPI.SchemaConfiguration.Type = SchemaConfiguration.self

    private static let objectTypeMap: [String: ApolloAPI.Object] = [
      "Channel": DCAPI.Objects.Channel,
      "Chapter": DCAPI.Objects.Chapter,
      "Device": DCAPI.Objects.Device,
      "Home": DCAPI.Objects.Home,
      "Library": DCAPI.Objects.Library,
      "LibraryConnection": DCAPI.Objects.LibraryConnection,
      "Me": DCAPI.Objects.Me,
      "Media": DCAPI.Objects.Media,
      "MediaConnection": DCAPI.Objects.MediaConnection,
      "MediaProgress": DCAPI.Objects.MediaProgress,
      "Mutation": DCAPI.Objects.Mutation,
      "Playback": DCAPI.Objects.Playback,
      "Playlist": DCAPI.Objects.Playlist,
      "PlaylistConnection": DCAPI.Objects.PlaylistConnection,
      "Query": DCAPI.Objects.Query,
      "Shelf": DCAPI.Objects.Shelf
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}