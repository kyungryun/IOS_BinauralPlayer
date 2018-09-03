//
//  VideoCollectionViewController.swift
//  BinauralPlayer
//
//  Created by kyungryun Choi on 2018. 5. 21..
//  Copyright © 2018년 kyungryun Choi. All rights reserved.
//

import UIKit
import Photos

class VideoCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var videoImages = [String]()
    
    override func viewDidLoad() {
        collectionView.delegate = self
        collectionView.dataSource = self
        super.viewDidLoad()
        
        for idx in 0..<appDelegate!.videoList.count{
            print("video \(appDelegate!.videoList[idx])")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "playVideo"{
            let dest = segue.destination
            
            guard let videoViewController = dest as? VideoViewController else{
                print("videoView")
                return
            }
            
            let cell = sender as! UICollectionViewCell
            let indexPath = self.collectionView!.indexPath(for: cell)
            
            let row = indexPath?.row
            videoViewController.vtitle = appDelegate!.videoNames[row!]
            videoViewController.vUrl = appDelegate!.videoList[row!]
            
        }
    }
    
    /*
     * 비디오 리스트 갱신
     */
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return appDelegate!.videoList.count
    }
    
    /*
     * 비디오 썸네일 설정
     */
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! CustomCollectionViewCell
        let row = indexPath.row
        
        var thumbImage: UIImage?
        let asset = AVAsset(url: appDelegate!.videoList[row])
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMake(asset.duration.value / 3, asset.duration.timescale)
        if let CGImage = try? assetImgGenerate.copyCGImage(at: time, actualTime: nil) {
            thumbImage = UIImage(cgImage: CGImage)
        }
        cell.videoImage.image = thumbImage
        cell.videoName.text = appDelegate!.videoNames[indexPath.row]
        
        return cell
    }
}
