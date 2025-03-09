class PingminOnion extends StaticMeshActor;

var StaticMeshComponent mOnionBodyMesh;
var StaticMeshComponent mOnionLegMesh1;
var StaticMeshComponent mOnionLegMesh2;
var StaticMeshComponent mOnionLegMesh3;

var float mCollectRadius;
var float mTimeElapsed;
var float mCollectTimer;

var PingminColor mColor;
var Material mBlueMaterial;
var Material mYellowMaterial;
var Material mRedMaterial;

event PostBeginPlay()
{
	Super.PostBeginPlay();

	SetPhysics(PHYS_None);
}

function InitOnion(PingminColor pico)
{
	mColor=pico;

	if(mColor == PC_Blue)
	{
		mOnionBodyMesh.SetMaterial(0, mBlueMaterial);
	}
	else if(mColor == PC_Yellow)
	{
		mOnionBodyMesh.SetMaterial(0, mYellowMaterial);
	}
	else if(mColor == PC_Red)
	{
		mOnionBodyMesh.SetMaterial(0, mRedMaterial);
	}
}

simulated event Tick( float deltaTime )
{
	super.Tick( deltaTime );

	mTimeElapsed=mTimeElapsed+deltaTime;
	if(mTimeElapsed >= mCollectTimer)
	{
		mTimeElapsed=0.f;
		CollectItems();
		RecyclePingmins();
	}
}

function CollectItems()
{
 	local GGKActor kact;

	 foreach AllActors(class'GGKActor', kact)
	 {
	 	//if kactor in range
	 	if(VSize2D(Location - kact.Location) <= mCollectRadius)
	 	{
			//if kactor grabbed by goat
			if(IsKactorGrabbedByGoat(kact))
				ConvertKActorIntoPingmins(kact);

			//if kactor grabbed Pingmins
			if(IsKactorGrabbedByPingmins(kact))
				ConvertKActorIntoPingmins(kact);
	 	}
	 }
}

function bool IsKactorGrabbedByGoat(GGKActor kact)
{
	return IsItemGrabbed(kact);
}

function bool IsKactorGrabbedByPingmins(GGKActor kact)
{
	local PingminCounter pc;

	foreach AllActors( class'PingminCounter', pc )
	{
		if(pc.mKActor == kact)
		{
			return true;
		}
	}

	return false;
}

function ConvertKActorIntoPingmins(GGKActor kact)
{
	local int pingminsCount, i;
	local GGNpcPingmin newPingmin;
	local float dist;
	local vector center, dest;
	local rotator rot;

	pingminsCount=class'PingminOnion'.static.GetPingminsValue(kact);

	dist=mCollectRadius + 20.f;//Add Pingmin radius

	center=Location;
	center.Z+=900.f;
	//Spawn new Pingmins
	for(i=0 ; i<pingminsCount ; i++)
	{
		rot=rotator(vect(1, 0, 0));
		rot.Yaw+=RandRange(0.f, 65536.f);

		dest=center+Normal(vector(rot))*dist;

		newPingmin = Spawn(class'GGNpcPingmin',,, dest, rot);
		newPingmin.mColor=mColor;
		newPingmin.InitPingmin();
		newPingmin.SetPhysics(PHYS_Falling);
	}

	//Destroy kactor
	kact.ShutDown();
	kact.Destroy();
}

function RecyclePingmins()
{
	local GGNpcPingmin pingmin;

	 foreach AllActors(class'GGNpcPingmin', pingmin)
	 {
	 	//if kactor in range
	 	if(VSize2D(Location - pingmin.Location) <= mCollectRadius)
	 	{
			if(ShouldRecycle(pingmin))
			{
				pingmin.Destroy();
			}
	 	}
	 }
}

function bool ShouldRecycle(GGNpcPingmin pingmin)
{
	return IsItemGrabbed(pingmin);
}

function bool IsItemGrabbed(Actor act)
{
	local GGPlayerControllerGame pc;

	foreach WorldInfo.AllControllers( class'GGPlayerControllerGame', pc )
	{
		if( pc.IsLocalPlayerController() && GGGoat(pc.Pawn) != none )
		{
			if(GGGoat(pc.Pawn).mGrabbedItem == act)
				return true;
		}
	}

	return false;
}

static function int GetPingminsValue(GGKActor kact)
{
	local float r, h;

	kact.GetBoundingCylinder(r, h);
	return (sqrt(r*r+h*h)/100.f) + 1;
}

static function vector GetOnionLocation(Actor dummy)
{
	local PingminOnion onion;

	foreach dummy.AllActors(class'PingminOnion', onion)
	{
		if(onion != none)
			return onion.Location;
	}

	return vect(0, 0, 0);
}

DefaultProperties
{
	mCollectTimer=1.f
	mCollectRadius=400.f

	mBlueMaterial=Material'Pingmins.Blue';
	mYellowMaterial=Material'Props_01.Materials.Bicycle_Yellow_Mat';
	mRedMaterial=Material'Props_01.Materials.Bicycle_Red';

	bNoDelete=false
	bStatic=false

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'MMO_ElfForest.Mesh.Lamp_01'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Scale3D=(X=3.f, Y=3.f, Z=1.5f)
		Rotation=(Pitch=0, Yaw=0, Roll=0)
		Translation=(X=0, Y=0, Z=850)
	End Object
	mOnionBodyMesh=StaticMeshComp1
	Components.Add(StaticMeshComp1)

	Begin Object class=StaticMeshComponent Name=StaticMeshComp2
		StaticMesh=StaticMesh'CityProps.mesh.Lights_lamp_D'
		Materials(0)=Material'Playground.Materials.Green'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Scale3D=(X=1.f, Y=1.f, Z=1.f)
		Rotation=(Pitch=0, Yaw=0, Roll=0)
		Translation=(X=0, Y=-400, Z=0)
	End Object
	mOnionLegMesh1=StaticMeshComp2
	Components.Add(StaticMeshComp2)

	Begin Object class=StaticMeshComponent Name=StaticMeshComp3
		StaticMesh=StaticMesh'CityProps.mesh.Lights_lamp_D'
		Materials(0)=Material'Playground.Materials.Green'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Scale3D=(X=1.f, Y=1.f, Z=1.f)
		Rotation=(Pitch=0, Yaw=21845, Roll=0)
		Translation=(X=346, Y=200, Z=0)
	End Object
	mOnionLegMesh2=StaticMeshComp3
	Components.Add(StaticMeshComp3)

	Begin Object class=StaticMeshComponent Name=StaticMeshComp4
		StaticMesh=StaticMesh'CityProps.mesh.Lights_lamp_D'
		Materials(0)=Material'Playground.Materials.Green'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Scale3D=(X=1.f, Y=1.f, Z=1.f)
		Rotation=(Pitch=0, Yaw=-21845, Roll=0)
		Translation=(X=-346, Y=200, Z=0)
	End Object
	mOnionLegMesh3=StaticMeshComp4
	Components.Add(StaticMeshComp4)

	CollisionComponent=StaticMeshComp1
	bCollideActors=true
	bBlockActors=true
}