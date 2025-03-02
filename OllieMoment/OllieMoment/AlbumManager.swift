import Foundation
import Photos

class AlbumManager {
    static let albumName = "OllieMoment"
    
    static func checkAndCreateAlbum() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access not authorized")
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if collection.firstObject == nil {
                // Album doesn't exist, create it.
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                }, completionHandler: { success, error in
                    if success {
                        print("Album \(albumName) created successfully")
                    } else {
                        print("Failed to create album \(albumName): \(error?.localizedDescription ?? "unknown error")")
                    }
                })
            } else {
                print("Album \(albumName) already exists")
            }
        }
    }
    
    static func addVideoToAlbum(videoURL: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                print("Photo library access not authorized")
                return
            }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            guard let album = collection.firstObject else {
                print("Album \(albumName) not found")
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                if let assetChangeRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL),
                   let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                   let placeholder = assetChangeRequest.placeholderForCreatedAsset {
                    albumChangeRequest.addAssets([placeholder] as NSArray)
                }
            }, completionHandler: { success, error in
                if success {
                    print("Successfully added video to album \(albumName)")
                } else {
                    print("Error adding video to album: \(error?.localizedDescription ?? "")")
                }
            })
        }
    }
}
