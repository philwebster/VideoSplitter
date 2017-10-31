import AVFoundation
import Photos
import UIKit

protocol VideoSplitterViewControllerDelegate: class {
    func videoSplitterViewControllerDidFinish(_ videoSplitterViewController: VideoSplitterViewController)
}

class VideoSplitterViewController: UIViewController {

    private var myContext = 0

    weak var delegate: VideoSplitterViewControllerDelegate?
    let asset: PHAsset
    let videoView = UIView()
    var avPlayer: AVPlayer?
    var avPlayerItem: AVPlayerItem?
    var avPlayerLayer: AVPlayerLayer?
    let timelineView = TimelineView()
    let slider = UISlider()
    
    var playerCurrentItemStatus: AVPlayerItemStatus = .unknown
    var isSeekInProgress = false
    var chaseTime = kCMTimeZero
    
    init(asset: PHAsset) {
        self.asset = asset
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        self.avPlayerItem?.removeObserver(self, forKeyPath: "status")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.tappedCancel(_:)))
        
        self.view.backgroundColor = UIColor.white
        
        let views = [self.videoView, self.timelineView, self.slider]
        views.forEach { (view) in
            view.translatesAutoresizingMaskIntoConstraints = false
            self.view.addSubview(view)
        }

        NSLayoutConstraint.activate([
            self.videoView.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor, multiplier: 0.75),
            self.videoView.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            self.videoView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.videoView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            self.videoView.heightAnchor.constraint(equalToConstant: 400)
            ])
        
        NSLayoutConstraint.activate([
            self.timelineView.widthAnchor.constraint(equalTo: self.view.widthAnchor),
            self.timelineView.heightAnchor.constraint(equalToConstant: 60),
            self.timelineView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.timelineView.bottomAnchor.constraint(equalTo: self.slider.topAnchor, constant: -8)
            ])
        
        self.slider.addTarget(self, action: #selector(self.sliderChanged(_:)), for: .valueChanged)
        NSLayoutConstraint.activate([
            self.slider.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.slider.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            self.slider.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.9)
            ])
        
        self.startVideoWithAsset(self.asset, in: self.videoView)
    }
    
    func startVideoWithAsset(_ asset: PHAsset, in view: UIView) {
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryAmbient, with: .mixWithOthers)
        
        PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (asset, audioMix, args) in
            let asset = asset as! AVURLAsset
            
            DispatchQueue.main.async {
                self.avPlayer = AVPlayer(url: asset.url)
                self.avPlayer?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
                
                let avPlayerLayer = AVPlayerLayer(player: self.avPlayer)
                self.avPlayerLayer = avPlayerLayer
                avPlayerLayer.frame = view.bounds
                avPlayerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                view.layer.insertSublayer(avPlayerLayer, at: 0)
                
                self.avPlayerItem = self.avPlayer?.currentItem
                self.avPlayerItem?.addObserver(self,
                                               forKeyPath: #keyPath(AVPlayerItem.status),
                                               options: [.new],
                                               context: &self.myContext)
            }
        }
    }
   
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &self.myContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItemStatus
            
            // Get the status change from the change dictionary
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItemStatus(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            self.playerCurrentItemStatus = status
            
            switch status {
            case .readyToPlay:
                self.slider.minimumValue = 0
                if let duration = self.avPlayerItem?.duration {
                    self.slider.maximumValue = Float(CMTimeGetSeconds(duration))
                }
                self.screenshot(handler: { (image) in
                    DispatchQueue.main.async {
                        self.timelineView.images.append(image)
                    }
                })
                break
            case .failed:
                break
            case .unknown:
                break
            }
        }
    }

    @objc func tappedCancel(_ sender: UIBarButtonItem) {
        self.delegate?.videoSplitterViewControllerDidFinish(self)
    }
    
    @objc func sliderChanged(_ slider: UISlider) {
        guard let timeScale = self.avPlayer?.currentItem?.tracks.first?.assetTrack.naturalTimeScale else {
            return
        }
        let time = CMTime(seconds: Double(slider.value), preferredTimescale: timeScale)
        self.stopPlayingAndSeekSmoothlyToTime(newChaseTime: time)
    }
    
    func stopPlayingAndSeekSmoothlyToTime(newChaseTime:CMTime) {
        self.avPlayer?.pause()
        
        if CMTimeCompare(newChaseTime, self.chaseTime) != 0 {
            self.chaseTime = newChaseTime;
            
            if !self.isSeekInProgress {
                self.trySeekToChaseTime()
            }
        }
    }
    
    func trySeekToChaseTime() {
        if self.playerCurrentItemStatus == .unknown {
        }
        else if playerCurrentItemStatus == .readyToPlay {
            self.actuallySeekToTime()
        }
    }
    
    func actuallySeekToTime() {
        self.isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        self.avPlayer?.seek(to: seekTimeInProgress, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (isFinished: Bool) -> Void in
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
            }
            else {
                self.trySeekToChaseTime()
            }
        })
    }
    
    func screenshot(handler: @escaping ((UIImage)->Void)) {
        guard let playerItem = self.avPlayerItem, let timeScale = playerItem.tracks.first?.assetTrack.naturalTimeScale else {
            return
        }
        
        let asset = playerItem.asset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        let endTime = Float(playerItem.duration.value)
        let strideLength = endTime / 5
        let times = stride(from: 0, to: endTime, by: strideLength).map { NSValue(time: CMTime(seconds: Double($0), preferredTimescale: timeScale)) }

        imageGenerator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, image, actualTime, result, error) in
            guard let image = image else {
                return
            }
            handler(UIImage(cgImage: image))
        }
    }
}
