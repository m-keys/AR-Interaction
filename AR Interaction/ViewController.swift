//
//  ViewController.swift
//  AR Interaction
//
//  Created by Александр Макаров on 17.09.2018.
//  Copyright © 2018 Александр Макаров. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var hoopAdded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        if !hoopAdded {
            let touchLocation = sender.location(in: sceneView)
            
            let hitTestResult = sceneView.hitTest(touchLocation, types: [.existingPlaneUsingExtent])
            
            if let result = hitTestResult.first {
                addHoop(result: result)
                hoopAdded = true
            }
        } else {
            createBasketball()
        }
    }
    
    func addHoop(result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else { return }
        
        let position = result.worldTransform.columns.3
        hoopNode.position = SCNVector3(position.x, position.y, position.z)
        
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        sceneView.scene.rootNode.addChildNode(hoopNode)
    }
    
    func createWall(planeAnchor: ARPlaneAnchor) -> SCNNode {
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        let geometry = SCNPlane(width: width, height: height)
        
        let node = SCNNode()
        node.geometry = geometry
        
        node.eulerAngles.x = -Float.pi / 2
        node.opacity = 0.25
        
        
        
        return node
    }
    
    func createBasketball() {
        guard let frame = sceneView.session.currentFrame else { return } //позиция камеры
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "basketball-147794_960_720")
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin : 0.01]))
        ball.physicsBody = physicsBody
        
        let transform = SCNMatrix4(frame.camera.transform)
        ball.transform = transform
        
        let power = Float(10)
        let force = SCNVector3(-transform.m31 * power, -transform.m32 * power, -transform.m33 * power)
        
        ball.physicsBody?.applyForce(force, asImpulse: true)
        
        sceneView.scene.rootNode.addChildNode(ball)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let floor = createWall(planeAnchor: planeAnchor)
        node.addChildNode(floor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let floor = node.childNodes.first,
            let geometry = floor.geometry as? SCNPlane else { return }
        
        geometry.width = CGFloat(planeAnchor.extent.x)
        geometry.height = CGFloat(planeAnchor.extent.z)
        
        floor.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
