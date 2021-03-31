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

// MARK: - Gallery SD Media Listener
/// Listener for `GallerySDMediaViewModel` state updates.
final class GallerySdMediaListener: NSObject {
    // MARK: - Internal Properties
    let didChange: GallerySdMediaListenerClosure

    // MARK: - Init
    init(didChange: @escaping GallerySdMediaListenerClosure) {
        self.didChange = didChange
    }
}
/// Alias for `GallerySdMediaListener` closure.
typealias GallerySdMediaListenerClosure = (GallerySDMediaState) -> Void

// MARK: - Internal Enums
/// Specify the formatting state of the SD card.
enum FormattingState {
    case none
    case inProgress
    case done
}

/// State for `GalleryMediaViewModel.
final class GallerySDMediaState: GalleryContentState {
    // MARK: - Private Properties
    /// Drone Uid.
    fileprivate(set) var droneUid: String?
    /// Current physical storage state.
    fileprivate(set) var physicalStorageState: UserStoragePhysicalState?
    /// Current file system storage state.
    fileprivate(set) var fileSystemStorageState: UserStorageFileSystemState?
    /// Check if SDCard could be formatted.
    fileprivate(set) var canFormat: Bool = false
    /// Current SDCard formattingStep.
    fileprivate(set) var formattingStep: FormattingStep?
    /// Current SDCard formattingStep.
    fileprivate(set) var formattingProgress: Int?
    /// Determine the format process state.
    fileprivate(set) var formattingState: FormattingState?

    // MARK: - Internal Properties
    var source: GallerySource {
        return GallerySource(type: .droneSdCard,
                             storageUsed: storageUsed,
                             storageCapacity: capacity,
                             isOffline: false)
    }

    // MARK: - Init
    required init() {
        super.init()
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - availableSpace: available space, in giga bytes
    ///    - capacity: capacity, in giga bytes
    ///    - downloadingItem: downloading item
    ///    - downloadStatus: download status
    ///    - downloadProgress: download progress
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - sourceType: source type
    ///    - referenceDate: reference date
    ///    - videoDuration: video duration
    ///    - videoPosition: video position
    ///    - videoState: video state
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  capacity: Double,
                  downloadingItem: MediaItem?,
                  downloadStatus: MediaTaskStatus,
                  downloadProgress: Float,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  sourceType: GallerySourceType,
                  referenceDate: Date,
                  videoDuration: TimeInterval,
                  videoPosition: TimeInterval,
                  videoState: VideoState?) {
        super.init(connectionState: connectionState,
                   availableSpace: availableSpace,
                   capacity: capacity,
                   downloadingItem: downloadingItem,
                   downloadStatus: downloadStatus,
                   downloadProgress: downloadProgress,
                   isRemoving: isRemoving,
                   medias: medias,
                   sourceType: sourceType,
                   referenceDate: referenceDate,
                   videoDuration: videoDuration,
                   videoPosition: videoPosition,
                   videoState: videoState)
    }

    /// Init.
    ///
    /// - Parameters:
    ///    - connectionState: drone connection state
    ///    - availableSpace: available space on SDCard
    ///    - canFormat: SDCard may be formatted
    ///    - capacity: Total SDCard capacity
    ///    - downloadingItem: downloading item
    ///    - downloadProgress: download progress
    ///    - downloadStatus: download status
    ///    - droneUid: media list
    ///    - formattingProgress: SDCard formatting progress
    ///    - formattingState: SDCard formatting state
    ///    - formattingStep: SDCard formatting step
    ///    - isRemoving: ViewModel is removing
    ///    - medias: media list
    ///    - referenceDate: reference date
    ///    - sourceType: source type
    ///    - physicalStorageState: SDCard physical state
    ///    - fileSystemStorageState: SDCard file system state
    ///    - videoDuration: video duration
    ///    - videoPosition: video position
    ///    - videoState: video state
    required init(connectionState: DeviceState.ConnectionState,
                  availableSpace: Double,
                  canFormat: Bool,
                  capacity: Double,
                  downloadingItem: MediaItem?,
                  downloadProgress: Float,
                  downloadStatus: MediaTaskStatus,
                  droneUid: String?,
                  formattingProgress: Int?,
                  formattingState: FormattingState?,
                  formattingStep: FormattingStep?,
                  isRemoving: Bool,
                  medias: [GalleryMedia],
                  referenceDate: Date,
                  sourceType: GallerySourceType,
                  physicalStorageState: UserStoragePhysicalState?,
                  fileSystemStorageState: UserStorageFileSystemState?,
                  videoDuration: TimeInterval,
                  videoPosition: TimeInterval,
                  videoState: VideoState?) {
        super.init(connectionState: connectionState,
                   availableSpace: availableSpace,
                   capacity: capacity,
                   downloadingItem: downloadingItem,
                   downloadStatus: downloadStatus,
                   downloadProgress: downloadProgress,
                   isRemoving: isRemoving,
                   medias: medias,
                   sourceType: sourceType,
                   referenceDate: referenceDate,
                   videoDuration: videoDuration,
                   videoPosition: videoPosition,
                   videoState: videoState)
        self.canFormat = canFormat
        self.droneUid = droneUid
        self.formattingProgress = formattingProgress
        self.formattingState = formattingState
        self.formattingStep = formattingStep
        self.physicalStorageState = physicalStorageState
        self.fileSystemStorageState = fileSystemStorageState
    }

    // MARK: - Override Funcs
    override func isEqual(to other: DeviceConnectionState) -> Bool {
        guard let typedOther = other as? GallerySDMediaState else {
            return super.isEqual(to: other)
        }

        return super.isEqual(to: typedOther)
            && self.canFormat == typedOther.canFormat
            && self.droneUid == typedOther.droneUid
            && self.formattingProgress == typedOther.formattingProgress
            && self.formattingState == typedOther.formattingState
            && self.formattingStep == typedOther.formattingStep
            && self.physicalStorageState == typedOther.physicalStorageState
            && self.fileSystemStorageState == typedOther.fileSystemStorageState
    }

    override func copy() -> GallerySDMediaState {
        return GallerySDMediaState(connectionState: self.connectionState,
                                   availableSpace: self.availableSpace,
                                   canFormat: self.canFormat,
                                   capacity: self.capacity,
                                   downloadingItem: self.downloadingItem,
                                   downloadProgress: self.downloadProgress,
                                   downloadStatus: self.downloadStatus,
                                   droneUid: self.droneUid,
                                   formattingProgress: self.formattingProgress,
                                   formattingState: self.formattingState,
                                   formattingStep: self.formattingStep,
                                   isRemoving: self.isRemoving,
                                   medias: self.medias,
                                   referenceDate: self.referenceDate,
                                   sourceType: self.sourceType,
                                   physicalStorageState: self.physicalStorageState,
                                   fileSystemStorageState: self.fileSystemStorageState,
                                   videoDuration: self.videoDuration,
                                   videoPosition: self.videoPosition,
                                   videoState: self.videoState)
    }
}

/// ViewModel for SDCard Gallery Media Item.
final class GallerySDMediaViewModel: DroneStateViewModel<GallerySDMediaState> {
    // MARK: - Private Properties
    private let groundSdk = GroundSdk()
    private var sdCardRef: Ref<RemovableUserStorage>?
    private var mediaListRef: Ref<[MediaItem]>?
    private var mediaList: [MediaItem] = []
    private var sdMediaListener: Set<GallerySdMediaListener> = []
    private var initialClosure: GallerySdMediaListenerClosure?

    // MARK: - Internal Properties
    var availableSpace: Double {
        return self.state.value.availableSpace
    }
    var downloadRequest: Ref<MediaDownloader>?
    var deleteRequest: Ref<MediaDeleter>?
    var deleteAllRequest: Ref<AllMediasDeleter>?
    var mediaStore: MediaStore?
    static var shared = GallerySDMediaViewModel()
    var storageUsed: Double {
        return self.state.value.storageUsed
    }
    var streamingReplayState: ReplayPlayState? {
        return streamingCurrentReplay?.playState
    }
    var streamingMediaReplayRef: Ref<MediaReplay>?
    var streamingCurrentResource: MediaItem.Resource?
    var streamingCurrentReplay: Replay? {
        return streamingMediaReplayRef?.value
    }
    var streamingDefaultTrack: MediaItem.Track = .defaultVideo

    // MARK: - Init
    /// Init.
    ///
    /// - Parameters:
    ///    - stateDidUpdate: called when drone location changed
    private override init(stateDidUpdate: ((GallerySDMediaState) -> Void)? = nil) {
        super.init(stateDidUpdate: stateDidUpdate)

        // Keep initial closure to prevent from breaking BaseViewModel's stateDidUpdate behaviour.
        initialClosure = stateDidUpdate
        state.valueChanged = { [weak self] state in
            // Run stateDidUpdate closure.
            self?.initialClosure?(state)
            // Run listeners closure.
            self?.sdMediaListener.forEach { listener in
                listener.didChange(state)
            }
        }
    }

    // MARK: - Override Funcs
    override func listenDrone(drone: Drone) {
        super.listenDrone(drone: drone)

        setupDroneListeners(drone: drone)
    }

    override func droneConnectionStateDidChange() {
        super.droneConnectionStateDidChange()
        
        if !self.state.value.isConnected() {
            let copy = self.state.value.copy()
            copy.sourceType = .droneSdCard
            copy.referenceDate = Date()
            copy.medias = []
            copy.availableSpace = 0.0
            self.state.set(copy)
        } else {
            guard let drone = drone else { return }

            setupDroneListeners(drone: drone)
        }
    }
}

// MARK: - Internal Funcs
extension GallerySDMediaViewModel {
    /// Update removing state.
    ///
    /// - Parameters:
    ///     - isRemoving: VM is removing
    func updateRemovingState(_ isRemoving: Bool) {
        let copy = self.state.value.copy()
        copy.isRemoving = isRemoving
        self.state.set(copy)
    }

    /// Downloader did update.
    ///
    /// - Parameters:
    ///     - mediaDownloader: MediaDownloader
    func downloaderDidUpdate(_ mediaDownloader: MediaDownloader?) {
        var copy = self.state.value.copy()
        copy.downloadProgress = mediaDownloader?.totalProgress ?? 0.0
        copy.downloadingItem = mediaDownloader?.currentMedia
        copy.downloadStatus = mediaDownloader?.status ?? .complete

        /// Update loading media if needed.
        copy = updateMediasDownloadState(state: copy)

        self.state.set(copy)
    }

    /// Setup drone listeners.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func setupDroneListeners(drone: Drone) {
        updateDroneUid(drone: drone)
        listenSDCard(drone: drone)
        loadMediaStore(drone: drone)
        loadMedia(drone: drone)
    }

    /// Refresh media list.
    func refreshMedias() {
        guard let drone = drone else { return }

        loadMedia(drone: drone)
    }

    /// Get a media preview image url.
    ///
    /// - Parameters:
    ///    - media: GalleryMedia
    ///    - index: index of image
    ///    - completion: completion block
    func getMediaPreviewImageUrl(_ media: GalleryMedia, _ index: Int = 0, completion: @escaping (URL?) -> Void) {
        if let galleryURL = ressourceGalleryURL(media, index),
            isResourceDownloaded(media, index) {
            completion(galleryURL)
        } else if let droneId = state.value.droneUid,
            let mediaItem = media.mediaItem,
            mediaItem.resources.count > index,
            let cachedImgUrl = mediaItem.resources[index].cachedImgUrl(droneId: droneId),
            mediaItem.resources[index].cachedImgUrlExist(droneId: droneId) {
            completion(cachedImgUrl)
        } else {
            completion(nil)
        }
    }

    /// Format SD Card.
    ///
    /// - Parameters:
    ///     - type: formatting type
    func format(_ type: FormattingType = .quick) {
        guard let drone = drone else { return }

        let copy = self.state.value.copy()
        copy.formattingState = .inProgress
        self.state.set(copy)
        _ = drone.getPeripheral(Peripherals.removableUserStorage)?.format(formattingType: type)
    }

    /// Called when format process is completed.
    func formatCompleted() {
        let copy = self.state.value.copy()
        copy.formattingState = .done
        self.state.set(copy)
    }
}

// MARK: - Private Funcs
private extension GallerySDMediaViewModel {
    /// Update drone Uid.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func updateDroneUid(drone: Drone) {
        let copy = self.state.value.copy()
        copy.droneUid = drone.uid
        self.state.set(copy)
    }

    /// Starts watcher for Removable User Storage.
    func listenSDCard(drone: Drone) {
        sdCardRef = drone.getPeripheral(Peripherals.removableUserStorage) { [weak self] storage in
            guard let storage = storage,
                let copy = self?.state.value.copy() else {
                    return
            }

            // Turn storage in mega bytes.
            copy.availableSpace = Double(storage.availableSpace) / Double(StorageUtils.Constants.bytesPerGigabyte)
            copy.physicalStorageState = storage.physicalState
            copy.fileSystemStorageState = storage.fileSystemState
            copy.canFormat = storage.canFormat
            copy.formattingProgress = storage.formattingState?.progress
            copy.formattingStep = storage.formattingState?.step
            if let capacity = storage.mediaInfo?.capacity {
                copy.capacity = Double(capacity) / Double(StorageUtils.Constants.bytesPerGigabyte)
            }
            self?.state.set(copy)
        }
    }

    /// Load MediaStore from drone.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func loadMediaStore(drone: Drone) {
        mediaStore = drone.getPeripheral(Peripherals.mediaStore)
    }

    /// Load MediaList from mediaStore peripherial.
    ///
    /// - Parameters:
    ///     - drone: current drone
    func loadMedia(drone: Drone) {
        mediaListRef = self.mediaStore?.newList { [weak self] droneMediaList in
            guard let strongSelf = self,
                let droneMediaList = droneMediaList,
                let copy = self?.state.value.copy() else {
                    return
            }

            copy.sourceType = .droneSdCard
            copy.referenceDate = Date()
            let filteredMediaResources = droneMediaList.filter({ $0.isSdStorage })
            let allMedias = filteredMediaResources.compactMap({ strongSelf.convertToGalleryMedia(mediaItem: $0, drone: drone) })
            copy.medias = allMedias.sorted(by: { $0.date > $1.date })
            strongSelf.state.set(copy)
        }
    }

    /// Convert MediaItem to GalleryMedia.
    ///
    /// - Parameters:
    ///    - mediaItem: MediaItem object
    ///    - drone: Current drone
    ///
    /// - Returns: GalleryMedia object for MediaItem in parameter.
    func convertToGalleryMedia(mediaItem: MediaItem, drone: Drone) -> GalleryMedia? {
        let downloadState: GalleryMediaDownloadState
        if self.state.value.downloadingItem?.uid == mediaItem.uid {
            downloadState = .downloading
        } else if mediaItem.isDownloaded {
            downloadState = .downloaded
        } else {
            downloadState = .toDownload
        }
        return GalleryMedia(uid: mediaItem.uid,
                            source: .droneSdCard,
                            mediaItem: mediaItem,
                            type: mediaItem.mediaType,
                            downloadState: downloadState,
                            size: self.size(for: mediaItem),
                            date: mediaItem.creationDate,
                            url: nil)
    }

    /// Returns Size for MediaItem.
    ///
    /// - Parameters:
    ///    - mediaItem: MediaItem object
    ///
    /// - Returns: Value for size of all MediaItem resources.
    func size(for mediaItem: MediaItem) -> UInt64 {
        return mediaItem.downloadableResources.reduce(0) { $0 + $1.size }
    }

    /// Update state regarding download status.
    ///
    /// - Parameters:
    ///    - state: Gallery SDMedia State
    /// - Returns: Updated Gallery SD Media State
    func updateMediasDownloadState(state: GallerySDMediaState) -> GallerySDMediaState {
        guard let loadingMedia = state.downloadingItem else { return state }

        let isError = state.downloadStatus == .error
        var allMedia = self.state.value.medias
        if let index = state.medias.firstIndex(where: { $0.mediaItem?.uid == loadingMedia.uid }),
            state.medias[index].downloadState != .downloading {
            // Update item downloadState if necessary.
            var mediaToUpdate = allMedia.remove(at: index)
            mediaToUpdate.downloadState = isError ? .error : .downloading
            allMedia.insert(mediaToUpdate, at: index)
        }
        state.medias = allMedia
        return state
    }

    /// Returns gallery Url.
    ///
    /// - Parameters:
    ///    - media: media
    ///    - index: index of image
    /// - Returns: gallery url for this media
    func ressourceGalleryURL(_ media: GalleryMedia?, _ index: Int = 0) -> URL? {
        guard let media = media,
            let mediaItem = media.mediaItem,
            mediaItem.resources.count > index else {
                return nil
        }

        return mediaItem.resources[index].galleryURL(droneId: self.state.value.droneUid,
                                                     mediaType: mediaItem.mediaType)
    }

    /// Determine if a media is downloaded.
    ///
    /// - Parameters:
    ///    - media: media
    ///    - index: index of image
    /// - Returns: boolean determining if the media is downloaded
    func isResourceDownloaded(_ media: GalleryMedia?, _ index: Int = 0) -> Bool {
        guard let media = media,
            let mediaItem = media.mediaItem,
            mediaItem.resources.count > index else {
                return false
        }

        return mediaItem.resources[index].isDownloaded(droneId: self.state.value.droneUid,
                                                       mediaType: mediaItem.mediaType)
    }
}

// MARK: - Gallery SD Media Listener
extension GallerySDMediaViewModel {
    /// Registers a listener for `GallerySdMediaListener`.
    ///
    /// - Parameters:
    ///    - didChange: listener's closure
    /// - Returns: registered listener
    func registerListener(didChange: @escaping GallerySdMediaListenerClosure) -> GallerySdMediaListener {
        let listener = GallerySdMediaListener(didChange: didChange)
        sdMediaListener.insert(listener)
        // Initial notification.
        listener.didChange(self.state.value)
        return listener
    }

    /// Removes previously registered `GallerySdMediaListener`.
    ///
    /// - Parameters:
    ///    - listener: listener to remove
    func unregisterListener(_ listener: GallerySdMediaListener?) {
        guard let listener = listener else {
            return
        }

        self.sdMediaListener.remove(listener)
    }

    /// Unregister all listener.
    func unregisterAllListener() {
        self.sdMediaListener.removeAll()
    }
}
