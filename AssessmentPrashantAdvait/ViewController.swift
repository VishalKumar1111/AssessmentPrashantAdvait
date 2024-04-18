//
//  ViewController.swift
//  AssessmentPrashantAdvait
//
//  Created by RLogixxTraining on 14/04/24.
//

import UIKit

class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
        let imageURL = "https://acharyaprashant.org/api/v2/content/misc/media-coverages?limit=100"
        var arrImages: [URL] = []
        let imageCache = NSCache<NSURL, UIImage>()
    
        override func viewDidLoad() {
            super.viewDidLoad()
    
            collectionView.register(UINib(nibName: "CustomCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "cell")
    
            collectionView.delegate = self
            collectionView.dataSource = self
    
            fetchImages()
        }
    
        func fetchImages() {
            guard let url = URL(string: imageURL) else { return }
    
            URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
                guard let data = data else { return }
    
                do {
                    // Decode JSON data into an array of dictionaries
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        for dict in jsonArray {
                            if let coverageURLString = dict["coverageURL"] as? String,
                               let coverageURL = URL(string: coverageURLString) {
                                self?.arrImages.append(coverageURL)
                            }
                        }
    
                        DispatchQueue.main.async {
                            self?.collectionView.reloadData()
                        }
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }.resume()
        }
    
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return arrImages.count
        }
    
    
    
    
    
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CustomCollectionViewCell
    
            // Check if indexPath is within the bounds of arrImages
            guard indexPath.row < arrImages.count else {
                // Handle the case where indexPath is out of bounds
                return cell
            }
    
            let imageURL = arrImages[indexPath.row] // Use the imageURL corresponding to the indexPath
    
            // Check memory cache
            if let cachedImage = imageCache.object(forKey: imageURL as NSURL) {
                cell.imgView.image = cachedImage
                return cell
            }
    
            // Check disk cache
            if let diskImage = loadImageFromDisk(with: imageURL) {
                cell.imgView.image = diskImage
                // Save to memory cache
                imageCache.setObject(diskImage, forKey: imageURL as NSURL)
                return cell
            }
    
            // If not cached, download image
            downloadImage(from: imageURL) { (image) in
                if let image = image {
                    // Save to memory cache
                    self.imageCache.setObject(image, forKey: imageURL as NSURL)
                    // Save to disk cache
                    self.saveImageToDisk(image, with: imageURL)
                    // Update UI on the main thread
                    DispatchQueue.main.async {
                        // Check if there are visible index paths
                        if !collectionView.indexPathsForVisibleItems.isEmpty {
                            // Assign the image to the cell
                            cell.imgView.image = image
                        }
                    }
                }
            }
    
            return cell
    
        }
    
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let width = (collectionView.frame.width - 20) / 3
            return CGSize(width: width, height: width)
        }
    
        func loadImageFromDisk(with imageURL: URL) -> UIImage? {
            // Get the URL for the directory where the images are saved
            guard let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                print("Failed to get cache directory URL")
                return nil
            }
    
            // Get the unique identifier from the last path component of the imageURL
            let uniqueIdentifier = imageURL.lastPathComponent
    
            // Append the unique identifier to the directory URL to form the file URL
            let fileURL = directoryURL.appendingPathComponent(uniqueIdentifier)
    
            // Check if the image file exists at the file URL
            if FileManager.default.fileExists(atPath: fileURL.path) {
                // Load the image from the file URL
                if let imageData = try? Data(contentsOf: fileURL),
                   let image = UIImage(data: imageData) {
                    print("Image loaded from disk: \(fileURL)")
                    return image
                } else {
                    print("Failed to load image from file: \(fileURL)")
                }
            } else {
                print("Image file exist at path: \(fileURL.path)")
            }
    
            return nil
        }
    
        func saveImageToDisk(_ image: UIImage, with imageURL: URL) {
            // Generate a UUID as the unique identifier for the image
            let uniqueIdentifier = UUID().uuidString
    
            // Get the URL for the directory where you want to save the image
            guard let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                print("Failed to get cache directory URL")
                return
            }
    
            // Append the unique identifier to the directory URL to form the file URL
            let fileName = "\(uniqueIdentifier).jpg"
            let fileURL = directoryURL.appendingPathComponent(fileName)
    
            // Convert the image to data
            guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                print("Failed to convert image to data")
                return
            }
    
            // Write the image data to the file
            do {
                try imageData.write(to: fileURL)
                print("Image saved to disk: \(fileURL)")
            } catch {
                print("Failed to save image to disk: \(error)")
            }
        }
    
    
        func downloadImage(from imageURL: URL, completion: @escaping (UIImage?) -> Void) {
            let operationQueue = OperationQueue()
            operationQueue.addOperation {
                let uniqueIdentifier = UUID().uuidString
                let fileName = "\(uniqueIdentifier).jpg"
    
                guard let directoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                    print("Failed to get cache directory URL")
                    completion(nil)
                    return
                }
    
                let fileURL = directoryURL.appendingPathComponent(fileName)
    
                URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                    guard let data = data, let image = UIImage(data: data) else {
                        completion(nil)
                        return
                    }
    
                    DispatchQueue.main.async {
                        // Update UI on main thread
                        do {
                            try data.write(to: fileURL)
                            print("Image saved to disk: \(fileURL)")
                        } catch {
                            print("Failed to save image to disk: \(error)")
                        }
                        completion(image)
                    }
                }.resume()
            }
        }
    }
    
    
    
   
