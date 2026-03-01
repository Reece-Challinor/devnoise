import CoreAudio
import Foundation

final class RouteObserver {
    enum RouteKind: String {
        case defaultOutput = "default-output"
        case defaultSystemOutput = "default-system-output"
    }

    struct RouteChange: Equatable {
        let kind: RouteKind
        let previousDeviceID: AudioDeviceID?
        let newDeviceID: AudioDeviceID?
    }

    typealias RouteChangeHandler = (RouteChange) -> Void

    private let listenerQueue: DispatchQueue
    private let routeChangeHandler: RouteChangeHandler

    private var isObserving = false
    private var lastKnownDefaultOutputDeviceID: AudioDeviceID?
    private var lastKnownDefaultSystemOutputDeviceID: AudioDeviceID?

    private lazy var defaultOutputListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.processChange(for: kAudioHardwarePropertyDefaultOutputDevice)
    }

    private lazy var defaultSystemOutputListener: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
        self?.processChange(for: kAudioHardwarePropertyDefaultSystemOutputDevice)
    }

    init(
        listenerQueue: DispatchQueue = .main,
        routeChangeHandler: @escaping RouteChangeHandler
    ) {
        self.listenerQueue = listenerQueue
        self.routeChangeHandler = routeChangeHandler
    }

    deinit {
        stopObserving()
    }

    func startObserving() {
        guard !isObserving else {
            return
        }

        lastKnownDefaultOutputDeviceID = currentDeviceID(for: kAudioHardwarePropertyDefaultOutputDevice)
        lastKnownDefaultSystemOutputDeviceID = currentDeviceID(for: kAudioHardwarePropertyDefaultSystemOutputDevice)

        addListener(for: kAudioHardwarePropertyDefaultOutputDevice, block: defaultOutputListener)
        addListener(for: kAudioHardwarePropertyDefaultSystemOutputDevice, block: defaultSystemOutputListener)

        isObserving = true
    }

    func stopObserving() {
        guard isObserving else {
            return
        }

        removeListener(for: kAudioHardwarePropertyDefaultOutputDevice, block: defaultOutputListener)
        removeListener(for: kAudioHardwarePropertyDefaultSystemOutputDevice, block: defaultSystemOutputListener)

        isObserving = false
        lastKnownDefaultOutputDeviceID = nil
        lastKnownDefaultSystemOutputDeviceID = nil
    }

    private func processChange(for selector: AudioObjectPropertySelector) {
        switch selector {
        case kAudioHardwarePropertyDefaultOutputDevice:
            let currentDeviceID = currentDeviceID(for: selector)
            guard currentDeviceID != lastKnownDefaultOutputDeviceID else {
                return
            }
            let change = RouteChange(
                kind: .defaultOutput,
                previousDeviceID: lastKnownDefaultOutputDeviceID,
                newDeviceID: currentDeviceID
            )
            lastKnownDefaultOutputDeviceID = currentDeviceID
            routeChangeHandler(change)

        case kAudioHardwarePropertyDefaultSystemOutputDevice:
            let currentDeviceID = currentDeviceID(for: selector)
            guard currentDeviceID != lastKnownDefaultSystemOutputDeviceID else {
                return
            }
            let change = RouteChange(
                kind: .defaultSystemOutput,
                previousDeviceID: lastKnownDefaultSystemOutputDeviceID,
                newDeviceID: currentDeviceID
            )
            lastKnownDefaultSystemOutputDeviceID = currentDeviceID
            routeChangeHandler(change)

        default:
            break
        }
    }

    private func addListener(
        for selector: AudioObjectPropertySelector,
        block: @escaping AudioObjectPropertyListenerBlock
    ) {
        var address = propertyAddress(for: selector)
        _ = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            listenerQueue,
            block
        )
    }

    private func removeListener(
        for selector: AudioObjectPropertySelector,
        block: @escaping AudioObjectPropertyListenerBlock
    ) {
        var address = propertyAddress(for: selector)
        _ = AudioObjectRemovePropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            listenerQueue,
            block
        )
    }

    private func currentDeviceID(for selector: AudioObjectPropertySelector) -> AudioDeviceID? {
        var address = propertyAddress(for: selector)
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr else {
            return nil
        }

        if deviceID == AudioDeviceID(0) {
            return nil
        }
        return deviceID
    }

    private func propertyAddress(for selector: AudioObjectPropertySelector) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
    }
}
