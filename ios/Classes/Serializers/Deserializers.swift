import ARKit

func deserializeVector3(_ coords: Array<Double>) -> SCNVector3 {
    let point = SCNVector3(coords[0], coords[1], coords[2])
    return point
}

func deserializeVector4(_ coords: Array<Double>) -> SCNVector4 {
    let point = SCNVector4(coords[0], coords[1], coords[2], coords[3])
    return point
}
