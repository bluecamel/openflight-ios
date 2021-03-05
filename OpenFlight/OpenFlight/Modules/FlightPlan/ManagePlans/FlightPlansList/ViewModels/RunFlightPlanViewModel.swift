//
//  Copyright (C) 2020 Parrot Drones SAS.
//
//    Redistribution and use in source and binary forms, with or without
//    modification, are permitted provided that the following conditions
//    are met:
//    * Redistributions of source code must retain the above copyright
//      notice, this list of conditions and the following disclaimer.
//    * Redistributions in binary form must reproduce the above copyright
//      notice, this list of conditions and the following disclaimer in
//      the documentation and/or other materials provided with the
//      distribution.
//    * Neither the name of the Parrot Company nor the names
//      of its contributors may be used to endorse or promote products
//      derived from this software without specific prior written
//      permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
//    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
//    PARROT COMPANY BE LIABLE FOR ANY DIRECT, INDIRECT,
//    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
//    OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
//    AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
//    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
//    OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
//    SUCH DAMAGE.

import GroundSdk

// MARK: - RunFlightPlanListener
/// Listener for `RunFlightPlanViewModel` state updates.
final class RunFlightPlanListener: NSObject {
    let didChange: RunFlightPlanListenerClosure
    init(didChange: @escaping RunFlightPlanListenerClosure) {
        self.didChange = didChange
    }
}

/// Alias for `RunFlightPlanListener` closure.
typealias RunFlightPlanListenerClosure = (RunFlightPlanState) -> Void

// MARK: - Internal Enum

/// Defines flight plan running state.
enum FlightPlanRunningState {
    case playing
    case paused
    case stopped
    case userStopped
    case uploading

    var isActive: Bool {
        switch self {
        case .playing,
             .paused,
             .uploading:
            return true
        default:
            return false
        }
    }
}

/// State for `RunFlightPlanViewModel`.

final class RunFlightPlanState: DeviceConnectionState {
    // MARK: - Internal Properties
    var isAvailable: Bool {
        return isConnected() && unavailabilityReasons.hasNoBlockingIssue
    }
    var formattedDuration: String? {
        switch runState {
        case .playing,
             .paused:
            return duration.formattedString
        default:
            return nil
        }
    }

    // MARK: - Private Properties
    // MARK: Utility properties
    /// Flight Plan running duration.
    fileprivate var duration: TimeInterval = 0.0
    /// Flight Plan run state.
    fileprivate(set) var runState: FlightPlanRunningState = .stopped {
        didSet {
            if runState == .stopped || runState == .userStopped {
                duration = 0.0
            }
        }
    }
    /// File is up to date, used in complement with isFileKnownByDrone
    /// to make sure the last Flight Plan version is uploaded.
    fileprivate(set) var isFileUpToDate: Bool = false

    // MARK: SDK properties
    /// Activation error.
    fileprivate(set) var activationError: FlightPlanActivationError = .none
    /// Flight Plan piloting state.
    fileprivate(set) var pilotingState: ActivablePilotingItfState = .idle
    /// Flight Plan upload state.
    fileprivate(set) var uploadState: FlightPlanFileUploadState = .none
    /// Unavailability reasons.
    fileprivate(set) var unavailabilityReasons: Set<FlightPlanUnavailabilityReason> = []
    /// File is known by the drone. Returns `true` if the drone has a Flight Plan to run.
    fileprivate(set) var isFileKnownByDrone: Bool = false
    /// Latest mission item executed.
    fileprivate(set) var latestItemExecuted: Int?
    /// MAVLink commands.
    fileprivate(set) var mavlinkCommands: [MavlinkCommand] = []
    /// Whether Flight Plan is completed. Transient state.
    fileprivate(set) var completed: Bool = false
    /// Current completion progress (from 0.0 to 1.0).
    fileprivate(set) var progress: Double = 0.0
    /// Traveled distance.
    fileprivate(set) var distance: Double = 0.0

    /// Returns last passed waypoint index.
    fileprivate var lastPassedWayPointIndex: Int? {
        guard let latestItem = self.latestItemExecuted else { return nil }

        return mavlinkCommands
            .prefix(latestItem + 1)
            .filter { $0 is NavigateToWaypointCommand }
            .count - 1
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///     - connectionState: connection state
    ///     - runState: run state
    ///     - activationError: activation error
    ///     - pilotingState: piloting state
    ///     - uploadState: upload state
    ///     - unavailabilityReasons: unavailability reasons
    ///     - isFileKnownByDrone: is file known by drone
    ///     - isFileUpToDate: is file up to date
    ///     - duration: running duration
    ///     - latestItemExecuted: latest mission item executed
    ///     - mavlinkCommands: MAVLink commands for current Flight Plan
    ///     - completed: whether Flight Plan is completed
    ///     - progress: current completion progress
    ///     - distance: traveled distance
    init(connectionState: DeviceState.ConnectionState,
         runState: FlightPlanRunningState,
         activationError: FlightPlanActivationError,
         pilotingState: ActivablePilotingItfState,
         uploadState: FlightPlanFileUploadState,
         unavailabilityReasons: Set<FlightPlanUnavailabilityReason>,
         isFileKnownByDrone: Bool,
         isFileUpToDate: Bool,
         duration: TimeInterval,
         latestItemExecuted: Int?,
         mavlinkCommands: [MavlinkCommand],
         completed: Bool,
         progress: Double,
         distance: Double) {
        super.init(connectionState: connectionState)

        self.runState = runState
        self.activationError = activationError
        self.uploadState = uploadState
        self.pilotingState = pilotingState
        self.unavailabilityReasons = unavailabilityReasons
        self.isFileKnownByDrone = isFileKnownByDrone
        self.isFileUpToDate = isFileUpToDate
        self.duration = duration
        self.latestItemExecuted = latestItemExecuted
        self.mavlinkCommands = mavlinkCommands
        self.completed = completed
        self.progress = progress
        self.distance = distance
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? RunFlightPlanState else {
            return false
        }
        return super.isEqual(to: other)
            && self.runState == other.runState
            && self.activationError == other.activationError
            && self.uploadState == other.uploadState
            && self.pilotingState == other.pilotingState
            && self.isAvailable == other.isAvailable
            && self.isFileKnownByDrone == other.isFileKnownByDrone
            && self.isFileUpToDate == other.isFileUpToDate
            && self.duration == other.duration
            && self.latestItemExecuted == other.latestItemExecuted
            && self.completed == other.completed
            && self.progress == other.progress
            && self.distance == other.distance
    }

    override func copy() -> RunFlightPlanState {
        return RunFlightPlanState(connectionState: self.connectionState,
                                  runState: self.runState,
                                  activationError: self.activationError,
                                  pilotingState: self.pilotingState,
                                  uploadState: self.uploadState,
                                  unavailabilityReasons: self.unavailabilityReasons,
                                  isFileKnownByDrone: self.isFileKnownByDrone,
                                  isFileUpToDate: self.isFileUpToDate,
                                  duration: self.duration,
                                  latestItemExecuted: self.latestItemExecuted,
                                  mavlinkCommands: self.mavlinkCommands,
                                  completed: self.completed,
                                  progress: self.progress,
                                  distance: self.distance)
    }
}

/// RunFlightPlanViewModel is used to run a Flight Plan on the drone.

final class RunFlightPlanViewModel: DroneStateViewModel<RunFlightPlanState> {
    // MARK: - Private Properties
    private var flightPlanPilotingRef: Ref<FlightPlanPilotingItf>?
    private weak var flightPlanViewModel: FlightPlanViewModel?
    private var runningTimer: Timer?
    private var flightPlanExecution: FlightPlanExecution?
    private var didStartExecution: Bool = false
    private var initialObstacleAvoidance: ObstacleAvoidanceMode?

    // MARK: - Private Enums
    private enum Constants {
        static let timerDelay: Double = 1.0
        static let progressRoundPrecision: Int = 2
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///     - flightPlanViewModel: Flight Plan view model
    ///     - stateDidUpdate: state did update closure
    init(flightPlanViewModel: FlightPlanViewModel,
         stateDidUpdate: ((RunFlightPlanState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)
        self.flightPlanViewModel = flightPlanViewModel
    }

    // MARK: - Deinit
    deinit {
        flightPlanPilotingRef = nil
        stopRunningTimer()
        restoreObstacleAvoidanceSetting()
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenFlightPlanPiloting(drone: drone)
        initObstacleAvoidance(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        if state.value.isConnected(),
           let drone = self.drone {
            initObstacleAvoidance(drone: drone)
        }
    }

    // MARK: - Internal Funcs
    /// Toggle play/pause.
    func togglePlayPause() {
        let state = self.state.value
        guard state.runState != .uploading,
              state.isConnected()
        else { return }

        state.runState == .playing ? pause() : play()
    }

    /// Resume execution.
    ///
    /// - Parameters:
    ///     - execution: Flight plan execution to resume.
    /// - Returns: if resume will happen or not.
    func resume(_ execution: FlightPlanExecution) -> Bool {
        guard self.drone?.isConnected == true,
              self.state.value.runState.isActive == false else {
            return false
        }

        self.flightPlanExecution = execution
        play()

        return true
    }

    /// Stop Flight Plan.
    func stop() {
        if self.getPilotingItf()?.deactivate() ?? false {
            self.flightPlanExecution?.state = FlightPlanExecutionState.stopped
            let copy = self.state.value.copy()
            copy.runState = .userStopped
            self.state.set(copy)
        }
    }

    /// Removes current MAVLink commands and flags the Flight Plan file as not up to date.
    /// Should be called when Flight Plan gets modified.
    func resetMavlinkCommands() {
        let copy = self.state.value.copy()
        copy.mavlinkCommands = []
        copy.isFileUpToDate = false
        self.state.set(copy)
    }
}

// MARK: - Private Funcs
private extension RunFlightPlanViewModel {
    // MARK: - Obstacle Avoidance
    /// Save initial obstacle avoidance drone setting.
    ///
    /// - Parameters:
    ///     - drone: drone
    func initObstacleAvoidance(drone: Drone) {
        if initialObstacleAvoidance == nil,
           let obstacleAvoidance = drone.getPeripheral(Peripherals.obstacleAvoidance)?.mode.value {
            initialObstacleAvoidance = obstacleAvoidance
        }
    }

    /// Set obstacle avoidance mode.
    ///
    /// - Parameters:
    ///     - mode: obstacle avoidance mode
    func setObstacleAvoidanceMode(_ mode: ObstacleAvoidanceMode) {
        drone?.getPeripheral(Peripherals.obstacleAvoidance)?.mode.value = mode
    }

    /// Restore drone's obstacle avoidance to its setting.
    /// Should be called when flight plan run is done.
    func restoreObstacleAvoidanceSetting() {
        guard let oaMode = initialObstacleAvoidance else { return }

        setObstacleAvoidanceMode(oaMode)
    }

    /// Apply obstacle avoidance setting.
    /// Should be called on flight plan's activation.
    func applyObstacleAvoidanceSetting() {
        if let obstacleAvoidanceActivated = flightPlanViewModel?.flightPlan?.obstacleAvoidanceActivated {
            let mode: ObstacleAvoidanceMode = obstacleAvoidanceActivated ? .standard : .disabled
            setObstacleAvoidanceMode(mode)
        }
    }

    // MARK: - Listen Flight Plan piloting interface
    /// Listen FlightPlan Piloting Interface.
    func listenFlightPlanPiloting(drone: Drone) {
        flightPlanPilotingRef = drone.getPilotingItf(PilotingItfs.flightPlan) { [weak self] flightPlanPiloting in
            guard let strongSelf = self,
                let pilotingItf = flightPlanPiloting else { return }

            let copy = strongSelf.state.value.copy()
            copy.activationError = pilotingItf.latestActivationError
            copy.pilotingState = pilotingItf.state
            copy.uploadState = pilotingItf.latestUploadState
            copy.unavailabilityReasons = pilotingItf.unavailabilityReasons
            copy.isFileKnownByDrone = pilotingItf.flightPlanFileIsKnown
            copy.latestItemExecuted = pilotingItf.latestMissionItemExecuted

            strongSelf.flightPlanExecution?.latestItemExecuted = pilotingItf.latestMissionItemExecuted

            // If a flight plan is active and reach the first way point, we start a new execution.
            if pilotingItf.state == .active,
               (pilotingItf.latestMissionItemExecuted ?? 0) > 0,
               strongSelf.state.value.runState == .playing,
               strongSelf.didStartExecution == false {
                strongSelf.startFlightPlanExecution()
            } else if pilotingItf.state == .idle,
                      strongSelf.state.value.runState == .userStopped {
                strongSelf.handleFlightEnds()
            }

            switch pilotingItf.state {
            case .unavailable:
                // Reset run state.
                copy.runState = .stopped
            case .idle where self?.state.value.runState == .playing:
                // Ends Flight Plan.
                strongSelf.handleFlightEnds()
                copy.runState = .stopped
                copy.completed = true
                DispatchQueue.main.async { [weak self] in
                    let copy = self?.state.value.copy()
                    copy?.completed = false
                    self?.state.set(copy)
                }
            case .active where self?.state.value.runState == .stopped:
                // Handle stop, then start case.
                copy.runState = .playing
                strongSelf.startRunningTimer(resetStartDate: true)
            default:
                break
            }

            switch pilotingItf.latestUploadState {
            case .uploading:
                copy.runState = .uploading
            case .uploaded where copy.runState == .uploading:
                // Try to handle auto play
                // directly via flightPlanPiloting to ease state change.
                if copy.pilotingState == .idle {
                    // Ends upload: start fight plan.
                    copy.runState = .playing
                    if self?.activate(isPaused: false ) ?? false {
                        self?.startRunningTimer(resetStartDate: true)
                    }
                }
            case .failed:
                copy.runState = .stopped
                strongSelf.flightPlanExecution?.state = FlightPlanExecutionState.error
            case .none where copy.runState == .uploading:
                copy.runState = .stopped
            default:
                break
            }

            strongSelf.state.set(copy)
        }
    }

    // MARK: - Helpers
    /// Helper to retrieve current FlightPlanPilotingItf in a safe way.
    /// - Returns: FlightPlanPilotingItf as optional
    func getPilotingItf() -> FlightPlanPilotingItf? {
        return self.drone?.getPilotingItf(PilotingItfs.flightPlan)
    }

    /// Activate flight plan.
    ///
    /// - Parameters:
    ///     - isPaused: flight plan execution was paused or not
    /// - Returns: success.
    func activate(isPaused: Bool) -> Bool {
        guard let interface = self.getPilotingItf() else { return false }

        var interpreter: FlightPlanInterpreter = .legacy
        if let flightPlan = self.flightPlanViewModel?.flightPlan,
           let fpStringType = flightPlan.type,
           let flightPlanType = FlightPlanTypeManager.shared.typeForKey(fpStringType) {
            interpreter = flightPlanType.mavLinkType
        }

        let activationSuccess: Bool
        if let missionItem = flightPlanExecution?.latestItemExecuted, missionItem > 1 {
            // FIXME: latestItemExecuted has currently one increment more (SDK related).
            activationSuccess = interface.activate(restart: !isPaused,
                                                   interpreter: interpreter,
                                                   missionItem: missionItem - 1)
        } else {
            activationSuccess = interface.activate(restart: !isPaused,
                                                   interpreter: interpreter)
        }

        if activationSuccess {
            // Apply OA setting when FP was activated.
            applyObstacleAvoidanceSetting()
        }

        return activationSuccess
    }

    // MARK: - Controls
    /// Plays or uploads Flight Plan regarding state.
    func play() {
        let state = self.state.value
        if state.isFileKnownByDrone,
           state.isFileUpToDate {
            let isPaused = state.runState == .paused
            if activate(isPaused: isPaused) {
                let copy = self.state.value.copy()
                copy.runState = .playing
                self.state.set(copy)
                startRunningTimer(resetStartDate: !isPaused)
            }
        } else if state.isAvailable {
            self.sendMavlinkToDevice()
        }
    }

    /// Pause Flight Plan.
    func pause() {
        if self.getPilotingItf()?.deactivate() ?? false {
            stopRunningTimer()
            let copy = self.state.value.copy()
            copy.runState = .paused
            self.state.set(copy)
        }
    }

    /// Send mavlink to device.
    func sendMavlinkToDevice() {
        // Generate mavlink file from Flight Plan.
        guard let flightPlan = self.flightPlanViewModel?.flightPlan,
              let path = flightPlan.mavlinkDefaultUrl?.path
        else {
            return
        }
        // Update state, assuming SDK's uploadFlightPlan will work.
        let copy = self.state.value.copy()
        if flightPlan.canGenerateMavlink == false,
           FileManager.default.fileExists(atPath: path) {
            // Do not generate Mavlink, use the stored one.
        } else {
            // Generate Mavlink from flight plan.
            let mavlinkCommands = FlightPlanManager.shared.generateMavlinkCommands(for: flightPlan)
            MavlinkFiles.generate(filepath: path, commands: mavlinkCommands)
            copy.mavlinkCommands = mavlinkCommands
        }
        copy.isFileUpToDate = true
        self.state.set(copy)
        // Send Mavlink to drone.
        self.getPilotingItf()?.uploadFlightPlan(filepath: path)
    }

    // MARK: - Timer
    /// Starts timer for running time.
    ///
    /// - Parameters:
    ///     - resetStartDate: reset start date if true
    func startRunningTimer(resetStartDate: Bool) {
        if resetStartDate {
            let copy = self.state.value.copy()
            copy.duration = 0.0
            self.state.set(copy)
        }
        runningTimer?.invalidate()
        runningTimer = Timer.scheduledTimer(withTimeInterval: Constants.timerDelay,
                                            repeats: true,
                                            block: { [weak self] _ in
                                                self?.updateDuration()
                                                self?.updateProgress()
                                            })
        runningTimer?.fire()
    }

    /// Stops timer for running time.
    func stopRunningTimer() {
        runningTimer?.invalidate()
        runningTimer = nil
    }

    /// Updates Flight Plan's duration.
    func updateDuration() {
        switch self.state.value.runState {
        // Start timer when the first item is reached.
        case .playing where self.state.value.latestItemExecuted ?? 0 > 0:
            let copy = self.state.value.copy()
            copy.duration += Constants.timerDelay
            self.state.set(copy)
        case .userStopped,
             .stopped:
            stopRunningTimer()
        default:
            break
        }
    }

    /// Updates Flight Plan's completion progress.
    func updateProgress() {
        guard let currentLocation = drone?.getInstrument(Instruments.gps)?.lastKnownLocation,
              let lastPassedWayPointIndex = state.value.lastPassedWayPointIndex,
              let currentPlan = flightPlanViewModel?.flightPlan?.plan else { return }

        let newProgress = currentPlan.completionProgress(with: currentLocation.agsPoint,
                                                         lastWayPointIndex: lastPassedWayPointIndex).rounded(toPlaces: Constants.progressRoundPrecision)

        // Update progress only if new value is higher
        // (value could regress due to GPS precision or OA).
        if newProgress > state.value.progress {
            let copy = self.state.value.copy()
            copy.progress = newProgress
            // TODO: implement a real traveled distance calculator instead of this.
            copy.distance = newProgress * (currentPlan.estimations.distance ?? 0.0)
            self.state.set(copy)
        }
    }

    /// Starts flight plan execution.
    func startFlightPlanExecution() {
        didStartExecution = true
        guard let flightPlanId = flightPlanViewModel?.flightPlan?.uuid else {
            return
        }

        let flightId = self.drone?.getInstrument(Instruments.flightInfo)?.flightId
        let settings = flightPlanViewModel?.flightPlan?.settings
        if self.flightPlanExecution == nil {
            // Start new execution.
            self.flightPlanExecution = FlightPlanExecution(flightPlanId: flightPlanId,
                                                flightId: flightId,
                                                startDate: Date(),
                                                settings: settings)
        } else {
            // Resume execution: Update settings and dates.
            self.flightPlanExecution?.state = .initialized
            self.flightPlanExecution?.settings = settings
            self.flightPlanExecution?.flightId = flightId
            if let endDate = self.flightPlanExecution?.endDate,
               let startDate = self.flightPlanExecution?.startDate {
                // Retrieve previous duration (as negative value).
                let duration = startDate.timeIntervalSinceNow - endDate.timeIntervalSinceNow
                // Substract duration to keep total duration.
                self.flightPlanExecution?.startDate = Date().addingTimeInterval(duration)
            } else {
                self.flightPlanExecution?.startDate = Date()
            }
            self.flightPlanExecution?.endDate = nil
        }

        guard let execution = self.flightPlanExecution else { return }

        self.flightPlanViewModel?.saveExecution(execution)
        // Sets the custom Id of the drone media meta data with the flight plan execution Id to get media that belong to the flight plan execution.
        self.drone?.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId = execution.executionId
    }

    /// Saves flight plan execution in database.
    func saveFlightPlanExecution() {
        // Reset the custom Id for the drone media meta data.
        self.drone?.getPeripheral(Peripherals.mainCamera2)?.mediaMetadata?.customId = ""

        guard let strongFpExecution = self.flightPlanExecution else { return }

        if strongFpExecution.state == .initialized {
            strongFpExecution.state = FlightPlanExecutionState.completed
            // Reset latestItemExecuted if flight was completed.
            strongFpExecution.latestItemExecuted = nil
        }
        strongFpExecution.endDate = Date()
        flightPlanViewModel?.saveExecution(strongFpExecution)
        self.flightPlanExecution = nil

        didStartExecution = false
    }

    /// Handle flight ends.
    func handleFlightEnds() {
        restoreObstacleAvoidanceSetting()
        saveFlightPlanExecution()
    }
}
