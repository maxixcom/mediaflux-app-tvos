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
      "Device": DCAPI.Objects.Device,
      "Me": DCAPI.Objects.Me,
      "Mutation": DCAPI.Objects.Mutation,
      "Query": DCAPI.Objects.Query
    ]

    static func objectType(forTypename typename: String) -> ApolloAPI.Object? {
      objectTypeMap[typename]
    }
  }

  nonisolated enum Objects {}
  nonisolated enum Interfaces {}
  nonisolated enum Unions {}

}