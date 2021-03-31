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

/// View model which handles Remote Control grab.
// TODO: All SkyCtrl3 references/names/files will be updated with SkyCtrl4 ones.
public final class RemoteControlGrabberViewModel {
    // MARK: - Private Properties
    /// ViewModels.
    private var rightSliderViewModel: RightSliderViewModel = RightSliderViewModel()
    private var leftSliderViewModel: LeftSliderViewModel = LeftSliderViewModel()
    private var rearLeftButtonViewModel: RearLeftButtonViewModel = RearLeftButtonViewModel()
    private var rearRightButtonViewModel: RearRightButtonViewModel = RearRightButtonViewModel()
    private var frontTopButtonViewModel: FrontTopButtonViewModel = FrontTopButtonViewModel()
    private var frontBottomButtonViewModel: FrontBottomButtonViewModel = FrontBottomButtonViewModel()
    /// Grabbers.
    private var rcRightSliderUpButtonGrabber: RemoteControlAxisButtonGrabber
    private var rcRightSliderDownButtonGrabber: RemoteControlAxisButtonGrabber
    private var rcRightSliderAxisGrabber: RemoteControlAxisGrabber
    private var rcLeftSliderAxisGrabber: RemoteControlAxisGrabber
    private var rcRearLeftButtonGrabber: RemoteControlButtonGrabber
    private var rcRearRightButtonGrabber: RemoteControlButtonGrabber
    private var rcFrontTopButtonGrabber: RemoteControlButtonGrabber
    private var rcFrontBottomButtonGrabber: RemoteControlButtonGrabber

    // MARK: - Private Enums
    private enum Keys {
        static let rightSliderUpKey: String = SkyCtrl3ButtonEvent.rightSliderUp.description
        static let rightSliderDownKey: String = SkyCtrl3ButtonEvent.rightSliderDown.description
        static let rightSliderAxisKey: String = SkyCtrl3AxisEvent.rightSlider.description
        static let leftSliderAxisKey: String = SkyCtrl3AxisEvent.leftSlider.description
        static let rcRearLeftButtonKey: String = SkyCtrl3ButtonEvent.rearLeftButton.description
        static let rcRearRightButtonKey: String = SkyCtrl3ButtonEvent.rearRightButton.description
        static let rcFrontTopButtonKey: String = SkyCtrl3ButtonEvent.frontTopButton.description
        static let rcFrontBottomButtonKey: String = SkyCtrl3ButtonEvent.frontBottomButton.description
    }

    // MARK: - Init
    public init() {
        // Right slider related grab.
        rcRightSliderUpButtonGrabber = RemoteControlAxisButtonGrabber(axis: .rightSlider,
                                                                      event: .rightSliderUp,
                                                                      key: Keys.rightSliderUpKey,
                                                                      action: rightSliderViewModel.actionUp)
        rcRightSliderDownButtonGrabber = RemoteControlAxisButtonGrabber(axis: .rightSlider,
                                                                        event: .rightSliderDown,
                                                                        key: Keys.rightSliderDownKey,
                                                                        action: rightSliderViewModel.actionDown)
        rcRightSliderAxisGrabber = RemoteControlAxisGrabber(axis: .rightSlider,
                                                            event: .rightSlider,
                                                            key: Keys.rightSliderAxisKey,
                                                            action: rightSliderViewModel.axisUpdated)

        // Left slider related grab.
        rcLeftSliderAxisGrabber = RemoteControlAxisGrabber(axis: .leftSlider,
                                                           event: .leftSlider,
                                                           key: Keys.leftSliderAxisKey,
                                                           action: leftSliderViewModel.axisUpdated)

        // Rear left button grab.
        rcRearLeftButtonGrabber = RemoteControlButtonGrabber(button: .rearLeftButton,
                                                             event: .rearLeftButton,
                                                             key: Keys.rcRearLeftButtonKey,
                                                             action: rearLeftButtonViewModel.rearLeftButtonTouchedUp)

        // Rear Right button grab.
        rcRearRightButtonGrabber = RemoteControlButtonGrabber(button: .rearRightButton,
                                                              event: .rearRightButton,
                                                              key: Keys.rcRearRightButtonKey,
                                                              action: rearRightButtonViewModel.rearRightButtonPressed)

        // Rear front top button grab.
        rcFrontTopButtonGrabber = RemoteControlButtonGrabber(button: .frontTopButton,
                                                             event: .frontTopButton,
                                                             key: Keys.rcFrontTopButtonKey,
                                                             action: frontTopButtonViewModel.frontTopButtonTouchedUp)

        // Rear front bottom button grab.
        rcFrontBottomButtonGrabber = RemoteControlButtonGrabber(button: .frontBottomButton,
                                                                event: .frontBottomButton,
                                                                key: Keys.rcFrontBottomButtonKey,
                                                                action: frontBottomButtonViewModel.frontBottomButtonTouchedUp)

        self.grabAll()
    }

    // MARK: - Deinit
    deinit {
        self.ungrabAll()
    }
}

// MARK: - Public Funcs
public extension RemoteControlGrabberViewModel {
    /// Deinits all grabbers.
    func ungrabAll() {
        rcRightSliderUpButtonGrabber.ungrab()
        rcRightSliderDownButtonGrabber.ungrab()
        rcRightSliderAxisGrabber.ungrab()
        rcLeftSliderAxisGrabber.ungrab()
        rcRearLeftButtonGrabber.ungrab()
        rcRearRightButtonGrabber.ungrab()
        rcFrontTopButtonGrabber.ungrab()
        rcFrontBottomButtonGrabber.ungrab()
    }
}

// MARK: - Private Funcs
private extension RemoteControlGrabberViewModel {
    /// Grabs all buttons and sliders.
    func grabAll() {
        rcRightSliderUpButtonGrabber.grab()
        rcRightSliderDownButtonGrabber.grab()
        rcRightSliderAxisGrabber.grab()
        rcLeftSliderAxisGrabber.grab()
        rcRearLeftButtonGrabber.grab()
        rcRearRightButtonGrabber.grab()
        rcFrontTopButtonGrabber.grab()
        rcFrontBottomButtonGrabber.grab()
    }
}
