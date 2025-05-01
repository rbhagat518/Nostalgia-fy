//
//  MontageViewController.swift
//  HelloSpotify
//
//  Created by Ram Bhagat  on 4/23/25.
//

import UIKit
import Photos
import AVFoundation
import WebKit


var player: AVPlayer?

class MontageViewController: UIViewController {
    var playedAt: String!
    var track: Track!
    var player: AVPlayer?
    var accessToken: String!


    @IBOutlet weak var spotifyEmbedContainer: UIView!
    var matchingAssets: [PHAsset] = []
    let imageManager = PHCachingImageManager()

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!


    override func viewDidLoad() {
        super.viewDidLoad()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: playedAt) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "MMMM d"
            let readableDate = displayFormatter.string(from: date)
            self.title = "On this Day \(readableDate)"
        }
        requestPhotoAccessIfNeeded {
            self.loadPhotosMatchingTrackDate()
        }
        if let url = track.externalURLs["spotify"],
           let id = URL(string: url)?.lastPathComponent {
            loadSpotifyEmbed(trackID: id)
        }


    }

    func loadSpotifyEmbed(trackID: String) {
        let webView = WKWebView(frame: spotifyEmbedContainer.bounds)
        spotifyEmbedContainer.addSubview(webView)

        let html = """
        <iframe src="https://open.spotify.com/embed/track/\(trackID)"
                width="100%" height="180" frameborder="0"
                allowtransparency="true" allow="encrypted-media">
        </iframe>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func fetchFullTrackInfo(trackID: String, completion: @escaping (Track?) -> Void) {
        guard let token = accessToken else {
            completion(nil)
            return
        }

        let url = URL(string: "https://api.spotify.com/v1/tracks/\(trackID)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                print("❌ No data for track ID: \(trackID)")
                completion(nil)
                return
            }

            do {
                let fullTrack = try JSONDecoder().decode(Track.self, from: data)
                print("✅ Full track preview URL:", fullTrack.previewURL ?? "none")
                completion(fullTrack)
            } catch {
                print("⚠️ Failed to decode full track:", error)
                completion(nil)
            }
        }.resume()
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
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        guard let exampleDate = formatter.date(from: playedAt) else {
            print("❌ Failed to parse playedAt")
            return
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month, .day], from: exampleDate)
        print("📆 Parsed date:", exampleDate)

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
            self.startSlideshow()
        }
    }

    var currentIndex = 0
    var slideshowTimer: Timer?

    func startSlideshow() {
        guard !matchingAssets.isEmpty else { return }

        currentIndex = 0
        showCurrentPhoto()

        slideshowTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
            self.currentIndex = (self.currentIndex + 1) % self.matchingAssets.count
            self.showCurrentPhoto()
        }
        if let urlString = track.previewURL, let url = URL(string: urlString) {
            player = AVPlayer(url: url)
            player?.play()
        }
    }

    func showCurrentPhoto() {
        let asset = matchingAssets[currentIndex]
        let targetSize = view.bounds.size

        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { image, _ in
            guard let image = image else { return }

            UIView.transition(with: self.imageView,
                              duration: 1.0,
                              options: .transitionCrossDissolve,
                              animations: {
                                  self.imageView.image = image
                              },
                              completion: nil)
        }
    }


    deinit {
        slideshowTimer?.invalidate()
    }
}


/*
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
*/


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
