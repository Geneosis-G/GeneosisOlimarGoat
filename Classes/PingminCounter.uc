class PingminCounter extends Actor;

var GGKActor mKActor;
var int mKactorWeight;
var vector mDesiredLocation;
var rotator mDesiredRotation;

var int mHoldingPingmins;
var int mValidHoldingPingmins;
var array<GGNpcPingmin> mPingmins;

var float mTotalTime;
var float mUpdateTime;

/**
 * See super.
 */
function InitCounter(GGKActor kact)
{
	mKActor=kact;
	SetBase(mKActor);
	mKactorWeight=class'PingminOnion'.static.GetPingminsValue(mKActor);
	mDesiredLocation=mKActor.Location;
	mDesiredLocation.Z+=50.f;
}

simulated event PostRenderFor( PlayerController PC, Canvas c, vector cameraPosition, vector cameraDir )
{
	local vector locationToUse, speechScreenLocation;
	local bool isCloseEnough, isOnScreen;
	local float cameraDistScale, cameraDist, cameraDistMax, cameraDistMin, speechScale;
	//WorldInfo.Game.Broadcast(self, "PostRenderFor=" $ PC $ " self=" $ self);
	locationToUse=mKActor.Location;

	cameraDist = VSize( cameraPosition - locationToUse );
	cameraDistMin = 500.0f;
	cameraDistMax = 4000.0f;
	cameraDistScale = GetScaleFromDistance( cameraDist, cameraDistMin, cameraDistMax );

	isCloseEnough = cameraDist < cameraDistMax;
	isOnScreen = cameraDir dot Normal( locationToUse - cameraPosition ) > 0.0f;

	c.Font = Font'UI_Fonts.InGameFont';
	c.PushDepthSortKey( int( cameraDist ) );

	if( isOnScreen && isCloseEnough )
	{
		// The scale from distance must be at least 0.2 but the scale from time can go all the way to 0.
		speechScale = FMax( 0.2f, cameraDistScale );
		speechScreenLocation = c.Project( locationToUse );
		RenderSpeechBubble( c, speechScreenLocation, speechScale);
	}

	c.PopDepthSortKey();
}

function float GetScaleFromDistance( float cameraDist, float cameraDistMin, float cameraDistMax )
{
	return FClamp( 1.0f - ( ( FMax( cameraDist, cameraDistMin ) - cameraDistMin ) / ( cameraDistMax - cameraDistMin ) ), 0.0f, 1.0f );
}

function RenderSpeechBubble( Canvas c, vector screenLocation, float screenScale)
{
	local FontRenderInfo renderInfo;
	local float textScale, XL, YL, maxTextScale;
	local string message;
	local float ratio;

	renderInfo.bClipText = true;

	maxTextScale = 5.f;
	textScale = Lerp( 0.0f, maxTextScale, screenScale );

	ratio = FMin(float(mHoldingPingmins)/float(mKactorWeight), 1.f);
	c.DrawColor = MakeColor( Lerp(0, 255, ratio), Lerp(0, 255, ratio), Lerp(0, 255, ratio), 255 );

	message = "" $ mHoldingPingmins;
	c.TextSize(message, XL, YL, textScale, textScale);
	c.SetPos(screenLocation.X, screenLocation.Y + ( -10.f * screenScale ));
	c.DrawAlignedShadowText(message,, textScale, textScale, renderInfo,,, 0.5f, 1.0f);

	message = "_";
	c.TextSize(message, XL, YL, textScale, textScale);
	c.SetPos(screenLocation.X, screenLocation.Y);
	c.DrawAlignedShadowText(message,, textScale, textScale, renderInfo,,, 0.5f, 1.0f);

	message = "" $ mKactorWeight;
	c.TextSize(message, XL, YL, textScale, textScale);
	c.SetPos(screenLocation.X, screenLocation.Y + ( 90.f * screenScale ));
	c.DrawAlignedShadowText(message,, textScale, textScale, renderInfo,,, 0.5f, 1.0f);
}

event Tick( float deltaTime )
{
	if(mKActor == none || mKActor.bPendingDelete || mKActor.bHidden)
	{
		Destroy();
		return;
	}

	super.Tick( deltaTime );

	mTotalTime = mTotalTime + deltaTime;
	if(mTotalTime >= mUpdateTime)
	{
		UpdateHoldingPingmins();
		if(mHoldingPingmins == 0)
		{
			Destroy();
			return;
		}

		if(mValidHoldingPingmins >= mKactorWeight)
		{
			MoveToCenter();
		}
	}

	mKActor.SetPhysics(PHYS_None);
	mKActor.SetLocation(mDesiredLocation);
	mKActor.SetRotation(mDesiredRotation);
}

function UpdateHoldingPingmins()
{
	local GGNpcPingmin pingmin;
	local GGAIControllerPingmin pingminController;

	mHoldingPingmins=0;
	mValidHoldingPingmins=0;
	mPingmins.Length=0;
	foreach AllActors(class'GGNpcPingmin', pingmin)
	{
		pingminController=GGAIControllerPingmin(pingmin.Controller);
		if(pingminController != none)
		{
			if(pingminController.transport && pingminController.mTargetKActor == mKActor)
			{
				mHoldingPingmins++;
				if(!pingmin.mIsRagdoll
				&& VSize2D(pingmin.Location - mKActor.Location) < 8.f * pingmin.GetCollisionRadius())
				{
					mValidHoldingPingmins++;
					mPingmins.AddItem(pingmin);
				}
			}
		}
	}
}

function MoveToCenter()
{
	local vector center, onionLoc;
	local GGNpcPingmin pingmin;
	local float r, h;

	if(mPingmins.Length == 0)
		return;

	// Find barycenter of valid pingmins
	foreach mPingmins(pingmin)
	{
		center = center + pingmin.Location;
	}
	center = center / mValidHoldingPingmins;
	mKActor.GetBoundingCylinder(r, h);
	center.Z += (h/2.f) + 50.f;

	mDesiredLocation=center;

	// Aim at onion
	onionLoc=class'PingminOnion'.static.GetOnionLocation(self);
	mDesiredRotation = rotator(Normal2D(onionLoc - mKActor.Location));
}

event Destroyed()
{
	if(mKActor != none)
	{
		mKActor.SetPhysics(PHYS_RigidBody);
	}
}

DefaultProperties
{
	mUpdateTime=0.1f

	bPostRenderIfNotVisible=true
}