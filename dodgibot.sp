#pragma semicolon 1

#include <sourcemod>
#include <smlib/arrays>
#include <smlib/math>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>	
#include <morecolors>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

Handle g_botName = null;
Handle g_hCvarVoteTime;
Handle g_hMinReactionTime;
Handle g_hMaxReactionTime;
Handle g_hFlickChances;
Handle g_hCQCFlickChances;
Handle g_hBeatableBot;

Handle g_hCvarServerChatTag;
Handle g_hCvarMainChatColor;
Handle g_hCvarKeywordChatColor;
Handle g_hCvarClientChatColor;
Handle g_hCvarBeatableBotMode;
Handle g_hCvarUnbeatableBotMode;
Handle cvarShieldRadius;
Handle cvarShieldForce;
Handle g_hBotMovement;

Handle g_hAimPlayer;
Handle g_hAimChance;

int bot;
int iVotes;
int iOwner;
bool bVoted[MAXPLAYERS + 1] = {false, ...};
bool ScaryPlayer[MAXPLAYERS + 1];
bool botActivated = false;
bool HasBotFlicked = false;
bool IsBotTouched = false;
bool IsBotBeatable;
bool MapChanged;
float FlickChances[7];
float CQCFlickChances[7];
float LastDeflectionTime;
float MinReactionTime;
float MaxReactionTime;
float CurrentReactionTime;
float g_fLastActiveTime;
bool g_bBarrierActive;

char g_strServerChatTag[256];
char g_strMainChatColor[256];
char g_strKeywordChatColor[256];
char g_strClientChatColor[256];
char g_strBeatableBotMode[256];
char g_strUnbeatableBotMode[256];

new const String:laughSounds[][] = {
    "vo/mvm/norm/pyro_mvm_laugh_addl04.mp3",
    "vo/mvm/norm/pyro_mvm_laughevil01.mp3",
    "vo/mvm/norm/pyro_mvm_laughevil02.mp3"
};

new const String:deflectSounds[][] = {
    "vo/mvm/norm/pyro_mvm_niceshot01.mp3",
    "vo/mvm/norm/pyro_mvm_thanks01.mp3",
    "vo/mvm/norm/pyro_mvm_autocappedintelligence01.mp3"
};

new const String:painSounds[][] = {
    "vo/mvm/norm/pyro_mvm_painsevere03.mp3",
    "vo/mvm/norm/pyro_mvm_painsevere05.mp3",
    "vo/mvm/norm/pyro_mvm_painsharp07.mp3"
};

new g_iLaughIndex = 0;
new g_iDeflectIndex = 0;
new g_iPainIndex = 0;
new Handle:g_aShuffledLaugh = INVALID_HANDLE;
new Handle:g_aShuffledDeflect = INVALID_HANDLE;
new Handle:g_aShuffledPain = INVALID_HANDLE;
new Handle:cvarVoteMode;
new Handle:cvarVotePercentage;
new bool:bVictorySoundPlayed = false;

new rocketDeflects = 0;
new bool:allowed[MAXPLAYERS+1] = {false, ...};
new victoryType = 0;
new bool:canTrackSpeed = false;
bool g_bBotMovement = true;

int nVotes = 0;
int nVoters = 0;
int nVotesNeeded = 0;
int g_iVoteType = 0;
 
bool g_bVoteCooldown = false; 
Handle cvarVotePercent;
Handle cvarVoteCooldown;

Handle g_hVictoryDeflects;

bool g_bSuperReflectActive = false;

int g_iSuperReflectAttempts = 0;
int g_iSuperReflectTarget = -1;
int g_iRocketHitCounter = 0;

new Handle:g_hBotDifficulty = INVALID_HANDLE;

int g_iConsecutiveDeflects;

Handle g_hPredictionQuality;
 
float g_fLastPlayerPositions[MAXPLAYERS+1][3]; 
float g_fLastUpdateTime[MAXPLAYERS+1]; 
int g_iPlayerMovementPattern[MAXPLAYERS+1]; 

float g_fRocketStuckTime[2048];
bool g_bRocketStuckCheck[2048];
bool g_bRocketSuperChecked[2048];
float g_fLastRocketPos[2048][3];

float g_fLastBotCheckTime = 0.0;
float g_fBotRespawnDelay = 5.0; 

int g_iPlayerFlickSuccess[MAXPLAYERS+1][7]; 
int g_iPlayerFlickAttempts[MAXPLAYERS+1][7]; 
bool g_bHardModeActive = false; 

bool g_bDeflectsExtended = false; 
float g_fOriginalVictoryDeflects = 0.0; 
bool g_bHardModeTimerPending = false;
bool g_bInternalDeflectChange = false;

int g_iPlayerDodgeDirection[MAXPLAYERS+1]; 
int g_iPlayerDodgeCount[MAXPLAYERS+1]; 
float g_fPlayerLastDodgeTime[MAXPLAYERS+1];
float g_fPlayerAvgVelocity[MAXPLAYERS+1][3]; 

public Plugin myinfo =
{
	name = "DodgiBot",
	author = "Rem",
	description = "DodgiBot",
	version = "v1.0",
	url = ""
};

public void OnPluginStart() {
	g_botName = CreateConVar("sm_botname", "DodgiBot", "Set the bot's name.");
	
	g_hCvarVoteTime = CreateConVar("sm_bot_vote_time", "25.0", "Time in seconds the vote menu should last.", 0);
	
	g_hMinReactionTime = CreateConVar("sm_bot_reacttime_min", "100.0", "Fastest the bot can react to the rocket being airblasted, DEFAULT: 100 milliseconds.", FCVAR_PROTECTED, true, 0.00, true, 200.00);
	MinReactionTime = GetConVarFloat(g_hMinReactionTime);
	HookConVarChange(g_hMinReactionTime, OnConVarChange);
	
	g_hMaxReactionTime = CreateConVar("sm_bot_reacttime_max", "200.0", "Slowest the bot can react to the rocket being airblasted, DEFAULT: 200 milliseconds, which is average for humans.", FCVAR_PROTECTED, true, 100.00, false);
	MaxReactionTime = GetConVarFloat(g_hMaxReactionTime);
	HookConVarChange(g_hMaxReactionTime, OnConVarChange);

	g_hFlickChances = CreateConVar("sm_bot_flick_chances", "15.0 40.0 10.0 10.0 10.0 10.0 5.0", "Percentage chances (out of 100%) that the bot will do a <None Wave USpike DSpike LSpike RSpike BackShot> flick.", FCVAR_PROTECTED);
	GetConVarArray(g_hFlickChances, FlickChances, sizeof(FlickChances));
	HookConVarChange(g_hFlickChances, OnConVarChange);
	
	g_hCQCFlickChances = CreateConVar("sm_bot_flick_chances_cqc", "5.0 10.0 25.0 25.0 10.0 10.0 15.0", "Percentage chances (out of 100%) that the bot will do a <None Wave USpike DSpike LSpike RSpike BackShot> flick during close quarters combat.", FCVAR_PROTECTED);
	GetConVarArray(g_hCQCFlickChances, CQCFlickChances, sizeof(CQCFlickChances));
	HookConVarChange(g_hCQCFlickChances, OnConVarChange);
	
	g_hBeatableBot = CreateConVar("sm_bot_beatable", "0", "Is the bot beatable or not? If 1, the bot will airblast at the normal rate and will take damage. Otherwise, 0 for a bot that never dies.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
	IsBotBeatable = GetConVarBool(g_hBeatableBot);
	HookConVarChange(g_hBeatableBot, OnConVarChange);
	
	g_hCvarServerChatTag = CreateConVar("sm_bot_servertag", "{ORANGE}[DBBOT]", "Tag that appears at the start of each chat announcement.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarServerChatTag, g_strServerChatTag, sizeof(g_strServerChatTag));
	HookConVarChange(g_hCvarServerChatTag, OnConVarChange);
	g_hCvarMainChatColor = CreateConVar("sm_bot_maincolor", "{WHITE}", "Color assigned to the majority of the words in chat announcements.");
	GetConVarString(g_hCvarMainChatColor, g_strMainChatColor, sizeof(g_strMainChatColor));
	HookConVarChange(g_hCvarMainChatColor, OnConVarChange);
	g_hCvarKeywordChatColor = CreateConVar("sm_bot_keywordcolor", "{DARKOLIVEGREEN}", "Color assigned to the most important words in chat announcements.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarKeywordChatColor, g_strKeywordChatColor, sizeof(g_strKeywordChatColor));
	HookConVarChange(g_hCvarKeywordChatColor, OnConVarChange);
	g_hCvarClientChatColor = CreateConVar("sm_bot_clientwordcolor", "{TURQUOISE}", "Color assigned to the client in chat announcements.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarClientChatColor, g_strClientChatColor, sizeof(g_strClientChatColor));
	HookConVarChange(g_hCvarClientChatColor, OnConVarChange);
	g_hCvarBeatableBotMode = CreateConVar("sm_bot_beatablebot_mode", "Beatable", "Name assigned to the beatable bot mode.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarBeatableBotMode, g_strBeatableBotMode, sizeof(g_strBeatableBotMode));
	HookConVarChange(g_hCvarBeatableBotMode, OnConVarChange);
	g_hCvarUnbeatableBotMode = CreateConVar("sm_bot_unbeatablebot_mode", "Unbeatable", "Name assigned to the unbeatable bot mode.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarUnbeatableBotMode, g_strUnbeatableBotMode, sizeof(g_strUnbeatableBotMode));
	HookConVarChange(g_hCvarUnbeatableBotMode, OnConVarChange);
	
	cvarShieldRadius = CreateConVar("sm_bot_shield_radius", "200.0", "Radius of the bot's protective shield", 0, true, 50.0, true, 500.0);
	HookConVarChange(cvarShieldRadius, OnConVarChange);
	
	cvarShieldForce = CreateConVar("sm_bot_shield_force", "800.0", "Force of the shield push", 0, true, 100.0, true, 2000.0);
	HookConVarChange(cvarShieldForce, OnConVarChange);
	
	cvarVoteMode = CreateConVar("sm_bot_vote_mode", "3", "Player vs Bot voting. 0 = No voting, 1 = Generic chat vote, 2 = Menu vote, 3 = Both (Generic chat first, then Menu vote).", 0, true, 0.0, true, 3.0);
	HookConVarChange(cvarVoteMode, OnConVarChange);
	
	cvarVotePercentage = CreateConVar("sm_bot_vote_percentage", "0.60", "How many players are required for the vote to pass? 0.60 = 60%.", 0, true, 0.05, true, 1.0);
	HookConVarChange(cvarVotePercentage, OnConVarChange);
	
	g_hVictoryDeflects = CreateConVar("sm_bot_victory_deflects", "60.0", 
		"Deflects needed to win", FCVAR_NONE, true, 14.0, true, 220.0);
	HookConVarChange(g_hVictoryDeflects, OnConVarChange);
	
	HookEvent("object_deflected", OnDeflect, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);

	RegAdminCmd("sm_pvb", Command_PVB, ADMFLAG_ROOT, "Enable PVB");
	RegAdminCmd("sm_scary", Command_ScaryPlayer, ADMFLAG_ROOT, "Make rockets scared of you!");
	RegAdminCmd("sm_botmode", Command_BotModeToggle, ADMFLAG_ROOT, "Toggle bot mode (ex: from Unbeatable -> Beatable or vice-versa)");

	RegConsoleCmd("sm_votepvb", Command_VotePvB, "Vote for the PVB");
	RegConsoleCmd("sm_votedif", Command_VoteDifficulty, "Vote to change bot difficulty");
	RegConsoleCmd("sm_votedeflects", Command_VoteDeflects, "Start deflects vote");
	RegConsoleCmd("sm_votesuper", Command_VoteSuper, "Start super vote");
	RegConsoleCmd("sm_votemovement", Command_VoteMovement, "Start movement vote");

	g_hAimPlayer = CreateConVar("sm_bot_super", "1", "Should the bot aim at players instead of rockets? 1 = Yes, 0 = No", _, true, 0.0, true, 1.0);
	g_hAimChance = CreateConVar("sm_bot_super_chance", "0.0", "Probability (0.0 to 1.0) that the bot aims at players when reflecting", _, true, 0.0, true, 1.0);

	AutoExecConfig(true, "DodgiBot");

	PrecacheSound("weapons/medi_shield_deploy.wav");
	PrecacheSound("weapons/medi_shield_retract.wav");

	for(int i = 0; i < sizeof(laughSounds); i++) PrecacheSound(laughSounds[i]);
	for(int i = 0; i < sizeof(deflectSounds); i++) PrecacheSound(deflectSounds[i]);
	for(int i = 0; i < sizeof(painSounds); i++) PrecacheSound(painSounds[i]);
	
	g_aShuffledLaugh = CreateArray();
	g_aShuffledDeflect = CreateArray();
	g_aShuffledPain = CreateArray();
	
	for(int i = 0; i < sizeof(laughSounds); i++) PushArrayCell(g_aShuffledLaugh, i);
	for(int i = 0; i < sizeof(deflectSounds); i++) PushArrayCell(g_aShuffledDeflect, i);
	for(int i = 0; i < sizeof(painSounds); i++) PushArrayCell(g_aShuffledPain, i);
	
	ShuffleSounds(g_aShuffledLaugh, g_iLaughIndex);
	ShuffleSounds(g_aShuffledDeflect, g_iDeflectIndex);
	ShuffleSounds(g_aShuffledPain, g_iPainIndex);

	g_hBotMovement = CreateConVar("sm_bot_movement", "0", "Enable bot movement (1: Enabled, 0: Disabled)", _, true, 0.0, true, 1.0);
	g_bBotMovement = GetConVarBool(g_hBotMovement);
	HookConVarChange(g_hBotMovement, OnConVarChange);

	cvarVotePercent = CreateConVar("sm_pvb_votepercent", "0.6", "Percentage of votes required (0.0-1.0)", 0, true, 0.0, true, 1.0);
	cvarVoteCooldown = CreateConVar("sm_pvb_votecooldown", "60.0", "Cooldown time between votes");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	RegConsoleCmd("sm_botmenu", Command_BotMenu, "Bot Menu");

	g_hBotDifficulty = CreateConVar("sm_bot_difficulty", "0", "Bot Difficulty (0=Normal, 1=Hard)", _, true, 0.0, true, 1.0);
	SetConVarInt(g_hBotDifficulty, 0);

	g_hPredictionQuality = CreateConVar("sm_bot_prediction", "0.7", "How accurate the bot is at predicting movement (0.0-1.0)", _, true, 0.0, true, 1.0);

	HookConVarChange(g_hPredictionQuality, OnConVarChange);

	for (int i = 1; i <= MAXPLAYERS; i++) {
		g_fLastPlayerPositions[i][0] = 0.0;
		g_fLastPlayerPositions[i][1] = 0.0;
		g_fLastPlayerPositions[i][2] = 0.0;
		g_fLastUpdateTime[i] = 0.0;
		g_iPlayerMovementPattern[i] = 0;

		g_iPlayerDodgeDirection[i] = 0;
		g_iPlayerDodgeCount[i] = 0;
		g_fPlayerLastDodgeTime[i] = 0.0;
		g_fPlayerAvgVelocity[i][0] = 0.0;
		g_fPlayerAvgVelocity[i][1] = 0.0;
		g_fPlayerAvgVelocity[i][2] = 0.0;
	}

	CreateTimer(0.1, Timer_CheckStuckRockets, _, TIMER_REPEAT);
	CreateTimer(5.0, Timer_CheckBotExists, _, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("superbot");
	return APLRes_Success;
}

public void OnPluginEnd()
{
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsOurBot(i)) {
			KickClient(i, "Plugin reloaded");
			break;
		}
	}
}

public void OnConVarChange(Handle hConvar, const char[] oldValue, const char[] newValue)
{
	if(hConvar == g_hMinReactionTime)
		MinReactionTime = StringToFloat(newValue);
	if(hConvar == g_hMaxReactionTime)
		MaxReactionTime = StringToFloat(newValue);
	if (hConvar == g_hFlickChances)
		GetConVarArray(g_hFlickChances, FlickChances, sizeof(FlickChances));
	if (hConvar == g_hCQCFlickChances)
		GetConVarArray(g_hCQCFlickChances, CQCFlickChances, sizeof(CQCFlickChances));
	if (hConvar == g_hBeatableBot)
		IsBotBeatable = GetConVarBool(g_hBeatableBot);
	if (hConvar == g_hCvarServerChatTag)
		strcopy(g_strServerChatTag, sizeof(g_strServerChatTag), newValue);
	if (hConvar == g_hCvarMainChatColor)
		strcopy(g_strMainChatColor, sizeof(g_strMainChatColor), newValue);
	if (hConvar == g_hCvarKeywordChatColor)
		strcopy(g_strKeywordChatColor, sizeof(g_strKeywordChatColor), newValue);
	if (hConvar == g_hCvarClientChatColor)
		strcopy(g_strClientChatColor, sizeof(g_strClientChatColor), newValue);
	if (hConvar == g_hCvarBeatableBotMode)
		strcopy(g_strBeatableBotMode, sizeof(g_strBeatableBotMode), newValue);
	if (hConvar == g_hCvarUnbeatableBotMode)
		strcopy(g_strUnbeatableBotMode, sizeof(g_strUnbeatableBotMode), newValue);
	if (hConvar == g_hBotMovement)
		g_bBotMovement = view_as<bool>(StringToInt(newValue));
	
	if (hConvar == g_hVictoryDeflects) {
		if (!g_bInternalDeflectChange && g_bDeflectsExtended) {
			g_bDeflectsExtended = false;
		}
	}

}

void GetConVarArray(Handle convar, float[] destarr, int size)
{
    char tmp[128];
    GetConVarString(convar, tmp, sizeof(tmp));
    
    char buffer[16];
    int index = 0;
    int pos = 0;
    int len;
    
    while ((len = SplitString(tmp[pos], " ", buffer, sizeof(buffer))) != -1 && index < size)
    {
        destarr[index++] = StringToFloat(buffer);
        pos += len;
        
        while (tmp[pos] == ' ') pos++;
    }
    
    if (index < size && tmp[pos] != '\0')
    {
        destarr[index] = StringToFloat(tmp[pos]);
    }
}

public Action Command_PVB(int client, int args) {
  if (IsValidClient(client)) {
    if (!botActivated) {
      CPrintToChatAll("%s %sPlayer vs Bot is now %sactivated", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
      EnableMode();
    } else {
      CPrintToChatAll("%s %sPlayer vs Bot is now %sdisabled", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
      DisableMode();
    }
  }
  return Plugin_Handled;
}

public OnMapEnd()
{
	MapChanged = true;
}

public OnMapStart()
{
	
	CreateTimer(5.0, Timer_MapStart);
	ShuffleSounds(g_aShuffledLaugh, g_iLaughIndex);
	ShuffleSounds(g_aShuffledDeflect, g_iDeflectIndex);
	ShuffleSounds(g_aShuffledPain, g_iPainIndex);
	PrecacheSound("mvm/mvm_tank_start.wav", true);

	PrecacheModel("models/bots/scout/bot_scout.mdl", true);
	PrecacheModel("models/bots/soldier/bot_soldier.mdl", true);
	PrecacheModel("models/bots/pyro/bot_pyro.mdl", true);
	PrecacheModel("models/bots/demo/bot_demo.mdl", true);
	PrecacheModel("models/bots/heavy/bot_heavy.mdl", true);
	PrecacheModel("models/bots/engineer/bot_engineer.mdl", true);
	PrecacheModel("models/bots/medic/bot_medic.mdl", true);
	PrecacheModel("models/bots/sniper/bot_sniper.mdl", true);
	PrecacheModel("models/bots/spy/bot_spy.mdl", true);

	ResetPerformanceStats();

	ResetStuckRocketData();
}

public Action Timer_MapStart(Handle timer)
{
	MapChanged = false;
	return Plugin_Continue;
}

public Action Command_ScaryPlayer(int client, int args)
{
  if (IsValidClient(client))
  {
    if (!ScaryPlayer[client])
    {
      CPrintToChatAll("%s %sYou are now %sscary!", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
      ScaryPlayer[client] = true;
    }
    else
    {
      CPrintToChatAll("%s %sYou are no longer %sscary", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
      ScaryPlayer[client] = false;
    }
  }
  return Plugin_Handled;
}

public Action Command_BotModeToggle(int client, int args)
{
	if (IsValidClient(client))
	{
		if (!botActivated)
		{
			CReplyToCommand(client, "%s %sUnable to change Bot Mode because PvB is %sdisabled.", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
		}
		if (!IsBotBeatable)
		{
			CPrintToChatAll("%s %sBot Mode changed to %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strBeatableBotMode);
		}
		else if (IsBotBeatable)
		{
			CPrintToChatAll("%s %sBot Mode changed to %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strUnbeatableBotMode);
		}
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client) {
	ScaryPlayer[client] = false;

	if (!IsFakeClient(client))
	{
		bVoted[client] = false;
		
		int playerCount = GetAllClientCount();
		if (playerCount == 1 && !botActivated) {
			EnableMode();
		}
	}
	
}

public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	if (botActivated) {
		int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (IsValidClient(iClient) && !IsFakeClient(iClient)) {
			if (GetClientTeam(iClient) == 3) {
				ChangeClientTeam(iClient, 2);
			}
		} else if (IsFakeClient(iClient) && IsOurBot(iClient)) {
			
			bot = iClient;
			if (!IsBotBeatable)
			{
				SDKHook(bot, SDKHook_OnTakeDamage, OnTakeDamage);
			}
			
			ApplyRobotEffect(bot);
		}
	}
	return Plugin_Continue;
}

public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	if (botActivated) {
		for(int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i)) {
				if(GetClientTeam(i) > 1) {
					SetEntityHealth(i, 175);
				}
			}
		}

	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "tf_projectile_rocket", false) || !botActivated)
		return;
	
	if (StrEqual(classname, "tf_projectile_rocket"))
	{
		rocketDeflects = 0;
		canTrackSpeed = true;
		g_bRocketSuperChecked[entity] = false;

		g_fRocketStuckTime[entity] = 0.0;
		g_bRocketStuckCheck[entity] = true;
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", g_fLastRocketPos[entity]);
	}
	
	SDKHook(entity, SDKHook_StartTouch, OnStartTouchBot);
}

public void OnPreThinkBot(int entity)
{
	if (entity == bot && IsBotTouched)
	{
		float fEntityOrigin[3], fBotOrigin[3], fDistance[3], fFinalAngle[3];
		int iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE && victoryType == 0) {
			int buttons = GetClientButtons(bot);
			int iCurrentWeapon = GetEntPropEnt(bot, Prop_Send,"m_hActiveWeapon");
			int iTeamRocket = GetEntProp(iEntity, Prop_Send, "m_iTeamNum");
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
			GetClientEyePosition(bot, fBotOrigin);
			MakeVectorFromPoints(fBotOrigin, fEntityOrigin, fDistance);
			GetVectorAngles(fDistance, fFinalAngle);
			FixAngle(fFinalAngle);
		if (iTeamRocket != 3) {
				if (!IsBotBeatable || (IsBotBeatable && (LastDeflectionTime + CurrentReactionTime) <= GetEngineTime()))
				{
					
					if(g_bSuperReflectActive && IsValidClient(g_iSuperReflectTarget) && IsPlayerAlive(g_iSuperReflectTarget))
					{
						float fBotEyes[3], fTargetEyes[3], fDirection[3], fAngles[3];
						GetClientEyePosition(bot, fBotEyes);
						GetClientEyePosition(g_iSuperReflectTarget, fTargetEyes);
						
						MakeVectorFromPoints(fBotEyes, fTargetEyes, fDirection);
						GetVectorAngles(fDirection, fAngles);
						FixAngle(fAngles);
						TeleportEntity(bot, NULL_VECTOR, fAngles, NULL_VECTOR);
					}
					else
					{
						TeleportEntity(bot, NULL_VECTOR, fFinalAngle, NULL_VECTOR);
					}
				}
				if (!IsBotBeatable)
				{
					FireRate(iCurrentWeapon);
				}
				SetEntProp(entity, Prop_Data, "m_nButtons", buttons);
				IsBotTouched = false;
			}
		}
	}
	SDKUnhook(entity, SDKHook_PreThink, OnPreThinkBot);
}

public Action OnDeflect(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iEntity = GetEventInt(hEvent, "object_entindex");
	int deflector = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (botActivated) {
		iOwner = deflector;
		if (FindEntityByClassname(iEntity, "tf_projectile_rocket") && IsValidEntity(iEntity)) {
			g_bRocketSuperChecked[iEntity] = false;
			if (iOwner != bot && IsValidClient(iOwner) && IsPlayerAlive(iOwner)) {
				LastDeflectionTime = GetGameTime();
				CurrentReactionTime = GetRandomFloat(MinReactionTime/1000.0, MaxReactionTime/1000.0);
				g_iConsecutiveDeflects++;
			}
			else if (iOwner == bot) {
				g_iConsecutiveDeflects = 0;

				if (IsHardModeFullyActive()) {
					int target = TargetClient();
					if (IsValidClient(target)) {
						for (int i = 0; i < 7; i++) {
							if (g_iPlayerFlickAttempts[target][i] > 0) {
								g_iPlayerFlickSuccess[target][i]++;
								break;
							}
						}
					}
				}

				g_bSuperReflectActive = false;
				g_iSuperReflectTarget = -1;
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
  if (botActivated && victim == bot) {

  }
  return Plugin_Changed;
}

bool IsHardModeFullyActive()
{
    return (GetConVarInt(g_hBotDifficulty) == 1 && g_bHardModeActive);
}

public Action OnPlayerDeath(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
    if (botActivated) {
        int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
        if (IsValidClient(client) && GetClientTeam(client) == 2) {
            bool lastRedDead = true;
            bool botAlive = IsValidClient(bot) && IsPlayerAlive(bot);
            
            for(int i = 1; i <= MaxClients; i++) {
                if(IsClientInGame(i) && i != client && IsPlayerAlive(i) && GetClientTeam(i) == 2) {
                    lastRedDead = false;
                    break;
                }
            }
            
            if(lastRedDead && botAlive) {
                if(g_iLaughIndex >= GetArraySize(g_aShuffledLaugh)) {
                    ShuffleSounds(g_aShuffledLaugh, g_iLaughIndex);
                    g_iLaughIndex = 0;
                }
                int index = GetArrayCell(g_aShuffledLaugh, g_iLaughIndex);
                EmitSoundToAll(laughSounds[index]);
                g_iLaughIndex++;
				g_iRocketHitCounter = 0;

				FakeClientCommand(bot, "taunt");
            }
        }
        
        if(client == bot) {
            if(g_iPainIndex >= GetArraySize(g_aShuffledPain)) {
                ShuffleSounds(g_aShuffledPain, g_iPainIndex);
                g_iPainIndex = 0;
            }
            int index = GetArrayCell(g_aShuffledPain, g_iPainIndex);
            EmitSoundToAll(painSounds[index]);
            g_iPainIndex++;

			g_iRocketHitCounter = 0;
            g_bHardModeActive = false;

            if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
                g_bInternalDeflectChange = true;
                SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
                g_bInternalDeflectChange = false;
                g_bDeflectsExtended = false;
            }
        }

        if (IsValidClient(client) && !IsFakeClient(client)) {
            g_iConsecutiveDeflects = 0;
        }
    }
    return Plugin_Continue;
}

public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	if (botActivated) {

        g_iRocketHitCounter = 0;
        g_bHardModeActive = false;

        if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
            g_bInternalDeflectChange = true;
            SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
            g_bInternalDeflectChange = false;
            g_bDeflectsExtended = false;
        }

	}
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	
	if (botActivated) {
		if (MapChanged) DisableMode();
		
		int playerCount = GetAllClientCount();

		if (playerCount == 0) {
			if (client == bot && IsValidClient(bot) && IsPlayerAlive(bot)) {
				LookAtControlPoint();
			}
			return Plugin_Continue;
		}
		
		int iClient = ChooseClient();
		if (IsValidClient(iClient) && IsPlayerAlive(iClient) && IsPlayerAlive(bot) && IsValidClient(client)) 
		{
			if (client == iClient) {
				ManeuverBotAgainstClient(client);
			}
			else if (client == bot)
			{
				if (IsBotBeatable && (LastDeflectionTime + CurrentReactionTime) > GetEngineTime())
				{
					return Plugin_Continue;
				}
				if (GetConVarFloat(g_hVictoryDeflects) != 0 && rocketDeflects >= GetConVarFloat(g_hVictoryDeflects) && !allowed[client])
				{
					victoryType = 1;
					buttons &= ~IN_ATTACK2;
					return Plugin_Changed;
				}
				if (GetConVarFloat(g_hVictoryDeflects) != 0 && rocketDeflects < GetConVarFloat(g_hVictoryDeflects) && !allowed[client])
				{
					victoryType = 0;
					AutoReflect(iClient, buttons, -1);

					if (g_bBotMovement) {
						int targetButtons = GetClientButtons(iClient);
						if (targetButtons & IN_JUMP) {
							buttons |= IN_JUMP;
						}
						if (targetButtons & IN_DUCK) {
							buttons |= IN_DUCK;
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

public void ManeuverBotAgainstClient(int client) {
	if (!g_bBotMovement) return;
	
	float client_position[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", client_position);
	
	float bot_position[3];
	GetEntPropVector(bot, Prop_Send, "m_vecOrigin", bot_position);
	
	float spawner_position[3];
	int entity_id = -1;
	while((entity_id = FindEntityByClassname(entity_id, "info_target")) != -1) {
		char entity_name[50];
		GetEntPropString(entity_id, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
		
		if(strcmp(entity_name, "rocket_spawn_blue", false) == 0) {
			break;
		}
	}
	GetEntPropVector(entity_id, Prop_Send, "m_vecOrigin", spawner_position);
	
	float endpoint[3]; 
	endpoint[0] = (2 * spawner_position[0]) - client_position[0];
	endpoint[1] = (2 * spawner_position[1]) - client_position[1];
	endpoint[2] = bot_position[2];
	
	float fVelocity[3];
	MakeVectorFromPoints(bot_position, endpoint, fVelocity);
	NormalizeVector(fVelocity, fVelocity);
	ScaleVector(fVelocity, 500.0);
	
	fVelocity[2] = 0.0;

	if(GetVectorDistance(endpoint, bot_position) < 20) {
		ScaleVector(fVelocity, 0.0);
	} else if(GetVectorDistance(endpoint, bot_position) < 30) {
		ScaleVector(fVelocity, 0.2);
	} else if(GetVectorDistance(endpoint, bot_position) < 50) {
		ScaleVector(fVelocity, 0.5);
	}
	TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, fVelocity);
}

public void OnClientDisconnect(int client) {
  if (IsFakeClient(client)) return;
  if (bVoted[client]) nVotes--;
  nVoters--;
  nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
    ScaryPlayer[client] = false;
    if (bVoted[client]) {
        if (iVotes > 0) {
            iVotes -= 1;
        }
        bVoted[client] = false;
    }
    
    int playerCount = GetAllClientCount();
    
    if (playerCount == 0 && botActivated) {
        DisableMode();
    }
}

stock void EnableMode() {
	CreateSuperbot();
	ChangeTeams();
	botActivated = true; 
 
	g_fLastBotCheckTime = GetGameTime(); 
}

stock void CreateSuperbot() {
	char botname[255];
	GetConVarString(g_botName, botname, sizeof(botname));

	ServerCommand("sm_manaosrobot_default 1");
	ServerCommand("mp_autoteambalance 0");
	ServerCommand("sv_cheats 1"); 

	ServerCommand("bot -team blue -class pyro -name \"%s\"", botname);

	CreateTimer(0.5, Timer_ConfigurePuppetBot);
}

stock void DisableMode() {
	ServerCommand("mp_autoteambalance 1");

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsOurBot(i)) {
			KickClient(i, "Bot deactivated");
			break; 
		}
	}
	
	for (int i = 1; i <= MaxClients; i++) {
		if (bVoted[i]) {
			bVoted[i] = false;
		}
	}
	iVotes = 0;
	botActivated = false;
	bot = 0; 
	g_fLastBotCheckTime = 0.0; 
}

stock int GetAllClientCount() {
	int count = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1) {
			count += 1;
		}
	}
	return count;
}

stock bool IsOurBot(int client) {
	if (!IsValidClient(client)) return false;
	if (!IsFakeClient(client)) return false;
	
	char botName[64];
	GetConVarString(g_botName, botName, sizeof(botName));
	
	char clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	
	return StrEqual(clientName, botName, false);
}

void ApplyRobotEffect(int client) {
	if (!IsValidClient(client)) return;
	
	TFClassType class = TF2_GetPlayerClass(client);
	char classname[16];
	
	switch(class) {
		case TFClass_Scout: strcopy(classname, sizeof(classname), "scout");
		case TFClass_Soldier: strcopy(classname, sizeof(classname), "soldier");
		case TFClass_Pyro: strcopy(classname, sizeof(classname), "pyro");
		case TFClass_DemoMan: strcopy(classname, sizeof(classname), "demo");
		case TFClass_Heavy: strcopy(classname, sizeof(classname), "heavy");
		case TFClass_Engineer: strcopy(classname, sizeof(classname), "engineer");
		case TFClass_Medic: strcopy(classname, sizeof(classname), "medic");
		case TFClass_Sniper: strcopy(classname, sizeof(classname), "sniper");
		case TFClass_Spy: strcopy(classname, sizeof(classname), "spy");
		default: return;
	}
	
	char model[PLATFORM_MAX_PATH];
	Format(model, sizeof(model), "models/bots/%s/bot_%s.mdl", classname, classname);
	
	if (IsModelPrecached(model)) {
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	}
}

stock void ChangeTeams() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			if (i != bot && GetClientTeam(i) == 3) {
				ChangeClientTeam(i, 2);
			}
		}
	}
}

stock void FollowClient(int client, int &buttons)
{
    float fOriginPlayer[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", fOriginPlayer);
    fOriginPlayer[2] = 300.0;
    NegateVector(fOriginPlayer);
    
    if ((buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT)))
    {
        TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, fOriginPlayer);
    }
}

public Action AutoReflect(int client, int &buttons, int iEntity)
{
    if (!IsValidClient(client))
        return Plugin_Continue;
    
    float fEntityOrigin[3], fBotOrigin[3], fEnemyOrigin[3], fRocketDistance[3], fFinalAngle[3], fEnemyDistCQC, fRocketDistAuto;

    while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
    {

        int iTeamRocket = GetEntProp(iEntity,	Prop_Send, "m_iTeamNum");
        GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
        GetClientEyePosition(bot, fBotOrigin);
        MakeVectorFromPoints(fBotOrigin, fEntityOrigin, fRocketDistance);
        int target = TargetClient();
        if (IsValidClient(target)) {
            GetClientEyePosition(target, fEnemyOrigin);
        } else {
            return Plugin_Continue;
        }
        GetVectorAngles(fRocketDistance, fFinalAngle);
        fRocketDistAuto = GetVectorDistance(fBotOrigin, fEntityOrigin, false);
        fEnemyDistCQC = GetVectorDistance(fBotOrigin, fEnemyOrigin, false);
        
        float fRocketVelocity[3];
        GetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fRocketVelocity);

        float AIRBLAST_RANGE = 256.0;   

        float fBotForward[3], fBotAngles[3];
        GetClientEyeAngles(bot, fBotAngles);
        GetAngleVectors(fBotAngles, fBotForward, NULL_VECTOR, NULL_VECTOR);
        
        float fToRocket[3];
        MakeVectorFromPoints(fBotOrigin, fEntityOrigin, fToRocket);
        NormalizeVector(fToRocket, fToRocket);
        
        float dotProduct = GetVectorDotProduct(fBotForward, fToRocket);
        bool bRocketInFront = (dotProduct > 0.0); 

        if (fRocketDistAuto < 400.0 && fRocketDistAuto >= AIRBLAST_RANGE && iTeamRocket != 3)
        {
            if(!g_bSuperReflectActive && !g_bRocketSuperChecked[iEntity] && GetConVarInt(g_hAimPlayer) == 1)
            {
                g_bRocketSuperChecked[iEntity] = true;
                if (GetRandomFloat() <= GetConVarFloat(g_hAimChance))
                {
                    int superTarget = TargetClient();
                    if(IsValidClient(superTarget) && IsPlayerAlive(superTarget))
                    {
                        g_bSuperReflectActive = true;
                        g_iSuperReflectTarget = superTarget;
                        g_iSuperReflectAttempts = 0; 
                    }
                }
            }
        }

        if (fRocketDistAuto < AIRBLAST_RANGE && iTeamRocket != 3)
        {
            if (!IsBotBeatable)
            {
                int iCurrentWeapon2 = GetEntPropEnt(bot, Prop_Send,"m_hActiveWeapon");
                if(IsValidEntity(iCurrentWeapon2)) FireRate(iCurrentWeapon2);
            }

            if(g_bSuperReflectActive && !bRocketInFront)
            {
                g_iSuperReflectAttempts++;
                if(g_iSuperReflectAttempts >= 1)
                {
                    
                    g_bSuperReflectActive = false;
                    g_iSuperReflectTarget = -1;
                    g_iSuperReflectAttempts = 0;
                }
            }
            
            if(g_bSuperReflectActive && IsValidClient(g_iSuperReflectTarget) && IsPlayerAlive(g_iSuperReflectTarget))
            {
                float fBotEyes[3], fTargetEyes[3], fDirection[3], fAngles[3];
                GetClientEyePosition(bot, fBotEyes);
                GetClientEyePosition(g_iSuperReflectTarget, fTargetEyes);
                
                MakeVectorFromPoints(fBotEyes, fTargetEyes, fDirection);
                GetVectorAngles(fDirection, fAngles);
                
                FixAngle(fAngles);
                TeleportEntity(bot, NULL_VECTOR, fAngles, NULL_VECTOR);
            }
            else
            {
                
                FixAngle(fFinalAngle);
                
                float fDeviationAngle[3];
                fDeviationAngle[0] = fFinalAngle[0] + GetRandomFloat(-3.0, 5.0);
                fDeviationAngle[1] = fFinalAngle[1] + GetRandomFloat(-15.0, 15.0);
                fDeviationAngle[2] = 0.0;
                
                if(fDeviationAngle[0] > 45.0) fDeviationAngle[0] = 45.0;
                if(fDeviationAngle[0] < -45.0) fDeviationAngle[0] = -45.0;
                
                FixAngle(fDeviationAngle);
                TeleportEntity(bot, NULL_VECTOR, fDeviationAngle, NULL_VECTOR);
            }
            
            buttons |= IN_ATTACK2;
            HasBotFlicked = false;
        }
        else
        {
            
            if (!HasBotFlicked && fRocketDistAuto < 500000.0)
            {
                if (!(GetRandomFloat() <= (FlickChances[0] / 100)))
                {
                    if (fEnemyDistCQC < 500.0)
                    {
                        GetFlickAngle(bot, iEntity, fFinalAngle, true);
                    }
                    else
                    {
                        GetFlickAngle(bot, iEntity, fFinalAngle, false);
                    }
                }
                FixAngle(fFinalAngle);
                TeleportEntity(bot, NULL_VECTOR, fFinalAngle, NULL_VECTOR);
                HasBotFlicked = true;
            }
            else
            {
                FixAngle(fFinalAngle);
                TeleportEntity(bot, NULL_VECTOR, fFinalAngle, NULL_VECTOR);
            }
        }
    }
    if ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) == INVALID_ENT_REFERENCE)
    {
        
        int targetPlayer = TargetClient();
        if (IsValidClient(targetPlayer) && IsPlayerAlive(targetPlayer)) {
            AimClient(targetPlayer);
        }
    }

    return Plugin_Continue;
}

stock void LerpVectors(const float start[3], const float end[3], float result[3], float t) {
    result[0] = start[0] + (end[0] - start[0]) * t;
    result[1] = start[1] + (end[1] - start[1]) * t;
    result[2] = start[2] + (end[2] - start[2]) * t;
}

public Action OnStartTouchBot(int entity, int other)
{
    if (victoryType == 1)
        return Plugin_Continue;
	
	if ((other == bot || ScaryPlayer[other]) && entity != INVALID_ENT_REFERENCE)
	{
		SDKHook(entity, SDKHook_Touch, OnTouchBot);
		return Plugin_Continue;
	}
	else if (entity == INVALID_ENT_REFERENCE)
	{
		SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchBot);
	}
	
	return Plugin_Continue;
}

public Action OnTouchBot(int entity, int other)
{
    if (victoryType == 1)
        return Plugin_Continue;
	
	int iCurrentWeapon = GetEntPropEnt(other, Prop_Send, "m_hActiveWeapon");
	float m_flNextSecondaryAttack = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextSecondaryAttack");
	float fGameTime = GetGameTime();
	if (m_flNextSecondaryAttack > fGameTime)
	{
        if (other == bot && IsValidEntity(entity))
        {

            char classname[64];
            GetEntityClassname(entity, classname, sizeof(classname));

            if (StrEqual(classname, "tf_projectile_rocket", false))
            {
                g_bRocketStuckCheck[entity] = true;
                g_fRocketStuckTime[entity] = GetGameTime();
                GetEntPropVector(entity, Prop_Data, "m_vecOrigin", g_fLastRocketPos[entity]);
            }
        }

		SDKUnhook(entity, SDKHook_Touch, OnTouchBot);
		return Plugin_Handled;
	}
	
	float vec[3];
	float botAngles[3];
	
	if (other == bot)
	{
		GetClientEyeAngles(bot, botAngles);
		
		float dirVector[3];
		GetAngleVectors(botAngles, dirVector, NULL_VECTOR, NULL_VECTOR);
		
		ScaleVector(dirVector, 1000.0);
		
		vec[0] = dirVector[0] + GetRandomFloat(-100.0, 100.0);
		vec[1] = dirVector[1] + GetRandomFloat(-100.0, 100.0);
		vec[2] = dirVector[2] + GetRandomFloat(-50.0, 150.0);
		
		float speed = GetVectorLength(vec);
		if (speed < 800.0)
		{
			NormalizeVector(vec, vec);
			ScaleVector(vec, 800.0);
		}
	}
	else
	{
		vec[0] = GetRandomFloat(-200.0, 200.0);
		vec[1] = GetRandomFloat(-200.0, 200.0);
		vec[2] = GetRandomFloat(100.0, 300.0);
	}
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vec);
	IsBotTouched = true;
	if (other == bot)
	{
		SDKHook(other, SDKHook_PreThink, OnPreThinkBot);
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouchBot);

    g_bRocketStuckCheck[entity] = false;

	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, any data)
{
	return (entity != data);
}

stock int ChooseClient() {
	
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_rocket")) != -1) {
		if (IsValidEntity(iEntity)) {
			int owner = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
			if (IsValidClient(owner) && IsPlayerAlive(owner) && !IsFakeClient(owner) && GetClientTeam(owner) == 2) {
				return owner; 
			}
		}
	}
	
	return TargetClient();
}

stock int TargetClient() {
	int iPlayer = -1;
	float fClosestDistance = -1.0;
	float fPlayerOrigin[3], fBotLocation[3];
	
	if (!IsValidClient(bot))
		return -1;
	
	GetClientAbsOrigin(bot, fBotLocation);
	
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && 
			IsPlayerAlive(i) && 
			!IsFakeClient(i) && 
			GetClientTeam(i) == 2) {
			GetClientAbsOrigin(i, fPlayerOrigin);
			float fDistance = GetVectorDistance(fBotLocation, fPlayerOrigin);
			
			if (fDistance < fClosestDistance || fClosestDistance == -1.0) {
				fClosestDistance = fDistance;
				iPlayer = i;
			}
		}
	}
	return iPlayer;
}

stock int GetClosestClient() {
	int iPlayer = -1;
	float fPlayerOrigin[3], fBotLocation[3], fClosestDistance = -1.0, fDistance;
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i) && IsValidClient(bot) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
			GetClientAbsOrigin(i, fPlayerOrigin);
			GetClientAbsOrigin(bot, fBotLocation);
			fDistance = GetVectorDistance(fBotLocation, fPlayerOrigin);
			if ((fDistance < fClosestDistance) || fClosestDistance == -1.0) {
				fClosestDistance = fDistance;
				iPlayer = i;
			}
		}
	}
	return iPlayer;
}

stock void AimClient(int client) {
	float fLocationPlayer[3], fLocationBot[3], fLocationPlayerFinal[3], fLocationAngle[3];
	GetClientAbsOrigin(bot, fLocationBot);
	GetClientAbsOrigin(client, fLocationPlayer);
	MakeVectorFromPoints(fLocationBot, fLocationPlayer, fLocationPlayerFinal);
	GetVectorAngles(fLocationPlayerFinal, fLocationAngle);
	FixAngle(fLocationAngle);
	TeleportEntity(bot, NULL_VECTOR, fLocationAngle, NULL_VECTOR);
}

stock void LookAtControlPoint() {
	if (!IsValidClient(bot)) return;
	
	float botPos[3], cpPos[3];
	GetClientAbsOrigin(bot, botPos);

	int cpEntity = FindEntityByClassname(-1, "team_control_point");
	if (cpEntity != -1) {
		GetEntPropVector(cpEntity, Prop_Send, "m_vecOrigin", cpPos);
	} else {
		
		int entity_id = -1;
		while((entity_id = FindEntityByClassname(entity_id, "info_target")) != -1) {
			char entity_name[50];
			GetEntPropString(entity_id, Prop_Data, "m_iName", entity_name, sizeof(entity_name));
			if(strcmp(entity_name, "rocket_spawn_red", false) == 0) {
				GetEntPropVector(entity_id, Prop_Send, "m_vecOrigin", cpPos);
				break;
			}
		}
	}

	float direction[3], angles[3];
	MakeVectorFromPoints(botPos, cpPos, direction);
	GetVectorAngles(direction, angles);
	FixAngle(angles);
	TeleportEntity(bot, NULL_VECTOR, angles, NULL_VECTOR);
}

stock void FireRate(int weapon) {
	float m_flNextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
	float m_flNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 10.0);
	float fGameTime = GetGameTime();

	float fTimePrimary = (m_flNextPrimaryAttack - fGameTime) - 0.99;
	float fTimeSecondary = (m_flNextSecondaryAttack - fGameTime) - 0.99;
	float fFinalPrimary = fTimePrimary + fGameTime;
	float fFinalSecondary = fTimeSecondary + fGameTime;

	SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", fFinalPrimary);
	SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", fFinalSecondary);
}

stock void FixAngle(float Angle[3]) {
	if (Angle[0] >= 90.0) {
		Angle[0] -= 360.0;
	}
}

public void AnglesNormalize(float vAngles[3])
{
	while(vAngles[0] > 89.0) vAngles[0] -= 360.0;
	while(vAngles[0] < -89.0) vAngles[0] += 360.0;
	while(vAngles[1] > 180.0) vAngles[1] -= 360.0;
	while(vAngles[1] < -180.0) vAngles[1] += 360.0;
}

stock float GetAngleX(const float coords1[3], const float coords2[3])
{
	float angle = RadToDeg(ArcTangent((coords2[1] - coords1[1]) / (coords2[0] - coords1[0])));
	if (coords2[0] < coords1[0])
	{
	if (angle > 0.0) angle -= 180.0;
	else angle += 180.0;
	}
	return angle;
}

public float AngleDistance(const float angle1, const float angle2, bool YAxis)
{
	float tempAng1 = angle1;
	float tempAng2 = angle2;
	float distance;
	if (!YAxis)
	{
		if (tempAng1 < 0.0)
			tempAng1 += 360.0;
		if (tempAng2 < 0.0)
			tempAng2 += 360.0;
		if(tempAng1 >= tempAng2) {
			distance = FloatAbs(tempAng1 - tempAng2);
		} else {
			distance = FloatAbs(tempAng2 - tempAng1);
		}
    }
	else
	{
		if (tempAng1 < 0.0 || tempAng2 < 0.0)
		{
			tempAng1 += 360.0;
			tempAng2 += 360.0;
		}
		if(tempAng1 >= tempAng2) {
 			distance = FloatAbs(tempAng1 - tempAng2);
		} else {
			distance = FloatAbs(tempAng2 - tempAng1);
		}
	}
	return distance;
}

public GetFlickAngle(int entity, int rocket, float angles[3], bool cqc)
{
	float flickChances[7];
	if (cqc)
	{
		Array_Copy(CQCFlickChances, flickChances, 7);
	}
	else
	{
		Array_Copy(FlickChances, flickChances, 7);
	}

	float fEntityOrigin[3], fBotOrigin[3], fEnemyOrigin[3];
	GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", fEntityOrigin);
	GetClientEyePosition(bot, fBotOrigin);

	int target = TargetClient();
	bool hasValidTarget = false;

	if (IsValidClient(target)) {
		hasValidTarget = true;
		GetClientEyePosition(target, fEnemyOrigin);

		if (IsHardModeFullyActive() && hasValidTarget) {

		int totalAttempts = 0;

			for (int i = 0; i < 7; i++) {
				totalAttempts += g_iPlayerFlickAttempts[target][i];
			}

			if (totalAttempts >= 5) {

				for (int i = 0; i < 7; i++) {
					if (g_iPlayerFlickAttempts[target][i] > 0) {
						float successRate = float(g_iPlayerFlickSuccess[target][i]) / float(g_iPlayerFlickAttempts[target][i]);

						flickChances[i] = flickChances[i] * (1.0 + successRate * 2.0);
					}
				}

				float totalProb = 0.0;
				for (int i = 0; i < 7; i++) {
					totalProb += flickChances[i];
				}

				if (totalProb > 0.0) {
					for (int i = 0; i < 7; i++) {
						flickChances[i] = (flickChances[i] / totalProb) * 100.0;
					}
				}

				int selectedFlick = ChooseFlickBasedOnChances(flickChances);
				g_iPlayerFlickAttempts[target][selectedFlick]++;

				ApplySelectedFlick(entity, rocket, angles, selectedFlick);

				return;
			}
		}
	}

	if (hasValidTarget && g_iPlayerDodgeCount[target] >= 2) {
		
		int dodgeDir = g_iPlayerDodgeDirection[target];
		
		if (dodgeDir == -1) {
			
			flickChances[5] *= 2.0; 
			flickChances[4] *= 0.5; 
		} else if (dodgeDir == 1) {
			
			flickChances[4] *= 2.0; 
			flickChances[5] *= 0.5; 
		}

		float totalProb = 0.0;
		for (int i = 0; i < 7; i++) {
			totalProb += flickChances[i];
		}
		if (totalProb > 0.0) {
			for (int i = 0; i < 7; i++) {
				flickChances[i] = (flickChances[i] / totalProb) * 100.0;
			}
		}
	}

	int selectedFlick = ChooseFlickBasedOnChances(flickChances);

	if (hasValidTarget) {
		g_iPlayerFlickAttempts[target][selectedFlick]++;
	}

	ApplySelectedFlick(entity, rocket, angles, selectedFlick);
}

int ChooseFlickBasedOnChances(float flickChances[7])
{
	float fRand = GetRandomFloat(0.0, 100.0);
	float accumChance = 0.0;

	for (int i = 0; i < 7; i++) {
		accumChance += flickChances[i];
		if (fRand <= accumChance) {
			return i;
		}
	}

	return 0; 
}

void ApplySelectedFlick(int entity, int rocket, float angles[3], int flickType)
{

	switch (flickType) {
		case 0: {

		}
		case 1: {

			float fLocationPlayer[3], fLocationPlayerFinal[3], fEntityOrigin[3];
		GetClientAbsOrigin(entity, fLocationPlayer);
			GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", fEntityOrigin);
		MakeVectorFromPoints(fEntityOrigin, fLocationPlayer, fLocationPlayerFinal);
		GetVectorAngles(fLocationPlayerFinal, angles);
	}
		case 2: {

		angles[0] = -89.00;
	}
		case 3: {

			if (angles[0] <= 50.00 && angles[0] >= 0.00) {
			angles[0] = 89.00;
		}
	}
		case 4: {

		angles[1] += 90.0;
	}
		case 5: {

		angles[1] -= 90.0;
	}
		case 6: {

		angles[1] += 180.0;
		}
	}
}

stock bool IsValidClient(int client) {
	return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

stock void UpdateBarrier(int botClient)
{
	if (!IsValidClient(botClient) || !IsPlayerAlive(botClient)) return;
	
	float botPos[3];
	GetClientAbsOrigin(botClient, botPos);
	botPos[2] += 10.0;
	
	float radius = GetConVarFloat(cvarShieldRadius);
	float activationRadius = radius + 200.0;
	float currentTime = GetGameTime();
	
	bool playerInRadius = false;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client)) continue;
		
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		if (GetVectorDistance(botPos, clientPos) <= activationRadius)
		{
			playerInRadius = true;
			break;
		}
	}
	
	if (playerInRadius)
	{
		g_fLastActiveTime = currentTime;
		if (!g_bBarrierActive)
		{
			g_bBarrierActive = true;
			StopSound(botClient, SNDCHAN_STATIC, "weapons/medi_shield_retract.wav");
			EmitSoundToAll("weapons/medi_shield_deploy.wav", botClient, SNDCHAN_STATIC, 140, _, 1.0);
		}
	}
	else if (g_bBarrierActive && (currentTime - g_fLastActiveTime > 5.0))
	{
		g_bBarrierActive = false;
		EmitSoundToAll("weapons/medi_shield_retract.wav", botClient, SNDCHAN_STATIC, 140, _, 1.0);
	}
	
	if (g_bBarrierActive)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (!IsValidClient(client) || IsFakeClient(client)) continue;
			
			TE_Start("BeamRingPoint");
			TE_WriteVector("m_vecCenter", botPos);
			TE_WriteFloat("m_flStartRadius", radius * 2 - 10.0);
			TE_WriteFloat("m_flEndRadius", radius * 2);
			TE_WriteNum("m_nModelIndex", PrecacheModel("sprites/laserbeam.vmt"));
			TE_WriteNum("m_nHaloIndex", 0);
			TE_WriteNum("m_nStartFrame", 0);
			TE_WriteNum("m_nFrameRate", 0);
			TE_WriteFloat("m_fLife", 0.3);
			TE_WriteFloat("m_fWidth", 5.0);
			TE_WriteFloat("m_fEndWidth", 5.0);
			TE_WriteNum("r", 0);
			TE_WriteNum("g", 127);
			TE_WriteNum("b", 255);
			TE_WriteNum("a", 100);
			TE_WriteNum("m_nFlags", 0);
			TE_SendToClient(client);
		}
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client)) continue;
		
		float clientPos[3];
		GetClientAbsOrigin(client, clientPos);
		float distance = GetVectorDistance(botPos, clientPos);
		
		if (distance > radius || GetClientTeam(client) == GetClientTeam(botClient)) continue;
		
		float pushDir[3];
		SubtractVectors(clientPos, botPos, pushDir);
		pushDir[2] = 0.0;
		NormalizeVector(pushDir, pushDir);
		
		float forceMultiplier = 1.0 - (distance / radius);
		float currentForce = GetConVarFloat(cvarShieldForce) * forceMultiplier;
		
		float currentVelocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", currentVelocity);
		currentVelocity[0] += pushDir[0] * currentForce;
		currentVelocity[1] += pushDir[1] * currentForce;
		currentVelocity[2] += pushDir[2] * currentForce;
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, currentVelocity);
	}
}

stock int GetRealClientCount(bool countBots = false)
{
    int clients = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && (countBots || !IsFakeClient(i)) && GetClientTeam(i) > 1)
        {
            clients++;
        }
    }
    return clients;
}

public void OnGameFrame()
{
	new rocket = FindEntityByClassname(-1, "tf_projectile_rocket");
	if (IsValidEntity(rocket) && victoryType == 0)
	{
		if (canTrackSpeed)
		{
			canTrackSpeed = false;
			decl Float:entityVelocity[3];
			GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", entityVelocity);
		}
		
		new rDeflects = GetEntProp(rocket, Prop_Send, "m_iDeflected") - 1;
		if (rDeflects > rocketDeflects)
		{
			rocketDeflects++;
			canTrackSpeed = true;
			
			if (IsHardModeFullyActive() && !g_bDeflectsExtended) {
				float currentVictoryDeflects = GetConVarFloat(g_hVictoryDeflects);
				
				if (rocketDeflects >= currentVictoryDeflects * 0.8) {
					g_fOriginalVictoryDeflects = currentVictoryDeflects;
					
					float newLimit = currentVictoryDeflects + 20.0;
					SetConVarFloat(g_hVictoryDeflects, newLimit);
					g_bDeflectsExtended = true;
					
					CPrintToChatAll("%s %sDeflects extended to %s%.0f", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, newLimit);
					
					EmitSoundToAll("mvm/mvm_tank_start.wav");
				}
			}
		}
	}
	
	if (victoryType == 1 && !bVictorySoundPlayed)
	{
		new currentBot = FindBot();
		new iRocket = FindRocketNearBot(currentBot, 100.0);
		
		if (iRocket != -1 && IsValidEntity(iRocket))
		{
			decl Float:rocketPos[3], Float:botPos[3];
			GetEntPropVector(iRocket, Prop_Data, "m_vecOrigin", rocketPos);
			
			GetClientAbsOrigin(currentBot, botPos);
			
			if (GetVectorDistance(rocketPos, botPos) < 100.0)
			{
				
				if(g_iDeflectIndex >= GetArraySize(g_aShuffledDeflect))
				{
					ShuffleSounds(g_aShuffledDeflect, g_iDeflectIndex);
				}
				new deflectIndex = GetArrayCell(g_aShuffledDeflect, g_iDeflectIndex);
				EmitSoundToAll(deflectSounds[deflectIndex]);
				g_iDeflectIndex++;
				bVictorySoundPlayed = true;

				int aliveRedPlayers = 0;
				for (int i = 1; i <= MaxClients; i++) {
					if (IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2) {
						aliveRedPlayers++;
					}
				}

				if(aliveRedPlayers == 1 && GetConVarInt(g_hBotDifficulty) == 1 && !g_bHardModeTimerPending && g_iRocketHitCounter < 2)
				{
					g_bHardModeTimerPending = true;
					g_iRocketHitCounter++;
					
					if(g_iRocketHitCounter == 1) {
						g_bHardModeActive = true;
						g_fOriginalVictoryDeflects = GetConVarFloat(g_hVictoryDeflects);
					}

					CreateTimer(2.0, Timer_AddHardModeDeflects, g_iRocketHitCounter);
				}
			}
		}
	}
	
	if (victoryType != 1)
	{
		bVictorySoundPlayed = false;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		
		if (client == bot && IsValidClient(client) && IsPlayerAlive(client))
		{
			UpdateBarrier(client);
		}
	}

	static float lastAnalysisUpdate = 0.0;
	float currentTime = GetGameTime();
	
	if (currentTime - lastAnalysisUpdate > 0.5) {
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i) && !IsFakeClient(i) && IsPlayerAlive(i)) {
				float currentPos[3];
				GetClientAbsOrigin(i, currentPos);
				UpdateMovementAnalysis(i, currentPos);
			}
		}
		lastAnalysisUpdate = currentTime;
	}
}

stock FindRocketNearBot(int botClient, float radius)
{

    if (!IsValidClient(botClient)) {
        return -1;
    }

    float fBotPos[3];
    GetClientAbsOrigin(botClient, fBotPos);
    
    int iEntity = -1;
    while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_rocket")) != -1)
    {
        if (!IsValidEntity(iEntity)) continue;
        
        float fRocketPos[3];
        GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fRocketPos);
        if (GetVectorDistance(fBotPos, fRocketPos) <= radius)
            return iEntity;
    }
    return -1;
}

stock FindBot()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return -1;
}

stock bool:IsClientBot(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client);
}

ShuffleSounds(Handle:array, &index)
{
    new size = GetArraySize(array);
    for(new i = size - 1; i > 0; i--)
    {
        new j = GetRandomInt(0, i);
        SwapArrayItems(array, i, j);
    }
    index = 0;
}

public Action Command_VotePvB(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", 
            g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (bVoted[client]) {
        CReplyToCommand(client, "%s %sYou already voted.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    nVotes++;
    bVoted[client] = true;
    
    if (!botActivated)
    {
        CPrintToChatAll("%s %s%s wants to enable PvB. (%d/%d votes)", 
            g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
    }
    else
    {
        CPrintToChatAll("%s %s%s wants to disable PvB. (%d/%d votes)", 
            g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
    }
    
    if (nVotes >= nVotesNeeded)
    {
        if (!botActivated)
        {
            CPrintToChatAll("%s %sEnabling PvB!", 
                g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
            botActivated = true;
            IsBotBeatable = false;
            EnableMode();
        }
        else
        {
            CPrintToChatAll("%s %sDisabling PvB.", 
                g_strServerChatTag, g_strMainChatColor);
            botActivated = false;
            DisableMode();
        }
        ResetVotes();
        CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
    }
    return Plugin_Handled;
}

public Action Timer_ResetVote(Handle timer)
{
    g_bVoteCooldown = false;
    return Plugin_Continue;
}

void ResetVotes()
{
    nVotes = 0;
    for (int i = 1; i <= MaxClients; i++) bVoted[i] = false;
}

public void OnClientConnected(int client)
{
    if (IsFakeClient(client)) return;
    bVoted[client] = false;
    nVoters++;
    nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
}

public Action Command_Say(int client, const char[] command, int argc)
{
    if (!client || IsChatTrigger()) return Plugin_Continue;
    
    char sMessage[256];
    GetCmdArgString(sMessage, sizeof(sMessage));
    StripQuotes(sMessage);
    TrimString(sMessage);
    
    char sLowerMessage[256];
    strcopy(sLowerMessage, sizeof(sLowerMessage), sMessage);
    String_ToLower(sLowerMessage);

    if (StrEqual(sLowerMessage, "!votepvb") || StrEqual(sLowerMessage, "/votepvb"))
    {
        FakeClientCommand(client, "sm_votepvb");
        return Plugin_Handled;
    }
    else if (StrEqual(sLowerMessage, "!votedif") || StrEqual(sLowerMessage, "/votedif"))
    {
        FakeClientCommand(client, "sm_votedif");
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

stock void String_ToLower(char[] str)
{
    int len = strlen(str);
    for (int i = 0; i < len; i++)
    {
        str[i] = CharToLower(str[i]);
    }
}

public Action Timer_AddHardModeDeflects(Handle timer, int hitNumber)
{
    g_bHardModeTimerPending = false;
    
    if(GetConVarInt(g_hBotDifficulty) != 1 || !botActivated)
        return Plugin_Continue;
    
    float currentDeflects = GetConVarFloat(g_hVictoryDeflects);
    float newLimit = currentDeflects + 10.0;
    
    g_bInternalDeflectChange = true;
    SetConVarFloat(g_hVictoryDeflects, newLimit);
    g_bInternalDeflectChange = false;
    
    g_bDeflectsExtended = true;
    
    if(hitNumber == 1) {
        CPrintToChatAll("%s %sHARD MODE! Deflects: %s%.0f", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, newLimit);
    } else {
        CPrintToChatAll("%s %sDeflects: %s%.0f", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, newLimit);
    }
    
    return Plugin_Continue;
}

public Action Command_BotMenu(int client, int args)
{
    if (!IsValidClient(client)) return Plugin_Handled;
    
    bool isAdmin = CheckCommandAccess(client, "sm_botmenu_admin", ADMFLAG_ROOT);
    
    if (isAdmin) {
        ShowAdminTypeMenu(client);
    } else {
        ShowUserMenu(client);
    }
    
    return Plugin_Handled;
}
void ShowAdminTypeMenu(int client) {
    Handle menu = CreateMenu(AdminTypeMenuHandler);
    SetMenuTitle(menu, "=== BOT MENU ===");
    
    AddMenuItem(menu, "user", "User (Vote)");
    AddMenuItem(menu, "admin", "Admin (Instant Change)");
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 30);
}

public void AdminTypeMenuHandler(Handle menu, MenuAction action, int client, int item) {
    switch(action) {
        case MenuAction_Select: {
            char info[32];
            GetMenuItem(menu, item, info, sizeof(info));
            
            if(StrEqual(info, "user")) {
                ShowUserMenu(client);
            }
            else if(StrEqual(info, "admin")) {
                ShowAdminMenu(client);
            }
        }
        case MenuAction_End: {
            CloseHandle(menu);
        }
    }
}

void ShowUserMenu(int client) {
    Handle menu = CreateMenu(UserMenuHandler);
    SetMenuTitle(menu, "=== VOTING ===");
    
    AddMenuItem(menu, "vote_pvb", "Vote PvB");
    AddMenuItem(menu, "vote_diff", "Vote Difficulty");
    AddMenuItem(menu, "vote_deflects", "Vote Deflects");
    AddMenuItem(menu, "vote_super", "Vote Super");
    AddMenuItem(menu, "vote_movement", "Vote Movement");
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 30);
}

public void UserMenuHandler(Handle menu, MenuAction action, int client, int item) {
    switch(action) {
        case MenuAction_Select: {
            char info[32];
            GetMenuItem(menu, item, info, sizeof(info));
            
            if(StrEqual(info, "vote_pvb")) {
                Command_VotePvB(client, 0);
            }
            else if(StrEqual(info, "vote_diff")) {
                Command_VoteDifficulty(client, 0);
            }
            else if(StrEqual(info, "vote_deflects")) {
                Command_VoteDeflects(client, 0);
            }
            else if(StrEqual(info, "vote_super")) {
                Command_VoteSuper(client, 0);
            }
            else if(StrEqual(info, "vote_movement")) {
                Command_VoteMovement(client, 0);
            }
        }
        case MenuAction_End: {
            CloseHandle(menu);
        }
    }
}

void ShowAdminMenu(int client) {
    Handle menu = CreateMenu(AdminMenuHandler);
    SetMenuTitle(menu, "=== ADMIN ===");

    char pvbStatus[64];
    Format(pvbStatus, sizeof(pvbStatus), "PvB: %s", botActivated ? "[ON]" : "[OFF]");
    AddMenuItem(menu, "toggle_pvb", pvbStatus);

    char diffStatus[64];
    int currentDiff = GetConVarInt(g_hBotDifficulty);
    Format(diffStatus, sizeof(diffStatus), "Difficulty: %s", currentDiff == 0 ? "Normal" : "Hard");
    AddMenuItem(menu, "toggle_diff", diffStatus);

    char superStatus[64];
    float superChance = GetConVarFloat(g_hAimChance);
    Format(superStatus, sizeof(superStatus), "Super: %.0f%%", superChance * 100.0);
    AddMenuItem(menu, "super_menu", superStatus);

    char deflectsStatus[64];
    float deflects = GetConVarFloat(g_hVictoryDeflects);
    Format(deflectsStatus, sizeof(deflectsStatus), "Deflects: %.0f", deflects);
    AddMenuItem(menu, "deflects_menu", deflectsStatus);

    char movementStatus[64];
    Format(movementStatus, sizeof(movementStatus), "Movement: %s", g_bBotMovement ? "[ON]" : "[OFF]");
    AddMenuItem(menu, "toggle_movement", movementStatus);
    
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 30);
}

public void AdminMenuHandler(Handle menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, item, info, sizeof(info));
            
            if(StrEqual(info, "toggle_pvb")) {
                if (botActivated) {
                    DisableMode();
                } else {
                    EnableMode();
                }
                ShowAdminMenu(client);
            }
            else if(StrEqual(info, "toggle_diff")) {
                int currentDiff = GetConVarInt(g_hBotDifficulty);
                int newDiff = (currentDiff == 0) ? 1 : 0;
                SetConVarInt(g_hBotDifficulty, newDiff);
                
                if (newDiff == 1) {
                    
                    g_bHardModeActive = false;
                    g_iRocketHitCounter = 0;
                    ResetPlayerFlickStats();
                } else {
                    
                    g_bHardModeActive = false;
                    g_iRocketHitCounter = 0;
                    ResetPlayerFlickStats();
                    
                    if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
                        SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
                        g_bDeflectsExtended = false;
                        g_fOriginalVictoryDeflects = 0.0;
                    }
                }
                ShowAdminMenu(client);
            }
            else if(StrEqual(info, "super_menu")) {
                ShowSuperChanceMenu(client);
            }
            else if(StrEqual(info, "deflects_menu")) {
                ShowDeflectsMenu(client);
            }
            else if(StrEqual(info, "toggle_movement")) {
                g_bBotMovement = !g_bBotMovement;
                SetConVarBool(g_hBotMovement, g_bBotMovement);
                ShowAdminMenu(client);
            }
        }
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
    }
}

void ShowSuperChanceMenu(int client) {
    Handle menu = CreateMenu(SuperChanceMenuHandler);
    SetMenuTitle(menu, "Super Chance:");
    
    AddMenuItem(menu, "0", "0%");
    AddMenuItem(menu, "25", "25%");
    AddMenuItem(menu, "50", "50%");
    AddMenuItem(menu, "75", "75%");
    AddMenuItem(menu, "100", "100%");
    
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, 20);
}

public void SuperChanceMenuHandler(Handle menu, MenuAction action, int client, int item) {
    switch(action) {
        case MenuAction_Select: {
            char info[32];
            GetMenuItem(menu, item, info, sizeof(info));
            float chance = StringToFloat(info) / 100.0;
            SetConVarFloat(g_hAimChance, chance);
            ShowAdminMenu(client);
        }
        case MenuAction_Cancel: {
            if (item == MenuCancel_ExitBack) ShowAdminMenu(client);
        }
        case MenuAction_End: {
            CloseHandle(menu);
        }
    }
}

void ShowDeflectsMenu(int client) {
    Handle menu = CreateMenu(DeflectsMenuHandler);
    SetMenuTitle(menu, "Deflects to win:");
    
    AddMenuItem(menu, "15", "15");
    AddMenuItem(menu, "30", "30");
    AddMenuItem(menu, "60", "60");
    AddMenuItem(menu, "70", "70");
    AddMenuItem(menu, "100", "100");
    AddMenuItem(menu, "150", "150");
    
    SetMenuExitBackButton(menu, true);
    DisplayMenu(menu, client, 20);
}

public void DeflectsMenuHandler(Handle menu, MenuAction action, int client, int item) {
    switch(action) {
        case MenuAction_Select: {
            char info[32];
            GetMenuItem(menu, item, info, sizeof(info));
            float deflects = StringToFloat(info);
            SetConVarFloat(g_hVictoryDeflects, deflects);
            ShowAdminMenu(client);
        }
        case MenuAction_Cancel: {
            if (item == MenuCancel_ExitBack) ShowAdminMenu(client);
        }
        case MenuAction_End: {
            CloseHandle(menu);
        }
    }
}

public Action Command_VoteDifficulty(int client, int args) {
    if (IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", 
            g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    StartDifficultyVote();
    return Plugin_Handled;
}

void StartDifficultyVote()
{
    Handle menu = CreateMenu(DifficultyVoteHandler);
    SetMenuTitle(menu, "Bot Difficulty:\n ");
    
    AddMenuItem(menu, "0", "Normal");
    AddMenuItem(menu, "1", "Hard");
    
    SetMenuExitButton(menu, true);
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void DifficultyVoteHandler(Handle menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_End:
        {
            CloseHandle(menu);
        }
        case MenuAction_VoteCancel:
        {
            if (param1 == VoteCancel_NoVotes)
            {
                CPrintToChatAll("%s %sNo votes", 
                    g_strServerChatTag, g_strMainChatColor);
            }
            else
            {
                CPrintToChatAll("%s %sVote cancelled", 
                    g_strServerChatTag, g_strMainChatColor);
            }
        }
        case MenuAction_VoteEnd:
        {
            decl String:item[64], String:display[64];
            GetMenuItem(menu, param1, item, sizeof(item), _, display, sizeof(display));
            
            int difficulty = StringToInt(item);

            SetConVarInt(g_hBotDifficulty, difficulty);

            if (difficulty == 1) {
                g_bHardModeActive = false;
                g_iRocketHitCounter = 0;
                
                CPrintToChatAll("%s %s%sHARD%s mode activates after first hit.", 
                    g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor);
            } else {
                g_bHardModeActive = false;

                if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
                    SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
                    g_bDeflectsExtended = false;
                    g_fOriginalVictoryDeflects = 0.0;
                }
            }
            
            CPrintToChatAll("%s %sDifficulty: %s%s", 
                g_strServerChatTag, 
                g_strMainChatColor,
                g_strKeywordChatColor,
                difficulty == 1 ? "HARD" : "NORMAL");
        }
    }
}

bool IsChatVoteInProgress()
{
    return (g_iVoteType != 0);
}

void ResetChatVote()
{
    g_iVoteType = 0;
    nVotes = 0;
    for (int i = 1; i <= MaxClients; i++) bVoted[i] = false;
}

public Action Command_VoteDeflects(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (g_bVoteCooldown) {
        CReplyToCommand(client, "%s %sPlease wait.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }

    if (g_iVoteType == 3) {
        if (bVoted[client]) {
            CReplyToCommand(client, "%s %sYou already voted.", g_strServerChatTag, g_strMainChatColor);
            return Plugin_Handled;
        }
        
        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        nVotes++;
        bVoted[client] = true;
        
        CPrintToChatAll("%s %s%s supports deflects vote. (%d/%d)", 
            g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
        
        if (nVotes >= nVotesNeeded) {
            ResetChatVote();
            StartDeflectsVoteMenu();
        }
        return Plugin_Handled;
    }
    
    if (IsChatVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }

    g_iVoteType = 3;
    nVotes = 1;
    bVoted[client] = true;
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    CPrintToChatAll("%s %s%s wants to vote deflects. Type !votedeflects (%d/%d)", 
        g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
    
    if (nVotes >= nVotesNeeded) {
        ResetChatVote();
        StartDeflectsVoteMenu();
    }
    
    return Plugin_Handled;
}

void StartDeflectsVoteMenu() {
    Handle menu = CreateMenu(DeflectsVoteHandler);
    SetMenuTitle(menu, "Deflects to win:\n ");
    AddMenuItem(menu, "15", "15");
    AddMenuItem(menu, "30", "30");
    AddMenuItem(menu, "60", "60");
    AddMenuItem(menu, "70", "70");
    AddMenuItem(menu, "100", "100");
    AddMenuItem(menu, "150", "150");
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void DeflectsVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: CloseHandle(menu);
        case MenuAction_VoteCancel: {
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            SetConVarFloat(g_hVictoryDeflects, StringToFloat(item));
            CPrintToChatAll("%s %sDeflects: %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, item);
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

public Action Command_VoteSuper(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (g_bVoteCooldown) {
        CReplyToCommand(client, "%s %sPlease wait.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (g_iVoteType == 4) {
        if (bVoted[client]) {
            CReplyToCommand(client, "%s %sYou already voted.", g_strServerChatTag, g_strMainChatColor);
            return Plugin_Handled;
        }
        
        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        nVotes++;
        bVoted[client] = true;
        
        CPrintToChatAll("%s %s%s supports super vote. (%d/%d)", 
            g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
        
        if (nVotes >= nVotesNeeded) {
            ResetChatVote();
            StartSuperVoteMenu();
        }
        return Plugin_Handled;
    }
    
    if (IsChatVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    g_iVoteType = 4;
    nVotes = 1;
    bVoted[client] = true;
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    CPrintToChatAll("%s %s%s wants to vote super. Type !votesuper (%d/%d)", 
        g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
    
    if (nVotes >= nVotesNeeded) {
        ResetChatVote();
        StartSuperVoteMenu();
    }
    
    return Plugin_Handled;
}

void StartSuperVoteMenu() {
    Handle menu = CreateMenu(SuperVoteHandler);
    SetMenuTitle(menu, "Super Chance:\n ");
    AddMenuItem(menu, "0", "0%");
    AddMenuItem(menu, "25", "25%");
    AddMenuItem(menu, "50", "50%");
    AddMenuItem(menu, "75", "75%");
    AddMenuItem(menu, "100", "100%");
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void SuperVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: CloseHandle(menu);
        case MenuAction_VoteCancel: {
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            float chance = StringToFloat(item) / 100.0;
            SetConVarFloat(g_hAimChance, chance);
            CPrintToChatAll("%s %sSuper: %s%s%%", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, item);
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

public Action Command_VoteMovement(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (g_bVoteCooldown) {
        CReplyToCommand(client, "%s %sPlease wait.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (g_iVoteType == 5) {
        if (bVoted[client]) {
            CReplyToCommand(client, "%s %sYou already voted.", g_strServerChatTag, g_strMainChatColor);
            return Plugin_Handled;
        }
        
        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));
        nVotes++;
        bVoted[client] = true;
        
        CPrintToChatAll("%s %s%s supports movement vote. (%d/%d)", 
            g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
        
        if (nVotes >= nVotesNeeded) {
            ResetChatVote();
            StartMovementVoteMenu();
        }
        return Plugin_Handled;
    }
    
    if (IsChatVoteInProgress()) {
        CReplyToCommand(client, "%s %sVote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    g_iVoteType = 5;
    nVotes = 1;
    bVoted[client] = true;
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    CPrintToChatAll("%s %s%s wants to vote movement. Type !votemovement (%d/%d)", 
        g_strServerChatTag, g_strMainChatColor, name, nVotes, nVotesNeeded);
    
    if (nVotes >= nVotesNeeded) {
        ResetChatVote();
        StartMovementVoteMenu();
    }
    
    return Plugin_Handled;
}

void StartMovementVoteMenu() {
    Handle menu = CreateMenu(MovementVoteHandler);
    SetMenuTitle(menu, "Bot Movement:\n ");
    AddMenuItem(menu, "0", "Disabled");
    AddMenuItem(menu, "1", "Enabled");
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void MovementVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: CloseHandle(menu);
        case MenuAction_VoteCancel: {
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            g_bBotMovement = (StringToInt(item) == 1);
            SetConVarBool(g_hBotMovement, g_bBotMovement);
            CPrintToChatAll("%s %sMovement: %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, 
                g_bBotMovement ? "Enabled" : "Disabled");
            g_bVoteCooldown = true;
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

void ResetPlayerFlickStats()
{
    for (int client = 1; client <= MAXPLAYERS; client++) {
        for (int i = 0; i < 7; i++) {
            g_iPlayerFlickSuccess[client][i] = 0;
            g_iPlayerFlickAttempts[client][i] = 0;
        }
    }
}

void ResetPerformanceStats()
{
    g_iConsecutiveDeflects = 0;

    g_bHardModeActive = false;
    g_bDeflectsExtended = false;
    g_iRocketHitCounter = 0;

    if (g_fOriginalVictoryDeflects > 0.0) {
        g_bInternalDeflectChange = true;
        SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
        g_bInternalDeflectChange = false;
        g_fOriginalVictoryDeflects = 0.0;
    }

    ResetPlayerFlickStats();
}

void UpdateMovementAnalysis(int client, float currentPos[3])
{
    float currentTime = GetGameTime();
    float timeDiff = currentTime - g_fLastUpdateTime[client];

    if (timeDiff < 0.1 || g_fLastUpdateTime[client] == 0.0) {
        g_fLastPlayerPositions[client][0] = currentPos[0];
        g_fLastPlayerPositions[client][1] = currentPos[1];
        g_fLastPlayerPositions[client][2] = currentPos[2];
        g_fLastUpdateTime[client] = currentTime;
        return;
    }

    float velocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);
    float speed = GetVectorLength(velocity);

    float alpha = 0.3; 
    g_fPlayerAvgVelocity[client][0] = g_fPlayerAvgVelocity[client][0] * (1.0 - alpha) + velocity[0] * alpha;
    g_fPlayerAvgVelocity[client][1] = g_fPlayerAvgVelocity[client][1] * (1.0 - alpha) + velocity[1] * alpha;
    g_fPlayerAvgVelocity[client][2] = g_fPlayerAvgVelocity[client][2] * (1.0 - alpha) + velocity[2] * alpha;

    if (IsValidClient(bot) && speed > 100.0)
    {
        float botPos[3];
        GetClientAbsOrigin(bot, botPos);

        float toBot[3];
        SubtractVectors(botPos, currentPos, toBot);
        toBot[2] = 0.0; 
        NormalizeVector(toBot, toBot);

        float leftVector[3];
        leftVector[0] = -toBot[1];
        leftVector[1] = toBot[0];
        leftVector[2] = 0.0;

        float horizontalVel[3];
        horizontalVel[0] = velocity[0];
        horizontalVel[1] = velocity[1];
        horizontalVel[2] = 0.0;

        float lateralMovement = GetVectorDotProduct(horizontalVel, leftVector);

        int currentDodge = 0;
        if (lateralMovement > 150.0) {
            currentDodge = -1; 
        } else if (lateralMovement < -150.0) {
            currentDodge = 1; 
        }

        if (currentDodge != 0) {
            if (currentDodge == g_iPlayerDodgeDirection[client]) {
                
                g_iPlayerDodgeCount[client]++;
            } else if (g_iPlayerDodgeDirection[client] != 0) {
                
                g_iPlayerDodgeCount[client] = 1;
            }
            g_iPlayerDodgeDirection[client] = currentDodge;
            g_fPlayerLastDodgeTime[client] = currentTime;
        }

        if (currentTime - g_fPlayerLastDodgeTime[client] > 2.0) {
            g_iPlayerDodgeDirection[client] = 0;
            g_iPlayerDodgeCount[client] = 0;
        }
    }

    if (speed < 50.0) {
        g_iPlayerMovementPattern[client] = 1; 
    } else if (speed > 400.0) {
        g_iPlayerMovementPattern[client] = 3; 
    } else {
        g_iPlayerMovementPattern[client] = 2; 
    }

    g_fLastPlayerPositions[client][0] = currentPos[0];
    g_fLastPlayerPositions[client][1] = currentPos[1];
    g_fLastPlayerPositions[client][2] = currentPos[2];
    g_fLastUpdateTime[client] = currentTime;
}

public Action Timer_CheckStuckRockets(Handle timer)
{
    if (!botActivated || !IsValidClient(bot) || !IsPlayerAlive(bot))
        return Plugin_Continue;

    float botPos[3];
    GetClientEyePosition(bot, botPos);

    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "tf_projectile_rocket")) != -1)
    {
        if (!IsValidEntity(entity) || !g_bRocketStuckCheck[entity])
            continue;

        float rocketPos[3];
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", rocketPos);

        float distance = GetVectorDistance(botPos, rocketPos);

        if (distance < 200.0)
        {

            float moveDistance = GetVectorDistance(g_fLastRocketPos[entity], rocketPos);

            if (moveDistance < 10.0)
            {
                if (g_fRocketStuckTime[entity] == 0.0)
                {
                    g_fRocketStuckTime[entity] = GetGameTime();
                }
                else if (GetGameTime() - g_fRocketStuckTime[entity] > 0.2)
                {

                    ForceReflectStuckRocket(entity);
                    g_bRocketStuckCheck[entity] = false; 
                }
            }
            else
            {
                g_fRocketStuckTime[entity] = 0.0; 
            }

            g_fLastRocketPos[entity][0] = rocketPos[0];
            g_fLastRocketPos[entity][1] = rocketPos[1];
            g_fLastRocketPos[entity][2] = rocketPos[2];
        }
        else
        {

            g_fRocketStuckTime[entity] = 0.0;
        }
    }

    return Plugin_Continue;
}

void ForceReflectStuckRocket(int rocket)
{
    if (!IsValidEntity(rocket) || !IsValidClient(bot) || !IsPlayerAlive(bot))
        return;

    char classname[64];
    GetEntityClassname(rocket, classname, sizeof(classname));

    if (!StrEqual(classname, "tf_projectile_rocket", false))
        return;

    float rocketPos[3], botPos[3], botAngles[3];
    GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", rocketPos);
    GetClientEyePosition(bot, botPos);
    GetClientEyeAngles(bot, botAngles);

    float botDirection[3], toRocket[3];
    GetAngleVectors(botAngles, botDirection, NULL_VECTOR, NULL_VECTOR);
    SubtractVectors(rocketPos, botPos, toRocket);
    NormalizeVector(toRocket, toRocket);
    float dotProduct = GetVectorDotProduct(botDirection, toRocket);

    if (dotProduct > 0.5)  
    {

        int target = TargetClient();

        float direction[3];

        if (IsValidClient(target))
        {
            float targetPos[3];
            GetClientAbsOrigin(target, targetPos);
            targetPos[2] += 40.0; 

            SubtractVectors(targetPos, rocketPos, direction);
        }
        else
        {

            GetAngleVectors(botAngles, direction, NULL_VECTOR, NULL_VECTOR);
        }

        NormalizeVector(direction, direction);

        float currentVelocity[3];
        GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", currentVelocity);
        float speed = GetVectorLength(currentVelocity);

        if (speed < 100.0)
            speed = 1100.0;

        ScaleVector(direction, speed);

        SetEntProp(rocket, Prop_Send, "m_iTeamNum", 3); 

        int deflects = GetEntProp(rocket, Prop_Send, "m_iDeflected");
        SetEntProp(rocket, Prop_Send, "m_iDeflected", deflects + 1);

        TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, direction);

        float botHand[3];
        botHand[0] = botPos[0] + botDirection[0] * 20.0;
        botHand[1] = botPos[1] + botDirection[1] * 20.0;
        botHand[2] = botPos[2] + botDirection[2] * 20.0;

        TE_SetupGlowSprite(botHand, PrecacheModel("materials/sprites/blueglow2.vmt"), 0.2, 1.0, 255);
        TE_SendToAll();
    }
}

void ResetStuckRocketData()
{
    for (int i = 0; i < 2048; i++)
    {
        g_fRocketStuckTime[i] = 0.0;
        g_bRocketStuckCheck[i] = false;
        g_fLastRocketPos[i][0] = 0.0;
        g_fLastRocketPos[i][1] = 0.0;
        g_fLastRocketPos[i][2] = 0.0;
    }
}

public Action Timer_CheckBotExists(Handle timer) {

    if (botActivated) {
        bool ourBotExists = false;

        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && IsOurBot(i)) {
                ourBotExists = true;
                bot = i; 
                break;
            }
        }

        if (!ourBotExists) {
            float currentTime = GetGameTime();

            if (currentTime - g_fLastBotCheckTime > g_fBotRespawnDelay) {
                RecreateBot();
                g_fLastBotCheckTime = currentTime;
            }
        }
    }

    return Plugin_Continue;
}

void RecreateBot() {
    char botname[255];
    GetConVarString(g_botName, botname, sizeof(botname));

    ServerCommand("tf_bot_kick all");
    ServerCommand("kick \"%s\"", botname);

    ServerCommand("sm_manaosrobot_default 1");
    ServerCommand("mp_autoteambalance 0");
    ServerCommand("sv_cheats 1"); 

    ServerCommand("bot -team blue -class pyro -name \"%s\"", botname);

    CPrintToChatAll("%s %sBot has been %sauto-restarted", 
        g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor);

    CreateTimer(0.5, Timer_ConfigurePuppetBot);
    CreateTimer(1.0, Timer_UpdateBotReference);
}

public Action Timer_UpdateBotReference(Handle timer) {
    int botIndex = FindBot();
    if (botIndex != -1) {
        bot = botIndex;

        if (!IsBotBeatable) {
            SDKHook(bot, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    return Plugin_Stop;
}

public Action Timer_SecondSound(Handle timer) {
    EmitSoundToAll("mvm/mvm_tank_start.wav");
    return Plugin_Stop;
}

public Action Timer_ApplySuperVelocity(Handle timer, int rocket) {
    if(!IsValidEntity(rocket)) return Plugin_Stop;

    char classname[64];
    GetEntityClassname(rocket, classname, sizeof(classname));
    if(!StrEqual(classname, "tf_projectile_rocket", false)) return Plugin_Stop;

    int superTarget = TargetClient();
    if(!IsValidClient(superTarget) || !IsPlayerAlive(superTarget)) return Plugin_Stop;

    float rocketPos[3], targetEyes[3], direction[3];
    GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", rocketPos);
    GetClientEyePosition(superTarget, targetEyes);
    
    MakeVectorFromPoints(rocketPos, targetEyes, direction);
    NormalizeVector(direction, direction);

    float currentVel[3];
    GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", currentVel);
    float speed = GetVectorLength(currentVel);
    if(speed < 100.0) speed = 1100.0; 

    ScaleVector(direction, speed);

    float rocketAngles[3];
    GetVectorAngles(direction, rocketAngles);

    TeleportEntity(rocket, NULL_VECTOR, rocketAngles, direction);
    
    return Plugin_Stop;
}

public Action Timer_ConfigurePuppetBot(Handle timer) {

    ServerCommand("bot_forceattack 0");      
    ServerCommand("bot_forceattack2 0");     
    ServerCommand("bot_dontmove 1");         
    ServerCommand("bot_mimic 0");            

    int botIndex = FindBot();
    if (botIndex != -1) {
        bot = botIndex;

        if (!IsBotBeatable) {
            SDKHook(bot, SDKHook_OnTakeDamage, OnTakeDamage);
        }

        float angles[3] = {0.0, 0.0, 0.0};
        TeleportEntity(bot, NULL_VECTOR, angles, NULL_VECTOR);

    }
    
    return Plugin_Stop;
}
