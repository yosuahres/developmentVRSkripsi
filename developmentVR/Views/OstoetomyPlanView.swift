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
                    if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                        content.add(scene)
                    }
                }
            } else {
                if let scene = try? await Entity(named: "Immersive", in: realityKitContentBundle) {
                    content.add(scene)
                }
            }
        }
    }
}
