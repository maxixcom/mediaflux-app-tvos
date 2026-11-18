// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct LibrariesQuery: GraphQLQuery {
    static let operationName: String = "Libraries"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"query Libraries { libraries(page: { size: 100 }) { __typename nodes { __typename id title itemCount coverUrl } } }"#
      ))

    public init() {}

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Query }
      static var __selections: [ApolloAPI.Selection] { [
        .field("libraries", Libraries.self, arguments: ["page": ["size": 100]]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        LibrariesQuery.Data.self
      ] }

      var libraries: Libraries { __data["libraries"] }

      /// Libraries
      ///
      /// Parent Type: `LibraryConnection`
      nonisolated struct Libraries: DCAPI.SelectionSet {
        let __data: DataDict
        init(_dataDict: DataDict) { __data = _dataDict }

        static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.LibraryConnection }
        static var __selections: [ApolloAPI.Selection] { [
          .field("__typename", String.self),
          .field("nodes", [Node].self),
        ] }
        static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
          LibrariesQuery.Data.Libraries.self
        ] }

        var nodes: [Node] { __data["nodes"] }

        /// Libraries.Node
        ///
        /// Parent Type: `Library`
        nonisolated struct Node: DCAPI.SelectionSet {
          let __data: DataDict
          init(_dataDict: DataDict) { __data = _dataDict }

          static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Library }
          static var __selections: [ApolloAPI.Selection] { [
            .field("__typename", String.self),
            .field("id", DCAPI.ID.self),
            .field("title", String.self),
            .field("itemCount", Int.self),
            .field("coverUrl", String?.self),
          ] }
          static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
            LibrariesQuery.Data.Libraries.Node.self
          ] }

          var id: DCAPI.ID { __data["id"] }
          var title: String { __data["title"] }
          var itemCount: Int { __data["itemCount"] }
          /// Обложка самого свежего медиа библиотеки.
          var coverUrl: String? { __data["coverUrl"] }
        }
      }
    }
  }

}