//
//  MeUIView.swift
//  OllieMoment
//
//  Created by 钱双贝 on 2025/3/1.
//

import SwiftUI
import PhotosUI
import Photos

struct MeUIView: View {
    // User profile states
    @State private var accountName: String = "Your Name"
    @State private var accountImage: Image = Image(systemName: "person.crop.circle.fill")
    
    // Settings Sheet
    @State private var showingSettings: Bool = false
    
    // Video Assets from "OllieMoment" album (for simplicity, using dummy data)
    @State private var videoAssets: [PHAsset] = []
    
    // Grid layout for posts
    let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // Profile Header (Instagram-style)
                    HStack(alignment: .center) {
                        accountImage
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text(accountName)
                                .font(.title2)
                                .bold()
                            // Additional info (e.g., bio) can be added here.
                        }
                    }
                    .padding([.horizontal, .top])
                    
                    // Divider
                    Divider()
                        .padding(.vertical, 5)
                    
                    // Grid of videos from "OllieMoment" album.
                    // For simplicity using dummy thumbnails.
                    LazyVGrid(columns: columns, spacing: 5) {
                        ForEach(0..<videoAssets.count, id: \.self) { index in
                            VideoThumbnailView(asset: videoAssets[index])
                        }
                    }
                    .padding(.horizontal)
                    .onAppear {
                        fetchVideoAssets()
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(accountName: $accountName, accountImage: $accountImage)
            }
        }
    }
    
    // Fetch video assets from the "OllieMoment" album using Photos API.
    func fetchVideoAssets() {
        // Request authorization if not already authorized.
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", AlbumManager.albumName)
                let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                if let album = collection.firstObject {
                    let assets = PHAsset.fetchAssets(in: album, options: nil)
                    var tempAssets: [PHAsset] = []
                    assets.enumerateObjects { (asset, _, _) in
                        if asset.mediaType == .video {
                            tempAssets.append(asset)
                        }
                    }
                    DispatchQueue.main.async {
                        videoAssets = tempAssets
                    }
                }
            } else {
                print("Photo library access not authorized")
            }
        }
    }
}

struct VideoThumbnailView: View {
    var asset: PHAsset
    @State private var thumbnail: UIImage? = nil
    
    var body: some View {
        ZStack {
            if let image = thumbnail {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.3)
                Image(systemName: "video")
                    .foregroundColor(.white)
            }
        }
        .frame(height: 120)
        .clipped()
        .onAppear {
            generateThumbnail(for: asset) { image in
                if let image = image {
                    self.thumbnail = image
                }
            }
        }
    }
    
    // Function to generate thumbnail image from PHAsset
    func generateThumbnail(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.resizeMode = .exact
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        let targetSize = CGSize(width: 150, height: 150)
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: targetSize,
                                              contentMode: .aspectFill,
                                              options: options) { image, _ in
            completion(image)
        }
    }
}

// Settings View to modify account picture and name
struct SettingsView: View {
    @Binding var accountName: String
    @Binding var accountImage: Image
    @Environment(\.presentationMode) var presentationMode
    @State private var newName: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account Picture")) {
                    HStack {
                        Spacer()
                        accountImage
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                        Spacer()
                    }
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text(selectedImage == nil ? "Select Photo" : "Change Photo")
                    }
                    .onChange(of: selectedItem) { newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                accountImage = Image(uiImage: uiImage)
                            }
                        }
                    }
                }
                
                Section(header: Text("Account Name")) {
                    TextField("Enter account name", text: $newName)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                if !newName.isEmpty {
                    accountName = newName
                }
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                newName = accountName
            }
        }
    }
    
}

struct MeUIView_Previews: PreviewProvider {
    static var previews: some View {
        MeUIView()
    }
}
