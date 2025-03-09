class OlimarGoat extends GGMutator;

var bool postRenderSet;

function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );

	if( goat != none )
	{
		if( IsValidForPlayer( goat ) )
		{
			if( !WorldInfo.bStartup )
			{
				SetPostRenderFor();
			}
			else
			{
				SetTimer( 1.0f, false, NameOf( SetPostRenderFor ));
			}
		}
	}

	super.ModifyPlayer( other );
}

function MakeOnion(vector center, PingminColor pico)
{
 	local PingminOnion onion;
 	local rotator rot;

	//Destroy old onions
	foreach AllActors(class'PingminOnion', onion)
 	{
 		onion.ShutDown();
 		onion.Destroy();
 	}

 	//Make new onion
 	rot=Rotator(vect(1, 0, 0));
	rot.Yaw+=RandRange(0.f, 65536.f);
 	onion = Spawn(class'PingminOnion',,, center, rot,, true);
 	onion.InitOnion(pico);
}

/**
 * Sets post render for on all local player controllers.
 */
function SetPostRenderFor()
{
	local PlayerController PC;

	if(postRenderSet)
		return;

	postRenderSet=true;
	foreach WorldInfo.LocalPlayerControllers( class'PlayerController', PC )
	{
		if( GGHUD( PC.myHUD ) == none )
		{
			// OKAY! THIS IS REALLY LAZY! This assume all PC's is initialized at the same time
			SetTimer( 0.5f, false, NameOf( SetPostRenderFor ));
			postRenderSet=false;
			break;
		}
		GGHUD( PC.myHUD ).mPostRenderActorsToAdd.AddItem( self );
	}
}

simulated event PostRenderFor( PlayerController PC, Canvas c, vector cameraPosition, vector cameraDir )
{
	local PingminCounter pingCount;

	foreach AllActors(class'PingminCounter', pingCount)
	{
		pingCount.PostRenderFor(PC, c, cameraPosition, cameraDir);
	}
}

DefaultProperties
{
	mMutatorComponentClass=class'OlimarGoatComponent'

	bPostRenderIfNotVisible=true
}