//
//  ClipUIView.swift
//  Test
//
//  Created by 钱双贝 on 2025/2/24.
//

import SwiftUI
import PhotosUI
import AVFoundation
import AVKit
import UniformTypeIdentifiers

struct ClipUIView: View {
    @State private var showingVideoPicker = false
    @State private var selectedVideo: PHPickerResult?
    @State private var videoSegments: [Segment] = []
    @State private var isProcessing = false
    @State private var currentPlayer: AVPlayer?
    @State private var selectedSegmentIndex: Int?
    @State private var originalVideoURL: URL?
    @State private var isShowingExportDialog = false
    @State private var exportOption: String = "All"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    if isProcessing {
                        ProgressView("Processing video...")
                    } else if let originalURL = originalVideoURL, !videoSegments.isEmpty {
                        VideoPlayer(player: currentPlayer ?? AVPlayer(url: originalURL))
                            .edgesIgnoringSafeArea(.all)
                        
                        // Clips list
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 10) {
                                ForEach(Array(videoSegments.enumerated()), id: \.offset) { index, segment in
                                    VStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedSegmentIndex == index ? Color.blue : Color.gray)
                                            .frame(width: 80, height: 60)
                                            .overlay(
                                                VStack {
                                                    Text("Clip \(index + 1)")
                                                        .foregroundColor(.white)
                                                    if segment.favorite {
                                                        Image(systemName: "star.fill")
                                                            .foregroundColor(.yellow)
                                                    }
                                                }
                                            )
                                    }
                                    .onTapGesture {
                                        selectedSegmentIndex = index
                                        if let url = originalVideoURL {
                                            let player = currentPlayer ?? AVPlayer(url: url)
                                            player.seek(to: CMTime(seconds: segment.startTime, preferredTimescale: 600))
                                            currentPlayer = player
                                            currentPlayer?.play()
                                        }
                                    }
                                    .highPriorityGesture(
                                        TapGesture(count: 2).onEnded {
                                            videoSegments[index].favorite.toggle()
                                            print("Segment \(index + 1) favorite: \(videoSegments[index].favorite)")
                                        }
                                    )
                                }
                            }
                            .padding()
                        }
                        .frame(height: 100)
                        .background(Color(UIColor.systemBackground))
                } else {
                    Button(action: {
                        showingVideoPicker = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(.white)
                                    .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                            )
                    }
                }
            }
        }
        .navigationTitle("Clip")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    currentPlayer?.pause()
                    currentPlayer = nil
                    videoSegments = []
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    isShowingExportDialog = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 24))
                }
            }
        }
        .sheet(isPresented: $showingVideoPicker) {
            VideoPicker(selectedVideo: $selectedVideo) { url in
                processVideo(url: url)
            }
        }
        .sheet(isPresented: $isShowingExportDialog) {
            ExportDialog(isPresented: $isShowingExportDialog, exportOption: $exportOption, onExport: {
                exportVideo(exportOption: exportOption)
            })
        }
        }
    }
    
    func processVideo(url: URL) {
        isProcessing = true
        
        // Create an instance of VideoSegmentProcessor and invoke its ImageModelProcess instance method
        let processor = VideoSegmentProcessor()
        let result = processor.ImageModelProcess(videoURL: url)
        if result.isEmpty {
            videoSegments = [Segment(startTime: 0, endTime: -1)]
        } else {
            videoSegments = result
        }
        print("ImageModelProcess result: \(videoSegments)")
        
        originalVideoURL = url
        currentPlayer = AVPlayer(url: url)
        selectedSegmentIndex = 0
        isProcessing = false
    }
    
    func exportVideo(exportOption: String) {
        guard let url = originalVideoURL else {
            print("Original video URL is nil")
            return
        }
        
        let asset = AVAsset(url: url)
        // Filter segments based on exportOption ("Favorite" exports only favorite segments; "All" exports all segments)
        let segmentsToExport: [Segment] = (exportOption == "Favorite") ? videoSegments.filter { $0.favorite } : videoSegments
        
        if segmentsToExport.isEmpty {
            print("No segments to export for option \(exportOption)")
            return
        }
        
        // Export each segment individually.
        for (index, segment) in segmentsToExport.enumerated() {
            // Generate a unique output URL for each segment.
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("exportedSegment_\(index).mp4")
            
            Task {
                do {
                    try await VideoSegmentProcessor.exportVideoSegment(asset: asset,
                        startTime: segment.startTime,
                        duration: segment.endTime - segment.startTime,
                        outputURL: outputURL)
                    
                    print("Exported video segment \(index) to \(outputURL)")
                    AlbumManager.addVideoToAlbum(videoURL: outputURL)
                } catch {
                    print("Failed to export segment \(index): \(error)")
                }
            }
        }
    }
    
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: PHPickerResult?
    @Environment(\.presentationMode) private var presentationMode
    var onVideoSelected: (URL) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
            super.init()
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let video = results.first {
                parent.selectedVideo = video
                
                video.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        print("Error loading video: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let url = url else { return }
                    
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)
                    
                    try? FileManager.default.removeItem(at: tempURL)
                    try? FileManager.default.copyItem(at: url, to: tempURL)
                    
                    DispatchQueue.main.async {
                        self.parent.onVideoSelected(tempURL)
                    }
                }
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct ExportDialog: View {
    @Binding var isPresented: Bool
    @Binding var exportOption: String
    var onExport: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Options")
                .font(.headline)
            Picker("Export Option", selection: $exportOption) {
                Text("Favorite").tag("Favorite")
                Text("All").tag("All")
            }
            .pickerStyle(SegmentedPickerStyle())
            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Spacer()
                Button("OK") {
                    isPresented = false
                    onExport()
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct ClipUIView_Previews: PreviewProvider{
    static var previews: some View{
        ClipUIView()
    }
}
