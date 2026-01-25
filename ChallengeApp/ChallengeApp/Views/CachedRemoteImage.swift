//
//  CachedRemoteImage.swift
//  ChallengeApp
//
//  Lightweight in-memory cached remote image loader
//  (avoids UI stalls on decoding large images)
//

import SwiftUI
import UIKit

final class RemoteImageCache: @unchecked Sendable {
    // NSCache is thread-safe; we access it from background tasks.
    static let shared = RemoteImageCache()
    private let cache = NSCache<NSURL, UIImage>()
    
    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 80 * 1024 * 1024 // ~80MB
    }
    
    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }
    
    func insert(_ image: UIImage, for url: URL) {
        let cost = Int(image.size.width * image.size.height * image.scale * image.scale)
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
    
    func remove(for url: URL) {
        cache.removeObject(forKey: url as NSURL)
    }
}

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    private var task: Task<Void, Never>?
    private var currentURL: URL?
    private var currentToken = UUID()
    
    func load(url: URL?) {
        guard url != currentURL else { return }
        currentURL = url
        currentToken = UUID()
        let token = currentToken
        
        task?.cancel()
        image = nil
        
        guard let url else { return }
        
        if let cached = RemoteImageCache.shared.image(for: url) {
            image = cached
            return
        }
        
        task = Task.detached(priority: .utility) { [url, token] in
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 15
                
                let (data, _) = try await URLSession.shared.data(for: request)
                try Task.checkCancellation()
                
                // Decode off-main
                guard let decoded = UIImage(data: data) else { return }
                RemoteImageCache.shared.insert(decoded, for: url)
                
                await MainActor.run { [weak self] in
                    guard let self, self.currentToken == token else { return }
                    self.image = decoded
                }
            } catch {
                // ignore cancellation / transient errors
            }
        }
    }
    
    func cancel() {
        task?.cancel()
        task = nil
    }
}

struct CachedRemoteImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @StateObject private var loader = RemoteImageLoader()
    
    var body: some View {
        Group {
            if let uiImage = loader.image {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .onAppear { loader.load(url: url) }
        .onChange(of: url) { _, newURL in loader.load(url: newURL) }
        .onDisappear { loader.cancel() }
    }
}

struct AvatarCircleButton: View {
    let avatarURLString: String?
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            let url = URL(string: avatarURLString ?? "")
            ZStack {
                if let avatarURLString, !avatarURLString.isEmpty, url != nil {
                    CachedRemoteImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.55, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.55, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .frame(width: size, height: size)
            .background(Color.white.opacity(0.12))
            .clipShape(Circle())
            .overlay(
                Circle().stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("profile.open".localized)
    }
}

