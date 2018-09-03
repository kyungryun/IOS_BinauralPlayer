//
//  ViewController.swift
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 5. 21..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

import UIKit
import Photos
import SwiftGifOrigin
class ViewController: UIViewController {
    
    @IBOutlet weak var gifView: UIImageView!

    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gifView.image = UIImage.gif(name: "sonicplay_info_loading_1")
        loadVideo()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    /*
     * 갤러리에서 비디오리스트 불러옴
     */
    public func loadVideo(){
        PHPhotoLibrary.requestAuthorization { (status) -> Void in
            let allVidOptions = PHFetchOptions()
            allVidOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue)
            allVidOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            
            let allVids = PHAsset.fetchAssets(with: allVidOptions)
            
            for index in 0..<allVids.count {
                print("\(allVids[index])")
                let name = PHAssetResource.assetResources(for: allVids[index]).first?.originalFilename
                print(name!)
                self.appDelegate?.videoNames.append(name!)
                let options: PHVideoRequestOptions = PHVideoRequestOptions()
                options.version = .original
                
                PHImageManager.default().requestAVAsset(forVideo: allVids[index], options: options, resultHandler: { (asset, audioMix, info) in
                    if let urlAsset = asset as? AVURLAsset {
                        let localVideoUrl = urlAsset.url
                        DispatchQueue.main.async {
                            self.appDelegate?.videoList.append(localVideoUrl)
                        }
                    }
                })
            }
        }
    }
}

