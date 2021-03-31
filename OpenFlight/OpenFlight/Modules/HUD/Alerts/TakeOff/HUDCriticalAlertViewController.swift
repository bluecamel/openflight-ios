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

// MARK: Protocols
/// Handles alert buttons logic.
protocol HUDCriticalAlertDelegate: class {
    /// Called when user dimisses the alert.
    func dismissAlert()

    /// Called when user taps on the action button.
    ///
    /// - Parameters:
    ///     - alert: current alert type
    func performAlertAction(alert: HUDCriticalAlertType?)
}

/// Displays a critical alert on the HUD.
final class HUDCriticalAlertViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet private weak var panelView: UIView!
    @IBOutlet private weak var alertTopView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var topImageView: UIImageView!
    @IBOutlet private weak var mainImageView: UIImageView!
    @IBOutlet private weak var buttonsView: UIView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var actionButton: UIButton!
    @IBOutlet private weak var descriptionLabel: UILabel!

    // MARK: - Internal Properties
    weak var delegate: HUDCriticalAlertDelegate?

    // MARK: - Private Properties
    private var currentAlert: HUDCriticalAlertType?

    // MARK: - Setup
    /// Instantiate the alert view controller.
    ///
    /// - Parameters:
    ///     - alert: alert type to present
    /// - Returns: The critical alert view controller.
    static func instantiate(with alert: HUDCriticalAlertType?) -> HUDCriticalAlertViewController {
        let viewController = StoryboardScene.HUDTakeOffAlert.initialScene.instantiate()
        viewController.currentAlert = alert

        return viewController
    }

    // MARK: - Override Funcs
    override func viewDidLoad() {
        super.viewDidLoad()

        initView()

        guard let strongModel = currentAlert else { return }

        setupView(alertModel: strongModel)
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - Actions
private extension HUDCriticalAlertViewController {
    @IBAction func backgroundButtonTouchedUpInside(_ sender: Any) {
        delegate?.dismissAlert()
    }

    @IBAction func cancelButtonTouchedUpInside(_ sender: Any) {
        delegate?.dismissAlert()
    }

    @IBAction func actionButtonTouchedUpInside(_ sender: Any) {
        delegate?.performAlertAction(alert: currentAlert)
    }
}

// MARK: - Private Funcs
private extension HUDCriticalAlertViewController {
    /// Inits panel view.
    func initView() {
        panelView.addBlurEffect()
        alertTopView.applyCornerRadius(Style.mediumCornerRadius)
        alertTopView.backgroundColor = ColorName.black.color
        titleLabel.makeUp(with: .large)
        descriptionLabel.makeUp(with: .large)
        cancelButton.setTitle(L10n.cancel, for: .normal)
        cancelButton.makeup(with: .large)
        actionButton.makeup(with: .large)
        actionButton.cornerRadiusedWith(backgroundColor: ColorName.greenPea.color,
                                        radius: Style.largeCornerRadius)
        cancelButton.cornerRadiusedWith(backgroundColor: .clear,
                                        borderColor: .white,
                                        radius: Style.largeCornerRadius,
                                        borderWidth: Style.mediumBorderWidth)
        descriptionLabel.makeUp(with: .big)
    }

    /// Updates the view according to model value.
    ///
    /// - Parameters:
    ///     - alertModel: current alert to display
    func setupView(alertModel: HUDCriticalAlertType) {
        titleLabel.text = alertModel.topTitle
        topImageView.image = alertModel.topIcon
        topImageView.isHidden = alertModel.topIcon == nil
        alertTopView.backgroundColor = alertModel.topBackgroundColor?.color
        mainImageView.image = alertModel.mainImage
        descriptionLabel.text = alertModel.mainDescription
        cancelButton.isHidden = alertModel.showCancelButton == false
        actionButton.setTitle(alertModel.actionButtonTitle, for: .normal)
        actionButton.setTitleColor(alertModel.actionButtonTitleColor?.color, for: .normal)
        actionButton.backgroundColor = alertModel.actionButtonBackgroundColor?.color
    }
}
