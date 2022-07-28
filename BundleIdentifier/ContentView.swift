import SwiftUI


struct ContentView: View {

    var body: some View {
        Form {
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], delegate: AppsDropDelegate())
    }

}


struct AppDropped: Hashable {
    
    let bundleIdentifier: String
    let name: String
    let icon: NSImage
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }

}


private struct AppsDropDelegate: DropDelegate {
    
    func validateDrop(info: DropInfo) -> Bool {
        guard info.hasItemsConforming(to: [.fileURL]) else { return false }
        
        let providers = info.itemProviders(for: [.fileURL])
        var result = false
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                let group = DispatchGroup()
                group.enter()
                
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    let itemIsAnApplicationBundle = try? url?.resourceValues(forKeys: [.contentTypeKey]).contentType == .applicationBundle
                    result = result || (itemIsAnApplicationBundle ?? false)    
                    group.leave()
                }
                
                _ = group.wait(timeout: .now() + 0.5)
            }
        }
        
        return result
    }
    
    func performDrop(info: DropInfo) -> Bool {
        let providers = info.itemProviders(for: [.fileURL])
        var result = false
        
        for provider in providers {
            if provider.canLoadObject(ofClass: URL.self) {
                let group = DispatchGroup()
                group.enter()
                
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    let itemIsAnApplicationBundle = (try? url?.resourceValues(forKeys: [.contentTypeKey]).contentType == .applicationBundle) ?? false
                    
                    if itemIsAnApplicationBundle, let url = url, let app = Bundle(url: url), let bundleIdentifier = app.bundleIdentifier {
                        DispatchQueue.main.async {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(bundleIdentifier, forType: .string)
                        }
                        
                        result = result || true
                    }
                    
                    group.leave()
                }
                
                _ = group.wait(timeout: .now() + 0.5)
            }
        }
        
        return result
    }
    
}
