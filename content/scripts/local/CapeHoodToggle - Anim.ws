/*
	Script original author: anakmonyet
	https://next.nexusmods.com/profile/anakmonyet?gameId=952

	Next-Gen port author: ElementaryLewis
	https://next.nexusmods.com/profile/ElementaryLewis?gameId=952
*/

state CHAnim in CR4Player
{
	var speedMultID : int ;
	var anim : name;
	var closeCamera : string;
	
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		closeCamera = theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'EnableAlternateExplorationCamera');
		
		if (closeCamera == "1")
		{
			if (IsPlayingHoodCapeAnim())
				DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.75f, -0.4f, 0.35f ), 0.2f, dt );
				
			return true;
		}
		
		return false;
	}
	
	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState(prevStateName);
		CHPlayAnimation();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		parent.ResetAnimationSpeedMultiplier(speedMultID);
		super.OnLeaveState(nextStateName);
	}
	
	event OnTakeDamage( action : W3DamageAction ) {
		if( (W3PlayerWitcher)action.victim && action.DealsAnyDamage() && !((W3Effect_Toxicity)action.causer) )
		{
			parent.OnTakeDamage(action);
			parent.GotoState('CHInterruption');
		}		
	}
	
	entry function CHPlayAnimation() 
	{
		switch(parent.animHoodCape) {
			case "hoodon":
				parent.AddTimer( 'TimerHoodOn', 1.0, false );
				parent.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'high_standing_determined_gesture_show_face', 1.0, 1.0);
				break;
			case "hoodoff":
				speedMultID = parent.SetAnimationSpeedMultiplier( 0.6 , speedMultID);	
				parent.AddTimer( 'TimerHoodOff', 0.95, false );			
				parent.AddTimer( 'TimerInterrupt', 1, false );
				parent.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_4', 0.25, 0.0);
				break;
			case "capeon":
				parent.AddTimer( 'TimerInterrupt', 4, false );
				parent.AddTimer( 'TimerCapeOn', 2, false );
				parent.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_2', 1.0, 0.0);
				break;
			case "capeoff":
				parent.AddTimer( 'TimerInterrupt', 4, false );
				parent.AddTimer( 'TimerCapeOff', 2, false );
				parent.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_2', 1.0, 0.0);
				break;
		}
		
		parent.GotoState( 'Exploration' );
	}
}

state CHInterruption in CR4Player
{
	var speedMultID : int;
	var closeCamera : string;
	
	event OnGameCameraTick( out moveData : SCameraMovementData, dt : float )
	{
		closeCamera = theGame.GetInGameConfigWrapper().GetVarValue('Gameplay', 'EnableAlternateExplorationCamera');
		
		if (closeCamera == "1")
		{
			if (IsPlayingHoodCapeAnim())
				DampVectorSpring( moveData.cameraLocalSpaceOffset, moveData.cameraLocalSpaceOffsetVel, Vector( 0.75f, -0.4f, 0.35f ), 0.2f, dt );
				
			return true;
		}
		
		return false;
	}
	
	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState(prevStateName);
		RemoveAllTimers();
		InterruptAnimation();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		super.OnLeaveState(nextStateName);
	}
	
	entry function InterruptAnimation() {
		speedMultID = parent.SetAnimationSpeedMultiplier( 0.5 , speedMultID);
		Sleep(0.25);
		speedMultID = parent.SetAnimationSpeedMultiplier( 0.25 , speedMultID);
		Sleep(0.25);
		speedMultID = parent.SetAnimationSpeedMultiplier( 0.1 , speedMultID);
		parent.ActionPlaySlotAnimation( 'PLAYER_SLOT', '' );
		Sleep(0.25);
		speedMultID = parent.SetAnimationSpeedMultiplier( 0.25 , speedMultID);		
		Sleep(0.5);
		parent.ResetAnimationSpeedMultiplier(speedMultID);
		parent.GotoState( 'Exploration' );
	}
	
	function RemoveAllTimers() {
		parent.RemoveTimer( 'TimerHoodOn' );
		parent.RemoveTimer( 'TimerHoodOff' );
		parent.RemoveTimer( 'TimerCapeOn' );
		parent.RemoveTimer( 'TimerCapeOff' );
	}
}


function SetHoodOnAnim() {
	if (!IsPlayingHoodCapeAnim())
		if (CanPlayAnimHoodCape()) {
			thePlayer.SetAnim("hoodon");
			thePlayer.GotoState('CHAnim');
		} else {
			//HoodOn();
		}
}


function SetHoodOffAnim() {
	if (!IsPlayingHoodCapeAnim())
		if (CanPlayAnimHoodCape()) {
			thePlayer.SetAnim("hoodoff");
			thePlayer.GotoState('CHAnim');
		} else {
			//HoodOff();
		}
}


function SetCapeOnAnim() {
	if (!IsPlayingHoodCapeAnim())
		if (CanPlayAnimHoodCape()) {
			thePlayer.SetAnim("capeon");
			thePlayer.GotoState('CHAnim');
		} else {
			//CapeOn();
		}
}


function SetCapeOffAnim() {
	if (!IsPlayingHoodCapeAnim())
		if (CanPlayAnimHoodCape()) {
			thePlayer.SetAnim("capeoff");
			thePlayer.GotoState('CHAnim');
		} else {
			//CapeOff();
		}
}


function CanPlayAnimHoodCape() : bool
{
	return thePlayer.GetCurrentStateName() == 'Exploration';
}


function IsPlayingHoodCapeAnim() : bool
{
	return thePlayer.GetCurrentStateName() == 'CHAnim' || thePlayer.GetCurrentStateName() == 'CHInterruption';
}