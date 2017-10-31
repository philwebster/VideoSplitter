import UIKit

class TimelineView: UIView {
    
    var images = [UIImage]() {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.subviews.forEach { $0.removeFromSuperview() }

        for (index, image) in self.images.enumerated() {
            let imageWidth = self.bounds.width / CGFloat(self.images.count)
            let origin = CGPoint(x: CGFloat(index) * imageWidth, y: 0)
            let size = CGSize(width: imageWidth, height: self.bounds.height)
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.frame = CGRect(origin: origin, size: size)
            self.addSubview(imageView)
        }
    }
}
