// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) @_spi(Unsafe) import ApolloAPI

extension DCAPI {
  nonisolated struct ProgressReportInput: InputObject {
    private(set) var __data: InputDict

    init(_ data: InputDict) {
      __data = data
    }

    init(
      mediaId: ID,
      positionMs: Long,
      durationMs: GraphQLNullable<Long> = nil,
      reportedAt: DateTime,
      final: GraphQLNullable<Bool> = nil
    ) {
      __data = InputDict([
        "mediaId": mediaId,
        "positionMs": positionMs,
        "durationMs": durationMs,
        "reportedAt": reportedAt,
        "final": final
      ])
    }

    var mediaId: ID {
      get { __data["mediaId"] }
      set { __data["mediaId"] = newValue }
    }

    var positionMs: Long {
      get { __data["positionMs"] }
      set { __data["positionMs"] = newValue }
    }

    /// Длительность по плееру — нужна, только если сервер её не знает.
    var durationMs: GraphQLNullable<Long> {
      get { __data["durationMs"] }
      set { __data["durationMs"] = newValue }
    }

    /// Когда позиция снята, по часам устройства.
    var reportedAt: DateTime {
      get { __data["reportedAt"] }
      set { __data["reportedAt"] = newValue }
    }

    /// Пауза или выход из плеера: записать сразу.
    var final: GraphQLNullable<Bool> {
      get { __data["final"] }
      set { __data["final"] = newValue }
    }
  }

}