@MainActor
enum ModelIdentifierGenerator {
    private static var nextIdentifier: UInt64 = 0

    static func make() -> UInt64 {
        defer { nextIdentifier &+= 1 }
        return nextIdentifier
    }
}
