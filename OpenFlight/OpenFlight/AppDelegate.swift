// Copyright (C) 2020 Parrot Drones SAS
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

import UIKit
import GroundSdk
import SwiftyUserDefaults
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: - Public Properties
    var window: UIWindow?
    lazy var persistentContainer: PersistentContainer = {
        let container = PersistentContainer(name: "Model")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        return container
    }()

    // MARK: - Private Properties
    /// Create a first groundSdk intance when Application delegate is created
    private let groundSdk: GroundSdk = {
        return AppDelegateSetup.sdkSetup()
    }()
    /// Main coordinator of the application.
    private var appCoordinator: AppCoordinator!
    /// Helper class that stores the current `Drone`.
    private let currentDroneStore = CurrentDroneStore()
    /// Helper class that stores the current `RemoteControl`.
    private let currentRemoteControlStore = CurrentRemoteControlStore()
    /// Gutma log manager ref.
    private var gutmaLogManager: Ref<GutmaLogManager>?

    // MARK: - Public Funcs
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {

        /// Sets up global managers and interactors
        setupProtobufMissionManager()
        setupFirmwareAndMissionsInteractor()

        /// Start AppCoordinator.
        self.appCoordinator = AppCoordinator()
        self.appCoordinator.start()
        addMissionsToHUDPanel()

        /// Configure Main Window of the App.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = self.appCoordinator.navigationController
        self.window?.makeKeyAndVisible()

        // App setup.
        gutmaLogManager = AppDelegateSetup.appSetup(application: application,
                                                    persistentContainer: persistentContainer,
                                                    groundSdk: groundSdk,
                                                    dataManager: CoreDataManager.shared)

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        self.persistentContainer.saveContext()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
}

// MARK: - ProtobufMissionsSetupProtocol
extension AppDelegate: ProtobufMissionsSetupProtocol {
    /// Sets up `FirmwareAndMissionsInteractor`
    func setupFirmwareAndMissionsInteractor() {
        FirmwareAndMissionsInteractor.shared.setup()
    }

    /// Sets up the ProtobufMissionManager.
    func setupProtobufMissionManager() {
        ProtobufMissionsManager.shared.setup(with: [OFMissionSignatures.defaultMission,
                                                    OFMissionSignatures.helloWorld])
    }

    /// Add protobuf missions to the HUD Panel.
    func addMissionsToHUDPanel() {
        MissionsManager.shared.addMissions([HelloWorldMission()])
    }
}

// MARK: - Setup
/// This class groups AppDelegate setups in a public static function
///  to prevent from missing changes in other targets.

public class AppDelegateSetup {
    /// Setup GroundSDK.
    public static func sdkSetup() -> GroundSdk {
        // Set optional config BEFORE starting GroundSdk
        #if DEBUG
        setenv("ULOG_LEVEL", "D", 1)
        GroundSdkConfig.sharedInstance.enableUsbDebug = true
        #else
        if Bundle.main.isInHouseBuild {
            setenv("ULOG_LEVEL", "D", 1)
        }
        #endif
        ParrotDebug.smartStartLog()

        // Activate DevToolbox.
        GroundSdkConfig.sharedInstance.enableDevToolbox = true

        if Defaults.debugC == true {
            GroundSdkConfig.sharedInstance.autoSelectWifiCountry = false
        }
        return GroundSdk()
    }

    /// Setup AppDelegate.
    ///
    /// - Parameters:
    ///     - application: UIApplication
    ///     - persistentContainer: PersistentContainer
    ///     - groundSdk: GroundSdk
    ///     - dataManager: CoreDataManager
    /// - Returns: GutmaLogManager reference
    public static func appSetup(application: UIApplication,
                                persistentContainer: PersistentContainer,
                                groundSdk: GroundSdk,
                                dataManager: CoreDataManager) -> Ref<GutmaLogManager>? {
        // Keep screen on while app is running (Enable).
        application.isIdleTimerDisabled = true

        // Enable device battery monitoring.
        UIDevice.current.isBatteryMonitoringEnabled = true

        // Reset mission mode defaults.
        Defaults.remove(\.userMissionProvider)
        Defaults.remove(\.userMissionMode)

        // Temporary reset Live streaming default.
        Defaults.remove(\.liveStreaming)

        // Start EV trigger manager.
        EVTriggerManager.shared.setup()

        // Start Core Data manager.
        CoreDataManager.shared.setup(with: persistentContainer)

        // Start listening gutmaLogManager and return its reference.
        return groundSdk.getFacility(Facilities.gutmaLogManager) { gutmaLogManager in
            guard let files = gutmaLogManager?.files,
                  !files.isEmpty else {
                return
            }

            dataManager.updateLocalFlights(newFiles: Array(files))
            gutmaLogManager?.files.forEach { urlFile in
                // Remove sdk's gutmas.
                _ = gutmaLogManager?.delete(file: urlFile)
            }
        }
    }
}
