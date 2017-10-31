import UIKit

class TimelineView: UIView {
    
    var images = [UIImage]() {
        didSet {
            self.setNeedsLayout()
        }
    }
    var imageViews = [UIImageView]()
    
    var markers = [UIView]()
    var scrubber = UIView()
    let panRecognizer = UIPanGestureRecognizer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.panRecognizer.addTarget(self, action: #selector(self.handlePan(_:)))
        self.addGestureRecognizer(self.panRecognizer)
        
        self.addSubview(self.scrubber)
        self.scrubber.backgroundColor = UIColor.red
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.imageViews.forEach { $0.removeFromSuperview() }
        self.imageViews = []

        for (index, image) in self.images.enumerated() {
            let imageWidth = self.bounds.width / CGFloat(self.images.count)
            let origin = CGPoint(x: CGFloat(index) * imageWidth, y: 0)
            let size = CGSize(width: imageWidth, height: self.bounds.height)
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(origin: origin, size: size)
            self.addSubview(imageView)
            self.imageViews.append(imageView)
        }
        
        self.bringSubview(toFront: self.scrubber)
        self.scrubber.frame = CGRect(x: self.scrubber.frame.origin.x, y: 0, width: 5, height: self.bounds.height)
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            break
        case .changed:
            self.scrubber.frame.origin.x = recognizer.location(in: self).x
        case .ended:
            break
        case .cancelled:
            break
        case .failed:
            break
        default:
            break
        }
    }
}
