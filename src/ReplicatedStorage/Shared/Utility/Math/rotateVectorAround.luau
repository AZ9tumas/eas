return function (vector: Vector3, amount: number, axis: Vector3)
    return CFrame.fromAxisAngle(axis, amount):VectorToWorldSpace(vector)
end