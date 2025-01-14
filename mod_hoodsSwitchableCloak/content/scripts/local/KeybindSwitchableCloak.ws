/*
	Script author: Priler
	https://next.nexusmods.com/profile/Priler?gameId=952

	Mod Github page: https://github.com/Priler/SwitchableCloak
*/

@addField( CR4Player )
public var ArdCloakSwitch : KeybindSwitchableCloak;

@wrapMethod( CR4Player ) function OnSpawned( spawnData : SEntitySpawnData )
{
	ArdCloakSwitch = new KeybindSwitchableCloak in this;
	ArdCloakSwitch.Init();

	wrappedMethod(spawnData);

	SetVanityValidationTimer();
}

@wrapMethod( CR4Player ) function OnStartFistfightMinigame()
{
	thePlayer.ArdCloakSwitch.InitVanityItemState();
	//if (GetWitcherPlayer().IsInFistFight() && !thePlayer.IsInFistFightMiniGame()) {
	thePlayer.ArdCloakSwitch.UnequipVanityItemDuringFistFightMinigame();
	//}

	wrappedMethod();
}

@addMethod(CR4Player) function SetToggleVanityItemOnTimer()
{
	if (thePlayer.ArdCloakSwitch.GetVanityItemType() == VanityCloak) {
		// Cloak etc timer
		AddTimer( 'TimerToggleVanityItemOn', 1.3, false );
	} else {
		// Hoods etc timer
		AddTimer( 'TimerToggleVanityItemOn', 0.7, false );
	}
}

@addMethod(CR4Player) function SetToggleVanityItemOffTimer()
{
	if (thePlayer.ArdCloakSwitch.GetVanityItemType() == VanityCloak) {
		// Cloak etc timer
		AddTimer( 'TimerToggleVanityItemOff', 1.3, false );
	} else {
		// Hoods etc timer
		AddTimer( 'TimerToggleVanityItemOff', 0.7, false );
	}
}

@addMethod(CR4Player) timer function TimerToggleVanityItemOff( dt : float, it : int )
{
	ArdCloakSwitch.UnequipVanityItem();
}

@addMethod(CR4Player) timer function TimerToggleVanityItemOn( dt : float, it : int )
{
	ArdCloakSwitch.EquipVanityItem();
}


@addField( CR4Player )
public var _vanityItemChangedCheckTimer: float;

@addMethod(CR4Player) function SetVanityValidationTimer()
{
	/*
	@TODO: Rewrite using hooks?
	*/
	AddTimer( 'TimerVanityValidation', 15, false ); // check every 10 seconds
}

@addMethod(CR4Player) timer function TimerVanityValidation( dt : float, it : int )
{

	thePlayer.ArdCloakSwitch.ValidateEquippedVanityItem();

	SetVanityValidationTimer(); // loop the timer
}

//@wrapMethod(CHairCutSceneChoiceAction) function GetActionIcon()
//{
//	thePlayer.ArdCloakSwitch.InitVanityItemState();
	//if (GetWitcherPlayer().IsInFistFight() && !thePlayer.IsInFistFightMiniGame()) {
//	thePlayer.ArdCloakSwitch.UnequipVanityItemDuringFistFightMinigame();
	//}
//
//	wrappedMethod();
//}

enum VanityItemState
{
	VanityItemUnknown,
	VanityItemOn,
	VanityItemOff
}

enum VanityItemType
{
	VanityUnknown,
	VanityCloak,
	VanityHood
}

class KeybindSwitchableCloak
{

	protected var lastEquippedVanityItem: SItemUniqueId;
	protected var factsLoaded : bool; default factsLoaded = false;
	protected var vanityItemState: VanityItemState; default vanityItemState = VanityItemUnknown; // get only
	protected var vanityType: VanityItemType; default vanityType = VanityUnknown; // get only
	protected var lastVanityType: VanityItemType; default lastVanityType = VanityUnknown;
	protected var toggleDisabled: bool; default toggleDisabled = false;
	protected var barberVanityItemWasEquipped: bool; default barberVanityItemWasEquipped = false;

	// comp. patch w/Invisibility Cloak mod
	protected var compatibilityWithInvisibilityCloak__Enabled: bool; default compatibilityWithInvisibilityCloak__Enabled = false;
	protected var compatibilityWithInvisibilityCloak__CloakName: CName; default compatibilityWithInvisibilityCloak__CloakName = 'Cloak of Invisibility';


	public function Init() {
		// init base values
		factsLoaded = false;
		vanityItemState = VanityItemUnknown;

		// init listeners
		theInput.RegisterListener(this, 'OnToggleVanityItem', 'SwitchCloak');
	}


	event OnToggleVanityItem(action: SInputAction)
	{
		if (IsPressed(action) &&
		   !toggleDisabled &&
		   !IsPlayingHoodCapeAnim() &&
		   (ModGetConfigValueBool('ModSwitchableCloakAllowSwitchOnHorse') || !thePlayer.IsInState( 'HorseRiding' ))) {

			// just do it
			toggleDisabled = true;
			ToggleVanityItem();
		}
	}


	public function OnBarberSceneOn()
	{
		thePlayer.ArdCloakSwitch.InitVanityItemState();
		thePlayer.ArdCloakSwitch.UnequipVanityItemDuringBarber();
	}


	public function OnBarberSceneOff()
	{
		thePlayer.ArdCloakSwitch.InitVanityItemState();
		thePlayer.ArdCloakSwitch.EquipVanityItemAfterBarber();
	}


	public function GetlastEquippedVanityItem(): SItemUniqueId
	{
		return lastEquippedVanityItem;
	}


	public function InitVanityItemState() {
		if (GetVanityItemState() != VanityItemUnknown)
			return; // already initialized

		// init cloak state
		if(GetEquippedVanityItem() != GetInvalidUniqueId()) {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Cloak state is ON");

			SetVanityItemState(VanityItemOn);
		} else {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Cloak state is OFF");

			SetVanityItemState(VanityItemOff);
		}
	}


	protected function SetVanityItemState(newState: VanityItemState)
	{
		vanityItemState = newState;
	}


	public function GetVanityItemState(): VanityItemState
	{
		return vanityItemState;
	}


	public function GetVanityItemType(): VanityItemType
	{
		return vanityType;
	}

	public function ValidateEquippedVanityItem(): bool
	{
		var equippedVanityItem: SItemUniqueId;

		// get the cloak
		equippedVanityItem = GetEquippedVanityItem();

		InitFacts();

		if (ItemToFlashUInt(equippedVanityItem) == ItemToFlashUInt(lastEquippedVanityItem)) {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Vanity Validation: GOOD.");

			return false; // nothing changed, it's the same vanity item
		} else if (equippedVanityItem != GetInvalidUniqueId()) {
			// other vanity item is equipped, re-save

			SetVanityItemState(VanityItemOn);

			lastEquippedVanityItem = equippedVanityItem;
			SaveLastUsedVanityItem(lastEquippedVanityItem);

			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Vanity Validation: CHANGED.");

			return true; // return true when vanity item is changed
		} else {
			// no vanity items equipped
			SetVanityItemState(VanityItemOff);

			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Vanity Validation: UNEQUIPPED.");

			return false;
		}
	}


	function GetEquippedVanityItem(): SItemUniqueId
	{
		var equippedItems: array<SItemUniqueId>;

		equippedItems = GetWitcherPlayer().GetEquippedItems();
		return SearchForVanityItem(equippedItems);
	}


	public function ToggleVanityItem()
	{
		var result: bool;

		InitVanityItemState();

		// cannot toggle cloak durning fist fight minigame
		if (thePlayer.IsFistFightMinigameEnabled())
			return;

		if(GetVanityItemState() == VanityItemOn) {
			// unequip cloak
			result = ToggleVanityItemOff(false);

			if(!result) {
				// for some reason toggle can't be done (no cloak found etc)
				toggleDisabled = false;
			}
		} else {
			// equip cloak
			result = ToggleVanityItemOn(false);

			if(!result) {
				// for some reason toggle can't be done (no cloak found etc)
				toggleDisabled = false;
			}
		}
	}


	public function ToggleVanityItemOff(forceIgnoreAnim: bool): bool
	{
		var equippedVanityItem: SItemUniqueId;

		InitVanityItemState();

		if (GetVanityItemState() != VanityItemOn) {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Cloak is already OFF ...");

			return false; // already off
		}

		// get the cloak
		equippedVanityItem = GetEquippedVanityItem();

		if (equippedVanityItem == GetInvalidUniqueId()) {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("No equipped cloak found ...");

			return false; // no equipped cloak found
		}

		// equipped cloak found
		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			theGame.GetGuiManager().ShowNotification("Equipped Clock Found! Unequipping ...");

		// store
		lastEquippedVanityItem = equippedVanityItem;
		SaveLastUsedVanityItem(lastEquippedVanityItem);

		if (vanityType == VanityCloak && ModGetConfigValueBool('ModSwitchableCloakPlayCloakAnimations') && !forceIgnoreAnim) {
			// unequip with cloak animation
			SetCapeOffAnim();
			thePlayer.SetToggleVanityItemOffTimer();	
		} else if (vanityType == VanityHood && ModGetConfigValueBool('ModSwitchableCloakPlayHoodAnimations') && !forceIgnoreAnim) {
			// unequip with hood animation
			SetHoodOffAnim();
			thePlayer.SetToggleVanityItemOffTimer();
		} else {
			// unequip without animation
			UnequipVanityItem();
		}

		return true;
	}


	public function ToggleVanityItemOn(forceIgnoreAnim: bool): bool
	{
		var equippedVanityItem: SItemUniqueId;

		InitVanityItemState();

		if (GetVanityItemState() != VanityItemOff) {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Cloak is already ON ...");

			return false; // already on
		}

		InitFacts();

		// get the cloak
		equippedVanityItem = GetEquippedVanityItem();

		if (equippedVanityItem == lastEquippedVanityItem) {
			// already on
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Already equipped");

			SetVanityItemState(VanityItemOn);
			return ToggleVanityItemOff(false);
		} else if (equippedVanityItem != GetInvalidUniqueId()) {
			// other vanity item is equipped

			SetVanityItemState(VanityItemOn);
			return ToggleVanityItemOff(false);
		} else {
			// no vanity items equipped, equip lastUsed if possible
			if (lastEquippedVanityItem != GetInvalidUniqueId()) {
				if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
					theGame.GetGuiManager().ShowNotification("Equipped last used cloak!");

				// check if item is in inventory
				if (!thePlayer.GetInventory().HasItemById(lastEquippedVanityItem)) {
					if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
						theGame.GetGuiManager().ShowNotification("Last equipped vanity item NOT FOUND");

					return false; // vanity item not found anymore (has been selled/dropped etc)
				}

				if (lastVanityType == VanityCloak && ModGetConfigValueBool('ModSwitchableCloakPlayCloakAnimations') && !forceIgnoreAnim) {
					// equip with cloak animation
					SetCapeOnAnim();
					thePlayer.SetToggleVanityItemOnTimer();
				} else if (lastVanityType == VanityHood && ModGetConfigValueBool('ModSwitchableCloakPlayHoodAnimations') && !forceIgnoreAnim) {
					// equip with hood animation
					SetHoodOnAnim();
					thePlayer.SetToggleVanityItemOnTimer();
				} else {
					// equip without animation
					EquipVanityItem();
				}

				return true;
			} else {
				if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled')) {
					theGame.GetGuiManager().ShowNotification("No last equipped cloak found!");
					theSound.SoundEvent("gui_global_denied");
				}

				return false;
			}
		}
	}


	public function InitFacts()
	{
		if (factsLoaded)
			return; // already initialized

		factsLoaded = true;
		lastEquippedVanityItem = RetrieveLastUsedVanityItem();
	}


	public function EquipVanityItem()
	{
		// unequip
		thePlayer.EquipItem(lastEquippedVanityItem);

		// change state
		SetVanityItemState(VanityItemOn);

		// enable toggling
		toggleDisabled = false;

		CompatibilityPerformCheckWInvisibilityCloak();
	}


	public function UnequipVanityItem()
	{
			// equip last used cloak
			thePlayer.UnequipItem(lastEquippedVanityItem);

			// change state
			SetVanityItemState(VanityItemOff);

			// enable toggling
			toggleDisabled = false;

			CompatibilityPerformCheckWInvisibilityCloak();
	}


	public function CompatibilityPerformCheckWInvisibilityCloak()
	{
		if (thePlayer.GetInventory().GetItemName(lastEquippedVanityItem) != compatibilityWithInvisibilityCloak__CloakName)
			return;

		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			GetWitcherPlayer().DisplayHudMessage("COMPATIBILITY PATCH: Cloak of Invisibility");

		// comp. patch with Invisibility Cloak
		if (GetVanityItemState() == VanityItemOn) {
			compatibilityWithInvisibilityCloak__Enabled = true;
			GetWitcherPlayer().SwitchableCloakCPWInvisibilityCloak();
		} else if (GetVanityItemState() == VanityItemOff) {
			compatibilityWithInvisibilityCloak__Enabled = false;
			GetWitcherPlayer().SwitchableCloakCPWInvisibilityCloak();
		}
	}


	public function UnequipVanityItemDuringFistFightMinigame()
	{
		if (!ModGetConfigValueBool('ModSwitchableCloakUnequipDuringFistFightMinigame'))
			return; // disabled by user

		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			theGame.GetGuiManager().ShowNotification("Unequipping cloak, because fist fight minigame begun ...");

		ToggleVanityItemOff(true); // no cloaks durning fist fight minigame
	}


	function UnequipVanityItemDuringBarber()
	{
		if (!ModGetConfigValueBool('ModSwitchableCloakUnequipDuringBarber'))
			return; // disabled by user

		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			theGame.GetGuiManager().ShowNotification("Unequipping cloak: Barber on enter ...");

		barberVanityItemWasEquipped = GetVanityItemState() == VanityItemOn; // remember vanity equip state

		ToggleVanityItemOff(true); // no cloaks durning barber visits
	}


	function EquipVanityItemAfterBarber()
	{
		if (!barberVanityItemWasEquipped || !ModGetConfigValueBool('ModSwitchableCloakUnequipDuringBarber'))
			return; // disabled by user && only equip, if there was an equipped cloak

		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			theGame.GetGuiManager().ShowNotification("Equipping cloak: Barber on leave ...");

		// @TODO: Auto lower hoods from Hoods?
		ToggleVanityItemOn(true); // equip cloak back on after barber visit
	}


	function RetrieveLastUsedVanityItem(): SItemUniqueId
	{
		var items : array<SItemUniqueId>;
		var lastEquippedVanityItem_FlashUInt: int;
		var i: int;

		if (FactsDoesExist("SwitchableCloak_lastEquippedVanityItem")) {
			lastEquippedVanityItem_FlashUInt = FactsQuerySum("SwitchableCloak_lastEquippedVanityItem");

			thePlayer.GetInventory().GetAllItems(items);

			for (i = 0; i < items.Size(); i += 1) {
				if (ItemToFlashUInt(items[i]) == lastEquippedVanityItem_FlashUInt) {
					if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
						theGame.GetGuiManager().ShowNotification("Previously used CLOAK was FACT restored!");

					return items[i];
				}
			}

			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("Previously used CLOAK was NOT FACT found!");

			return ___RetrieveLastUsedVanityItem();
		} else {
			if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
				theGame.GetGuiManager().ShowNotification("FACTS not found.");

			return ___RetrieveLastUsedVanityItem();
		}
	}


	/* OLD KEY (backward compatibility with versions 1.4, 1.3 etc) */
	function ___RetrieveLastUsedVanityItem(): SItemUniqueId
	{
		var items : array<SItemUniqueId>;
		var lastEquippedVanityItem_FlashUInt: int;
		var i: int;

		if (FactsDoesExist("SwitchableCloak_lastEquippedCloak")) {
			lastEquippedVanityItem_FlashUInt = FactsQuerySum("SwitchableCloak_lastEquippedCloak");

			thePlayer.GetInventory().GetAllItems(items);

			for (i = 0; i < items.Size(); i += 1) {
				if (ItemToFlashUInt(items[i]) == lastEquippedVanityItem_FlashUInt) {
					return items[i];
				}
			}

			return GetInvalidUniqueId();
		} else {
			return GetInvalidUniqueId();
		}
	}


	function SaveLastUsedVanityItem(newValue: SItemUniqueId)
	{
		if (FactsDoesExist("SwitchableCloak_lastEquippedVanityItem")) {
			FactsSet("SwitchableCloak_lastEquippedVanityItem", ItemToFlashUInt(newValue));
		} else {
			FactsAdd("SwitchableCloak_lastEquippedVanityItem", ItemToFlashUInt(lastEquippedVanityItem));
		}
	}


	function SearchForVanityItem(itemsList: array<SItemUniqueId>): SItemUniqueId
	{
		var i: int;
		var _searchForHoods: bool;

		_searchForHoods = ModGetConfigValueBool('ModSwitchableCloakAllowForHoodsEtc');

		// iterate all given items
		for(i = 10; i < itemsList.Size(); i += 1) {
			// iter
			if( IsItemCloak(itemsList[i]) ) {
				// Cloak recognized, return
				if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
					theGame.GetGuiManager().ShowNotification("Vanity type is CLOAK");

				lastVanityType = vanityType;
				vanityType = VanityCloak;

				return itemsList[i];
			}

			if (_searchForHoods) {
				// Search for hoods etc too

				if( IsItemHood(itemsList[i])) {
					// Hood recognized, return
					if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
						theGame.GetGuiManager().ShowNotification("Vanity type is HOOD");

					lastVanityType = vanityType;
					vanityType = VanityHood;
					return itemsList[i];
				}
			}
		}

		// nothing found
		if (ModGetConfigValueBool('ModSwitchableCloakIsDebugEnabled'))
			theGame.GetGuiManager().ShowNotification("Vanity type is UNKNOWN");

		lastVanityType = vanityType;
		vanityType = VanityUnknown;
		return GetInvalidUniqueId();
	}


	function IsItemCloak(item: SItemUniqueId): bool
	{
		var tags : array<CName>;
		var substrings : array<string>;

		/*
			CHECK FOR CLOAKS etc.
		*/

		// fill tags
		tags.PushBack('AHW');

		// fill substrings
		substrings.PushBack("Cloak");
		substrings.PushBack("Cape");

		// check for tags (auto-hide-weapons for cloaks etc)
		if (ItemHasAnyTagFromList(item, tags)
		// check for certain substrings
		|| ItemNameContainsAnySubstring(NameToString(thePlayer.inv.GetItemName(item)), substrings))
		{
			// is toggle-able cloak/cape etc item
			return true;
		}

		// Unknown vanity type or none is equipped
		return false;
	}


	function IsItemHood(item: SItemUniqueId): bool
	{
		var tags : array<CName>;
		var substrings : array<string>;

		/*
			CHECK FOR HOODS etc.
		*/

		tags.Clear();
		substrings.Clear();

		// enable for hoods, caps, scarfs etc
		tags.PushBack('ToggleHood');
		substrings.PushBack("Hood");
		// substrings.PushBack("hood");
		substrings.PushBack("Cape");
		substrings.PushBack("Scarf");
		substrings.PushBack("Beanie");
		substrings.PushBack("Hat");
		substrings.PushBack("Mask");

		substrings.PushBack("Crach Fur Alt");
		substrings.PushBack("Crach Fur");

		// check for tags (toggle-able hoods from hoods etc)
		if (ItemHasAnyTagFromList(item, tags)
		// check for certain substrings
		|| ItemNameContainsAnySubstring(NameToString(thePlayer.inv.GetItemName(item)), substrings))
		{
			// is toggle-able hood/scarf etc item
			return true;
		}

		// Unknown vanity type or none is equipped
		return false;
	}


	function ItemHasAnyTagFromList(item: SItemUniqueId, tagsList: array<CName>): bool
	{
		var i: int;

		for(i = 0; i < tagsList.Size(); i += 1)
	    {
	        if (thePlayer.inv.ItemHasTag(item, tagsList[i]))
	        	return true;
	    }
	    return false; // No tags found
	}


	function ItemNameContainsAnySubstring(inputstring: string, substrings: array<string>): bool
	{
		var i: int;

		for(i = 0; i < substrings.Size(); i += 1)
	    {
	        if (StrContains(inputstring, substrings[i]))
	        	return true;
	    }
	    return false; // No substrings matched
	}


	/**
	* Checks the mod menu for a setting and returns its value as a string
	*
	* @nam the name of the mod menu setting to be checked
	* @return a string with the value of that setting in the mod menu
	*/
	function ModGetConfigValue(nam : name) : string
	{
		var conf: CInGameConfigWrapper;
		var value: string;
		
		conf = theGame.GetInGameConfigWrapper();
		
		value = conf.GetVarValue('ModSwitchableCloak', nam);
		return value;
	}


	function ModGetConfigValueBool(nam : name) : bool
	{
		return (bool)ModGetConfigValue(nam);
	}


	/**
	* Sets a mod menu setting to the desired value
	*
	* @nam the name of the mod menu setting to be changed
	* @value the value the mod menu setting is to be changed to
	*/
	function ModSetConfigValue(nam : name, value :string)
	{
		var conf: CInGameConfigWrapper;
		
		
		conf = theGame.GetInGameConfigWrapper();
		
		conf.SetVarValue('ModSwitchableCloak', nam,value);
	}
}