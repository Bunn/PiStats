import Testing

/// All tests that use `MockURLProtocol` share its process-wide request handler.
/// Nesting them below one serialized suite prevents sibling suites from
/// overwriting each other's handlers when Swift Testing runs in parallel.
@Suite("Mock network tests", .serialized)
struct MockNetworkTests {}
