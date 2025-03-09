class GGNpcPingmin extends GGNpc;

enum PingminColor
{
	PC_Blue,
	PC_Yellow,
	PC_Red
};

var Material mBlueMaterial;
var Material mYellowMaterial;
var Material mRedMaterial;

var PingminColor mColor;

var StaticMeshComponent mFlowerMesh;

function InitPingmin()
{
	mesh.AttachComponent(mFlowerMesh, 'Head', vect(0, 0, 0), rot( 0, 0, 0 ));
	mFlowerMesh.SetLightEnvironment( mesh.lightenvironment );

	UpdateColor();

	if(Controller == none)
	{
		SpawnDefaultController();
	}
}

function UpdateColor()
{
	if(mColor == PC_Blue)
	{
		mesh.SetMaterial(0, mBlueMaterial);
	}
	else if(mColor == PC_Yellow)
	{
		mesh.SetMaterial(0, mYellowMaterial);
	}
	else if(mColor == PC_Red)
	{
		mesh.SetMaterial(0, mRedMaterial);
	}
}

/**
 * Human readable name of this actor.
 */
function string GetActorName()
{
	if(mColor == PC_Blue) return "Blue Pingmin";
	if(mColor == PC_Yellow) return "Yellow Pingmin";
	if(mColor == PC_Red) return "Red Pingmin";

	return "Pingmin";
}

/**
 * How much score this actor gives.
 */
function int GetScore()
{
	return 10;
}

//Nope
function MakeGoatBaa();

DefaultProperties
{
	ControllerClass=class'GGAIControllerPingmin'

	Begin Object name=WPawnSkeletalMeshComponent
		SkeletalMesh=SkeletalMesh'ClassyGoat.mesh.ClassyGoat_01'
		AnimSets(0)=AnimSet'ClassyGoat.Anim.ClassyGoat_Anim_01'
		AnimTreeTemplate=AnimTree'ClassyGoat.Anim.ClassyGoat_AnimTree'
		PhysicsAsset=PhysicsAsset'ClassyGoat.mesh.ClassyGoat_Physics_01'
		Translation=(Z=8.f)
	End Object
	mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	Begin Object class=StaticMeshComponent Name=StaticMeshComp1
		StaticMesh=StaticMesh'Circus.Meshes.Glowing_Flower_01'
		Scale3D=(X=0.2f, Y=0.2f, Z=0.2f)
		Translation=(X=0, Y=0, Z=0)
	End Object
	mFlowerMesh=StaticMeshComp1

	mBlueMaterial=Material'Pingmins.Blue';
	mYellowMaterial=Material'Props_01.Materials.Bicycle_Yellow_Mat';
	mRedMaterial=Material'Props_01.Materials.Bicycle_Red';

	Begin Object name=CollisionCylinder
		CollisionRadius=20.0f
		CollisionHeight=35.0f
		CollideActors=true
		BlockActors=true
		BlockRigidBody=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
	End Object

	mDefaultAnimationInfo=(AnimationNames=(Idle),AnimationRate=1.0f,MovementSpeed=0.0f)
	mAttackAnimationInfo=(AnimationNames=(Ram),AnimationRate=1.0f,MovementSpeed=0.0f)
	mRunAnimationInfo=(AnimationNames=(Run),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true);
	mPanicAnimationInfo=(AnimationNames=(Run),AnimationRate=1.0f,MovementSpeed=700.0f,LoopAnimation=true)
	mApplaudAnimationInfo=()
	mDanceAnimationInfo=()
	mPanicAtWallAnimationInfo=()
	mAngryAnimationInfo=()
	mIdleAnimationInfo=()
	mNoticeGoatAnimationInfo=()
	mIdleSittingAnimationInfo=()

	mAutoSetReactionSounds=true

	mNoticeGoatSounds=()
	mAngrySounds=()
	mApplaudSounds=()
	mPanicSounds=()
	mKnockedOverSounds=(SoundCue'Zombie_Impact_Sounds.SurvivalMode.Brain_Impact_Cue')
	mAllKnockedOverSounds=(SoundCue'Zombie_Impact_Sounds.SurvivalMode.Brain_Impact_Cue')

	mCanPanic=false
	mNPCSoundEnabled=false

	SightRadius=1500.0f
	HearingThreshold=1500.0f

	MaxJumpHeight=250

	mStandUpDelay=1.f

	mAttackRange=80.0f;
	mAttackMomentum=1000.0f

	mTimesKnockedByGoatStayDownLimit=1000000
}