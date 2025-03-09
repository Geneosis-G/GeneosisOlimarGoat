class OlimarGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var StaticMeshComponent mHelmetMesh;
var Material mSuitMaterial;
var SkeletalMesh mGoatMesh;

var bool mIsRightClicking;
var CallRing mCallRing;
var GGCrosshairActor mCrosshairActor;

// Max distance between the goat and the control ring center
var float mControlRange;

// Control ring radius
var float mControlRadius;

// Vertical offset to place the pingmin before throwing
var float mThrowOffsetZ;
var float mThrowForce;
var SoundCue mThrowSound;
var SoundCue mWhistleSound;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		// Add space helmet
		if(!IsZero(gMe.mesh.GetBoneLocation('Head')))
		{
			gMe.mesh.AttachComponent(mHelmetMesh, 'Head', vect(0, 0, 0), rot( 0, 0, 0 ));
		}
		else
		{
			gMe.AttachComponent(mHelmetMesh);
		}
		mHelmetMesh.SetLightEnvironment( gMe.mesh.lightenvironment );

		// Add space suit
		if(gMe.Mesh.SkeletalMesh == mGoatMesh)
		{
    		gMe.mesh.SetMaterial(0, mSuitMaterial);
    	}
	}
}

function DetachFromPlayer()
{
	mCrosshairActor.DestroyCrosshair();
	mCallRing.Destroy();
	super.DetachFromPlayer();
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey ))|| newKey == 'XboxTypeS_LeftTrigger')
		{
			mIsRightClicking = true;
		}

		if(mIsRightClicking)
		{
			if(newKey == 'TWO' || newKey == 'XboxTypeS_DPad_Up')
			{
				MakeOnion(PC_Red);
			}

			if(newKey == 'THREE' || newKey == 'XboxTypeS_DPad_Left')
			{
				MakeOnion(PC_Yellow);
			}

			if(newKey == 'FOUR' || newKey == 'XboxTypeS_DPad_Down')
			{
				MakeOnion(PC_Blue);
			}

			if(localInput.IsKeyIsPressed("GBA_Baa", string( newKey )))
			{
				CallPingmins();
			}

			if(localInput.IsKeyIsPressed("GBA_Special", string( newKey )))
			{
				ThrowPingmin();
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("RightMouseButton", string( newKey ))|| newKey == 'XboxTypeS_LeftTrigger')
		{
			mIsRightClicking = false;
		}
	}
}

function MakeOnion(PingminColor pico)
{
	local vector pos;

	if(gMe.mIsRagdoll || gMe.Velocity != vect(0, 0, 0) || gMe.mIsInAir)
		return;

	pos=gMe.Location;
	pos.Z -= gMe.GetCollisionHeight();
	OlimarGoat(myMut).MakeOnion(pos, pico);
}

function CallPingmins()
{
	local GGNpcPingmin pingmin;
	local GGAIControllerPingmin pingminController;

	gMe.PlaySound(mWhistleSound);

	foreach gMe.AllActors(class'GGNpcPingmin', pingmin)
	{
		//if correct controller and in range
		pingminController=GGAIControllerPingmin(pingmin.Controller);
		if(pingminController != none)
		{
			if(VSize2D(mCallRing.Location - pingminController.GetPosition(pingmin)) < mControlRadius)
			{
				//Make Pingmins follow goat
				pingminController.FollowNewOlimar(gMe);
			}
		}
	}
}

function ThrowPingmin()
{
	local GGNpcPingmin pingmin;
	local Actor target;
	local vector dir;
	local float multiplier;

	if(gMe.mIsRagdoll)
		return;

	pingmin=GetClosestPingminFollower();
	if(pingmin == none)
		return;

	target=FindTarget();
	//Throw pingmin
 	pingmin.SetRagdoll(true);
 	SetPawnPosition(pingmin, GetThrowLocation());
 	dir=Normal(mCrosshairActor.Location-GetThrowLocation());
 	multiplier=pingmin.mColor==PC_Yellow?2.f:1.f;
	pingmin.mesh.SetRBLinearVelocity(dir*mThrowForce*multiplier);

	gMe.PlaySound(mThrowSound);

	//Notify controller
	GGAIControllerPingmin(pingmin.Controller).ThrowPingmin(target);
}

function GGNpcPingmin GetClosestPingminFollower()
{
	local GGNpcPingmin pingmin, closestPingmin;
	local GGAIControllerPingmin pingminController;
	local float minDist, dist;

	minDist=-1;
	foreach gMe.AllActors(class'GGNpcPingmin', pingmin)
	{
		pingminController=GGAIControllerPingmin(pingmin.Controller);
		if(pingminController != none && pingminController.olimar == gMe)
		{
			dist=VSize2D(gMe.Location - pingminController.GetPosition(pingmin));
			if(minDist == -1 || dist<minDist)
			{
				minDist=dist;
				closestPingmin=pingmin;
			}
		}
	}

	return closestPingmin;
}

function Actor FindTarget()
{
	local vector traceStart, traceEnd, hitLocation, hitNormal;
	local Actor hitActor;

	traceStart = mCrosshairActor.Location;
	traceEnd = traceStart;
	traceEnd += -normal(vector(mCrosshairActor.Rotation)) *  mControlRadius;

	foreach gMe.TraceActors( class'Actor', hitActor, hitLocation, hitNormal, traceEnd, traceStart )
	{
		if(hitActor == mCallRing || hitActor == gMe || hitActor.Base == gMe || hitActor.Owner == gMe)
		{
			continue;
		}

		break;
	}

	return hitActor;
}

function SetPawnPosition(GGPawn gpawn, vector pos)
{
	local EPhysics oldPhysics;
	local bool oldCollideAct, oldBlockAct, oldMeshCollideAct, oldMeshBlockAct, oldMeshBlockRigid;

	oldPhysics=gpawn.Physics;
	gpawn.SetPhysics(PHYS_None);
	oldCollideAct=gpawn.bCollideActors;
	oldBlockAct=gpawn.bBlockActors;
	oldMeshCollideAct=gpawn.mesh.CollideActors;
	oldMeshBlockAct=gpawn.mesh.BlockActors;
	oldMeshBlockRigid=gpawn.mesh.BlockRigidBody;
	gpawn.SetCollision(false, false);
	gpawn.mesh.SetActorCollision(false, false);
	gpawn.mesh.SetBlockRigidBody(false);

	gpawn.mesh.SetRBPosition(pos);
	gpawn.SetLocation(pos);

	gpawn.SetPhysics(oldPhysics);
	gpawn.SetCollision(oldCollideAct, oldBlockAct);
	gpawn.mesh.SetActorCollision(oldMeshCollideAct, oldMeshBlockAct);
	gpawn.mesh.SetBlockRigidBody(oldMeshBlockRigid);
}

function vector GetThrowLocation()
{
	return gMe.Location + (vect(0, 0, 1) * (gMe.GetCollisionHeight() + mThrowOffsetZ));
}

event TickMutatorComponent( float deltaTime )
{
	super.TickMutatorComponent(deltaTime);

	if(mCrosshairActor == none || mCrosshairActor.bPendingDelete)
	{
		mCrosshairActor = gMe.Spawn(class'GGCrosshairActor');
		mCrosshairActor.SetColor(MakeLinearColor( 215.f/255.f, 215.f/255.f, 215.f/255.f, 1.0f ));
	}

	if(mCallRing == none || mCallRing.bPendingDelete)
	{
		mCallRing=gMe.Spawn(class'CallRing');
	}

	CalcRingLocation();
	mCrosshairActor.SetHidden(!mIsRightClicking);
	mCallRing.SetHidden(!mIsRightClicking);
}

function CalcRingLocation()
{
	local vector dest;
	local vector offset, camLocation;
	local rotator camRotation;
	local vector traceStart, traceEnd, hitLocation, hitNormal;
	local Actor hitActor;

	if(gMe.Controller != none)
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	}
	else
	{
		camLocation=gMe.Location;
		camRotation=gMe.Rotation;
	}
	traceStart = camLocation;
	traceEnd = traceStart;
	traceEnd += (vect(1, 0, 0)*(mControlRange + VSize2D(camLocation-gMe.Location))) >> (camRotation + (rot(1, 0, 0)*10*DegToUnrRot));

	foreach gMe.TraceActors( class'Actor', hitActor, hitLocation, hitNormal, traceEnd, traceStart )
	{
		if(hitActor == mCallRing || hitActor == gMe || hitActor.Base == gMe || hitActor.Owner == gMe || hitActor.bHidden)
		{
			continue;
		}

		break;
	}

	if(hitActor == none)
	{
		hitLocation=traceEnd;
	}

	mCrosshairActor.UpdateCrosshair(hitLocation, -vector(camRotation));

	offset=hitNormal;
	offset.Z=0;
	dest = hitLocation + Normal(offset);//*(mControlRadius + 1.f);

	if(hitActor == none || hitNormal.Z < 0.5f)
	{
		traceStart = dest;
		traceEnd = dest;
		traceEnd += vect(0, 0, 1)*-100000.f;

		hitActor = gMe.Trace( hitLocation, hitNormal, traceEnd, traceStart);
		if(hitActor != none)
		{
			dest=hitLocation;
		}
	}

	mCallRing.SetLocation(dest);
}

defaultproperties
{
	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Space_Museum_Exterior.Meshes.Sphere'
		Materials[0]=Material'House_01.Materials.Window_Mat_01'
		Scale3D=(X=0.2f, Y=0.2f, Z=0.2f)
		Translation=(X=10, Y=0, Z=-20)
	End Object
	mHelmetMesh=StaticMeshComp1

	mGoatMesh=SkeletalMesh'goat.mesh.goat'
	mSuitMaterial=Material'Space_GoatSpaceSuit.Materials.Goat_SpaceSuit_Mat_01'

	mControlRange=2000.f
	mControlRadius=350.f
	mThrowOffsetZ=40.f
	mThrowForce=1500.f

	mThrowSound=SoundCue'Pingmins.throwSound'
	mWhistleSound=SoundCue'Pingmins.whistleSound'
}