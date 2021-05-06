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
import Reusable

// MARK: - Protocols
protocol DashboardFooterCellDelegate: class {
    /// Starts confidentiality from dashboard.
    func startConfidentiality()

    /// Starts support link from dashboard.
    func startSupport()

    /// Starts parrot debug screen from dashboard.
    func startParrotDebugScreen()
}

/// Custom View used for the footer of the Dashboard.
final class DashboardFooterCell: UICollectionViewCell, NibReusable {
    // MARK: - Outlets
    @IBOutlet private weak var versionLabel: UILabel!
    @IBOutlet private weak var dataConfidentialityButton: UIButton!
    @IBOutlet private weak var supportButton: UIButton!
    @IBOutlet private weak var droneVersionLabel: UILabel!
    @IBOutlet private weak var controllerVersionLabel: UILabel!
    @IBOutlet private weak var versionTitleLabel: UILabel!
    @IBOutlet private weak var controllerTitleLabel: UILabel!
    @IBOutlet private weak var droneTitleLabel: UILabel!
    @IBOutlet private weak var versionsView: UIView!

    // MARK: - Internal Properties
    weak var delegate: DashboardFooterCellDelegate?

    // MARK: - Override Funcs
    override func awakeFromNib() {
        super.awakeFromNib()

        updateView()
        // Debug tap gesture.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showParrotDebugScreen))
        tapGesture.numberOfTapsRequired = 3
        versionsView.addGestureRecognizer(tapGesture)
    }

    // MARK: - Internal Funcs
    /// Sets up dashboard footer informations.
    ///
    /// - Parameters:
    ///     - state: State for `DashboardFooterViewModel`.
    func setup(state: DashboardFooterState) {
        splitStringWithDash(label: droneVersionLabel, versionString: state.droneVersionNumber)
        splitStringWithDash(label: controllerVersionLabel, versionString: state.remoteVersionNumber)
    }
}

// MARK: - Actions
private extension DashboardFooterCell {
    @IBAction func dataConfidentialityButtonTouchedUpInside(_ sender: Any) {
        delegate?.startConfidentiality()
    }

    @IBAction func supportButtonTouchedUpInside(_ sender: Any) {
        delegate?.startSupport()
    }
}

// MARK: - Private Funcs
private extension DashboardFooterCell {
    /// Update text for version number and buttons.
    func updateView() {
        versionTitleLabel.text = L10n.commonApp
        controllerTitleLabel.text = L10n.commonController
        droneTitleLabel.text = L10n.commonDrone
        splitStringWithDash(label: versionLabel, versionString: AppUtils.version)
        dataConfidentialityButton.titleLabel?.numberOfLines = 2
        dataConfidentialityButton.titleLabel?.adjustsFontSizeToFitWidth = true
        dataConfidentialityButton.titleLabel?.minimumScaleFactor = 0.6
        dataConfidentialityButton.setTitle(L10n.dashboardFooterDataConfidentiality,
                                           for: .normal)
        supportButton.setTitle(L10n.dashboardSupportTitle,
                               for: .normal)
        dataConfidentialityButton.contentVerticalAlignment = .top
        supportButton.contentVerticalAlignment = .top
    }

    /// Shows the Parrot debug screen.
    @objc func showParrotDebugScreen() {
        delegate?.startParrotDebugScreen()
    }

    /// Used to split version string to an array of strings.
    ///
    /// - Parameters:
    ///     - label: label to assign strings
    ///     - versionString: string to split
    func splitStringWithDash(label: UILabel,
                             versionString: String?) {
        guard let versionString = versionString,
              versionString != Style.dash else {
            label.text = Style.dash
            return
        }

        let versionStringsArray = versionString.components(separatedBy: Style.dash)
        label.text = versionStringsArray.joined(separator: Style.newLine)
    }
}