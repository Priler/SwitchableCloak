/*
	Script original author: anakmonyet
	https://next.nexusmods.com/profile/anakmonyet?gameId=952

	Next-Gen port author: ElementaryLewis
	https://next.nexusmods.com/profile/ElementaryLewis?gameId=952
*/

@addField(CR4Player)
var hood_on : bool;

@addField(CR4Player)
public var animHoodCape : string;

@addMethod(CR4Player) public function SetAnim( val : string )
{
	animHoodCape = val;
}

@addMethod(CR4Player) timer function TimerInterrupt( dt : float, it : int )
{
	GotoState('CHInterruption');
}