class GGAIControllerPingmin extends GGAIControllerPassiveGoat;

var float mDestinationOffset;

var kActorSpawnable destActor;
var bool cancelNextRagdoll;
var float totalTime;
var bool isArrived;
var bool isPossessing;

var GGGoat olimar;
var bool agressive;
var GGNpc mTargetNpc;
var bool transport;
var GGKActor mTargetKActor;
var float mySpeed;
var float pushForce;
//var vector pushVector;

event PostBeginPlay()
{
	super.PostBeginPlay();
}

/**
 * Cache the NPC and mOriginalPosition
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local ProtectInfo destination;

	super.Possess(inPawn, bVehicleTransition);

	isPossessing=true;
	if(mMyPawn == none)
		return;

	mMyPawn.mProtectItems.Length=0;
	if(destActor == none)
	{
		destActor = Spawn(class'kActorSpawnable', mMyPawn,,,,,true);
		destActor.SetHidden(true);
		destActor.SetPhysics(PHYS_None);
		destActor.CollisionComponent=none;
	}
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " destActor=" $ destActor);
	destActor.SetLocation(mMyPawn.Location);
	destination.ProtectItem = mMyPawn;
	destination.ProtectRadius = 1000000.f;
	mMyPawn.mProtectItems.AddItem(destination);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mMyPawn.mProtectItems[0].ProtectItem=" $ mMyPawn.mProtectItems[0].ProtectItem);
	StandUp();
}

event UnPossess()
{
	destActor.ShutDown();
	destActor.Destroy();

	isPossessing=false;
	super.UnPossess();
	mMyPawn=none;
}

//Kill AI if pingmin is destroyed
function bool KillAIIfPawnDead()
{
	if(mMyPawn == none || mMyPawn.bPendingDelete || mMyPawn.Controller != self)
	{
		UnPossess();
		Destroy();
		return true;
	}

	return false;
}

event Tick( float deltaTime )
{
	local float speed, max_speed;

	//Kill destroyed pingmins
	if(isPossessing)
	{
		if(KillAIIfPawnDead())
		{
			return;
		}
	}

	// Optimisation
	if( mMyPawn.IsInState( 'UnrenderedState' ) )
	{
		return;
	}

	Super.Tick( deltaTime );

	// Stop attack if pawn destroyed or invalid for attack
	if(agressive &&
	(mTargetNpc == none || mTargetNpc.bPendingDelete || !CanAttack(mTargetNpc)))
	{
		agressive=false;
	}

	// Stop transport if kactor destroyed
	if(transport &&
	(mTargetKActor == none || mTargetKActor.bPendingDelete || mTargetKActor.bHidden))
	{
		transport=false;
	}

	// Fix dead attacked pawns
	if( mPawnToAttack != none )
	{
		if( mPawnToAttack.bPendingDelete )
		{
			mPawnToAttack = none;
		}
	}

	//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=" $ isArrived $ ", Vel=" $ mMyPawn.Velocity);
	cancelNextRagdoll=false;

	if(!mMyPawn.mIsRagdoll)
	{
		//Fix NPC with no collisions
		if(mMyPawn.CollisionComponent == none)
		{
			mMyPawn.CollisionComponent = mMyPawn.Mesh;
		}

		//Fix NPC rotation
		UnlockDesiredRotation();
		if(mPawnToAttack != none)
		{
			Pawn.SetDesiredRotation( rotator( Normal2D( mPawnToAttack.Location - Pawn.Location ) ) );
			mMyPawn.LockDesiredRotation( true );

			//Fix pawn stuck after attack
			if(!IsValidEnemy(mPawnToAttack) || !PawnInRange(mPawnToAttack))
			{
				EndAttack();
			}
			else if(mCurrentState == '')
			{
				GotoState( 'ChasePawn' );
			}
		}
		else
		{
			//Fix random movement state
			if(mCurrentState == '')
			{
				//WorldInfo.Game.Broadcast(self, mMyPawn $ " no state detected");
				GoToState('FollowOlimar');
			}

			UpdateFollowOlimar();
			//Force speed reduction when close to target
			speed=VSize(mMyPawn.Velocity);
			max_speed=VSize2D(GetPosition(mMyPawn)-destActor.Location)*2.f;
			if(speed > max_speed)
			{
				mMyPawn.Velocity.X*=max_speed/speed;
				mMyPawn.Velocity.Y*=max_speed/speed;
				//mMyPawn.Velocity.Z*=max_speed/speed;
			}
			//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mMyPawn.Physics $ ")");
			//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mMyPawn.mCurrentAnimationInfo.AnimationNames[0] $ ")");
			//WorldInfo.Game.Broadcast(self, mMyPawn $ "(" $ mCurrentState $ ")");

		}
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " (2) isArrived=" $ isArrived $ ", Vel=" $ mMyPawn.Velocity);
		if(IsZero(mMyPawn.Velocity))
		{
			if(isArrived && !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo ) && !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mAttackAnimationInfo ))
			{
				mMyPawn.SetAnimationInfoStruct( mMyPawn.mDefaultAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "DefaultAnim");
			}
		}
		else
		{
			if(VSize2D(mMyPawn.Velocity) < olimar.mWalkSpeed)
			{
				if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mRunAnimationInfo ) )
				{
					mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "RunAnim");
				}
			}
			else
			{
				if( !mMyPawn.isCurrentAnimationInfoStruct( mMyPawn.mPanicAnimationInfo ) )
				{
					mMyPawn.SetAnimationInfoStruct( mMyPawn.mPanicAnimationInfo );//WorldInfo.Game.Broadcast(self, mMyPawn $ "RunAnim");
				}
			}
		}
		// if waited too long to before reaching some place or some target, abandon
		totalTime = totalTime + deltaTime;
		if(totalTime > 11.f)
		{
			mMyPawn.SetRagdoll(true);
		}
		// if walking on transport item, ragdoll
		if(transport && mMyPawn.Base == mTargetKActor)
		{
			mMyPawn.SetRagdoll(true);
		}
	}
	else
	{
		//Fix NPC not standing up
		if(!IsTimerActive( NameOf( StandUp ) ))
		{
			StartStandUpTimer();
		}

		//Make drowning goats follow olimar
		if(mMyPawn.mInWater)
		{
			totalTime = totalTime + deltaTime;
			if(totalTime > 1.f)
			{
				totalTime=0.f;
				DoRagdollJump();
			}
		}
	}

	// Fix glitchy sound?
	mMyPawn.SetSoundEnabled(false);
}

function FollowNewOlimar(GGGoat newOlimar)
{
	local float newSpeed, ratio;

	if(olimar != none)//Can't steal pingmins to other olimars
		return;

	olimar=newOlimar;
	agressive=false;
	transport=false;

	ratio=GGNpcPingmin(mMyPawn).mColor==PC_Blue?2.f:1.f;
	newSpeed=olimar.mSprintSpeed * ratio;

	mMyPawn.GroundSpeed = newSpeed;
	mMyPawn.AirSpeed = newSpeed;
	mMyPawn.WaterSpeed = newSpeed;
	mMyPawn.LadderSpeed = newSpeed;
	mMyPawn.mRunAnimationInfo.MovementSpeed=olimar.mWalkSpeed * ratio;
	mMyPawn.mPanicAnimationInfo.MovementSpeed=newSpeed;
	mMyPawn.JumpZ = olimar.JumpZ * ratio;
}

function ThrowPingmin(Actor target)
{
	local GGAIControllerPingmin otherController;

	olimar=none;

	// if aiming at other pingmin, get the same behaviour as this pingmin
	if(GGNpcPingmin(target) != none)
	{
		otherController=GGAIControllerPingmin(GGNpcPingmin(target).Controller);
		if(otherController != none)
		{
			if(otherController.agressive)
			{
				AttackTarget(otherController.mTargetNpc);
			}
			else if(otherController.transport)
			{
				TransportTarget(otherController.mTargetKActor);
			}
		}
	}
	// if aiming at NPC try to attack it
	else if(GGNpc(target) != none)
	{
		AttackTarget(GGNpc(target));
	}
	// if aiming at Kactor try to transport it
	else if(GGKActor(target) != none)
	{
		TransportTarget(GGKActor(target));
	}
}

function AttackTarget(GGNpc npcTarget)
{
	if(CanAttack(npcTarget))
	{
		agressive=true;
		mTargetNpc=npcTarget;
	}
}

function TransportTarget(GGKactor kactTarget)
{
	local PingminCounter counter, kactCounter;

	transport=true;
	mTargetKActor=kactTarget;

	foreach AllActors(class'PingminCounter', counter)
	{
		if(counter.mKActor == mTargetKActor)
		{
			kactCounter=counter;
			break;
		}
	}
	if(kactCounter == none)
	{
		kactCounter = Spawn(class'PingminCounter');
		kactCounter.InitCounter(mTargetKActor);
	}
}

/**
 * Do ragdoll jump, e.g. for jumping out of water.
 */
function DoRagdollJump()
{
	local vector newVelocity, dest;

	if(olimar == none)
	{
		dest=class'PingminOnion'.static.GetOnionLocation(self);
	}
	else
	{
		dest=GetPosition(olimar);
	}

	if(dest == vect(0, 0, 0))
		return;

	newVelocity = Normal2D(dest-GetPosition(mMyPawn));
	newVelocity.Z = 1.f;
	newVelocity = Normal(newVelocity) * olimar.mRagdollJumpZ;

	mMyPawn.mesh.SetRBLinearVelocity( newVelocity );
}

function UpdateFollowOlimar()
{
	local vector dest, voffset;
	local GGNpc hitNpcGoat;
    local vector HitLoc, HitNorm, start, end;
    local TraceHitInfo hitInfo;
	local GGAIControllerPingmin pingminController;
	local GGPawn target, target2;
	local float myRadius, targetRadius, offset;
	local rotator roffset;

	if(mPawnToAttack != none || mMyPawn.mIsRagdoll)
	{
		return;
	}
	// if too close to another pingmin or olimar, avoid it
	if(AvoidPingmins())
	{
		return;
	}

	if(olimar != none)
	{
		target=olimar;
		target2=olimar;
	}
	else if(transport)
	{
		MoveItemToOnion();
		return;
	}
	else
	{
		AimAtDestWithOffset(GetPosition(mMyPawn) + normal(vector(mMyPawn.Rotation)), mMyPawn.GetCollisionRadius());
		return;
	}
	myRadius=mMyPawn.GetCollisionRadius();
	roffset=mMyPawn.Rotation;
	roffset.Yaw+=16384;
	start = GetPosition(mMyPawn) + Normal(vector(roffset))*myRadius;
    end = GetPosition(target) + Normal(vector(roffset))*myRadius;
	end.Z=start.Z;
    foreach TraceActors(class'GGNpc', hitNpcGoat, HitLoc, HitNorm, end, start, ,hitInfo)
    {
        pingminController=GGAIControllerPingmin(hitNpcGoat.Controller);
		if(pingminController != none && pingminController != self)
		{
			target=hitNpcGoat;
			break;
		}
    }
	roffset=mMyPawn.Rotation;
	roffset.Yaw-=16384;
	start = GetPosition(mMyPawn) + Normal(vector(roffset))*myRadius;
    end = GetPosition(target2) + Normal(vector(roffset))*myRadius;
	end.Z=start.Z;
    foreach TraceActors(class'GGNpc', hitNpcGoat, HitLoc, HitNorm, end, start, ,hitInfo)
    {
        pingminController=GGAIControllerPingmin(hitNpcGoat.Controller);
		if(pingminController != none && pingminController != self)
		{
			target2=hitNpcGoat;
			break;
		}
    }

	//WorldInfo.Game.Broadcast(self, mMyPawn $ " start random movement");

	if(VSize(GetPosition(target2)-GetPosition(mMyPawn))<VSize(GetPosition(target)-GetPosition(mMyPawn)))
	{
		target=target2;
	}
	targetRadius=target.GetCollisionRadius();
	dest=GetPosition(target);
	offset=myRadius*2 + targetRadius;
	voffset=Normal2D(GetPosition(mMyPawn)-dest)*offset;
	dest+=voffset;
	dest.Z=GetPosition(mMyPawn).Z;

	AimAtDestWithOffset(dest, offset);
}

function vector GetPosition(GGPawn gpawn)
{
	return gpawn.mIsRagdoll?gpawn.mesh.GetPosition():gpawn.Location;
}

function bool AvoidPingmins()
{
	local GGPawn closestPawn;
	local GGNpcPingmin pingmin;
	local PlayerController PC;
	local GGAIControllerPingmin pingminController;
	local float minDist, dist, range, myRadius;
	local vector dest;
	local TraceHitInfo hitInfo;

	// Find closest pingmin
	myRadius=mMyPawn.GetCollisionRadius();
	range=myRadius * 3.f;
	minDist=-1;
	foreach VisibleCollidingActors( class'GGNpcPingmin', pingmin, range, mMyPawn.Location,,,,, hitInfo )
	{
		pingminController=GGAIControllerPingmin(pingmin.Controller);
		if(pingminController != none && pingminController != self)
		{
			dist=VSize2D(mMyPawn.Location - GetPosition(pingmin));
			if(minDist == -1 || dist<minDist)
			{
				minDist=dist;
				closestPawn=pingmin;
			}
		}
	}
	// Or closest player
	foreach WorldInfo.AllControllers(class'PlayerController', PC)
	{
		if(GGPawn(PC.Pawn) != none)
		{
			dist=VSize2D(mMyPawn.Location - GetPosition(GGPawn(PC.Pawn)));
			if(minDist == -1 || dist<minDist)
			{
				minDist=dist;
				closestPawn=GGPawn(PC.Pawn);
			}
		}
	}
	// if too close, avoid it
	if(minDist != -1 && minDist < (myRadius + closestPawn.GetCollisionRadius() + 5.f))
	{
		dest=mMyPawn.Location;
		dest+=Normal2D(mMyPawn.Location-GetPosition(closestPawn)) * range;
		AimAtDestWithOffset(dest, myRadius);
		return true;
	}

	return false;
}

function MoveItemToOnion()
{
	local float distToItem, myRadius;
	local vector dest;

	distToItem=VSize2D(mMyPawn.Location - mTargetKActor.Location);
	myRadius=mMyPawn.GetCollisionRadius();
	if(distToItem < myRadius * 6.f)
	{
		dest=class'PingminOnion'.static.GetOnionLocation(self);
	}
	else
	{
		dest=mTargetKActor.Location;
	}

	AimAtDestWithOffset(dest, myRadius);
}

function AimAtDestWithOffset(vector dest, float offset)
{
	if(VSize2D(GetPosition(mMyPawn)-dest) < offset)
	{
		dest=GetPosition(mMyPawn);
		if(!isArrived)
		{
			isArrived=true;//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=true");
			mMyPawn.ZeroMovementVariables();
		}
		totalTime=0.f;
	}
	else
	{
		if(isArrived)
		{
			isArrived=false;//WorldInfo.Game.Broadcast(self, mMyPawn $ " (1) isArrived=false");
			totalTime=-10.f;
		}
	}

	//DrawDebugLine (mMyPawn.Location, dest, 0, 0, 0,);

	destActor.SetLocation(dest);
	if(!isArrived)
	{
		Pawn.SetDesiredRotation( rotator( Normal2D( destActor.Location - Pawn.Location ) ) );
	}
	mMyPawn.LockDesiredRotation( true );
}

function StartProtectingItem( ProtectInfo protectInformation, GGPawn threat )
{
	StopAllScheduledMovement();
	totalTime=0.f;
	threat=mTargetNpc;

	mCurrentlyProtecting = protectInformation;

	mPawnToAttack = threat;

	StartLookAt( threat, 5.0f );

	GotoState( 'ChasePawn' );
}

/**
 * Attacks mPawnToAttack using mMyPawn.mAttackMomentum
 * called when our pawn needs to protect and item from a given pawn
 */
function AttackPawn()
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local int damage;

	super.AttackPawn();

	gpawn = GGPawn(mPawnToAttack);
	mmoEnemy = GGNPCMMOEnemy(mPawnToAttack);
	zombieEnemy = GGNpcZombieGameModeAbstract(mPawnToAttack);
	if(gpawn != none)
	{
		damage = int(RandRange(1, 5));
		if(GGNpcPingmin(mMyPawn).mColor == PC_Red)
			damage *= 2;
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			mmoEnemy.TakeDamageFrom(damage, mMyPawn, class'GGDamageTypeExplosiveActor');
		}
		else
		{
			gpawn.TakeDamage( 0.f, self, gpawn.Location, vect(0, 0, 0), class'GGDamageType',, mMyPawn);
		}
		//Damage zombies
		if(zombieEnemy != none)
		{
			zombieEnemy.TakeDamage(damage, self, zombieEnemy.Location, vect(0, 0, 0), class'GGDamageTypeZombieSurvivalMode' );
		}
	}

	//Fix pawn stuck after attack
	if(IsValidEnemy(mPawnToAttack) && PawnInRange(mPawnToAttack))
	{
		GotoState( 'ChasePawn' );
	}
	else
	{
		EndAttack();
	}
}

/**
 * We have to disable the notifications for changing states, since there are so many npcs which all have hundreds of calls.
 */
state MasterState
{
	function BeginState( name prevStateName )
	{
		mCurrentState = GetStateName();
	}
}

state FollowOlimar extends MasterState
{
	event PawnFalling()
	{
		GoToState( 'WaitingForLanding',,,true );
	}
Begin:
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " FollowOlimar");
	mMyPawn.ZeroMovementVariables();
	while(mPawnToAttack == none && !KillAIIfPawnDead())
	{
		//WorldInfo.Game.Broadcast(self, mMyPawn $ " STATE OK!!!");
		if(!isArrived)
		{
			MoveToward (destActor);
		}
		else
		{
			MoveToward (mMyPawn,, mDestinationOffset);// Ugly hack to prevent "runnaway loop" error
		}
	}
	mMyPawn.ZeroMovementVariables();
}

state WaitingForLanding
{
	event LongFall()
	{
		mDidLongFall = true;
	}

	event NotifyPostLanded()
	{
		if( mDidLongFall || !CanReturnToOrginalPosition() )
		{
			if( mMyPawn.IsDefaultAnimationRestingOnSomething() )
			{
			    mMyPawn.mDefaultAnimationInfo =	mMyPawn.mIdleAnimationInfo;
			}

			mOriginalPosition = mMyPawn.Location;
		}

		mDidLongFall = false;

		StopLatentExecution();
		mMyPawn.ZeroMovementVariables();
		GoToState( 'FollowOlimar', 'Begin',,true );
	}

Begin:
	mMyPawn.ZeroMovementVariables();
	WaitForLanding( 1.0f );
}

state ChasePawn extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	mMyPawn.SetAnimationInfoStruct( mMyPawn.mRunAnimationInfo );

	while(mPawnToAttack != none && !KillAIIfPawnDead() && (VSize( mMyPawn.Location - mPawnToAttack.Location ) > mMyPawn.mAttackRange || !ReadyToAttack()))
	{
		MoveToward( mPawnToAttack,, mDestinationOffset );
	}

	if(mPawnToAttack == none)
	{
		ReturnToOriginalPosition();
	}
	else
	{
		FinishRotation();
		GotoState( 'Attack' );
	}
}

state Attack extends MasterState
{
	ignores SeePlayer;
 	ignores SeeMonster;
 	ignores HearNoise;
 	ignores OnManual;
 	ignores OnWallJump;
 	ignores OnWallRunning;

begin:
	Focus = mPawnToAttack;

	StartAttack( mPawnToAttack );
	FinishRotation();
}

/**
 * Helper function to determine if the last seen goat is near a given protect item
 * @param  protectInformation - The protectInfo to check against
 * @return true / false depending on if the goat is near or not
 */
function bool GoatNearProtectItem( ProtectInfo protectInformation )
{
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " mProtectItems[0]=" $ mMyPawn.mProtectItems[0].ProtectItem);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " ProtectItem=" $ protectInformation.ProtectItem);

	if( protectInformation.ProtectItem == None || mVisibleEnemies.Length == 0 )
	{
		return false;
	}
	else
	{
		return true;
	}
}

/**
 * Helper function to determine if our pawn is close to a protect item, called when we arrive at a pathnode
 * @param currentlyAtNode - The pathNode our pawn just arrived at
 * @param out_ProctectInformation - The info about the protect item we are near if any
 * @return true / false depending on if the pawn is near or not
 */
function bool NearProtectItem( PathNode currentlyAtNode, out ProtectInfo out_ProctectInformation )
{
	out_ProctectInformation=mMyPawn.mProtectItems[0];
	return true;
}

function bool IsValidEnemy( Pawn newEnemy )
{
	local GGPawn gpawn;

	gpawn=GGPawn(newEnemy);
	if(!agressive || gpawn.mIsRagdoll)
	{
		return false;
	}

	return CanAttack(newEnemy);
}

function bool CanAttack(Pawn newEnemy)
{
	local GGNpc npc;

	npc = GGNpc(newEnemy);
	//WorldInfo.Game.Broadcast(self, mMyPawn $ " canAttack(npc)=" $ npc);
	if(npc != none)
	{
		if(npc.mInWater)
		{
			return false;
		}

		//WorldInfo.Game.Broadcast(self, mMyPawn $ " canAttack(controller)=" $ npc.Controller);
		if(GGAIControllerPingmin(npc.Controller) != none)
		{
			return false;
		}

		if(npc.Controller != none)
		{
			return true;
		}
	}

	return false;
}

/**
 * Helper functioner for determining if the goat is in range of uur sightradius
 * if other is not specified mLastSeenGoat is checked against
 */
function bool PawnInRange( optional Pawn other )
{
	if(mMyPawn.mIsRagdoll || mPawnToAttack.Physics == PHYS_RigidBody)
	{
		return false;
	}
	else
	{
		return super.PawnInRange(other);
	}
}

/**
 * Called when an actor takes damage
 */
function OnTakeDamage( Actor damagedActor, Actor damageCauser, int damage, class< DamageType > dmgType, vector momentum )
{
	if(damagedActor == mMyPawn)
	{
		if(dmgType == class'GGDamageTypeCollision' && !mMyPawn.mIsRagdoll)
		{
			cancelNextRagdoll=true;
			//pushVector=pushForce*Normal(damagedActor.Location-damageCauser.Location);
		}
	}
}

function bool CanReturnToOrginalPosition()
{
	return false;
}

/**
 * Go back to where the position we spawned on
 */
function ReturnToOriginalPosition()
{
	GotoState( 'FollowOlimar' );
}

/**
 * Helper function for when we see the goat to determine if it is carrying a scary object
 */
function bool GoatCarryingDangerItem()
{
	return false;
}

function bool PawnUsesScriptedRoute()
{
	return false;
}

//--------------------------------------------------------------//
//			GGNotificationInterface								//
//--------------------------------------------------------------//

/**
 * Called when an actor begins to ragdoll
 */
function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	local GGNPc npc;

	npc = GGNPc( ragdolledActor );

	if(ragdolledActor == mMyPawn)
	{
		if(isRagdoll)
		{
			if(cancelNextRagdoll)
			{
				cancelNextRagdoll=false;
				StandUp();
				//mMyPawn.SetPhysics( PHYS_Falling);
				//mMyPawn.Velocity+=pushVector;
			}
			else
			{
				if( IsTimerActive( NameOf( StopPointing ) ) )
				{
					StopPointing();
					ClearTimer( NameOf( StopPointing ) );
				}

				if( IsTimerActive( NameOf( StopLookAt ) ) )
				{
					StopLookAt();
					ClearTimer( NameOf( StopLookAt ) );
				}

				if( mCurrentState == 'ProtectItem' )
				{
					ClearTimer( nameof( AttackPawn ) );
					ClearTimer( nameof( DelayedGoToProtect ) );
				}
				StopAllScheduledMovement();
				StartStandUpTimer();
				EndAttack();
				totalTime=0.f;
			}

			if( npc != none && npc.LifeSpan > 0.0f )
			{
				if( npc == mPawnToAttack )
				{
					EndAttack();
				}

				if( npc == mLookAtActor )
				{
					StopLookAt();
				}
			}
		}
	}
}

function bool PanicOnRagdoll();
function bool WantToPanicOverTrick( GGTrickBase trickMade );
function bool WantToPanicOverKismetTrick( GGSeqAct_GiveScore trickRelatedKismet );
function bool AfraidOfGoatWithDangerItem();
function bool CanPanic();

DefaultProperties
{
	mDestinationOffset=100.0f

	bIsPlayer=true
	mIgnoreGoatMaus=true

	mAttackIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mCheckProtItemsThreatIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)
	mVisibilityCheckIntervalInfo=(Min=1.f,Max=1.f,CurrentInterval=1.f)

	agressive=false
	transport=false
	cancelNextRagdoll=false
	pushForce=10.f
}