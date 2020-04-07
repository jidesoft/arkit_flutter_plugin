import ARKit

func deserializeVector3(_ coords: Array<Double>) -> SCNVector3 {
    let point = SCNVector3(coords[0], coords[1], coords[2])
    return point
}

func deserializeVector4(_ coords: Array<Double>) -> SCNVector4 {
    let point = SCNVector4(coords[0], coords[1], coords[2], coords[3])
    return point
}

func deserializeMatrix(_ coords: Array<Double>) -> SCNMatrix4 {
    let point = SCNMatrix4.init(m11: Float(coords[0]), m12: Float(coords[1]), m13: Float(coords[2]), m14: Float(coords[3]),
        m21: Float(coords[4]), m22: Float(coords[5]), m23: Float(coords[6]), m24: Float(coords[7]),
        m31: Float(coords[8]), m32: Float(coords[9]), m33: Float(coords[10]), m34: Float(coords[11]),
        m41: Float(coords[12]), m42: Float(coords[13]), m43: Float(coords[14]), m44: Float(coords[15]))
    return point
}
