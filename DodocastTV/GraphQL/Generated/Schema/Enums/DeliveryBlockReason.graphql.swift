// @generated
// This file was automatically generated and should not be edited.

@_spi(Internal) import ApolloAPI

extension DCAPI {
  nonisolated enum DeliveryBlockReason: String, EnumType {
    /// Минус на балансе.
    case suspended = "SUSPENDED"
    /// Исчерпан лимит трафика тарифа за цикл.
    case trafficLimit = "TRAFFIC_LIMIT"
  }

}