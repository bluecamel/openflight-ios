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

import UIKit
import CoreLocation
import GroundSdk
import ArcGIS

/// Class representing a Flight Plan waypoint.
public final class WayPoint: Codable {
    // MARK: - Public Properties
    var altitude: Double
    var yaw: Double
    var hasCustomYaw: Bool?
    var speed: Double
    var shouldContinue: Bool
    var shouldFollowPOI: Bool?
    var poiIndex: Int?
    var actions: [Action]?

    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }

    /// Navigate to waypoint MAVLink command.
    var wayPointMavlinkCommand: MavlinkStandard.NavigateToWaypointCommand {
        return MavlinkStandard.NavigateToWaypointCommand(latitude: latitude,
                                                         longitude: longitude,
                                                         altitude: altitude,
                                                         yaw: yaw)
    }

    /// Waypoint speed MAVLink command.
    var speedMavlinkCommand: MavlinkStandard.ChangeSpeedCommand {
        return MavlinkStandard.ChangeSpeedCommand(speedType: .airSpeed,
                                                  speed: speed)
    }

    /// View mode MAVLink command.
    var viewModeCommand: MavlinkStandard.SetViewModeCommand {
        if shouldFollowPOI ?? false {
            return MavlinkStandard.SetViewModeCommand(mode: .roi,
                                                      roiIndex: poiIndex ?? Constants.defaultPoiIndex)
        }
        if shouldContinue {
            return MavlinkStandard.SetViewModeCommand(mode: .continue)
        }
        return MavlinkStandard.SetViewModeCommand(mode: .absolute)
    }

    /// Returns altitude value with unit.
    var formattedAltitude: String {
        return UnitHelper.stringDistanceWithDouble(self.altitude, spacing: false)
    }

    /// Returns provider for waypoint settings.
    var settingsProvider: WayPointSettingsProvider {
        return WayPointSettingsProvider(wayPoint: self)
    }

    /// Returns provider for segment settings.
    var segmentSettingsProvider: WayPointSegmentSettingsProvider {
        return WayPointSegmentSettingsProvider(wayPoint: self)
    }

    /// Related point of interest, if any.
    weak var poiPoint: PoiPoint?
    /// Previous waypoint, if any.
    weak var previousWayPoint: WayPoint?
    /// Next waypoint, if any.
    weak var nextWayPoint: WayPoint?

    // MARK: - Private Properties
    private var longitude: Double
    private var latitude: Double
    /// Returns current automatic yaw, in degrees [0, 360].
    private var computedYaw: Double {
        let computedYaw: Double
        if let poiPoint = poiPoint {
            computedYaw = AGSGeometryEngine.standardGeodeticDistance(between: self.agsPoint,
                                                                     and: poiPoint.agsPoint,
                                                                     azimuthUnit: .degrees())?.azimuth1 ?? 0.0
        } else if let next = nextWayPoint {
            computedYaw = AGSGeometryEngine.standardGeodeticDistance(between: self.agsPoint,
                                                                     and: next.agsPoint,
                                                                     azimuthUnit: .degrees())?.azimuth1 ?? 0.0
        } else if let previous = previousWayPoint {
            computedYaw = AGSGeometryEngine.standardGeodeticDistance(between: previous.agsPoint,
                                                                     and: self.agsPoint,
                                                                     azimuthUnit: .degrees())?.azimuth1 ?? 0.0
        } else {
            computedYaw = 0.0
        }

        return computedYaw.asPositiveDegrees
    }
    /// Returns true if a Rth action is set.
    private var hasRthAction: Bool {
        return actions?.contains(where: { $0.type == .rth }) == true
    }

    // MARK: - Private Enums
    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
        case altitude
        case yaw
        case hasCustomYaw
        case speed
        case shouldContinue = "continue"
        case shouldFollowPOI = "followPOI"
        case poiIndex = "poi"
        case actions
    }

    private enum Constants {
        static let defaultPoiIndex: Int = -1
        static let defaultSpeed: Double = 5.0
        static let customYawDelta: Double = 5.0
    }

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - coordinate: waypoint GPS coordinate
    ///    - altitude: waypoint altitude (in meters)
    ///    - yaw: waypoint yaw for drone
    ///    - hasCustomYaw: whether waypoint has a custom yaw defined
    ///    - speed: drone target speed at waypoint, if nil default speed is used
    ///    - shouldContinue: determine if drone should continue
    ///    - shouldFollowPOI: determine if drone should follow POI for is orientation
    ///    - poiIndex: POI index
    ///    - actions: action to start on waypoint
    public init(coordinate: CLLocationCoordinate2D,
                altitude: Double,
                yaw: Double = 0.0,
                hasCustomYaw: Bool = false,
                speed: Double? = nil,
                shouldContinue: Bool,
                shouldFollowPOI: Bool,
                poiIndex: Int?,
                actions: [Action]?) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.altitude = altitude
        self.yaw = yaw
        self.hasCustomYaw = hasCustomYaw
        self.speed = speed ?? Constants.defaultSpeed
        self.shouldContinue = shouldContinue
        self.shouldFollowPOI = shouldFollowPOI
        self.poiIndex = poiIndex
        self.actions = actions
    }

    /// Init WayPoint with Mavlink commands.
    ///
    /// - Parameters:
    ///    - navigateToWaypointCommand: navigate to waypoint Mavlink command
    ///    - speedMavlinkCommand: speed Mavlink command
    ///    - viewModeCommand: view mode Mavlink command (absolute, continue, or ROI)
    public init(navigateToWaypointCommand: MavlinkStandard.NavigateToWaypointCommand,
                speedMavlinkCommand: MavlinkStandard.ChangeSpeedCommand?,
                viewModeCommand: MavlinkStandard.SetViewModeCommand?) {
        latitude = navigateToWaypointCommand.latitude
        longitude = navigateToWaypointCommand.longitude
        altitude = navigateToWaypointCommand.altitude
        yaw = navigateToWaypointCommand.yaw
        speed = 0
        shouldContinue = false
        shouldFollowPOI = false
        if let speedMavlinkCommand = speedMavlinkCommand {
            update(speedMavlinkCommand: speedMavlinkCommand)
        }
        if let viewModeCommand = viewModeCommand {
            update(viewModeCommand: viewModeCommand)
        }
    }

    // MARK: - Public Funcs
    /// Updates waypoint's view mode with given parameters?
    ///
    /// - Parameters:
    ///    - shouldContinue: conitnue mode
    ///    - shouldFollowPOI: follow point of interest mode
    ///    - poiIndex: index of point of interest
    public func updateViewMode(shouldContinue: Bool = false,
                               shouldFollowPOI: Bool = false,
                               poiIndex: Int? = nil) {
        self.shouldContinue = shouldContinue
        self.shouldFollowPOI = shouldFollowPOI
        self.poiIndex = poiIndex
    }

    /// Updates waypoint's speed with given parameter.
    ///
    /// - Parameters:
    ///    - speed: target speed
    public func updateSpeed(_ speed: Double) {
        self.speed = speed
    }

    /// Add action to waypoint actions.
    ///
    /// - Parameters:
    ///    - action: action to add to WayPoint
    public func addAction(_ action: Action) {
        if actions == nil {
            actions = []
        }
        actions?.append(action)
    }

    /// Updates WayPoint with view mode Mavlink command.
    ///
    /// - Parameters:
    ///    - viewModeCommand: view mode Mavlink command (absolute, continue, or ROI)
    public func update(viewModeCommand: MavlinkStandard.SetViewModeCommand) {
        switch viewModeCommand.mode {
        case .continue:
            updateViewMode(shouldContinue: true)
        case .roi:
            updateViewMode(shouldContinue: true,
                           shouldFollowPOI: true,
                           poiIndex: viewModeCommand.roiIndex)
        default:
            updateViewMode()
        }
    }

    /// Updates WayPoint with speed Mavlink command.
    ///
    /// - Parameters:
    ///    - speedMavlinkCommand: speed Mavlink command
    public func update(speedMavlinkCommand: MavlinkStandard.ChangeSpeedCommand) {
        speed = speedMavlinkCommand.speed
    }
}

// MARK: - Internal Funcs
extension WayPoint {
    /// Updates RTH action.
    ///
    /// - Parameters:
    ///    - shouldRth: whether drone should perform a RTH on this point
    func updateRTHAction(_ shouldRth: Bool) {
        switch (shouldRth, hasRthAction) {
        case (true, false):
            addAction(Action(type: .rth))
        case (false, true):
            actions?.removeAll(where: { $0.type == .rth })
        default:
            break
        }
    }

    /// Sets coordinate of waypoint. This will
    /// trigger automatic yaw updates.
    ///
    /// - Parameters:
    ///    - coordinate: new waypoint's coordinate
    func setCoordinate(_ coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        updateYawAndRelations()
    }

    /// Sets custom yaw. If given yaw is close to automatic
    /// value, `hasCustomYaw` is set back to false.
    ///
    /// - Parameters:
    ///    - yaw: yaw to apply, in degrees [0, 360]
    func setCustomYaw(_ yaw: Double) {
        hasCustomYaw = !yaw.isCloseTo(computedYaw,
                                      withDelta: Constants.customYawDelta)
        if hasCustomYaw == true {
            self.yaw = yaw
        } else {
            updateYaw()
        }
    }

    /// Updates waypoint's yaw.
    func updateYaw() {
        guard hasCustomYaw != true else { return }

        yaw = computedYaw
    }

    /// Updates waypoint's yaw, as well as previous and next waypoint yaws.
    func updateYawAndRelations() {
        self.updateYaw()
        previousWayPoint?.updateYaw()
        nextWayPoint?.updateYaw()
    }

    /// Assigns point of interest to waypoint.
    ///
    /// - Parameters:
    ///    - poiPoint: point of interest to assign
    ///    - poiIndex: point of interest's index
    func assignPoiPoint(poiPoint: PoiPoint,
                        poiIndex: Int) {
        self.hasCustomYaw = false
        self.poiIndex = poiIndex
        self.shouldFollowPOI = true
        self.poiPoint = poiPoint
        self.updateYaw()
    }

    /// Unassigns point of interest from waypoint.
    func unassignPoiPoint() {
        self.poiIndex = nil
        self.shouldFollowPOI = false
        self.poiPoint = nil
        self.updateYaw()
    }
}
