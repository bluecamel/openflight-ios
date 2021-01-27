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

/// Coordinator for drone calibration screens.
public final class DroneCalibrationCoordinator: Coordinator {
    // MARK: - Public Properties
    public var navigationController: NavigationController?
    public var childCoordinators = [Coordinator]()
    public var parentCoordinator: Coordinator?

    // MARK: - Public Funcs
    public func start() {
        let viewController = DroneCalibrationViewController.instantiate(coordinator: self)
        self.navigationController = NavigationController(rootViewController: viewController)
        self.navigationController?.isNavigationBarHidden = true
    }
}

// MARK: - Drone Details Navigation
extension DroneCalibrationCoordinator {
    /// Dismisses current coordinator.
    func dismissDroneCalibration() {
        self.parentCoordinator?.dismissChildCoordinator()
    }

    /// Start magnetometer calibration.
    func startMagnetometerCalibration() {
        let controller = MagnetometerCalibrationViewController.instantiate(isRequired: false, coordinator: self)
        self.push(controller)
    }

    /// Starts Gimbal calibration.
    func startGimbal() {
        let droneGimbalCalibrationCoordinator = DroneGimbalCalibrationCoordinator()
        droneGimbalCalibrationCoordinator.parentCoordinator = self
        droneGimbalCalibrationCoordinator.start()
        self.present(childCoordinator: droneGimbalCalibrationCoordinator,
                     overFullScreen: true)
    }

    /// Starts Stereo Vision calibration.
    func startStereoVisionCalibration() {
        let controller = StereoVisionCalibViewController.instantiate(coordinator: self)
        self.push(controller)
    }

    /// Starts Stereo Vision calibration steps.
    func startStereoVisionCalibrationSteps() {
        let controller = StereoVisionCalibStepsViewController.instantiate(coordinator: self)
        self.push(controller)
    }

    /// Shows calibration Stereo Vision result.
    ///
    /// - Parameters:
    ///    - isCalibrated: Bool that indicates if the stereo vision sensor is calibrated.
    func startStereoVisionCalibrationResult(isCalibrated: Bool) {
        let controller = StereoVisionCalibResultViewController.instantiate(coordinator: self)
        controller.isCalibrated = isCalibrated
        push(controller)
    }

    /// Starts Horizon correction.
    func startHorizonCorrection() {
        let controller = HorizonCorrectionViewController.instantiate(coordinator: self)
        self.push(controller)
    }
}