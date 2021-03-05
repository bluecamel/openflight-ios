//
//  Copyright (C) 2021 Parrot Drones SAS.
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

/// Protocol for MAVLink to Flight Plan parser.
public protocol MavlinkToFlightPlanParser {
    /// Generates FlightPlan from MAVLink file at given URL or MAVLink string.
    ///
    /// - Parameters:
    ///    - url: url of MAVLink file to parse
    ///    - mavlinkString: MAVLink string to parse
    ///    - title: title of FlightPlan to generate
    ///    - type: Flight Plan type
    ///    - uuid: Flight Plan ID
    ///    - version: version of FlightPlan
    ///    - model: model of drone for generated FlightPlan
    ///
    /// - Returns: generated `SavedFlightPlan` is operation succeeded, `nil` otherwise
    // swiftlint:disable:next function_parameter_count
    static func generateFlightPlanFromMavlink(url: URL?,
                                              mavlinkString: String?,
                                              title: String,
                                              type: String?,
                                              uuid: String?,
                                              settings: [FlightPlanLightSetting],
                                              polygonPoints: [PolygonPoint]?,
                                              version: Int,
                                              model: Drone.Model) -> SavedFlightPlan?
}

/// Default implementation.
public final class MavlinkLegacyToFlightPlanGenerator: MavlinkToFlightPlanParser {
    public static func generateFlightPlanFromMavlink(
        url: URL? = nil,
        mavlinkString: String? = nil,
        title: String,
        type: String? = nil,
        uuid: String? = nil,
        settings: [FlightPlanLightSetting] = [],
        polygonPoints: [PolygonPoint]? = nil,
        version: Int = FlightPlanConstants.defaultFlightPlanVersion,
        model: Drone.Model) -> SavedFlightPlan? {

        var commands: [MavlinkCommand] = []

        if let strongUrl = url {
            commands = MavlinkFiles.parse(filepath: strongUrl.path)
        } else if let strongMavlinkString = mavlinkString {
            commands = MavlinkFiles.parse(mavlinkString: strongMavlinkString)
        }

        var takeOffActions = [Action]()
        var pois = [PoiPoint]()
        var waypoints = [WayPoint]()

        var currentWaypoint: WayPoint?
        var currentViewModeCommand = SetViewModeCommand(mode: .absolute)
        var currentSpeedCommand: ChangeSpeedCommand?

        for command in commands {
            switch command {
            case let roiCommand as SetRoiCommand:
                let newPoi = PoiPoint(roiMavLinkCommand: roiCommand)
                pois.append(newPoi)

            case let viewModeCommand as SetViewModeCommand:
                currentWaypoint?.update(viewModeCommand: viewModeCommand)
                currentViewModeCommand = viewModeCommand

            case let speedModeCommand as ChangeSpeedCommand:
                currentWaypoint?.update(speedMavlinkCommand: speedModeCommand)
                currentSpeedCommand = speedModeCommand

            case let waypointCommand as NavigateToWaypointCommand:
                let newWaypoint = WayPoint(navigateToWaypointCommand: waypointCommand,
                                           speedMavlinkCommand: currentSpeedCommand,
                                           viewModeCommand: currentViewModeCommand)
                waypoints.append(newWaypoint)
                currentWaypoint = newWaypoint

            default:
                guard let newAction = Action(mavLinkCommand: command) else { continue }
                if let currentWaypoint = currentWaypoint {
                    currentWaypoint.addAction(newAction)
                } else {
                    takeOffActions.append(newAction)
                }
            }
        }

        let flightPlanObject = FlightPlanObject(takeoffActions: takeOffActions,
                                                pois: pois,
                                                wayPoints: waypoints)
        let savedFlightPlan = SavedFlightPlan(version: version,
                                              title: title,
                                              type: type,
                                              uuid: uuid ?? UUID().uuidString,
                                              product: model,
                                              plan: flightPlanObject,
                                              settings: settings,
                                              polygonPoints: polygonPoints)
        return savedFlightPlan
    }
}
