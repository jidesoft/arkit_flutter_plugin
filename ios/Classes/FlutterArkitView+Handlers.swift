import ARKit

extension FlutterArkitView {
    func onAddNode(_ arguments: Dictionary<String, Any>) {
        let geometryArguments = arguments["geometry"] as? Dictionary<String, Any>
        let geometry = createGeometry(geometryArguments, withDevice: sceneView.device)
        let node = createNode(geometry, fromDict: arguments, forDevice: sceneView.device)
        if let parentNodeName = arguments["parentNodeName"] as? String {
            let parentNode = sceneView.scene.rootNode.childNode(withName: parentNodeName, recursively: true)
            parentNode?.addChildNode(node)
        } else {
            sceneView.scene.rootNode.addChildNode(node)
        }
    }
    
    func onRemoveNode(_ arguments: Dictionary<String, Any>) {
        guard let nodeName = arguments["nodeName"] as? String else {
            logPluginError("nodeName deserialization failed", toChannel: channel)
            return
        }
        let node = sceneView.scene.rootNode.childNode(withName: nodeName, recursively: true)
        node?.removeFromParentNode()
    }
    
    func onGetNodeBoundingBox(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let geometryArguments = arguments["geometry"] as? Dictionary<String, Any> else {
            logPluginError("geometryArguments deserialization failed", toChannel: channel)
            result(nil)
            return
        }
        let geometry = createGeometry(geometryArguments, withDevice: sceneView.device)
        let node = createNode(geometry, fromDict: arguments, forDevice: sceneView.device)
        
        let resArray = [serializeVector(node.boundingBox.min), serializeVector(node.boundingBox.max)]
        result(resArray)
    }
    
    func onPositionChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["position"] as? Array<Double>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.position = deserializeVector3(params)
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onRotationChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["rotation"] as? Array<Double>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.rotation = deserializeVector4(params)
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onEulerAnglesChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["eulerAngles"] as? Array<Double>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.eulerAngles = deserializeVector3(params)
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onLookAtChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["lookAt"] as? Array<Double>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.look(at: deserializeVector3(params))
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }

    func onScaleChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["scale"] as? Array<Double>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.scale = deserializeVector3(params)
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onOpacityChanged(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let params = arguments["opacity"] as? CGFloat
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            node.opacity = params
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }

    func onUpdateSingleProperty(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let args = arguments["property"] as? Dictionary<String, Any>,
            let propertyName = args["propertyName"] as? String,
            let propertyValue = args["propertyValue"],
            let keyProperty = args["keyProperty"] as? String
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            if let obj = node.value(forKey: keyProperty) as? NSObject {
                obj.setValue(propertyValue, forKey: propertyName)
            } else {
                logPluginError("value is not a NSObject", toChannel: channel)
            }
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onUpdateMaterials(_ arguments: Dictionary<String, Any>) {
        guard let name = arguments["name"] as? String,
            let rawMaterials = arguments["materials"] as? Array<Dictionary<String, Any>>
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true) {
            
            let materials = parseMaterials(rawMaterials)
            node.geometry?.materials = materials
        } else {
            logPluginError("node not found", toChannel: channel)
        }
    }
    
    func onUpdateFaceGeometry(_ arguments: Dictionary<String, Any>) {
        #if !DISABLE_TRUEDEPTH_API
        guard let name = arguments["name"] as? String,
            let param = arguments["geometry"] as? Dictionary<String, Any>,
            let fromAnchorId = param["fromAnchorId"] as? String
            else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        if let node = sceneView.scene.rootNode.childNode(withName: name, recursively: true),
            let geometry = node.geometry as? ARSCNFaceGeometry,
            let anchor = sceneView.session.currentFrame?.anchors.first(where: {$0.identifier.uuidString == fromAnchorId}) as? ARFaceAnchor
        {
            
            geometry.update(from: anchor.geometry)
        } else {
            logPluginError("node not found, geometry was empty, or anchor not found", toChannel: channel)
        }
        #else
        logPluginError("TRUEDEPTH_API disabled", toChannel: channel)
        #endif
    }
    
    func onPerformHitTest(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let x = arguments["x"] as? Double,
            let y = arguments["y"] as? Double else {
                logPluginError("deserialization failed", toChannel: channel)
                result(nil)
                return
        }
        let viewWidth = sceneView.bounds.size.width
        let viewHeight = sceneView.bounds.size.height
        let location = CGPoint(x: viewWidth * CGFloat(x), y: viewHeight * CGFloat(y));
        let arHitResults = getARHitResultsArray(sceneView, atLocation: location)
        result(arHitResults)
    }
    
    func onGetLightEstimate(_ result:FlutterResult) {
        let frame = sceneView.session.currentFrame
        if let lightEstimate = frame?.lightEstimate {
            let res = ["ambientIntensity": lightEstimate.ambientIntensity, "ambientColorTemperature": lightEstimate.ambientColorTemperature]
            result(res)
        } else {
            result(nil)
        }
    }
    
    func onProjectPoint(_ arguments: Dictionary<String, Any>, _ result:FlutterResult) {
        guard let rawPoint = arguments["point"] as? Array<Double> else {
            logPluginError("deserialization failed", toChannel: channel)
            result(nil)
            return
        }
        let point = deserializeVector3(rawPoint)
        let projectedPoint = sceneView.projectPoint(point)
        let res = serializeVector(projectedPoint)
        result(res)
    }
    
    func onCameraProjectionMatrix(_ result:FlutterResult) {
        if let frame = sceneView.session.currentFrame {
            let matrix = serializeMatrix(frame.camera.projectionMatrix)
            result(matrix)
        } else {
            result(nil)
        }
    }
    
    func onPlayAnimation(_ arguments: Dictionary<String, Any>) {
        guard let key = arguments["key"] as? String,
            let sceneName = arguments["sceneName"] as? String,
            let animationIdentifier = arguments["animationIdentifier"] as? String else {
                logPluginError("deserialization failed", toChannel: channel)
                return
        }
        
        if let sceneUrl = Bundle.main.url(forResource: sceneName, withExtension: "dae"),
            let sceneSource = SCNSceneSource(url: sceneUrl, options: nil),
            let animation = sceneSource.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            animation.repeatCount = 1
            animation.fadeInDuration = 1
            animation.fadeOutDuration = 0.5
            sceneView.scene.rootNode.addAnimation(animation, forKey: key)
        } else {
            logPluginError("animation failed", toChannel: channel)
        }
    }
    
    func onStopAnimation(_ arguments: Dictionary<String, Any>) {
        guard let key = arguments["key"] as? String else {
            logPluginError("deserialization failed", toChannel: channel)
            return
        }
        sceneView.scene.rootNode.removeAnimation(forKey: key)
    }
    

    func onCreateDirectionLabels(_ arguments: Dictionary<String, Any>) {
        drawDirectionLabels(node: sceneView.scene.rootNode);
    }

    func createTextNode(string: String) -> SCNNode {
        let skScene = SKScene(size: CGSize(width: 200, height: 200))
        skScene.backgroundColor = UIColor.clear

        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 200, height: 200), cornerRadius: 100)
        rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 5
        rectangle.alpha = 1
        let labelNode = SKLabelNode(text: string)
        labelNode.fontSize = 60
        labelNode.position = CGPoint(x:100,y:80)
        skScene.addChild(rectangle)
        skScene.addChild(labelNode)

        let plane = SCNPlane(width: 10, height: 10)
        plane.firstMaterial?.diffuse.contents = skScene
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        plane.cornerRadius = 5

//        let text = SCNText(string: string, extrusionDepth: 0)
//        text.font = UIFont.systemFont(ofSize: 1.0)
//        text.flatness = 0.01
//        text.firstMaterial?.diffuse.contents = UIColor.red
//        text.firstMaterial?.lightingModel = .constant

        let textNode = SCNNode(geometry: plane)

//        let fontSize = Float(20)
//        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
//        let (min, max) = textNode.boundingBox
//        textNode.pivot = SCNMatrix4MakeTranslation(min.x + 0.5 * (max.x - min.x), min.y + 0.5 * (max.y - min.y), min.z + 0.5 * (max.z - min.z))

        return textNode
    }

    func drawDirectionLabels(node: SCNNode) {
        let distance = 100;
        let north = createTextNode(string: "N");
        north.position = SCNVector3(0, 0, -distance)
        node.addChildNode(north)

        let northEast = createTextNode(string: "NE");
        northEast.eulerAngles = SCNVector3(0, -45.toRadians(), 0)
        northEast.position = SCNVector3(distance, 0, -distance)
        node.addChildNode(northEast)

        let east = createTextNode(string: "E");
        east.eulerAngles = SCNVector3(0, -90.toRadians(), 0)
        east.position = SCNVector3(distance, 0, 0)
        node.addChildNode(east)

        let southEast = createTextNode(string: "SE");
        southEast.eulerAngles = SCNVector3(0, -127.toRadians(), 0)
        southEast.position = SCNVector3(distance, 0, distance)
        node.addChildNode(southEast)

        let south = createTextNode(string: "S");
        south.eulerAngles = SCNVector3(0, -180.toRadians(), 0)
        south.position = SCNVector3(0, 0, distance)
        node.addChildNode(south)

        let southWest = createTextNode(string: "SW");
        southWest.eulerAngles = SCNVector3(0, -225.toRadians(), 0)
        southWest.position = SCNVector3(-distance, 0, distance)
        node.addChildNode(southWest)

        let west = createTextNode(string: "W");
        west.eulerAngles = SCNVector3(0, -270.toRadians(), 0)
        west.position = SCNVector3(-distance, 0, 0)
        node.addChildNode(west)

        let northWest = createTextNode(string: "NW");
        northWest.eulerAngles = SCNVector3(0, -325.toRadians(), 0)
        northWest.position = SCNVector3(-distance, 0, -distance)
        node.addChildNode(northWest)
  }
}

extension Int {
    func toRadians() -> CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0;
    }

    func toRadiansAsFloat() -> Float {
        return Float(CGFloat(self) * CGFloat.pi / 180.0);
    }
}

extension Float {
    func toRadians() -> CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0;
    }
}

extension Double {
    func toRadians() -> CGFloat {
        return CGFloat(self) * CGFloat.pi / 180.0;
    }
}



