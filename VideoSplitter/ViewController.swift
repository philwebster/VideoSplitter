import MobileCoreServices
import Photos
import UIKit

class ViewController: UIViewController {
    
    let pickVideoButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        self.pickVideoButton.translatesAutoresizingMaskIntoConstraints = false
        self.pickVideoButton.setTitle("Pick Video", for: .normal)
        self.pickVideoButton.addTarget(self, action: #selector(self.pickVideoTapped(_:)), for: .touchUpInside)
        self.view.addSubview(self.pickVideoButton)
        NSLayoutConstraint.activate([
            self.pickVideoButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.pickVideoButton.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        PHPhotoLibrary.requestAuthorization { (status) in
            
        }
    }

    @objc func pickVideoTapped(_ sender: UIButton) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) == true else {
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        self.present(picker, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let asset = info[UIImagePickerControllerPHAsset] as? PHAsset else {
            print("error getting asset")
            return
        }
        
        self.dismiss(animated: true) {
            let splitter = VideoSplitterViewController(asset: asset)
            splitter.delegate = self
            let nav = UINavigationController(rootViewController: splitter)
            self.present(nav, animated: true, completion: nil)
        }
    }
}

extension ViewController: UINavigationControllerDelegate {
    
}

extension ViewController: VideoSplitterViewControllerDelegate {
    
    func videoSplitterViewControllerDidFinish(_ videoSplitterViewController: VideoSplitterViewController) {
        self.dismiss(animated: true, completion: nil)
    }
}
