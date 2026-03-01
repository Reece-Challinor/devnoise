import Foundation

enum RemapCaptureError: Error, Equatable {
    case alreadyCapturing
    case permissionDenied
    case eventTapUnavailable
    case invalidChord
    case cancelled
    case timedOut
}
