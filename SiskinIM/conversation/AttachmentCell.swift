//
//  AttachmentCell.swift
//  Siskin IM
//
//  Created by Nandini Barve on 09/11/21.
//  Copyright © 2021 Tigase, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class AttachmentCell: UITableViewCell {

    @IBOutlet var customView: UIView!;
    @IBOutlet var imageViewAttachment: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    //let localUrl = DownloadStore.instance.url(for: "\(item.id)")
    func getImageFromDir(localUrl: URL) -> UIImage? {
//        if NSFileManager.defaultManager().fileExistsAtPath(imageUrlPath) {
//            let url = NSURL(string: imageUrlPath)
//            let data = NSData(contentsOfURL: url!)
//            imageView.image = UIImage(data: data!)
//        }
        do {
            let imageData = try Data(contentsOf: localUrl)
            return UIImage(data: imageData)
        } catch {
            print("Not able to load image")
        }
       /* if let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsUrl.appendingPathComponent(imageName)
            do {
                let imageData = try Data(contentsOf: fileURL)
                return UIImage(data: imageData)
            } catch {
                print("Not able to load image")
            }
        }*/
        return nil
    }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        
        return nil
    }

}
