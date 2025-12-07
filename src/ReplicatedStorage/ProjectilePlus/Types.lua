local Types = {}
local Signal = require(script.Parent:WaitForChild("Signal"))
type Signal<T> = Signal.Signal<T>

export type CatchCallback = (Projectile: Projectile) -> ()

export type Catcher = {
	Destroy: (self: Catcher) -> (),
	WeldTo: (self: Catcher, WeldTo: BasePart, Offset: CFrame) -> (),
	UnWeld: (self: Catcher) -> (),
	OnCaught: CatchCallback?,
	Caught: Signal<Projectile>,
	Destroyed: Signal<nil>,
	FireCaught: (self: Catcher, Projectile: Projectile) -> (),
	Debounce: number,
	CaughtList: { Projectile },
	Position: Vector3,
	CFrame: CFrame,
	Size: Vector3,
	Shape: Enum.PartType,
}

export type OnHitSomeoneCallback = (Hit: Model) -> ()
export type OnHitMapCallback = (Hit: BasePart) -> ()

export type Projectile = {
	Destroy: (self: Projectile) -> (),
	Homing: (self: Projectile, Target: BasePart | Vector3, Strength: number?) -> (),
	StopHoming: (self: Projectile) -> (),
	Owner: Model,
	Speed: number,
	TimeScale: number,
	Radius: number,
	ReflectEnabled: boolean,
	Velocity: Vector3,
	Position: Vector3,
	CFrame: CFrame,
	Key: string,
	Lifetime: number,
	LastTime: number,
	StartTime: number,
	Debounce: number,
	HitList: { string },
	DestroyOnHit: boolean,
	DestroyOnMapHit: boolean,
	CheckForPeople: boolean,
	CheckForMap: boolean,
	UseRaycastingForPeople: boolean,
	UseRaycastingForMap: boolean,
	raycastParams: RaycastParams,
	OParams: OverlapParams,
	OnHitSomeone: OnHitSomeoneCallback?,
	OnHitMap: OnHitMapCallback?,
	ID: string,
	HomingTarget: BasePart?,
	HomingTargetPosition: Vector3?,
	HomingStrength: number,
	GravityEnabled: boolean,
	GravityForce: number?,
	HitSomeone: Signal<Model>,
	Destroying: Signal<Model>,
	HitMap: Signal<BasePart>,
	FireHitSomeone: (self: Projectile, Hit: Model, HitPosition: Vector3) -> (),
	FireHitMap: (self: Projectile, Hit: BasePart, HitPosition: Vector3) -> (),
}

return Types
