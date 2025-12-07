-- ____            _           _   _ _
--|  _ \ _ __ ___ (_) ___  ___| |_(_) | ___     _
--| |_) | '__/ _ \| |/ _ \/ __| __| | |/ _ \  _| |_
--|  __/| | | (_) | |  __/ (__| |_| | |  __/ |_   _|
--|_|   |_|  \___// |\___|\___|\__|_|_|\___|   |_|
--              |__/
--Version 1 Documentation
--Projectile Plus developed by Bartokens. Zone module by azavier123

--Projectile Plus is an all-in one projectile system that handles client-server interactions and uses it's own physics calculations.
--Projectiles are not parts, but rather tables that are constantly updated on the server.
--You can create your own parts on the client for visuals, and handle all events on the client such as projectile hit.
--You can also differentiate between hitting players and hitting the map.
--Includes Homing, Gravity, and Bouncing features.

--Setup Guide:
--1. Place the ProjectilePlus module in ReplicatedStorage.
--2. In any server script, require the module (the parent of this script) to activate it.
--3. In any local script, require the Client module to activate the client.
--4. You can now use any of the Server or Client methods without error.

--Server Methods:

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectilePlus.CreateProjectile(

--		Owner : Model, --The owner of the projectile. You would set this to the character of the player.

--		Key : string, --A unique identifier to give the projectile which can be referenced on the client.

--		Radius : number, --The radius of the Projectile.

--		Velocity : Vector3, --The direction the projectile will move towards.

--		StartPosition : Vector3,  --The position the projectile starts at.

--		Lifetime : number, --How long the projectile will last in seconds before being destroyed.

--		Speed : number, --The speed of the projectile

--		raycastParams : RaycastParams --Optional RaycastParams

--)
--Creates a projectile on the server

--Projectile Properties:

--Owner --The owner of the projectile. Ignored on hit detection.

--Speed --How fast the projectile moves.

--TimeScale --1 by default. Can be used to speed up or slow down the projectile.

--Radius --The radius of the projectile

--ReflectEnabled --Determines whether or not the projectile bounces when hitting map surfaces.

--Velocity --The direction the projectile moves in

--Position --The position of the projectile. Updates every frame.

--CFrame --Read only property. The CFrame of the projectile. Updates every frame.

--Key --The unique ID of the projectile

--Lifetime --How long the projectile will exist in seconds.

--LastTime --The last time the projectile was updated on the server.

--StartTime --The time the projectile was created.

--Debounce --The debounce time of the projectile. Used to prevent hit events from firing multiple times.

--HitList --A table of all hit players by the projectile. Resets for each individual player on debounce.

--DestroyOnHit --Determines whether or not the projectile is destroyed when hitting a player.

--DestroyOnMapHit --Determines whether or not the projectile is destroyed when hitting the map.

--CheckForPeople --Determines whether or not the projectile actively checks for players. Turn this off if you don't need player detection

--CheckForMap --Determines whether or not the projectile actively checks for the map. Turn this off if you don't need map detection

--UseRaycastingForPeople --When true the projectile will use raycasting instead of spherecasting for player detection. Ideal for smaller projectiles.

--UseRaycastingForMap --When true the projectile will use raycasting instead of spherecasting for map detection. Ideal for larger projectiles.

--raycastParams --The raycastParams used for hit detection.

--OParams --The OParams used for spatial queries.

--OnHitSomeone --A function that is fired when the projectile hits a player.

--OnHitMap --A function that is fired when the projectile hits the map.

--ID --The unique ID of the projectile created by HTTPService:GenerateGUID()

--HomingTarget --The current homing target of the projectile. Only works when projectile:Homing() is called.

--HomingTargetPosition --The current homing target position. Only works when projectile:Homing() is called.

--HomingStrength --How aggresively the projectile will follow the homing target.

--GravityEnabled --Toggles gravity for the projectile.

--GravityForce --The strength of gravity for the projectile. 1 by default.

--Projectile Methods:

--projectile:Destroy() --Destroys the projectile.

--projectile:Homing(Target, Strength) --Makes the projectile begin homing on a specified target part.

--projectile:StopHoming() --Makes the projectile stop homing.

--Projectile Events:

--projectile.Destroying() --Fired when the projectile is destroyed.

--projectile.HitSomeone(Hit,HitPosition) --Fired when the projectile hits a player.

--projectile.HitMap(Hit,HitPosition) --Fired when the projectile hits the map.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectilePlus.CreateCatcher(

--Size: Vector3, --The size of the Catcher

--Cframe: CFrame, --The CFrame of the Catcher

--Shape: Enum.PartType --The Shape of the Catcher.

--)
--Creates a projectile catcher which detects when projectiles collide with it.

--Catcher Properties:

--OnCaught --An optional function which is fired on projectile caught.

--Debounce --How many seconds before the Catcher can catch the same projectile again.

--CaughtList --The list of projectiles caught by the Catcher. Individual projectiles removed on debounce.

--Position --The position of the Catcher.

--CFrame --The CFrame of the Catcher.

--Size --The size of the Catcher.

--Shape --The shape of the Catcher.

--Catcher Methods:

--catcher:Destroy() --Destroys the Catcher.

--catcher:WeldTo(WeldTarget, Offset) --Welds the Catcher to a part with an optional CFrame offset. The part can also be any table with a CFrame property, meaning Catchers can be welded to projectiles.

--catcher:UnWeld() --Unwelds the Catcher.

--Catcher Events:

--catcher.Caught(Projectile) --Fired when a projectile is caught.

--catcher.Destroyed() --Fired when the Catcher is destroyed.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectilePlus:HitScan(

--Origin: Vector3,  --The origin point of the Hitscan raycast.

--EndPoint: Vector3, --The end point of the Hitscan raycast.

--MaxRange: number, --The max range of the Hitscan raycast.

--raycastParams: RaycastParams --Optional rayCastParams.

--)
--A built in HitScan function. It is really just a simple raycast, but it can be intercepted by Projectile Catchers.
--Returns a model, a table, or a part depending on if it hit a player, a catcher, or the map respectively.
--Currently does not work with wedge or cylinder catchers.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectilePlus:Initialize()

--Activates the server side of the module. This must be called before any other functions, though it is automatically called on first require.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectilePlus:GetProjectiles()

--Returns all existing projectiles.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectileSystem:ClearProjectiles()

--Destroys all existing projectiles.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--ProjectileSystem:PlayerCleanup(Player:Player)

--Destroys all existing projectiles belonging to a specific player. Automatically called on player leaving if AutoPlayerCleanup is set to true.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Client Events:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Client.ProjectileAdded(Projectile)
--An event that fires when projectiles are created on the server and then passed to the client.

--Client.ProjectileDestroying(Projectile)
--An event that fires when projectiles are destroyed on the server and the client.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Special Client Projectile Methods:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Projectile:WeldPart(part: BasePart, offset: CFrame?)
--Welds a BasePart to the projectile by updating it's CFrame every frame with an optional offset.

--Projectile:ClearWelds()
--Clears all active welds
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
