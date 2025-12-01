
//
//  Character3D_SceneKit.swift
//  Element8
//
//  Created by Copilot on 2025-12-01 (example).
//  SceneKit-based SwiftUI wrapper to display a 3D character model from the app bundle,
//  play named animation clips, and respond to taps.
//
//  Usage:
//    Character3DSceneView(profileKey: "fire", preferredAnimation: "idle", autoPlay: true)
//
import SwiftUI
import SceneKit
#if canImport(UIKit)
import UIKit
#endif

/// SwiftUI wrapper around an SCNView that loads a model file by convention:
/// - "<profileKey>.usdz" or "<profileKey>.scn" (first found in bundle).
/// The view attempts to find and play an animation named `preferredAnimation` when it appears.
public struct Character3DSceneView: UIViewRepresentable {
    public var profileKey: String
    public var preferredAnimation: String? = "idle"
    public var autoPlay: Bool = true
    /// Optional scale to apply to the imported node
    public var modelScale: Float = 1.0
    /// Whether the model should continuously play the preferred animation (loop).
    public var loopAnimation: Bool = true
    /// Optional tap callback
    public var onTap: (() -> Void)? = nil

    public init(profileKey: String,
                preferredAnimation: String? = "idle",
                autoPlay: Bool = true,
                modelScale: Float = 1.0,
                loopAnimation: Bool = true,
                onTap: (() -> Void)? = nil) {
        self.profileKey = profileKey
        self.preferredAnimation = preferredAnimation
        self.autoPlay = autoPlay
        self.modelScale = modelScale
        self.loopAnimation = loopAnimation
        self.onTap = onTap
    }

    public func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.backgroundColor = UIColor.clear
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.rendersContinuously = true
        scnView.scene = SCNScene()
        scnView.isUserInteractionEnabled = true

        // Add tap gesture recognizer
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tap)

        // Camera
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0.7, 2.1) // tweak to taste
        scnView.scene?.rootNode.addChildNode(cameraNode)

        // Light (ambient)
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.6, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scnView.scene?.rootNode.addChildNode(ambientNode)

        // Directional fill
        let dir = SCNLight()
        dir.type = .directional
        dir.color = UIColor(white: 0.95, alpha: 1.0)
        let dirNode = SCNNode()
        dirNode.light = dir
        dirNode.eulerAngles = SCNVector3(-0.6, 0.7, 0)
        scnView.scene?.rootNode.addChildNode(dirNode)

        // Load model async to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            loadModelIntoScene(scnView: scnView)
        }

        return scnView
    }

    public func updateUIView(_ uiView: SCNView, context: Context) {
        // noop; could update animation target etc.
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Model loading helpers

    private func loadModelIntoScene(scnView: SCNView) {
        guard let scene = findSceneForProfileKey(profileKey) else {
            return
        }

        // To ensure we update UI on main:
        DispatchQueue.main.async {
            // Clear previous model nodes except camera/light nodes that we added
            let reservedNames: Set<String> = ["__camera", "__light"]
            for node in scnView.scene?.rootNode.childNodes ?? [] {
                // Keep lights and camera (they don't have name set, but we use indexes)
                // For simplicity, remove all nodes that are not camera or light.
                if node.camera == nil && node.light == nil {
                    node.removeFromParentNode()
                }
            }

            // Attach all top-level nodes from loaded scene
            for child in scene.rootNode.childNodes {
                // scale each node by modelScale
                child.scale = SCNVector3(modelScale, modelScale, modelScale)
                scnView.scene?.rootNode.addChildNode(child)
            }

            // Optionally play animation
            if autoPlay, let pref = preferredAnimation {
                playAnimationIfPresent(in: scnView, named: pref, loop: loopAnimation)
            }
        }
    }

    /// Attempt to locate a scene in the bundle using common conventions:
    /// - <profileKey>.usdz
    /// - <profileKey>.scn (or inside art.scnassets/<profileKey>.scn)
    private func findSceneForProfileKey(_ key: String) -> SCNScene? {
        // 1) Try USDZ at top-level
        if let url = Bundle.main.url(forResource: key, withExtension: "usdz") {
            return try? SCNScene(url: url, options: nil)
        }
        // 2) Try .scn at top-level
        if let url2 = Bundle.main.url(forResource: key, withExtension: "scn") {
            return try? SCNScene(url: url2, options: nil)
        }
        // 3) Try art.scnassets/<key>.scn
        if let url3 = Bundle.main.url(forResource: "art.scnassets/\(key)", withExtension: "scn") {
            return try? SCNScene(url: url3, options: nil)
        }
        // 4) Fallback: try to load as named resource via SCNScene(named:)
        if let scn = SCNScene(named: "\(key).scn") { return scn }
        if let scn2 = SCNScene(named: "art.scnassets/\(key).scn") { return scn2 }

        return nil
    }

    /// Plays an animation named `named` if available in the loaded scene.
    /// This looks into the scene's animation players and SCNSceneSource animations.
    private func playAnimationIfPresent(in scnView: SCNView, named name: String, loop: Bool) {
        // Try to find any animation player for the root node or children
        func traversePlay(_ node: SCNNode) -> Bool {
            // SceneKit stores named CAAnimations in node.animationKeys / animationPlayer(forKey:)
            if let player = node.animationPlayer(forKey: name) {
                player.play()
                player.animation.repeatCount = loop ? .infinity : 1
                return true
            }

            // Try to find CAAnimation attached via key in the scene source (less common)
            for key in node.animationKeys {
                if key == name {
                    node.animationPlayer(forKey: key)?.play()
                    node.animationPlayer(forKey: key)?.animation.repeatCount = loop ? .infinity : 1
                    return true
                }
            }

            for c in node.childNodes {
                if traversePlay(c) { return true }
            }
            return false
        }

        if let root = scnView.scene?.rootNode {
            let found = traversePlay(root)
            if found { return }
        }

        // As a last resort, try to load animations using SCNSceneSource if model was loaded from URL.
        if let sceneURL = scnView.scene?.value(forKey: "sceneURL") as? URL {
            if let source = SCNSceneSource(url: sceneURL, options: nil) {
                // Iterate through identifiers and try to find matching animation identifiers
                let identifiers = source.identifiersOfEntries(withClass: CAAnimation.self)
                if identifiers.contains(name), let anim = source.entryWithIdentifier(name, withClass: CAAnimation.self) {
                    anim.repeatCount = loop ? .infinity : 1
                    scnView.scene?.rootNode.addAnimation(anim, forKey: name)
                    return
                }
                // Try playing the first animation if no name match
                if let firstId = identifiers.first, let anim = source.entryWithIdentifier(firstId, withClass: CAAnimation.self) {
                    anim.repeatCount = loop ? .infinity : 1
                    scnView.scene?.rootNode.addAnimation(anim, forKey: firstId)
                }
            }
        }
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject {
        var parent: Character3DSceneView

        init(_ parent: Character3DSceneView) {
            self.parent = parent
            super.init()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            parent.onTap?()
        }
    }
}
