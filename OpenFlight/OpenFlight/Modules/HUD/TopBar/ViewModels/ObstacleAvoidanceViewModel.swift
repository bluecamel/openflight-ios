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

/// State for `ObstacleAvoidanceViewModel`.
final class ObstacleAvoidanceState: DeviceConnectionState {
    // MARK: - Internal Properties
    /// Whether if obstacle avoidance is activated.
    fileprivate(set) var obstacleAvoidanceActivated: Bool = false
    /// Whether if stereo vision sensor calibration is needed.
    fileprivate(set) var stereoVisionCalibrationNeeded: Bool = false

    // MARK: Helpers
    /// Image to display obstacle avoidance state.
    var obstacleAvoidanceImage: UIImage {
        if !isConnected() {
            return Asset.ObstacleAvoidance.icObstacleDetectionDisconnected.image
        } else if obstacleAvoidanceActivated && stereoVisionCalibrationNeeded {
            return Asset.ObstacleAvoidance.icObstacleDetectionError.image
        } else if obstacleAvoidanceActivated && !stereoVisionCalibrationNeeded {
            return Asset.ObstacleAvoidance.icObstacleDetectionOn.image
        } else {
            return Asset.ObstacleAvoidance.icObstacleDetectionOff.image
        }
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone's connection state
    ///    - obstacleAvoidanceActivated: wheter obstacle avoidance is activated
    ///    - stereoVisionCalibrationNeeded: Bool that indicates if stereo vision sensor calibration is needed.
    init(connectionState: DeviceState.ConnectionState,
         obstacleAvoidanceActivated: Bool,
         stereoVisionCalibrationNeeded: Bool) {
        super.init(connectionState: connectionState)

        self.obstacleAvoidanceActivated = obstacleAvoidanceActivated
        self.stereoVisionCalibrationNeeded = stereoVisionCalibrationNeeded
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let other = other as? ObstacleAvoidanceState else {
            return false
        }

        return super.isEqual(to: other)
            && self.obstacleAvoidanceActivated == other.obstacleAvoidanceActivated
            && self.stereoVisionCalibrationNeeded == other.stereoVisionCalibrationNeeded
    }

    override func copy() -> ObstacleAvoidanceState {
        return ObstacleAvoidanceState(connectionState: self.connectionState,
                                      obstacleAvoidanceActivated: self.obstacleAvoidanceActivated,
                                      stereoVisionCalibrationNeeded: self.stereoVisionCalibrationNeeded)
    }
}

/// View model for drone details buttons.
final class ObstacleAvoidanceViewModel: DroneStateViewModel<ObstacleAvoidanceState> {
    // MARK: - Private Properties
    private var obstacleAvoidanceRef: Ref<ObstacleAvoidance>?
    private var stereoVisionSensorRef: Ref<StereoVisionSensor>?
    private var flyingIndicatorsRef: Ref<FlyingIndicators>?
    private var manualPilotingRef: Ref<ManualCopterPilotingItf>?

    // MARK: - Deinit
    deinit {
        self.obstacleAvoidanceRef = nil
        self.stereoVisionSensorRef = nil
        self.flyingIndicatorsRef = nil
        self.manualPilotingRef = nil
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        listenObstacleAvoidance(drone)
        listenStereoVisionSensor(drone)
        listenManualPiloting(drone: drone)
        listenFlyingIndicators(drone: drone)
    }
}

// MARK: - Private Funcs
private extension ObstacleAvoidanceViewModel {
    /// Starts watcher for obstacle avoidance.
    func listenObstacleAvoidance(_ drone: Drone) {
        obstacleAvoidanceRef = drone.getPeripheral(Peripherals.obstacleAvoidance) { [weak self] _ in
            self?.updateObstacleAvoidanceState()
        }
        updateObstacleAvoidanceState()
    }

    /// Starts watcher for flying indicators.
    func listenFlyingIndicators(drone: Drone) {
        flyingIndicatorsRef = drone.getInstrument(Instruments.flyingIndicators) { [weak self] _ in
            self?.updateObstacleAvoidanceState()
        }
    }

    /// Starts watcher for manual piloting.
    func listenManualPiloting(drone: Drone) {
        manualPilotingRef = drone.getPilotingItf(PilotingItfs.manualCopter) { [weak self] _ in
            self?.updateObstacleAvoidanceState()
        }
    }

    /// Updates obstacle avoidance state.
    func updateObstacleAvoidanceState() {
        guard let drone = drone,
              let strongObstacleAvoidance = drone.getPeripheral(Peripherals.obstacleAvoidance),
              let manualPiloting = drone.getPilotingItf(PilotingItfs.manualCopter),
              let flyingIndicators = drone.getInstrument(Instruments.flyingIndicators) else {
            return
        }

        let copy = self.state.value.copy()
        guard !manualPiloting.canHandLand,
              manualPiloting.state == .active,
              manualPiloting.smartTakeOffLandAction != .land,
              flyingIndicators.flyingState != .takingOff,
              flyingIndicators.flyingState != .landing else {
            copy.obstacleAvoidanceActivated = false
            self.state.set(copy)
            return
        }

        copy.obstacleAvoidanceActivated = strongObstacleAvoidance.mode.value == .standard
        self.state.set(copy)
    }

    /// Starts watcher for stereo vision sensor.
    func listenStereoVisionSensor(_ drone: Drone) {
        stereoVisionSensorRef = drone.getPeripheral(Peripherals.stereoVisionSensor) { [weak self] stereoVisionSensor in
            self?.updateStereoVisionSensorCalibrationState(with: stereoVisionSensor)
        }
        updateStereoVisionSensorCalibrationState(with: drone.getPeripheral(Peripherals.stereoVisionSensor))
    }

    /// Updates stereo vision sensor calibration state.
    func updateStereoVisionSensorCalibrationState(with stereoVisionSensor: StereoVisionSensor?) {
        guard let strongStereoVisionSensor = stereoVisionSensor else { return }

        let copy = self.state.value.copy()
        copy.stereoVisionCalibrationNeeded = !strongStereoVisionSensor.isCalibrated
        self.state.set(copy)
    }
}
