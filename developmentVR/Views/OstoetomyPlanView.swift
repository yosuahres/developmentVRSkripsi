import SwiftUI
import RealityKit
import RealityKitContent

struct OstoetomyPlanView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        RealityView { content in
            if let selectedCaseGroup = appState.selectedCaseGroup,
               let usdzURL = selectedCaseGroup.usdzURL {
                do {
                    let modelEntity = try await ModelEntity(contentsOf: usdzURL)
                    content.add(modelEntity)
                } catch {
                    print("Error loading USDZ model from URL: \(error)")
                    // Fallback to Immersive.usda if USDZ fails to load
                    if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        content.add(scene)
                    }
                }
            } else {
                // Load the Immersive.usda scene from RealityKitContent as a fallback
                if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(scene)
                }
            }
        }
    }
}
