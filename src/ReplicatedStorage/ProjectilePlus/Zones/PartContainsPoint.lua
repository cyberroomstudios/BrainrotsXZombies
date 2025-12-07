type UseAxisType = { X: boolean, Y: boolean, Z: boolean }

local PartTypeContainsPoint = {}

PartTypeContainsPoint[Enum.PartType.Ball] = function(cframe: CFrame, size: Vector3, p: Vector3, UseAxis: UseAxisType)
	local dp = p - cframe.Position
	local dx, dy, dz = dp.X, dp.Y, dp.Z
	local minSize = math.min(math.min(size.X, size.Y), size.Z) * 0.5

	local contributions = 0

	if UseAxis.X then
		contributions += dx * dx
	end
	if UseAxis.Y then
		contributions += dy * dy
	end
	if UseAxis.Z then
		contributions += dz * dz
	end

	return contributions <= minSize * minSize
end

PartTypeContainsPoint[Enum.PartType.Cylinder] = function(
	cframe: CFrame,
	size: Vector3,
	p: Vector3,
	UseAxis: UseAxisType
)
	local localPoint = cframe:PointToObjectSpace(p):Abs()

	if UseAxis.X and localPoint.X > size.X * 0.5 then
		return false
	end

	local dy, dz = localPoint.Y, localPoint.Z
	local minSize = math.min(size.Y, size.Z) * 0.5

	local contributions = 0

	if UseAxis.Y then
		contributions += dy * dy
	end
	if UseAxis.Z then
		contributions += dz * dz
	end

	return contributions <= minSize * minSize
end

PartTypeContainsPoint[Enum.PartType.Block] = function(cframe: CFrame, size: Vector3, p: Vector3, UseAxis: UseAxisType)
	local localPoint = cframe:PointToObjectSpace(p):Abs()

	if UseAxis.X and localPoint.X > size.X * 0.5 then
		return false
	end
	if UseAxis.Y and localPoint.Y > size.Y * 0.5 then
		return false
	end
	if UseAxis.Z and localPoint.Z > size.Z * 0.5 then
		return false
	end

	return true
end

PartTypeContainsPoint[Enum.PartType.Wedge] = function(cframe: CFrame, size: Vector3, p: Vector3, UseAxis: UseAxisType)
	local localPoint = cframe:PointToObjectSpace(p)
	local absPoint = localPoint:Abs()
	local wsy, wsz = size.Y, size.Z
	local uay, uaz = UseAxis.Y, UseAxis.Z

	if UseAxis.X and absPoint.X > size.X * 0.5 then
		return false
	end
	if uay and absPoint.Y > wsy * 0.5 then
		return false
	end
	if uaz and absPoint.Z > wsz * 0.5 then
		return false
	end
	if uay and uaz and localPoint.Y * wsz > localPoint.Z * wsy then
		return false
	end

	return true
end

PartTypeContainsPoint[Enum.PartType.CornerWedge] = function(
	cframe: CFrame,
	size: Vector3,
	p: Vector3,
	UseAxis: UseAxisType
)
	local localPoint = cframe:PointToObjectSpace(p)
	local absPoint = localPoint:Abs()
	local wsx, wsy, wsz = size.X, size.Y, size.Z
	local uax, uay, uaz = UseAxis.X, UseAxis.Y, UseAxis.Z

	if uax and absPoint.X > wsx * 0.5 then
		return false
	end
	if uay and absPoint.Y > wsy * 0.5 then
		return false
	end
	if uaz and absPoint.Z > wsz * 0.5 then
		return false
	end
	if uay and uaz and localPoint.Y * wsz > localPoint.Z * -wsy then
		return false
	end
	if uax and uay and localPoint.Y * wsx > localPoint.X * wsy then
		return false
	end

	return true
end

local function PartContainsPoint(
	shape: Enum.PartType,
	cframe: CFrame,
	size: Vector3,
	p: Vector3,
	boundingAxis: ("X" | "Y" | "Z")?
)
	assert(
		not boundingAxis or boundingAxis == "X" or boundingAxis == "Y" or boundingAxis == "Z",
		"If you select a bounding axis, it must be either X, Y, or Z"
	)

	local useAxis = { X = true, Y = true, Z = true }
	if boundingAxis then
		useAxis[boundingAxis] = nil
	end

	return PartTypeContainsPoint[shape](cframe, size, p, useAxis)
end

return PartContainsPoint
