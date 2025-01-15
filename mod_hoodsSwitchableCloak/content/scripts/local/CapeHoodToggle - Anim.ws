/*
	Script original author: anakmonyet
	https://next.nexusmods.com/profile/anakmonyet?gameId=952

	Next-Gen port author: ElementaryLewis
	https://next.nexusmods.com/profile/ElementaryLewis?gameId=952

	Script rewritten by: Priler (for Switchable Cloak mod)
	https://next.nexusmods.com/profile/Priler?gameId=952

	Mod Github page: https://github.com/Priler/SwitchableCloak
*/

statemachine class SwitchableCloakStateMachine
{
	public var animationType : string;
	public var saveLockId: int;

	public function Initialize()
	{
		GotoState('CHIdle');
	}

	public function SetHoodOnAnim() {
		if (CanPerformAnim() && !IsPlayingAnim() && !CannotPlayAnim())
		{
			animationType = "hoodon";

			SheatheSwordAndPlayAnimation();
		}
	}


	public function SetHoodOffAnim() {
		if (CanPerformAnim() && !IsPlayingAnim() && !CannotPlayAnim())
		{
			animationType = "hoodoff";

			SheatheSwordAndPlayAnimation();
		}
	}


	public function SetCapeOnAnim() {
		LogChannel('modSwitchableCloak', "Set cape on anim ...");
		LogChannel('modSwitchableCloak', "CanPerformAnim: " + CanPerformAnim());
		LogChannel('modSwitchableCloak', "IsPlayingAnim: " + IsPlayingAnim());
		LogChannel('modSwitchableCloak', "CannotPlayAnim: " + CannotPlayAnim());
		if (CanPerformAnim() && !IsPlayingAnim() && !CannotPlayAnim())
		{
			animationType = "capeon";

			BlockActions(true);
			SheatheSwordAndPlayAnimation();
		}
	}


	public function SetCapeOffAnim() {
		LogChannel('modSwitchableCloak', "Set cape off anim ...");
		LogChannel('modSwitchableCloak', "CanPerformAnim: " + CanPerformAnim());
		LogChannel('modSwitchableCloak', "IsPlayingAnim: " + IsPlayingAnim());
		LogChannel('modSwitchableCloak', "CannotPlayAnim: " + CannotPlayAnim());
		if (CanPerformAnim() && !IsPlayingAnim() && !CannotPlayAnim())
		{
			animationType = "capeoff";

			BlockActions(true);
			SheatheSwordAndPlayAnimation();
		}
	}


	function SwitchableCloakIsOnFoot() : bool
	{
		return thePlayer.GetCurrentStateName() == 'Exploration' && thePlayer.substateManager.GetStateCur() == 'Idle'
			|| thePlayer.GetCurrentStateName() == 'CombatSteel'
			|| thePlayer.GetCurrentStateName() == 'CombatSilver'
			|| thePlayer.GetCurrentStateName() == 'CombatFists';
	}


	function CannotPlayAnim() : bool
	{
		// Waiting, Exploration, Meditation, MeditationWaiting, Swimming, CombatFists, AimThrow, Aiming, 
		// return thePlayer.GetCurrentStateName() == 'Exploration';
		return thePlayer.IsInAir()
			|| thePlayer.IsCrossbowHeld()
			|| thePlayer.IsThrowingItem()
			|| thePlayer.playerAiming.GetCurrentStateName() == 'Aiming'
			|| thePlayer.substateManager.GetStateCur() == 'Slide'
			|| thePlayer.substateManager.GetStateCur() == 'Climb'
			|| thePlayer.substateManager.GetStateCur() == 'Land'
			|| thePlayer.substateManager.GetStateCur() == 'Roll';
	}


	function IsPlayingAnim() : bool
	{
		return thePlayer.GetCurrentStateName() == 'CHAnim' || thePlayer.GetCurrentStateName() == 'CHInterruption';
	}


	function CanPerformAnim() : bool
	{
		return !thePlayer.IsInCombat();
	}


	function BlockActions(block : bool)
	{
		var actionBlockingExceptions	: array<EInputActionBlock>;

		if (block)
		{
			actionBlockingExceptions.PushBack(EIAB_ExplorationFocus);
			actionBlockingExceptions.PushBack(EIAB_RunAndSprint);
			actionBlockingExceptions.PushBack(EIAB_Sprint);

			actionBlockingExceptions.PushBack(EIAB_Movement);
			actionBlockingExceptions.PushBack(EIAB_Jump);
			actionBlockingExceptions.PushBack(EIAB_DrawWeapon);
			actionBlockingExceptions.PushBack(EIAB_SwordAttack);
			actionBlockingExceptions.PushBack(EIAB_LightAttacks);
			actionBlockingExceptions.PushBack(EIAB_SpecialAttackLight);
			actionBlockingExceptions.PushBack(EIAB_Parry);
			actionBlockingExceptions.PushBack(EIAB_Counter);
			actionBlockingExceptions.PushBack(EIAB_Dodge);

			thePlayer.BlockAllActions('CHAnim', true, actionBlockingExceptions);

			theGame.CreateNoSaveLock('CHAnim', saveLockId);
		}
		else
		{
			thePlayer.BlockAllActions('CHAnim', false);

			theGame.ReleaseNoSaveLock(saveLockId);
		}
	}

	public function GetPerformingAnimationState() : SwitchableCloakStateMachineStateCHAnim
	{
		if (GetCurrentStateName() == 'CHAnim')
		{
			return (SwitchableCloakStateMachineStateCHAnim)GetState('CHAnim');
		}

		return NULL;
	}

	private function SheatheSwordAndPlayAnimation()
	{
		if (thePlayer.IsWeaponHeld('silversword') || thePlayer.IsWeaponHeld('steelsword'))
		{
			thePlayer.OnEquipMeleeWeapon(PW_None, true, true);
			GetWitcherPlayer().AddTimer('SwitchableCloakPerformAnimationDelayed', 1.5f);
		}
		else
		{
			GotoState('CHAnim');
		}
	}
}

state CHAnim in SwitchableCloakStateMachine
{
	var speedMultID : int ;
	var anim : name;
	var closeCamera : string;

	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState(prevStateName);

		theGame.GetGameCamera().RemoveTag('CHIdle');
		theGame.GetGameCamera().RemoveTag('CHInterruption');
		theGame.GetGameCamera().AddTag('CHAnim');

		parent.BlockActions(true);
		CHPlayAnimation();
	}
	
	event OnLeaveState( nextStateName : name )
	{
		thePlayer.ResetAnimationSpeedMultiplier(speedMultID);
		parent.BlockActions(false);
		super.OnLeaveState(nextStateName);
	}

	entry function CHPlayAnimation() 
	{
		//while(VecLengthSquared(thePlayer.GetMovingAgentComponent().GetVelocity()) > 1.f)
		//	Sleep(0.1f);

		// thePlayer.DisplayHudMessage("Playing animation ...");
		LogChannel('modSwitchableCloak', "Playing cloak animation ...");

		switch(parent.animationType) {
			case "hoodon":
				speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.9f, speedMultID);
				GetWitcherPlayer().AddTimer( 'SwitchableCloakInterruptAnimationDelayed', 1.7f, false );
				GetWitcherPlayer().SetToggleVanityItemOnTimer();
				thePlayer.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'high_standing_determined_gesture_show_face', 1.0f, 1.0f);
				break;
			case "hoodoff":
				speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.6f, speedMultID);
				GetWitcherPlayer().AddTimer( 'SwitchableCloakInterruptAnimationDelayed', 0.9f, false );
				GetWitcherPlayer().SetToggleVanityItemOffTimer();
				thePlayer.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_4', 0.25f, 0.0f);
				break;
			case "capeon":
				speedMultID = thePlayer.SetAnimationSpeedMultiplier( 1.0f, speedMultID);
				GetWitcherPlayer().AddTimer( 'SwitchableCloakInterruptAnimationDelayed', 3.4f, false );
				GetWitcherPlayer().SetToggleVanityItemOnTimer();
				thePlayer.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_2', 1.5f / 1.0f, 0.3f / 1.0f);
				break;
			case "capeoff":
				speedMultID = thePlayer.SetAnimationSpeedMultiplier( 1.0f, speedMultID);
				GetWitcherPlayer().AddTimer( 'SwitchableCloakInterruptAnimationDelayed', 1.75f, false );
				GetWitcherPlayer().SetToggleVanityItemOffTimer();
				thePlayer.ActionPlaySlotAnimation( 'PLAYER_SLOT', 'man_standing_adjusting_and_cleaning_clothes_loop_2', 1.5f / 1.0f, 0.3f / 1.0f);
				break;
		}

		parent.GotoState('CHIdle');
	}

	public function InterruptAnimOnTakeDamage(action : W3DamageAction)
	{
		if (action.DealsAnyDamage() && !action.IsDoTDamage())
		{
			parent.GotoState('CHInterruption');
		}
	}
}

state CHIdle in SwitchableCloakStateMachine
{
	var closeCamera : string;

	event OnEnterState(prevStateName : name)
	{
		super.OnEnterState(prevStateName);

		theGame.GetGameCamera().RemoveTag('CHAnim');
		theGame.GetGameCamera().RemoveTag('CHInterruption');
		theGame.GetGameCamera().AddTag('CHIdle');
	}
	
	event OnLeaveState(nextStateName : name)
	{
		super.OnLeaveState(nextStateName);
	}
}

state CHInterruption in SwitchableCloakStateMachine
{
	var speedMultID : int;
	var closeCamera : string;

	event OnEnterState( prevStateName : name )
	{
		super.OnEnterState(prevStateName);
		RemoveAllTimers();

		theGame.GetGameCamera().RemoveTag('CHIdle');
		theGame.GetGameCamera().RemoveTag('CHAnim');
		theGame.GetGameCamera().AddTag('CHInterruption');

		InterruptAnimation();
	}

	event OnLeaveState( nextStateName : name )
	{
		thePlayer.ResetAnimationSpeedMultiplier(speedMultID);
		parent.BlockActions(false);
		super.OnLeaveState(nextStateName);
	}
	
	entry function InterruptAnimation() {
		speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.6 , speedMultID);
		Sleep(0.5);
		speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.3 , speedMultID);
		Sleep(0.25);
		speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.1 , speedMultID);
		thePlayer.ActionPlaySlotAnimation( 'PLAYER_SLOT', '', 0.9f, 0.9f );
		speedMultID = thePlayer.SetAnimationSpeedMultiplier( 0.4 , speedMultID);
		Sleep(0.4);

		parent.GotoState( 'CHIdle' );
	}

	function RemoveAllTimers() {
		GetWitcherPlayer().RemoveTimer('SwitchableCloakInterruptAnimationDelayed');
		GetWitcherPlayer().RemoveTimer('SwitchableCloakPerformAnimationDelayed');
		// GetWitcherPlayer().RemoveTimer('TimerToggleVanityItemOff');
		// GetWitcherPlayer().RemoveTimer('TimerToggleVanityItemOn');
	}
}


function GetSwitchableCloakStateMachine() : SwitchableCloakStateMachine
{
	var playerWitcher : W3PlayerWitcher = GetWitcherPlayer();

	return playerWitcher.switchableCloakSM;
}

function SwitchableCloakGetPerformingAnimationState() : SwitchableCloakStateMachineStateCHAnim
{
	return GetSwitchableCloakStateMachine().GetPerformingAnimationState();
}

@addField(W3PlayerWitcher) public var switchableCloakSM: SwitchableCloakStateMachine;

@wrapMethod(W3PlayerWitcher) function OnSpawned(spawnData : SEntitySpawnData)
{
	wrappedMethod(spawnData);

	switchableCloakSM = new SwitchableCloakStateMachine in this;
	switchableCloakSM.Initialize();
}

@addField(CR4Player)
var hood_on : bool;

@addMethod(W3PlayerWitcher) timer function SwitchableCloakInterruptAnimationDelayed(dt : float, id : int)
{
	switchableCloakSM.GotoState('CHInterruption');
}

@wrapMethod(W3PlayerWitcher) function OnTakeDamage(action : W3DamageAction)
{
	wrappedMethod(action);

	if (switchableCloakSM.IsPlayingAnim())
	{
		SwitchableCloakGetPerformingAnimationState().InterruptAnimOnTakeDamage(action);
	}
}

@addMethod(W3PlayerWitcher) timer function SwitchableCloakPerformAnimationDelayed(time : float, id : int)
{
	switchableCloakSM.GotoState('CHAnim');
}
