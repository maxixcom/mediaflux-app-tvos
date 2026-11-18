// @generated
// This file was automatically generated and should not be edited.

@_exported import ApolloAPI
@_spi(Execution) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct ProgressReportMutation: GraphQLMutation {
    static let operationName: String = "ProgressReport"
    static let operationDocument: ApolloAPI.OperationDocument = .init(
      definition: .init(
        #"mutation ProgressReport($input: ProgressReportInput!) { progressReport(input: $input) }"#
      ))

    public var input: ProgressReportInput

    public init(input: ProgressReportInput) {
      self.input = input
    }

    @_spi(Unsafe) public var __variables: Variables? { ["input": input] }

    nonisolated struct Data: DCAPI.SelectionSet {
      let __data: DataDict
      init(_dataDict: DataDict) { __data = _dataDict }

      static var __parentType: any ApolloAPI.ParentType { DCAPI.Objects.Mutation }
      static var __selections: [ApolloAPI.Selection] { [
        .field("progressReport", Bool.self, arguments: ["input": .variable("input")]),
      ] }
      static var __fulfilledFragments: [any ApolloAPI.SelectionSet.Type] { [
        ProgressReportMutation.Data.self
      ] }

      /// Позиция просмотра. Слать раз в 10–15 с во время игры, при паузе и выходе из плеера — сразу с `final: true`.
      /// Перед сменой сервера — дослать накопленное. Не чаще раза в 5 с с устройства (всплеск до 3) — иначе RATE_LIMITED.
      /// Между устройствами побеждает поздний отчёт по `reportedAt`.
      var progressReport: Bool { __data["progressReport"] }
    }
  }

}