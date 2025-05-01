//
//  MontageViewController.swift
//  HelloSpotify
//
//  Created by Ram Bhagat  on 4/23/25.
//

import UIKit
import Photos

class MontageViewController: UIViewController {
    var playedAt: String!
    var track: Track! // Passed from previous screen

    var matchingAssets: [PHAsset] = []
    let imageManager = PHCachingImageManager()


    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self

        titleLabel.text = "Photos from \(track.name)'s Day"

        requestPhotoAccessIfNeeded {
            self.loadPhotosMatchingTrackDate()
        }
    }

    func requestPhotoAccessIfNeeded(completion: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion()
        } else {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }

    func loadPhotosMatchingTrackDate() {
        print("🎧 playedAt:", playedAt ?? "nil")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let exampleDate = formatter.date(from: playedAt) else {
            print("❌ Failed to parse playedAt")
            return
        }
        print("📆 Parsed date:", exampleDate)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: exampleDate)
        print("Looking for photos from day \(components.day!), month \(components.month!)")

        var assets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let assetComponents = calendar.dateComponents([.month, .day], from: creationDate)
                if assetComponents.day == components.day && assetComponents.month == components.month {
                    assets.append(asset)
                }
            }
        }
        print("Found \(assets.count) matching photos")


        DispatchQueue.main.async {
            self.matchingAssets = assets
            self.collectionView.reloadData()
        }
    }
}

extension MontageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matchingAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell

        let asset = matchingAssets[indexPath.item]
        let targetSize = collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath)?.size ?? CGSize(width: 200, height: 200)

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { image, _ in
            cell.imageView.image = image
        }

        return cell
    }
}

class ImageCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
}

func fetchPhotos(for day: Int, month: Int, completion: @escaping ([PHAsset]) -> Void) {
    print("hi")
    var matching: [PHAsset] = []

    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

    let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    allPhotos.enumerateObjects { asset, _, _ in
        guard let date = asset.creationDate else { return }
        let components = Calendar.current.dateComponents([.day, .month], from: date)
        if components.day == day && components.month == month {
            matching.append(asset)
        }
    }

    completion(matching)
}



/*
import Foundation
import UIKit
import Photos

class MontageViewController: UIViewController {
    var track: Track! // Passed from previous screen
    var playedAt: String!

    var matchingAssets: [PHAsset] = []
    let imageManager = PHCachingImageManager()

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: track.playedAt) {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.month, .day], from: date)

            fetchPhotos(for: components.day!, month: components.month!) { assets in
                DispatchQueue.main.async {
                    self.matchingAssets = assets
                    self.collectionView.reloadData()
                }
            }
        }
    }


    func requestPhotoAccessIfNeeded(completion: @escaping () -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion()
        } else {
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }

    func loadPhotosMatchingTrackDate() {
        guard let exampleDate = ISO8601DateFormatter().date(from: track.playedAt) else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: exampleDate)

        var assets: [PHAsset] = []
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.enumerateObjects { asset, _, _ in
            if let creationDate = asset.creationDate {
                let assetComponents = calendar.dateComponents([.month, .day], from: creationDate)
                if assetComponents.day == components.day && assetComponents.month == components.month {
                    assets.append(asset)
                }
            }
        }

        DispatchQueue.main.async {
            self.matchingAssets = assets
            self.collectionView.reloadData()
        }
    }
}

extension MontageViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return matchingAssets.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell

        let asset = matchingAssets[indexPath.item]
        imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: nil) { image, _ in
            cell.imageView.image = image
        }

        return cell
    }
}

func fetchPhotos(for day: Int, month: Int, completion: @escaping ([PHAsset]) -> Void) {
    var matching: [PHAsset] = []

    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

    let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

    allPhotos.enumerateObjects { asset, _, _ in
        guard let date = asset.creationDate else { return }
        let components = Calendar.current.dateComponents([.day, .month], from: date)
        if components.day == day && components.month == month {
            matching.append(asset)
        }
    }

    completion(matching)
}


class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
}
*/
