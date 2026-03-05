import Foundation
import CheBiblatexMCPCore

do {
    let server = try await CheBiblatexMCPServer()
    try await server.run()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
