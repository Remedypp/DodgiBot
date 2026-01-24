/** HEADER & GLOBALS */

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

Handle g_hMinOrbitTime;
Handle g_hMaxOrbitTime;

Handle g_hOrbitChance;
Handle g_hOrbitEnabled;

int bot;
int iOwner;
bool bVoted[MAXPLAYERS + 1] = {false, ...};

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

float MinOrbitTime;
float MaxOrbitTime;

float g_fOrbitStartTime = 0.0;
float g_fCurrentOrbitDuration = 0.0;
bool g_bOrbitEnabled = true;


bool IsBotOrbiting = false;
bool IsBotOrbitingRight = false;
bool IsBotOrbitingLeft = false;

int g_iCurrentRocketTarget = -1;
bool g_bOrbitDecisionMade = false;
bool g_bShouldOrbit = false;

enum OrbitPhase {
    PHASE_IDLE = 0,
    PHASE_APPROACHING,
    PHASE_ORBITING,
    PHASE_EVADING,
    PHASE_BAILOUT
}

#define PREDICTION_HORIZON 60
#define COLLISION_RADIUS 28.0
#define MIN_ORBIT_RADIUS 100.0
#define MAX_ORBIT_RADIUS 400.0
#define BAILOUT_THREAT_THRESHOLD 0.65
#define BAILOUT_CONFIRM_TICKS 1
#define BOT_MAX_SPEED 450.0

float g_fTickInterval = 0.015;
OrbitPhase g_CurrentOrbitPhase = PHASE_IDLE;
int g_iBailoutConfirmCounter = 0;
float g_fLastThreatScore = 0.0;
bool g_bOrbitDirectionLeft = false;

float g_PredictedRocketPos[PREDICTION_HORIZON][3];
float g_PredictedBotPos[PREDICTION_HORIZON][3];

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
 
Handle cvarVotePercent;
Handle cvarVoteCooldown;

float g_fGlobalVoteCooldownEndTime = 0.0;

int g_iPendingVoteType = 0;

Handle g_hCurrentVoteMenu = null;

int nPvBVotes = 0;
int nPvBVotesNeeded = 0;
bool bPvBVoted[MAXPLAYERS + 1] = {false, ...};

Handle g_hVictoryDeflects;

bool g_bSuperReflectActive = false;

int g_iSuperReflectAttempts = 0;
int g_iSuperReflectTarget = -1;
int g_iRocketHitCounter = 0;
float g_fSuperReflectTimeout;

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
 

bool g_bDeflectsExtended = false; 
float g_fOriginalVictoryDeflects = 0.0; 
bool g_bHardModeTimerPending = false;
bool g_bInternalDeflectChange = false;

int g_iHardModeFocusTarget = -1;
float g_fHardModeFocusEndTime = 0.0;

int g_iProgressivePhase = 1;
bool g_bRoundEndedByKill = false;
bool g_bNoclipEasterEgg = false;
int g_iEasterEggTarget = -1;
float g_fBotSpawnTime = 0.0;

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
/** CORE PLUGIN LOGIC */

public void OnPluginStart() {
	LoadBotConfig();

	g_aShuffledLaugh = CreateArray();
	g_aShuffledDeflect = CreateArray();
	g_aShuffledPain = CreateArray();
	
	for(int i = 0; i < sizeof(laughSounds); i++) PushArrayCell(g_aShuffledLaugh, i);
	for(int i = 0; i < sizeof(deflectSounds); i++) PushArrayCell(g_aShuffledDeflect, i);
	for(int i = 0; i < sizeof(painSounds); i++) PushArrayCell(g_aShuffledPain, i);
	
	ShuffleSounds(g_aShuffledLaugh, g_iLaughIndex);
	ShuffleSounds(g_aShuffledDeflect, g_iDeflectIndex);
	ShuffleSounds(g_aShuffledPain, g_iPainIndex);

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
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	RegConsoleCmd("sm_botmenu", Command_BotMenu, "Bot Menu");
	RegConsoleCmd("sm_pvb", Command_VotePvB, "Vote to enable/disable PvB");
	RegConsoleCmd("sm_votepvb", Command_VotePvB, "Vote to enable/disable PvB");
	RegConsoleCmd("sm_votediff", Command_VoteDifficulty, "Vote difficulty");
	RegConsoleCmd("sm_votedif", Command_VoteDifficulty, "Vote difficulty");
	RegConsoleCmd("sm_votedeflects", Command_VoteDeflects, "Vote deflects");
	RegConsoleCmd("sm_votesuper", Command_VoteSuper, "Vote super chance");
	RegConsoleCmd("sm_votemovement", Command_VoteMovement, "Vote movement");
	RegConsoleCmd("sm_votemove", Command_VoteMovement, "Vote movement");
	RegConsoleCmd("sm_revote", Command_Revote, "Revote in current poll");
	
	RegAdminCmd("sm_bot_toggle", Command_BotModeToggle, ADMFLAG_GENERIC, "Toggle Bot Mode");
	RegAdminCmd("sm_bot_beatable", Command_BotBeatable, ADMFLAG_GENERIC, "Toggle Bot Beatable Mode");

	HookEvent("object_deflected", OnDeflect, EventHookMode_Post);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);

	InitMessageSystem();
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
	PrecacheSound("weapons/medi_shield_deploy.wav", true);
	PrecacheSound("weapons/medi_shield_retract.wav", true);

	for(int i = 0; i < sizeof(laughSounds); i++) PrecacheSound(laughSounds[i], true);
	for(int i = 0; i < sizeof(deflectSounds); i++) PrecacheSound(deflectSounds[i], true);
	for(int i = 0; i < sizeof(painSounds); i++) PrecacheSound(painSounds[i], true);

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
	
	g_bNoclipEasterEgg = false;
	g_iEasterEggTarget = -1;
	g_fBotSpawnTime = 0.0;

	botActivated = false;
	bot = 0;
	for (int i = 1; i <= MaxClients; i++) bVoted[i] = false;

    g_fGlobalVoteCooldownEndTime = 0.0;
    g_iPendingVoteType = 0;
}

public Action Timer_MapStart(Handle timer)
{
	MapChanged = false;
	return Plugin_Continue;
}
/** CONFIGURATION & CVARS */

void LoadBotConfig()
{
	g_botName = CreateConVar("db_bot_name", "DodgiBot", "Set the bot's name.");
	
	g_hCvarVoteTime = CreateConVar("db_bot_vote_time", "25.0", "Time in seconds the vote menu should last.", 0);
	
	g_hMinReactionTime = CreateConVar("db_bot_react_min", "100.0", "Fastest the bot can react to the rocket being airblasted, DEFAULT: 100 milliseconds.", FCVAR_PROTECTED, true, 0.00, true, 200.00);
	MinReactionTime = GetConVarFloat(g_hMinReactionTime);
	HookConVarChange(g_hMinReactionTime, OnConVarChange);
	
	g_hMaxReactionTime = CreateConVar("db_bot_react_max", "200.0", "Slowest the bot can react to the rocket being airblasted, DEFAULT: 200 milliseconds, which is average for humans.", FCVAR_PROTECTED, true, 100.00, false);
	MaxReactionTime = GetConVarFloat(g_hMaxReactionTime);
	HookConVarChange(g_hMaxReactionTime, OnConVarChange);

	g_hMinOrbitTime = CreateConVar("db_bot_orbit_min", "2.00", "Minimum amount of time (in seconds) the bot can orbit, DEFAULT: 0 seconds.", FCVAR_PROTECTED, true, 0.00, false);
	MinOrbitTime = GetConVarFloat(g_hMinOrbitTime);
	HookConVarChange(g_hMinOrbitTime, OnConVarChange);
	
	g_hMaxOrbitTime = CreateConVar("db_bot_orbit_max", "5.00", "Maximum amount of time (in seconds) the bot can orbit, DEFAULT: 3 seconds.", FCVAR_PROTECTED, true, 0.00, false);
	MaxOrbitTime = GetConVarFloat(g_hMaxOrbitTime);
	HookConVarChange(g_hMaxOrbitTime, OnConVarChange);
	
	g_hOrbitChance = CreateConVar("db_bot_orbit_chance", "20.0", "Percent chance that the bot will orbit before airblasting.", FCVAR_PROTECTED, true, 0.00, true, 100.0);
	HookConVarChange(g_hOrbitChance, OnConVarChange);

	g_hOrbitEnabled = CreateConVar("db_bot_orbit_enable", "1", "Enable/Disable the orbiting system entirely. 1=Enabled, 0=Disabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
	g_bOrbitEnabled = GetConVarBool(g_hOrbitEnabled);
	HookConVarChange(g_hOrbitEnabled, OnConVarChange);

	g_hFlickChances = CreateConVar("db_bot_flick_chance", "15.0 40.0 10.0 10.0 10.0 10.0 5.0", "Percentage chances (out of 100%) that the bot will do a <None Wave USpike DSpike LSpike RSpike BackShot> flick.", FCVAR_PROTECTED);
	GetConVarArray(g_hFlickChances, FlickChances, sizeof(FlickChances));
	HookConVarChange(g_hFlickChances, OnConVarChange);
	
	g_hCQCFlickChances = CreateConVar("db_bot_flick_chance_cqc", "5.0 10.0 25.0 25.0 10.0 10.0 15.0", "Percentage chances (out of 100%) that the bot will do a <None Wave USpike DSpike LSpike RSpike BackShot> flick during close quarters combat.", FCVAR_PROTECTED);
	GetConVarArray(g_hCQCFlickChances, CQCFlickChances, sizeof(CQCFlickChances));
	HookConVarChange(g_hCQCFlickChances, OnConVarChange);
	
	g_hBeatableBot = CreateConVar("db_bot_beatable", "0", "Is the bot beatable or not? If 1, the bot will airblast at the normal rate and will take damage. Otherwise, 0 for a bot that never dies.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
	IsBotBeatable = GetConVarBool(g_hBeatableBot);
	HookConVarChange(g_hBeatableBot, OnConVarChange);
	
	g_hCvarServerChatTag = CreateConVar("db_bot_chat_tag", "{ORANGE}[DBBOT]", "Tag that appears at the start of each chat announcement.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarServerChatTag, g_strServerChatTag, sizeof(g_strServerChatTag));
	HookConVarChange(g_hCvarServerChatTag, OnConVarChange);
	g_hCvarMainChatColor = CreateConVar("db_bot_chat_color_main", "{WHITE}", "Color assigned to the majority of the words in chat announcements.");
	GetConVarString(g_hCvarMainChatColor, g_strMainChatColor, sizeof(g_strMainChatColor));
	HookConVarChange(g_hCvarMainChatColor, OnConVarChange);
	g_hCvarKeywordChatColor = CreateConVar("db_bot_chat_color_key", "{DARKOLIVEGREEN}", "Color assigned to the most important words in chat announcements.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarKeywordChatColor, g_strKeywordChatColor, sizeof(g_strKeywordChatColor));
	HookConVarChange(g_hCvarKeywordChatColor, OnConVarChange);
	g_hCvarClientChatColor = CreateConVar("db_bot_chat_color_client", "{TURQUOISE}", "Color assigned to the client in chat announcements.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarClientChatColor, g_strClientChatColor, sizeof(g_strClientChatColor));
	HookConVarChange(g_hCvarClientChatColor, OnConVarChange);
	g_hCvarBeatableBotMode = CreateConVar("db_bot_mode_name_beatable", "Beatable", "Name assigned to the beatable bot mode.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarBeatableBotMode, g_strBeatableBotMode, sizeof(g_strBeatableBotMode));
	HookConVarChange(g_hCvarBeatableBotMode, OnConVarChange);
	g_hCvarUnbeatableBotMode = CreateConVar("db_bot_mode_name_unbeatable", "Unbeatable", "Name assigned to the unbeatable bot mode.", FCVAR_PROTECTED);
	GetConVarString(g_hCvarUnbeatableBotMode, g_strUnbeatableBotMode, sizeof(g_strUnbeatableBotMode));
	HookConVarChange(g_hCvarUnbeatableBotMode, OnConVarChange);
	
	cvarShieldRadius = CreateConVar("db_bot_shield_radius", "200.0", "Radius of the bot's protective shield", 0, true, 50.0, true, 500.0);
	HookConVarChange(cvarShieldRadius, OnConVarChange);
	
	cvarShieldForce = CreateConVar("db_bot_shield_force", "800.0", "Force of the shield push", 0, true, 100.0, true, 2000.0);
	HookConVarChange(cvarShieldForce, OnConVarChange);
	
	cvarVoteMode = CreateConVar("db_bot_vote_mode", "3", "Player vs Bot voting. 0 = No voting, 1 = Generic chat vote, 2 = Menu vote, 3 = Both (Generic chat first, then Menu vote).", 0, true, 0.0, true, 3.0);
	HookConVarChange(cvarVoteMode, OnConVarChange);
	
	g_hVictoryDeflects = CreateConVar("db_bot_victory_deflects", "60.0", 
		"Deflects needed to win", FCVAR_NONE, true, 14.0, true, 220.0);
	HookConVarChange(g_hVictoryDeflects, OnConVarChange);

	g_hAimPlayer = CreateConVar("db_bot_super_reflect", "1", "Should the bot aim at players instead of rockets? 1 = Yes, 0 = No", _, true, 0.0, true, 1.0);
	g_hAimChance = CreateConVar("db_bot_super_chance", "0.0", "Probability (0.0 to 1.0) that the bot aims at players when reflecting", _, true, 0.0, true, 1.0);

	g_hBotMovement = CreateConVar("db_bot_movement", "0", "Enable bot movement (1: Enabled, 0: Disabled)", _, true, 0.0, true, 1.0);
	g_bBotMovement = GetConVarBool(g_hBotMovement);
	HookConVarChange(g_hBotMovement, OnConVarChange);

	cvarVotePercent = CreateConVar("db_bot_vote_percent", "0.6", "Percentage of votes required (0.0-1.0)", 0, true, 0.0, true, 1.0);
	cvarVoteCooldown = CreateConVar("db_bot_vote_cooldown", "15.0", "Cooldown time between votes", _, true, 0.0, true, 300.0);

	g_hBotDifficulty = CreateConVar("db_bot_difficulty", "0", "Bot Difficulty (0=Normal, 1=Hard, 2=Progressive)", _, true, 0.0, true, 2.0);
	SetConVarInt(g_hBotDifficulty, 0);

	g_hPredictionQuality = CreateConVar("db_bot_prediction", "0.7", "How accurate the bot is at predicting movement (0.0-1.0)", _, true, 0.0, true, 1.0);
	HookConVarChange(g_hPredictionQuality, OnConVarChange);

	AutoExecConfig(true, "DodgiBot");
}

public void OnConVarChange(Handle hConvar, const char[] oldValue, const char[] newValue)
{
	if(hConvar == g_hMinReactionTime)
		MinReactionTime = StringToFloat(newValue);
	if(hConvar == g_hMaxReactionTime)
		MaxReactionTime = StringToFloat(newValue);
	if(hConvar == g_hMinOrbitTime)
		MinOrbitTime = StringToFloat(newValue);
	if(hConvar == g_hMaxOrbitTime)
		MaxOrbitTime = StringToFloat(newValue);

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
	if (hConvar == g_hOrbitEnabled)
		g_bOrbitEnabled = GetConVarBool(g_hOrbitEnabled);
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
/** UTILITIES & HELPERS */

stock void EnableMode() {
	CreateSuperbot();
	ChangeTeams();
	botActivated = true; 
 
	g_fLastBotCheckTime = GetGameTime(); 
}

stock void CreateSuperbot() {
	char botname[255];
	GetConVarString(g_botName, botname, sizeof(botname));

	ServerCommand("mp_autoteambalance 0");

    int newBot = CreateFakeClient(botname);
    if (newBot > 0) {
        bot = newBot; 
        ChangeClientTeam(newBot, 3); 
        TF2_SetPlayerClass(newBot, TFClass_Pyro);
        TF2_RespawnPlayer(newBot);
    } else {
        ServerCommand("tf_bot_add 1 pyro blue easy");
    }

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

stock void LerpVectors(const float start[3], const float end[3], float result[3], float t) {
    result[0] = start[0] + (end[0] - start[0]) * t;
    result[1] = start[1] + (end[1] - start[1]) * t;
    result[2] = start[2] + (end[2] - start[2]) * t;
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
	if (!IsValidClient(bot)) return -1;

	if (GetConVarInt(g_hBotDifficulty) == 1) {
		float currentTime = GetGameTime();
		
		bool keepFocus = false;
		if (g_iHardModeFocusTarget != -1 && IsValidClient(g_iHardModeFocusTarget) && IsPlayerAlive(g_iHardModeFocusTarget) && GetClientTeam(g_iHardModeFocusTarget) == 2) {
			if (currentTime < g_fHardModeFocusEndTime) {
				float botPos[3], targetPos[3];
				GetClientEyePosition(bot, botPos);
				GetClientEyePosition(g_iHardModeFocusTarget, targetPos);
				
				TR_TraceRayFilter(botPos, targetPos, MASK_VISIBLE, RayType_EndPoint, TEF_ExcludeEntity, bot);
				if (TR_DidHit(INVALID_HANDLE)) {
					keepFocus = true;
				}
			}
		}
		
		if (keepFocus) {
			return g_iHardModeFocusTarget;
		}
		
		ArrayList candidates = new ArrayList();
		float botPos[3];
		GetClientEyePosition(bot, botPos);
		
		for (int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2) {
				candidates.Push(i);
			}
		}
		
		if (candidates.Length > 0) {
			g_iHardModeFocusTarget = candidates.Get(GetRandomInt(0, candidates.Length - 1));
			g_fHardModeFocusEndTime = currentTime + 3.0;
		} else {
			g_iHardModeFocusTarget = -1;
		}
		
		delete candidates;
		return g_iHardModeFocusTarget;
	}

	int iPlayer = -1;
	float fClosestDistance = -1.0;
	float fPlayerOrigin[3], fBotLocation[3];
	
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
    if (!IsValidClient(client)) return;
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
    Angle[0] -= 360.0 * RoundToFloor((Angle[0] + 180.0) / 360.0);
    if (Angle[0] > 89.0) Angle[0] = 89.0;
    if (Angle[0] < -89.0) Angle[0] = -89.0;
    
    Angle[1] -= 360.0 * RoundToFloor((Angle[1] + 180.0) / 360.0);
    
    Angle[2] = 0.0; 
}

public void AnglesNormalize(float vAngles[3])
{
	while(vAngles[0] > 89.0) vAngles[0] -= 360.0;
	while(vAngles[0] < -89.0) vAngles[0] += 360.0;
	while(vAngles[1] > 180.0) vAngles[1] -= 360.0;
	while(vAngles[1] < -180.0) vAngles[1] += 360.0;
    vAngles[2] = 0.0;
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

public GetFlickAngle(int entity, int rocket, float angles[3], bool cqc, bool useBaseAngles)
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

				ApplySelectedFlick(entity, rocket, angles, selectedFlick, useBaseAngles);

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

	ApplySelectedFlick(entity, rocket, angles, selectedFlick, useBaseAngles);
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

void ApplySelectedFlick(int entity, int rocket, float angles[3], int flickType, bool useBaseAngles)
{

	switch (flickType) {
		case 0: {

		}
		case 1: {

			float fLocationPlayer[3], fLocationPlayerFinal[3], fEntityOrigin[3];
			if (!useBaseAngles) {
				GetClientAbsOrigin(entity, fLocationPlayer);
				GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", fEntityOrigin);
				MakeVectorFromPoints(fEntityOrigin, fLocationPlayer, fLocationPlayerFinal);
				GetVectorAngles(fLocationPlayerFinal, angles);
			}
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
        
        int iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum");
        int botTeam = GetClientTeam(botClient);
        
        if (iTeam != botTeam && GetVectorDistance(fBotPos, fRocketPos) <= radius)
            return iEntity;
    }
    return -1;
}

stock FindBot()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientBot(i) && IsPlayerAlive(i))
		{
			return i;
		}
	}
	return -1;
}

stock bool IsClientBot(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client);
}

void ShuffleSounds(Handle array, int &index)
{
    int size = GetArraySize(array);
    for(int i = size - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        SwapArrayItems(array, i, j);
    }
    index = 0;
}

stock void String_ToLower(char[] str)
{
    int len = strlen(str);
    for (int i = 0; i < len; i++)
    {
        str[i] = CharToLower(str[i]);
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
    } else {
        for (int i = 1; i <= MaxClients; i++) {
            if (IsClientInGame(i) && IsOurBot(i)) {
                KickClient(i, "Bot deactivated");
                bot = 0;
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

    ServerCommand("mp_autoteambalance 0");

    int newBot = CreateFakeClient(botname);
    if (newBot > 0) {
        bot = newBot; 
        ChangeClientTeam(newBot, 3); 
        TF2_SetPlayerClass(newBot, TFClass_Pyro);
        TF2_RespawnPlayer(newBot);
    } else {
        ServerCommand("tf_bot_add 1 pyro blue easy");
    }

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
    
    if(speed < 1100.0) speed = 1100.0;
    
    ScaleVector(direction, speed);
    TeleportEntity(rocket, NULL_VECTOR, NULL_VECTOR, direction);
    
    return Plugin_Stop;
}

public Action Timer_ConfigurePuppetBot(Handle timer) {
    if (IsValidClient(bot)) {
        ServerCommand("tf_bot_difficulty 3");
        ServerCommand("tf_bot_keep_class_after_death 1");
        ServerCommand("tf_bot_taunt_victim_chance 0");
        ServerCommand("tf_bot_join_after_player 0");
        
        SetEntProp(bot, Prop_Send, "m_iTeamNum", 3); 
        SetEntProp(bot, Prop_Send, "m_bIsMiniBoss", 1);
        
        TF2_SetPlayerClass(bot, TFClass_Pyro);
        TF2_RegeneratePlayer(bot);
        
        ApplyRobotEffect(bot);
    }
    return Plugin_Stop;
}

stock bool IsHardModeFullyActive() {
    return (GetConVarInt(g_hBotDifficulty) == 2 && g_iProgressivePhase >= 3);
}

stock int GetRandomPlayer(int team) {
    ArrayList players = new ArrayList();
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == team) {
            players.Push(i);
        }
    }
    
    int randomPlayer = -1;
    if (players.Length > 0) {
        randomPlayer = players.Get(GetRandomInt(0, players.Length - 1));
    }
    
    delete players;
    return randomPlayer;
}
/** AI & LOGIC */

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
	
	if (botActivated) {
		if (MapChanged) DisableMode();
		
		int playerCount = GetAllClientCount();

		if (playerCount == 0) {
			if (client == bot && IsValidClient(bot) && IsPlayerAlive(bot)) {
				if (GetEntityMoveType(bot) == MOVETYPE_NOCLIP) {
					SetEntityMoveType(bot, MOVETYPE_WALK);
					g_bNoclipEasterEgg = false;
					g_iEasterEggTarget = -1;
				}
				LookAtControlPoint();
			}
			return Plugin_Continue;
		}
		
		int iClient = ChooseClient();
		
        if (client == bot && IsValidClient(bot) && IsPlayerAlive(bot))
        {
            if (IsBotBeatable && (LastDeflectionTime + CurrentReactionTime) > GetEngineTime())
            {
                return Plugin_Continue;
            }
            
            ComputeUnifiedMovement(iClient);
            
            float victoryLimit = GetConVarFloat(g_hVictoryDeflects);
            if (GetConVarInt(g_hBotDifficulty) == 2) victoryLimit = 60.0;

            if (victoryLimit != 0 && rocketDeflects >= victoryLimit && !allowed[client])
            {
                victoryType = 1;
                buttons &= ~IN_ATTACK2;
                return Plugin_Changed;
            }
            if (victoryLimit != 0 && rocketDeflects < victoryLimit && !allowed[client])
            {
                victoryType = 0;
                AutoReflect(iClient, buttons, -1);
            }
        }
        else if (IsValidClient(iClient) && IsPlayerAlive(iClient) && client == iClient)
		{
            if (GetEntityMoveType(bot) == MOVETYPE_NOCLIP && g_bBotMovement) {
                g_bNoclipEasterEgg = true;
                
                if (!IsValidClient(g_iEasterEggTarget) || !IsPlayerAlive(g_iEasterEggTarget)) {
                    g_iEasterEggTarget = GetRandomPlayer(2);
                    if (g_iEasterEggTarget != -1) {
                        CPrintToChatAll("%s %sEaster Egg Target: %N", g_strServerChatTag, g_strMainChatColor, g_iEasterEggTarget);
                    }
                }

                if (IsValidClient(g_iEasterEggTarget) && IsPlayerAlive(g_iEasterEggTarget)) {
                    float targetPos[3], botPos[3], vecVelocity[3];
                    GetClientAbsOrigin(g_iEasterEggTarget, targetPos);
                    GetClientAbsOrigin(bot, botPos);
                    
                    targetPos[2] += 150.0;

                    float time = GetGameTime();
                    float radius = 200.0;
                    float x = Cosine(time * 3.0) * radius;
                    float y = Sine(time * 3.0) * radius;

                    float dest[3];
                    dest[0] = targetPos[0] + x;
                    dest[1] = targetPos[1] + y;
                    dest[2] = targetPos[2];

                    MakeVectorFromPoints(botPos, dest, vecVelocity);
                    ScaleVector(vecVelocity, 10.0);
                    
                    TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, vecVelocity);
                    
                    float angleToTarget[3], vecLook[3];
                    float targetEyes[3];
                    GetClientEyePosition(g_iEasterEggTarget, targetEyes);
                    GetClientEyePosition(bot, botPos);
                    
                    MakeVectorFromPoints(botPos, targetEyes, vecLook);
                    GetVectorAngles(vecLook, angleToTarget);
                    FixAngle(angleToTarget);
                    TeleportEntity(bot, NULL_VECTOR, angleToTarget, NULL_VECTOR);
                }
            } else {
                if (g_bNoclipEasterEgg && (GetGameTime() - g_fBotSpawnTime < 1.0)) {
                    SetEntityMoveType(bot, MOVETYPE_NOCLIP);
                } else {
                    g_bNoclipEasterEgg = false;
                }
            }
		}
	}

	return Plugin_Continue;
}

void ModRateOfFire(int weapon)
{
    if (!IsValidEntity(weapon)) return;
    
    float m_flNextPrimaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack");
    float m_flNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
    SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 10.0);

    float fGameTime = GetGameTime();
    float fPrimaryTime = ((m_flNextPrimaryAttack - fGameTime) - 0.99);
    float fSecondaryTime = ((m_flNextSecondaryAttack - fGameTime) - 0.99);

    SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", fPrimaryTime + fGameTime);
    SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", fSecondaryTime + fGameTime);
}

public Action AutoReflect(int client, int &buttons, int iEntity)
{
    int iBestRocket = -1;
    float fBestDist = 99999.0;
    float fBestRocketPos[3];


    int iCurrentEntity = -1;
    while ((iCurrentEntity = FindEntityByClassname(iCurrentEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE)
    {
        int iTeam = GetEntProp(iCurrentEntity, Prop_Send, "m_iTeamNum");
        if (iTeam == 3) continue;

        float fPos[3];
        GetEntPropVector(iCurrentEntity, Prop_Data, "m_vecOrigin", fPos);

        float fBotPos[3];
        GetClientEyePosition(bot, fBotPos);

        float fDist = GetVectorDistance(fBotPos, fPos);

        if (fDist < fBestDist)
        {
            fBestDist = fDist;
            iBestRocket = iCurrentEntity;
            fBestRocketPos[0] = fPos[0];
            fBestRocketPos[1] = fPos[1];
            fBestRocketPos[2] = fPos[2];

        }
    }

    static float fNextAimTime;

    if (iBestRocket != -1)
    {
        bool bCanReflect = true;
        if (IsBotBeatable && (LastDeflectionTime + CurrentReactionTime) > GetEngineTime())
        {
            bCanReflect = false;
        }

        float fRocketVel[3];
        GetEntPropVector(iBestRocket, Prop_Data, "m_vecAbsVelocity", fRocketVel);
        float fSpeed = GetVectorLength(fRocketVel);
        
        float fReactionDist = 250.0;
        if (fSpeed > 1000.0) {
            fReactionDist = fSpeed * 0.15; 
            if (fReactionDist < 250.0) fReactionDist = 250.0;
            if (fReactionDist > 600.0) fReactionDist = 600.0;
        }

        if(!g_bSuperReflectActive && !g_bRocketSuperChecked[iBestRocket] && GetConVarInt(g_hAimPlayer) == 1 && fBestDist < 400.0 && fBestDist >= 250.0)
        {
            float chance = GetConVarFloat(g_hAimChance);
            if (GetConVarInt(g_hBotDifficulty) == 2) {
                if (g_iProgressivePhase == 1) chance = 0.0;
                else if (g_iProgressivePhase == 2) chance = 0.05;
                else if (g_iProgressivePhase == 3) chance = 0.30;
            }
            if (chance < 0.1) chance = 0.0;

            g_bRocketSuperChecked[iBestRocket] = true;
            if (GetRandomFloat() <= chance)
            {
                int superTarget = TargetClient();
                if(IsValidClient(superTarget) && IsPlayerAlive(superTarget))
                {
                    g_bSuperReflectActive = true;
                    g_iSuperReflectTarget = superTarget;
                    g_iSuperReflectAttempts = 0; 
                    g_fSuperReflectTimeout = GetGameTime() + 10.0;
                }
            }
        }

        if (g_bSuperReflectActive && GetGameTime() > g_fSuperReflectTimeout) {
            g_bSuperReflectActive = false;
            g_iSuperReflectTarget = -1;
        }

        if (IsBotOrbiting) {
            bCanReflect = false;
        }

        if (bCanReflect && fBestDist < fReactionDist)
        {
            float fBotEyes[3];
            GetClientEyePosition(bot, fBotEyes);
            
            float fVector[3];
            MakeVectorFromPoints(fBotEyes, fBestRocketPos, fVector);
            
            float fAngles[3];
            GetVectorAngles(fVector, fAngles);

            bool readyToAirblast = true;

            if(g_bSuperReflectActive && IsValidClient(g_iSuperReflectTarget) && IsPlayerAlive(g_iSuperReflectTarget))
            {
                float fTargetEyes[3], fDirection[3];
                GetClientEyePosition(g_iSuperReflectTarget, fTargetEyes);
                MakeVectorFromPoints(fBotEyes, fTargetEyes, fDirection);
                GetVectorAngles(fDirection, fAngles);
                
                float fBotForward[3];
                GetAngleVectors(fAngles, fBotForward, NULL_VECTOR, NULL_VECTOR);
                float fToRocket[3];
                MakeVectorFromPoints(fBotEyes, fBestRocketPos, fToRocket);
                NormalizeVector(fToRocket, fToRocket);
                if (GetVectorDotProduct(fBotForward, fToRocket) < 0.9) {
                    readyToAirblast = false;
                } else {
                     g_iSuperReflectAttempts++;
                     if(g_iSuperReflectAttempts >= 1) {
                        g_bSuperReflectActive = false;
                        g_iSuperReflectTarget = -1;
                        g_iSuperReflectAttempts = 0;
                     }
                }
            }

            FixAngle(fAngles);
            TeleportEntity(bot, NULL_VECTOR, fAngles, NULL_VECTOR);
            
            if (readyToAirblast) {
                int weapon = GetEntPropEnt(bot, Prop_Send, "m_hActiveWeapon");
                ModRateOfFire(weapon);
                buttons |= IN_ATTACK2;
                HasBotFlicked = false;
            }
            
            return Plugin_Changed;
        }
        else
        {
            if (IsBotOrbiting) {
                AimClient(client);
                HasBotFlicked = false;
                fNextAimTime = GetEngineTime() + 0.1; 
            }
            else {
                float fBotEyes[3];
                GetClientEyePosition(bot, fBotEyes);
                float fVector[3];
                MakeVectorFromPoints(fBotEyes, fBestRocketPos, fVector);
                float fAngles[3];
                GetVectorAngles(fVector, fAngles);

                if (!HasBotFlicked)
                {
                    bool allowFlicks = true;
                    if (GetConVarInt(g_hBotDifficulty) == 2 && g_iProgressivePhase == 1) allowFlicks = false;

                    if (allowFlicks && !(GetRandomFloat() <= (FlickChances[0] / 100)))
                    {
                        float fEnemyDistCQC = 9999.0;
                        int target = TargetClient();
                        if (IsValidClient(target)) {
                            float fEnemyOrigin[3];
                            GetClientEyePosition(target, fEnemyOrigin);
                            fEnemyDistCQC = GetVectorDistance(fBotEyes, fEnemyOrigin);
                        }

                        if (fEnemyDistCQC < 500.0)
                        {
                            GetFlickAngle(bot, iBestRocket, fAngles, true, false);
                        }
                        else
                        {
                            GetFlickAngle(bot, iBestRocket, fAngles, false, false);
                        }
                    }
                    FixAngle(fAngles);
                    TeleportEntity(bot, NULL_VECTOR, fAngles, NULL_VECTOR);
                    HasBotFlicked = true;
                    fNextAimTime = GetEngineTime() + 0.35;
                }
                if (fNextAimTime <= GetEngineTime())
                {
                    AimClient(client);
                }
            }
        }
    }
    else
    {
        if (fNextAimTime <= GetEngineTime())
        {
            AimClient(client); 
        }
    }
    return Plugin_Continue;
}
public void OnPreThinkBot(int entity)
{
	if (entity == bot && IsBotTouched)
	{
		float fEntityOrigin[3], fBotOrigin[3], fDistance[3], fFinalAngle[3];
		int iEntity = -1;
		while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE) {
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
					TeleportEntity(bot, NULL_VECTOR, fFinalAngle, NULL_VECTOR);
				}
				
                if (IsValidEntity(iCurrentWeapon)) {
                    ModRateOfFire(iCurrentWeapon);
                }
                
                float victoryLimit = GetConVarFloat(g_hVictoryDeflects);
                if (GetConVarInt(g_hBotDifficulty) == 2) victoryLimit = 60.0;
                
                if (victoryLimit == 0 || rocketDeflects < victoryLimit) {
				        buttons |= IN_ATTACK2;
                }

				SetEntProp(entity, Prop_Data, "m_nButtons", buttons);
				IsBotTouched = false;
			}
		}
	}
	SDKUnhook(entity, SDKHook_PreThink, OnPreThinkBot);
}

public Action OnStartTouchBot(int entity, int other)
{
	if ((other == bot) && entity != INVALID_ENT_REFERENCE)
	{
        float victoryLimit = GetConVarFloat(g_hVictoryDeflects);
        if (GetConVarInt(g_hBotDifficulty) == 2) victoryLimit = 60.0;

        if (victoryLimit == 0 || rocketDeflects < victoryLimit) {
		        SDKHook(entity, SDKHook_Touch, OnTouchBot);
        }
        
        if (IsBotOrbiting) {
            IsBotOrbiting = false;
            float fStop[3] = {0.0, 0.0, 0.0};
            TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, fStop);
        }
        
        float vVelocity[3], vOrigin[3];
        GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
        
        float fBotOrigin[3];
        GetClientAbsOrigin(bot, fBotOrigin);
        
        float vNormal[3];
        SubtractVectors(vOrigin, fBotOrigin, vNormal); 
        NormalizeVector(vNormal, vNormal);
        
        float dotProduct = GetVectorDotProduct(vVelocity, vNormal);
        
        if (dotProduct < 0.0) {
            float vBounce[3];
            ScaleVector(vNormal, dotProduct * 2.0);
            SubtractVectors(vVelocity, vNormal, vBounce); 
            
            TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vBounce);
        }
        
		return Plugin_Handled;
	}
	else if (entity == INVALID_ENT_REFERENCE)
	{
		SDKUnhook(entity, SDKHook_StartTouch, OnStartTouchBot);
	}
	
	return Plugin_Continue;
}

public Action OnTouchBot(int entity, int other)
{
	int iCurrentWeapon = GetEntPropEnt(other, Prop_Send, "m_hActiveWeapon");
	float m_flNextSecondaryAttack = GetEntPropFloat(iCurrentWeapon, Prop_Send, "m_flNextSecondaryAttack");
	float fGameTime = GetGameTime();
	if (m_flNextSecondaryAttack > fGameTime)
	{
		SDKUnhook(entity, SDKHook_Touch, OnTouchBot);
		return Plugin_Handled;
	}
	float vec[3] = {0.0, 0.0, 0.0};
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vec);
	IsBotTouched = true;
	if (other == bot)
	{
		SDKHook(other, SDKHook_PreThink, OnPreThinkBot);
	}
	SDKUnhook(entity, SDKHook_Touch, OnTouchBot);
	return Plugin_Handled;
}
/** EVENTS */

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
			g_fBotSpawnTime = GetGameTime();
			
			if (g_bNoclipEasterEgg) {
				SetEntityMoveType(bot, MOVETYPE_NOCLIP);
			}
		}
	}
	return Plugin_Continue;
}

public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	if (botActivated) {
		g_bRoundEndedByKill = false;
		for(int i = 1; i <= MaxClients; i++) {
			if (IsValidClient(i)) {
				if(GetClientTeam(i) > 1) {
					SetEntityHealth(i, 175);
				}
			}
			}
		}

		if (g_bNoclipEasterEgg && IsValidClient(bot) && IsPlayerAlive(bot)) {
			SetEntityMoveType(bot, MOVETYPE_NOCLIP);
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
      if (!IsBotBeatable) {
          float victoryLimit = GetConVarFloat(g_hVictoryDeflects);
          if (GetConVarInt(g_hBotDifficulty) == 2) victoryLimit = 60.0;

          if (victoryLimit != 0 && rocketDeflects < victoryLimit) {
              damage = 0.0;
              return Plugin_Changed;
          }
      }
  }
  return Plugin_Continue;
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
				BotSayKill(client);
				g_bRoundEndedByKill = true;
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
			g_bRoundEndedByKill = true;

			g_iRocketHitCounter = 0;


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

        g_iProgressivePhase = 1;

        if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
            g_bInternalDeflectChange = true;
            SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
            g_bInternalDeflectChange = false;
            g_bDeflectsExtended = false;
        }

		g_bNoclipEasterEgg = false;
		g_iEasterEggTarget = -1;

        int winner = GetEventInt(hEvent, "team");
        if (winner == 3) {
            BotSayWin();
			if (!g_bRoundEndedByKill) {
				if(g_iLaughIndex >= GetArraySize(g_aShuffledLaugh)) {
                    ShuffleSounds(g_aShuffledLaugh, g_iLaughIndex);
                    g_iLaughIndex = 0;
                }
                int index = GetArrayCell(g_aShuffledLaugh, g_iLaughIndex);
                EmitSoundToAll(laughSounds[index]);
                g_iLaughIndex++;
				FakeClientCommand(bot, "taunt");
			}
        } else if (winner == 2) {
            BotSayLose();
			if (!g_bRoundEndedByKill) {
				if(g_iPainIndex >= GetArraySize(g_aShuffledPain)) {
					ShuffleSounds(g_aShuffledPain, g_iPainIndex);
					g_iPainIndex = 0;
				}
				int index = GetArrayCell(g_aShuffledPain, g_iPainIndex);
				EmitSoundToAll(painSounds[index]);
				g_iPainIndex++;
			}
        }

	}
	return Plugin_Continue;
}

public void OnClientConnected(int client)
{
    if (IsFakeClient(client)) return;
    bVoted[client] = false;
    bPvBVoted[client] = false;
    nVoters++;
    nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
    nPvBVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
}

public void OnClientDisconnect(int client) {
  if (IsFakeClient(client)) return;
  
  if (bVoted[client]) nVotes--;
  if (bPvBVoted[client]) nPvBVotes--;
  
  nVoters--;
  nVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
  nPvBVotesNeeded = RoundToFloor(float(nVoters) * GetConVarFloat(cvarVotePercent));
  

    bVoted[client] = false;
    bPvBVoted[client] = false;
    
    int playerCount = GetAllClientCount();
    
    if (playerCount == 0 && botActivated) {
        DisableMode();
    }
}

public Action Command_Say(int client, const char[] command, int argc)
{
    return Plugin_Continue;
}
/** GAMEPLAY */

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

			if (GetConVarInt(g_hBotDifficulty) == 2) {
				if (rocketDeflects < 25) {
					if (g_iProgressivePhase != 1) {
						g_iProgressivePhase = 1;
						CPrintToChatAll("%s %sPhase 1: %sWarmup", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
					}
				} else if (rocketDeflects >= 25 && rocketDeflects < 35) {
					if (g_iProgressivePhase != 2) {
						g_iProgressivePhase = 2;
						CPrintToChatAll("%s %sPhase 2: %sActive", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
						BotSayRandom();
					}
				} else if (rocketDeflects >= 45) {
					if (g_iProgressivePhase != 3) {
						g_iProgressivePhase = 3;
						CPrintToChatAll("%s %sPhase 3: %sMaximum Power", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
						BotSayRandom();
					}
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

    if (botActivated) {
        BotSayStart();
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
/** MENUS */

public Action Command_VotePvB(int client, int args) {
    if (client != 0 && !IsValidClient(client)) return Plugin_Handled;
    
    if (client != 0 && g_fGlobalVoteCooldownEndTime > GetGameTime()) {
        float remaining = g_fGlobalVoteCooldownEndTime - GetGameTime();
        float maxCooldown = GetConVarFloat(cvarVoteCooldown);
        if (remaining > maxCooldown) {
            remaining = maxCooldown;
            g_fGlobalVoteCooldownEndTime = GetGameTime() + maxCooldown;
        }
        CReplyToCommand(client, "%s %sPlease wait %.1f seconds.", g_strServerChatTag, g_strMainChatColor, remaining);
        return Plugin_Handled;
    }

    if (bPvBVoted[client]) {
        CReplyToCommand(client, "%s %sYou already voted.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    char name[MAX_NAME_LENGTH];
    GetClientName(client, name, sizeof(name));
    
    nPvBVotes++;
    bPvBVoted[client] = true;
    
    if (!botActivated)
    {
        CPrintToChatAll("%s %s%s %swants to %senable %sPvB. (%d/%d votes)", 
            g_strServerChatTag, g_strClientChatColor, name, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor, nPvBVotes, nPvBVotesNeeded);
    }
    else
    {
        CPrintToChatAll("%s %s%s %swants to %sdisable %sPvB. (%d/%d votes)", 
            g_strServerChatTag, g_strClientChatColor, name, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor, nPvBVotes, nPvBVotesNeeded);
    }
    
    if (nPvBVotes >= nPvBVotesNeeded)
    {
        if (!botActivated)
        {
            CPrintToChatAll("%s %sPlayer vs Bot is now %sactivated!", g_strServerChatTag, g_strUnbeatableBotMode, g_strMainChatColor, g_strKeywordChatColor);
            IsBotBeatable = false;
            EnableMode();
        }
        else
        {
            CPrintToChatAll("%s %sPlayer vs Bot is now%s disabled!", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
            DisableMode();
        }
        
        ResetPvBVotes();
        g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
    }
    return Plugin_Handled;
}

void ResetPvBVotes() {
    nPvBVotes = 0;
    for (int i = 1; i <= MaxClients; i++) bPvBVoted[i] = false;
}

public Action Timer_ResetVote(Handle timer)
{
    
    if (g_iPendingVoteType != 0) {
        int nextVote = g_iPendingVoteType;
        g_iPendingVoteType = 0;
        
        if (nextVote == -1) {
             CPrintToChatAll("%s %sStarting queued vote: %sPvB", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
             Command_VotePvB(0, 0);
        } else if (nextVote == 3) {
             CPrintToChatAll("%s %sStarting queued vote: %sDeflects", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
             StartDeflectsVoteMenu();
        } else if (nextVote == 4) {
             CPrintToChatAll("%s %sStarting queued vote: %sSuper Chance", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
             StartSuperVoteMenu();
        } else if (nextVote == 5) {
             CPrintToChatAll("%s %sStarting queued vote: %sMovement", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor);
             StartMovementVoteMenu();
        }
    }
    
    return Plugin_Continue;
}

public Action Command_Revote(int client, int args) {
    if (!IsValidClient(client)) return Plugin_Handled;
    
    if (!IsVoteInProgress()) {
        CReplyToCommand(client, "%s %sNo vote in progress.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    if (g_hCurrentVoteMenu == null) {
        CReplyToCommand(client, "%s %sCannot revote in this poll.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }
    
    int clients[1];
    clients[0] = client;
    VoteMenu(g_hCurrentVoteMenu, clients, 1, 20);
    
    return Plugin_Handled;
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
    
    char title[256];
    int currentDiff = GetConVarInt(g_hBotDifficulty);
    char diffName[32];
    if (currentDiff == 0) Format(diffName, sizeof(diffName), "Normal");
    else if (currentDiff == 1) Format(diffName, sizeof(diffName), "Hard");
    else if (currentDiff == 2) Format(diffName, sizeof(diffName), "Progressive (Phase %d)", g_iProgressivePhase);

    Format(title, sizeof(title), "=== BOT STATUS ===\nPvB: %s\nDifficulty: %s\nSuper: %.0f%%\nDeflects: %.0f\nMovement: %s\n------------------", 
        botActivated ? "ON" : "OFF",
        diffName,
        GetConVarFloat(g_hAimChance) * 100.0,
        GetConVarFloat(g_hVictoryDeflects),
        g_bBotMovement ? "ON" : "OFF"
    );
    SetMenuTitle(menu, title);
    
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
    
    char title[256];
    int currentDiff = GetConVarInt(g_hBotDifficulty);
    char diffName[32];
    if (currentDiff == 0) Format(diffName, sizeof(diffName), "Normal");
    else if (currentDiff == 1) Format(diffName, sizeof(diffName), "Hard");
    else if (currentDiff == 2) Format(diffName, sizeof(diffName), "Progressive (Phase %d)", g_iProgressivePhase);

    Format(title, sizeof(title), "=== [ADMIN] BOT CONTROL ===\nPvB: %s\nDifficulty: %s\nSuper: %.0f%% | Deflects: %.0f\nMovement: %s\n------------------", 
        botActivated ? "ON" : "OFF",
        diffName,
        GetConVarFloat(g_hAimChance) * 100.0,
        GetConVarFloat(g_hVictoryDeflects),
        g_bBotMovement ? "ON" : "OFF"
    );
    SetMenuTitle(menu, title);

    char pvbStatus[64];
    Format(pvbStatus, sizeof(pvbStatus), "Toggle PvB [%s]", botActivated ? "OFF" : "ON");
    AddMenuItem(menu, "toggle_pvb", pvbStatus);

    AddMenuItem(menu, "toggle_diff", "Change Difficulty");
    AddMenuItem(menu, "super_menu", "Set Super Chance");
    AddMenuItem(menu, "deflects_menu", "Set Deflects Limit");
    AddMenuItem(menu, "toggle_movement", "Toggle Movement");
    
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
                int newDiff = (currentDiff + 1) % 3;
                SetConVarInt(g_hBotDifficulty, newDiff);
                
                if (newDiff == 1) {

                    g_iRocketHitCounter = 0;
                    ResetPlayerFlickStats();
                } else if (newDiff == 2) {

                    g_iRocketHitCounter = 0;
                    g_iProgressivePhase = 1;
                    ResetPlayerFlickStats();
                } else {

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
    AddMenuItem(menu, "2", "Progressive");
    
    SetMenuExitButton(menu, true);
    g_hCurrentVoteMenu = menu;
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

                g_iRocketHitCounter = 0;
                
                CPrintToChatAll("%s %s%sHARD%s mode activates after first hit.", 
                    g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor);
            } else if (difficulty == 2) {

                g_iRocketHitCounter = 0;
                g_iProgressivePhase = 1;
                
                CPrintToChatAll("%s %s%sPROGRESSIVE%s mode activated.", 
                    g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, g_strMainChatColor);
            } else {


                if (g_bDeflectsExtended && g_fOriginalVictoryDeflects > 0.0) {
                    SetConVarFloat(g_hVictoryDeflects, g_fOriginalVictoryDeflects);
                    g_bDeflectsExtended = false;
                    g_fOriginalVictoryDeflects = 0.0;
                }
            }
            
            char diffName[32];
            if (difficulty == 0) Format(diffName, sizeof(diffName), "NORMAL");
            else if (difficulty == 1) Format(diffName, sizeof(diffName), "HARD");
            else if (difficulty == 2) Format(diffName, sizeof(diffName), "PROGRESSIVE");

            CPrintToChatAll("%s %sDifficulty: %s%s", 
                g_strServerChatTag, 
                g_strMainChatColor,
                g_strKeywordChatColor,
                diffName);
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
    if (client != 0 && !IsValidClient(client)) return Plugin_Handled;
    
    if (client != 0 && g_fGlobalVoteCooldownEndTime > GetGameTime()) {
        float remaining = g_fGlobalVoteCooldownEndTime - GetGameTime();
        float maxCooldown = GetConVarFloat(cvarVoteCooldown);
        if (remaining > maxCooldown) {
            remaining = maxCooldown;
            g_fGlobalVoteCooldownEndTime = GetGameTime() + maxCooldown;
        }
        CReplyToCommand(client, "%s %sPlease wait %.1f seconds.", g_strServerChatTag, g_strMainChatColor, remaining);
        return Plugin_Handled;
    }
    
    if (GetConVarInt(g_hBotDifficulty) == 2) {
        CReplyToCommand(client, "%s %sThis vote is disabled in Progressive Mode.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }

    if (IsVoteInProgress()) {
        if (g_iVoteType != 3) {
             CReplyToCommand(client, "%s %sAnother vote is in progress. Queued.", g_strServerChatTag, g_strMainChatColor);
             g_iPendingVoteType = 3;
             return Plugin_Handled;
        }
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
    g_hCurrentVoteMenu = menu;
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void DeflectsVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: {
            g_hCurrentVoteMenu = null;
            CloseHandle(menu);
        }
        case MenuAction_VoteCancel: {
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            SetConVarFloat(g_hVictoryDeflects, StringToFloat(item));
            CPrintToChatAll("%s %sDeflects: %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, item);
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

public Action Command_VoteSuper(int client, int args) {
    if (client != 0 && !IsValidClient(client)) return Plugin_Handled;
    
    if (client != 0 && g_fGlobalVoteCooldownEndTime > GetGameTime()) {
        float remaining = g_fGlobalVoteCooldownEndTime - GetGameTime();
        float maxCooldown = GetConVarFloat(cvarVoteCooldown);
        if (remaining > maxCooldown) {
            remaining = maxCooldown;
            g_fGlobalVoteCooldownEndTime = GetGameTime() + maxCooldown;
        }
        CReplyToCommand(client, "%s %sPlease wait %.1f seconds.", g_strServerChatTag, g_strMainChatColor, remaining);
        return Plugin_Handled;
    }
    
    if (GetConVarInt(g_hBotDifficulty) == 2) {
        CReplyToCommand(client, "%s %sThis vote is disabled in Progressive Mode.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }

    if (IsVoteInProgress()) {
        if (g_iVoteType != 4) {
             CReplyToCommand(client, "%s %sAnother vote is in progress. Queued.", g_strServerChatTag, g_strMainChatColor);
             g_iPendingVoteType = 4;
             return Plugin_Handled;
        }
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
    g_hCurrentVoteMenu = menu;
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void SuperVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: {
            g_hCurrentVoteMenu = null;
            CloseHandle(menu);
        }
        case MenuAction_VoteCancel: {
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            float chance = StringToFloat(item) / 100.0;
            SetConVarFloat(g_hAimChance, chance);
            CPrintToChatAll("%s %sSuper: %s%s%%", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, item);
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

public Action Command_VoteMovement(int client, int args) {
    if (client != 0 && !IsValidClient(client)) return Plugin_Handled;
    
    if (client != 0 && g_fGlobalVoteCooldownEndTime > GetGameTime()) {
        float remaining = g_fGlobalVoteCooldownEndTime - GetGameTime();
        float maxCooldown = GetConVarFloat(cvarVoteCooldown);
        if (remaining > maxCooldown) {
            remaining = maxCooldown;
            g_fGlobalVoteCooldownEndTime = GetGameTime() + maxCooldown;
        }
        CReplyToCommand(client, "%s %sPlease wait %.1f seconds.", g_strServerChatTag, g_strMainChatColor, remaining);
        return Plugin_Handled;
    }
    
    if (GetConVarInt(g_hBotDifficulty) == 2) {
        CReplyToCommand(client, "%s %sThis vote is disabled in Progressive Mode.", g_strServerChatTag, g_strMainChatColor);
        return Plugin_Handled;
    }

    if (IsVoteInProgress()) {
        if (g_iVoteType != 5) {
             CReplyToCommand(client, "%s %sAnother vote is in progress. Queued.", g_strServerChatTag, g_strMainChatColor);
             g_iPendingVoteType = 5;
             return Plugin_Handled;
        }
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
    SetMenuTitle(menu, "Enable Bot Movement:\n ");
    AddMenuItem(menu, "1", "Yes");
    AddMenuItem(menu, "0", "No");
    g_hCurrentVoteMenu = menu;
    VoteMenuToAll(menu, GetConVarInt(g_hCvarVoteTime));
}

public void MovementVoteHandler(Handle menu, MenuAction action, int param1, int param2) {
    switch (action) {
        case MenuAction_End: {
            g_hCurrentVoteMenu = null;
            CloseHandle(menu);
        }
        case MenuAction_VoteCancel: {
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
        case MenuAction_VoteEnd: {
            char item[64];
            GetMenuItem(menu, param1, item, sizeof(item));
            bool enable = view_as<bool>(StringToInt(item));
            SetConVarBool(g_hBotMovement, enable);
            CPrintToChatAll("%s %sMovement: %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, enable ? "Enabled" : "Disabled");
            g_fGlobalVoteCooldownEndTime = GetGameTime() + GetConVarFloat(cvarVoteCooldown);
            CreateTimer(GetConVarFloat(cvarVoteCooldown), Timer_ResetVote);
        }
    }
}

public Action Command_BotBeatable(int client, int args) {
    if (args < 1) {
        IsBotBeatable = !IsBotBeatable;
    } else {
        char arg[16];
        GetCmdArg(1, arg, sizeof(arg));
        IsBotBeatable = (StringToInt(arg) != 0);
    }
    
    if (!IsBotBeatable && botActivated && IsPlayerAlive(bot)) {
        SDKHook(bot, SDKHook_OnTakeDamage, OnTakeDamage);
    }
    
    CReplyToCommand(client, "%s %sBot Beatable: %s%s", g_strServerChatTag, g_strMainChatColor, g_strKeywordChatColor, IsBotBeatable ? "ON" : "OFF");
    return Plugin_Handled;
}
/**
 * Messages
 * Handles bot chat messages and commands.
 * Add your messages in the arrays below using the format: "PROBABILITY|MESSAGE"
 * Example: "10|Hello" means 10% chance to say "Hello".
 * If the total probability for a category is less than 100%, the remaining chance is for silence.
 */

// Messages sent when the round starts or bot joins
char g_strStartMessages[][] = {
    "20|ready?",
    "10|lets go",
    "10|training time",
    "5|beep boop"
};

// Messages sent when the bot wins the round
char g_strWinMessages[][] = {
    "30|gg",
    "20|nice try",
    "10|close one",
    "10|good game",
    "5|wp"
};

// Messages sent when the bot loses the round
char g_strLoseMessages[][] = {
    "20|ns",
    "20|nice shot",
    "10|wow",
    "10|you got me",
    "5|gg wp"
};

// Messages sent when the bot kills a player
// Use {victim} to insert the victim's name
char g_strKillMessages[][] = {
    "20|oops {victim}",
    "20|sorry {victim}",
    "10|nice try {victim}",
    "10|almost {victim}",
    "5|cya {victim}"
};

// Random messages sent periodically
char g_strRandomMessages[][] = {
    "10|i am learning",
    "10|dodgeball is fun",
    "10|nice server",
    "5|beep boop",
    "5|:)"
};

Handle g_hRandomMessageTimer = null;

void InitMessageSystem() {
    if (g_hRandomMessageTimer != null) {
        KillTimer(g_hRandomMessageTimer);
    }
    g_hRandomMessageTimer = CreateTimer(GetRandomFloat(60.0, 120.0), Timer_RandomMessage);
}

public Action Timer_RandomMessage(Handle timer) {
    if (botActivated && IsValidClient(bot) && IsPlayerAlive(bot)) {
        BotSayRandom();
    }
    
    g_hRandomMessageTimer = CreateTimer(GetRandomFloat(60.0, 120.0), Timer_RandomMessage);
    return Plugin_Stop;
}

void BotChat(const char[] message) {
    if (!botActivated || !IsValidClient(bot)) return;
    
    // Use FakeClientCommand to make the bot "say" it in chat.
    // This allows it to execute chat commands too if the message starts with ! or /
    FakeClientCommand(bot, "say %s", message);
}

bool GetWeightedMessage(char[][] messageArray, int arraySize, char[] outputBuffer, int outputSize) {
    float roll = GetRandomFloat(0.0, 100.0);
    float currentWeight = 0.0;
    
    for(int i=0; i < arraySize; i++) {
        char entry[256];
        strcopy(entry, sizeof(entry), messageArray[i]);
        
        char parts[2][256];
        if (ExplodeString(entry, "|", parts, 2, 256) == 2) {
            float chance = StringToFloat(parts[0]);
            currentWeight += chance;
            
            if (roll <= currentWeight) {
                strcopy(outputBuffer, outputSize, parts[1]);
                return true;
            }
        }
    }
    
    return false;
}

void BotSayStart() {
    char message[256];
    if (GetWeightedMessage(g_strStartMessages, sizeof(g_strStartMessages), message, sizeof(message))) {
        BotChat(message);
    }
}

void BotSayWin() {
    char message[256];
    if (GetWeightedMessage(g_strWinMessages, sizeof(g_strWinMessages), message, sizeof(message))) {
        BotChat(message);
    }
}

void BotSayLose() {
    char message[256];
    if (GetWeightedMessage(g_strLoseMessages, sizeof(g_strLoseMessages), message, sizeof(message))) {
        BotChat(message);
    }
}

void BotSayKill(int victim) {
    char message[256];
    if (GetWeightedMessage(g_strKillMessages, sizeof(g_strKillMessages), message, sizeof(message))) {
        char name[MAX_NAME_LENGTH];
        GetClientName(victim, name, sizeof(name));
        ReplaceString(message, sizeof(message), "{victim}", name);
        BotChat(message);
    }
}

void BotSayRandom() {
    char message[256];
    if (GetWeightedMessage(g_strRandomMessages, sizeof(g_strRandomMessages), message, sizeof(message))) {
        BotChat(message);
    }
}
/** MOVEMENT */

void InitOrbitPredictionSystem() {
    g_fTickInterval = GetTickInterval();
    g_CurrentOrbitPhase = PHASE_IDLE;
    g_iBailoutConfirmCounter = 0;
    g_fLastThreatScore = 0.0;
}



void CalculateMimicVelocity(int targetClient, float outVelocity[3]) {
    outVelocity[0] = 0.0;
    outVelocity[1] = 0.0;
    outVelocity[2] = 0.0;
    
    if (!IsValidClient(targetClient) || !IsPlayerAlive(targetClient)) return;
    if (!IsValidClient(bot) || !IsPlayerAlive(bot)) return;
    
    float client_position[3];
    GetEntPropVector(targetClient, Prop_Send, "m_vecOrigin", client_position);
    
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
    
    if (entity_id == -1) return;
    GetEntPropVector(entity_id, Prop_Send, "m_vecOrigin", spawner_position);
    
    float endpoint[3]; 
    endpoint[0] = (2 * spawner_position[0]) - client_position[0];
    endpoint[1] = (2 * spawner_position[1]) - client_position[1];
    endpoint[2] = bot_position[2];
    
    MakeVectorFromPoints(bot_position, endpoint, outVelocity);
    NormalizeVector(outVelocity, outVelocity);
    ScaleVector(outVelocity, 500.0);
    
    outVelocity[2] = 0.0;
    
    float distToEndpoint = GetVectorDistance(endpoint, bot_position);
    if(distToEndpoint < 20) {
        ScaleVector(outVelocity, 0.0);
    } else if(distToEndpoint < 30) {
        ScaleVector(outVelocity, 0.2);
    } else if(distToEndpoint < 50) {
        ScaleVector(outVelocity, 0.5);
    }
}

void PredictRocketTrajectory(
    float rocketPos[3], 
    float rocketVel[3], 
    float rocketSpeed, 
    float turnRate,
    float targetPos[3],
    float outPositions[][3],
    int ticks
) {
    float pos[3], dir[3];
    pos[0] = rocketPos[0];
    pos[1] = rocketPos[1];
    pos[2] = rocketPos[2];
    
    float velMag = GetVectorLength(rocketVel);
    if (velMag < 1.0) velMag = 1.0;
    dir[0] = rocketVel[0] / velMag;
    dir[1] = rocketVel[1] / velMag;
    dir[2] = rocketVel[2] / velMag;
    
    for (int t = 0; t < ticks; t++) {
        outPositions[t][0] = pos[0];
        outPositions[t][1] = pos[1];
        outPositions[t][2] = pos[2];
        
        float toTarget[3];
        toTarget[0] = targetPos[0] - pos[0];
        toTarget[1] = targetPos[1] - pos[1];
        toTarget[2] = targetPos[2] - pos[2];
        NormalizeVector(toTarget, toTarget);
        
        dir[0] = dir[0] + (toTarget[0] - dir[0]) * turnRate;
        dir[1] = dir[1] + (toTarget[1] - dir[1]) * turnRate;
        dir[2] = dir[2] + (toTarget[2] - dir[2]) * turnRate;
        NormalizeVector(dir, dir);
        
        pos[0] = pos[0] + dir[0] * rocketSpeed * g_fTickInterval;
        pos[1] = pos[1] + dir[1] * rocketSpeed * g_fTickInterval;
        pos[2] = pos[2] + dir[2] * rocketSpeed * g_fTickInterval;
    }
}

void PredictBotTrajectory(float botPos[3], float botVel[3], float outPositions[][3], int ticks) {
    float pos[3];
    pos[0] = botPos[0];
    pos[1] = botPos[1];
    pos[2] = botPos[2];
    
    for (int t = 0; t < ticks; t++) {
        outPositions[t][0] = pos[0];
        outPositions[t][1] = pos[1];
        outPositions[t][2] = pos[2];
        
        pos[0] = pos[0] + botVel[0] * g_fTickInterval;
        pos[1] = pos[1] + botVel[1] * g_fTickInterval;
        pos[2] = pos[2] + botVel[2] * g_fTickInterval;
    }
}

bool CheckCollisionPath(float rocketPath[][3], float botPath[][3], int ticks, int &collisionTick) {
    collisionTick = -1;
    
    for (int t = 0; t < ticks - 1; t++) {
        float A[3], B[3], P[3];
        A[0] = rocketPath[t][0]; A[1] = rocketPath[t][1]; A[2] = rocketPath[t][2];
        B[0] = rocketPath[t + 1][0]; B[1] = rocketPath[t + 1][1]; B[2] = rocketPath[t + 1][2];
        P[0] = botPath[t][0]; P[1] = botPath[t][1]; P[2] = botPath[t][2];
        
        float D[3];
        D[0] = B[0] - A[0]; D[1] = B[1] - A[1]; D[2] = B[2] - A[2];
        
        float segLenSq = D[0]*D[0] + D[1]*D[1] + D[2]*D[2];
        if (segLenSq < 0.001) segLenSq = 0.001;
        
        float AP[3];
        AP[0] = P[0] - A[0]; AP[1] = P[1] - A[1]; AP[2] = P[2] - A[2];
        
        float dotAPD = AP[0]*D[0] + AP[1]*D[1] + AP[2]*D[2];
        float param = dotAPD / segLenSq;
        if (param < 0.0) param = 0.0;
        if (param > 1.0) param = 1.0;
        
        float C[3];
        C[0] = A[0] + param * D[0];
        C[1] = A[1] + param * D[1];
        C[2] = A[2] + param * D[2];
        
        float dist = GetVectorDistance(P, C);
        
        if (dist < COLLISION_RADIUS) {
            collisionTick = t;
            return true;
        }
    }
    
    return false;
}

float CalculateThreatScore(float timeToImpact, float escapeMargin, float closingSpeed, float turnRate) {
    float score = 0.0;
    
    float ttiScore = 0.0;
    if (timeToImpact > 0.0 && timeToImpact < 0.5) {
        ttiScore = 1.0 - (timeToImpact / 0.5);
    }
    score += ttiScore * 0.4;
    
    float escapeScore = 0.0;
    if (escapeMargin < 0.0) {
        escapeScore = FloatAbs(escapeMargin) / BOT_MAX_SPEED;
        if (escapeScore > 1.0) escapeScore = 1.0;
    }
    score += escapeScore * 0.3;
    
    float closingScore = closingSpeed / 2000.0;
    if (closingScore > 1.0) closingScore = 1.0;
    if (closingScore < 0.0) closingScore = 0.0;
    score += closingScore * 0.2;
    
    float turnScore = turnRate / 0.2;
    if (turnScore > 1.0) turnScore = 1.0;
    score += turnScore * 0.1;
    
    return score;
}

float CalculateEscapeMargin(float rocketPos[3], float rocketVel[3], float rocketSpeed, float turnRate, float botPos[3], float orbitRadius) {
    float toBot[3];
    SubtractVectors(botPos, rocketPos, toBot);
    NormalizeVector(toBot, toBot);
    
    float tangent[3];
    tangent[0] = -toBot[1];
    tangent[1] = toBot[0];
    tangent[2] = 0.0;
    
    float rocketTangentSpeed = GetVectorDotProduct(rocketVel, tangent);
    float rocketAngularSpeed = turnRate * rocketSpeed;
    float rocketPursuitSpeed = rocketAngularSpeed * orbitRadius;
    
    return BOT_MAX_SPEED - (FloatAbs(rocketTangentSpeed) + rocketPursuitSpeed);
}

float CalculateClosingSpeed(float rocketPos[3], float rocketVel[3], float botPos[3]) {
    float toBot[3];
    SubtractVectors(botPos, rocketPos, toBot);
    NormalizeVector(toBot, toBot);
    return GetVectorDotProduct(rocketVel, toBot);
}

void CalculateOptimalOrbitVelocity(float rocketPos[3], float rocketSpeed, float turnRate, float botPos[3], bool orbitLeft, float threatScore, float closingSpeed, float outVelocity[3]) {
    float toRocket[3];
    SubtractVectors(rocketPos, botPos, toRocket);
    float currentRadius = GetVectorLength(toRocket);
    if (currentRadius < 1.0) currentRadius = 1.0;
    NormalizeVector(toRocket, toRocket);
    
    float speedFactor = rocketSpeed / 1500.0;
    float agilityFactor = 1.0 + (turnRate * 8.0);
    
    float optimalRadius = 240.0 / (1.0 + speedFactor * 0.4) * agilityFactor;
    
    if (optimalRadius < 140.0) optimalRadius = 140.0;
    if (optimalRadius > 380.0) optimalRadius = 380.0;
    
    float tangent[3];
    tangent[0] = -toRocket[1];
    tangent[1] = toRocket[0];
    tangent[2] = 0.0;
    
    if (orbitLeft) {
        tangent[0] = -tangent[0];
        tangent[1] = -tangent[1];
    }
    
    float radialDir[3];
    radialDir[0] = -toRocket[0];
    radialDir[1] = -toRocket[1];
    radialDir[2] = 0.0;
    
    float radiusError = optimalRadius - currentRadius;
    
    float radialStrength = radiusError / 50.0; 
    
    if (currentRadius < 150.0) {
        radialStrength *= 2.5; 
        if (radialStrength > 4.0) radialStrength = 4.0; 
    }
    
    if (radialStrength > 3.0) radialStrength = 3.0; 
    if (radialStrength < -1.5) radialStrength = -1.5;
    
    float angularPursuitSpeed = turnRate * rocketSpeed;
    float baseSpeed = angularPursuitSpeed * optimalRadius * 1.2;
    
    float minSpeedMultiplier = 1.6 + (speedFactor - 1.0) * 0.5; 
    if (minSpeedMultiplier < 1.6) minSpeedMultiplier = 1.6;
    if (minSpeedMultiplier > 3.0) minSpeedMultiplier = 3.0; 
    
    float minSpeed = rocketSpeed * minSpeedMultiplier;
    if (baseSpeed < minSpeed) baseSpeed = minSpeed;
    
    float threatBoost = 1.0;
    if (threatScore > 0.2) {
        threatBoost = 1.0 + (threatScore * 2.0);
    }
    
    float closingBoost = 1.0;
    if (closingSpeed > 0.0) {
        closingBoost = 1.0 + (closingSpeed / rocketSpeed) * 1.5;  
        if (closingBoost > 3.5) closingBoost = 3.5;
    }
    
    float radiusBoost = 1.0;
    if (currentRadius < optimalRadius * 0.7) { 
        float emergencyFactor = 1.0 - (currentRadius / (optimalRadius * 0.7));
        radiusBoost = 1.0 + emergencyFactor * 2.0;  
    }
    
    float finalSpeed = baseSpeed * threatBoost * closingBoost * radiusBoost;
    if (finalSpeed < 550.0) finalSpeed = 550.0;  
    
    float maxSpeed = rocketSpeed * 2.5;  
    if (maxSpeed < 4000.0) maxSpeed = 4000.0;  
    if (maxSpeed > 8000.0) maxSpeed = 8000.0;  
    if (finalSpeed > maxSpeed) finalSpeed = maxSpeed;
    
    if (threatScore > 0.6) {
        radialStrength = -0.8;
    } else if (threatScore > 0.4) {
        radialStrength = -0.4;
    }
    
    if (currentRadius < 120.0) {
        radialStrength = 3.0; 
    }
    
    outVelocity[0] = tangent[0] + radialDir[0] * radialStrength;
    outVelocity[1] = tangent[1] + radialDir[1] * radialStrength;
    outVelocity[2] = 0.0;
    
    NormalizeVector(outVelocity, outVelocity);
    ScaleVector(outVelocity, finalSpeed);
}

bool SelectOptimalOrbitDirection(float rocketPos[3], float rocketVel[3], float botPos[3]) {
    float rocketDir[3];
    rocketDir[0] = rocketVel[0];
    rocketDir[1] = rocketVel[1];
    rocketDir[2] = 0.0;
    if (GetVectorLength(rocketDir) > 0.001) {
        NormalizeVector(rocketDir, rocketDir);
    }
    
    float leftPerp[3], rightPerp[3];
    leftPerp[0] = -rocketDir[1];  
    leftPerp[1] = rocketDir[0];
    leftPerp[2] = 0.0;
    
    rightPerp[0] = rocketDir[1];  
    rightPerp[1] = -rocketDir[0];
    rightPerp[2] = 0.0;
    
    float rocketToBot[3];
    SubtractVectors(botPos, rocketPos, rocketToBot);
    rocketToBot[2] = 0.0;
    NormalizeVector(rocketToBot, rocketToBot);
    
    float leftAlignment = GetVectorDotProduct(rocketToBot, leftPerp);
    float rightAlignment = GetVectorDotProduct(rocketToBot, rightPerp);
    
    return (leftAlignment > rightAlignment);
}

OrbitPhase UpdateOrbitPhase(OrbitPhase current, float rocketDistance, float rocketSpeed, float threatScore, bool collisionPredicted, float timeToImpact) {
    if (collisionPredicted && timeToImpact >= 0.0 && timeToImpact < 0.35) {
        return PHASE_BAILOUT; 
    }
    
    if (rocketDistance < 140.0 && threatScore > 0.8) {
        return PHASE_BAILOUT;
    }
    
    if (rocketSpeed > 2400.0) {
        return PHASE_IDLE;
    }
    
    float timeToImpactSimple = 99.0;
    if (rocketSpeed > 1.0) {
        timeToImpactSimple = rocketDistance / rocketSpeed;
    }
    
    float reactionThreshold = 0.8; 
    
    if (current == PHASE_IDLE) {
        
        if (rocketDistance < 400.0 || timeToImpactSimple < reactionThreshold || collisionPredicted) {
            return PHASE_APPROACHING;
        }
        return PHASE_IDLE;
    }
    
    if (current == PHASE_APPROACHING) {
        if (rocketDistance < 0.0) return PHASE_IDLE;
        
        if (timeToImpactSimple > reactionThreshold * 1.5 && !collisionPredicted) {
            return PHASE_IDLE;
        }
        
        if (rocketDistance < 300.0) return PHASE_ORBITING;
        if (collisionPredicted && threatScore > 0.3) return PHASE_EVADING;
        return PHASE_APPROACHING;
    }
    if (current == PHASE_ORBITING) {
        if (rocketDistance < 0.0) return PHASE_IDLE;
        
        if (collisionPredicted && threatScore > 0.4) return PHASE_EVADING; 
        if (threatScore > 0.6) return PHASE_EVADING; 
        
        if (rocketDistance > 500.0) return PHASE_APPROACHING;
        return PHASE_ORBITING;
    }
    if (current == PHASE_EVADING) {
        if (rocketDistance < 0.0) return PHASE_IDLE;
        if (threatScore >= BAILOUT_THREAT_THRESHOLD) return PHASE_BAILOUT;
        if (!collisionPredicted && threatScore < 0.2) return PHASE_ORBITING;
        return PHASE_EVADING;
    }
    if (current == PHASE_BAILOUT) {
        return PHASE_IDLE;
    }
    return PHASE_IDLE;
}

OrbitPhase ComputeAdvancedOrbit(int rocket, float outVelocity[3]) {
    outVelocity[0] = 0.0;
    outVelocity[1] = 0.0;
    outVelocity[2] = 0.0;
    
    if (!IsValidClient(bot) || !IsPlayerAlive(bot)) {
        g_CurrentOrbitPhase = PHASE_IDLE;
        return PHASE_IDLE;
    }
    
    if (!IsValidEntity(rocket)) {
        g_CurrentOrbitPhase = PHASE_IDLE;
        return PHASE_IDLE;
    }
    
    float botPos[3], botVel[3];
    GetClientAbsOrigin(bot, botPos);
    GetEntPropVector(bot, Prop_Data, "m_vecAbsVelocity", botVel); 
    
    float rocketPos[3], rocketVel[3];
    GetEntPropVector(rocket, Prop_Data, "m_vecOrigin", rocketPos);
    GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", rocketVel);
    
    float rocketSpeed = GetVectorLength(rocketVel);
    int deflects = GetEntProp(rocket, Prop_Send, "m_iDeflected");
    float turnRate = 0.05 + (0.005 * float(deflects));
    
    float rocketDistance = GetVectorDistance(botPos, rocketPos);
    
    PredictRocketTrajectory(rocketPos, rocketVel, rocketSpeed, turnRate, botPos, g_PredictedRocketPos, PREDICTION_HORIZON);
    PredictBotTrajectory(botPos, botVel, g_PredictedBotPos, PREDICTION_HORIZON);
    
    int collisionTick;
    bool collisionPredicted = CheckCollisionPath(g_PredictedRocketPos, g_PredictedBotPos, PREDICTION_HORIZON, collisionTick);
    
    float timeToImpact = -1.0;
    if (collisionPredicted && collisionTick >= 0) {
        timeToImpact = float(collisionTick) * g_fTickInterval;
    }
    
    float escapeMargin = CalculateEscapeMargin(rocketPos, rocketVel, rocketSpeed, turnRate, botPos, rocketDistance);
    float closingSpeed = CalculateClosingSpeed(rocketPos, rocketVel, botPos);
    
    float threatScore = CalculateThreatScore(timeToImpact, escapeMargin, closingSpeed, turnRate);
    g_fLastThreatScore = threatScore;
    

    
    OrbitPhase newPhase = UpdateOrbitPhase(g_CurrentOrbitPhase, rocketDistance, rocketSpeed, threatScore, collisionPredicted, timeToImpact);
    
    if (newPhase == PHASE_BAILOUT) {
        g_iBailoutConfirmCounter++;
        if (g_iBailoutConfirmCounter < BAILOUT_CONFIRM_TICKS) {
            newPhase = PHASE_EVADING;
        }
    } else {
        g_iBailoutConfirmCounter = 0;
    }
    
    g_CurrentOrbitPhase = newPhase;
    
    float rocketDir[3];
    NormalizeVector(rocketVel, rocketDir);
    float toBot[3];
    SubtractVectors(botPos, rocketPos, toBot);
    NormalizeVector(toBot, toBot);

    float speedFactor = rocketSpeed / 1500.0;
    float agilityFactor = 1.0 + (turnRate * 8.0);
    
    float optimalRadius = 240.0 / (1.0 + speedFactor * 0.4) * agilityFactor;
    if (optimalRadius < 140.0) optimalRadius = 140.0;
    
    if (g_CurrentOrbitPhase == PHASE_IDLE) {
        return PHASE_IDLE;
    }
    if (g_CurrentOrbitPhase == PHASE_APPROACHING) {
        
        float targetRadius = optimalRadius; 
        
        if (!IsBotOrbitingLeft && !IsBotOrbitingRight) {
            g_bOrbitDirectionLeft = SelectOptimalOrbitDirection(rocketPos, rocketVel, botPos);
            if (g_bOrbitDirectionLeft) {
                IsBotOrbitingLeft = true;
                IsBotOrbitingRight = false;
            } else {
                IsBotOrbitingLeft = false;
                IsBotOrbitingRight = true;
            }
        }
        
        float toRocket[3];
        SubtractVectors(rocketPos, botPos, toRocket);
        toRocket[2] = 0.0; 
        float distToRocket = GetVectorLength(toRocket);
        
        if (distToRocket > targetRadius + 10.0) {
            
            float angleToRocket = ArcTangent2(toRocket[1], toRocket[0]);
            float tangentOffset = ArcCosine(targetRadius / distToRocket);
            
            float targetAngle;
            if (g_bOrbitDirectionLeft) {
                targetAngle = angleToRocket + tangentOffset; 
            } else {
                targetAngle = angleToRocket - tangentOffset;
            }
            
            float tangentPoint[3];
            tangentPoint[0] = rocketPos[0] - (Cosine(targetAngle) * targetRadius); 
            tangentPoint[1] = rocketPos[1] - (Sine(targetAngle) * targetRadius);
            tangentPoint[2] = botPos[2];
            
            SubtractVectors(tangentPoint, botPos, outVelocity);
            outVelocity[2] = 0.0;
            NormalizeVector(outVelocity, outVelocity);
            
        } else {
            CalculateOptimalOrbitVelocity(rocketPos, rocketSpeed, turnRate, botPos, g_bOrbitDirectionLeft, threatScore, closingSpeed, outVelocity);
            NormalizeVector(outVelocity, outVelocity);
        }
        
        float positionSpeed = rocketSpeed;
        
        if (closingSpeed > 0.0) {
            float closingBoost = 1.0 + (closingSpeed / rocketSpeed) * 0.4;
            if (closingBoost > 1.5) closingBoost = 1.5;
            positionSpeed = positionSpeed * closingBoost;
        }
        
        if (threatScore > 0.2) {
            positionSpeed = positionSpeed * (1.0 + threatScore * 0.8);
        }
        
        if (positionSpeed < rocketSpeed * 0.8) positionSpeed = rocketSpeed * 0.8;  
        float maxSpeed = rocketSpeed * 1.6;  
        if (maxSpeed < 3000.0) maxSpeed = 3000.0;
        if (maxSpeed > 5000.0) maxSpeed = 5000.0;
        if (positionSpeed > maxSpeed) positionSpeed = maxSpeed;
        
        ScaleVector(outVelocity, positionSpeed);
        return PHASE_APPROACHING;
    }
    if (g_CurrentOrbitPhase == PHASE_ORBITING || g_CurrentOrbitPhase == PHASE_EVADING) {
        if (g_CurrentOrbitPhase == PHASE_ORBITING && !IsBotOrbitingLeft && !IsBotOrbitingRight) {
            g_bOrbitDirectionLeft = SelectOptimalOrbitDirection(rocketPos, rocketVel, botPos);
            if (g_bOrbitDirectionLeft) {
                IsBotOrbitingLeft = true;
                IsBotOrbitingRight = false;
            } else {
                IsBotOrbitingLeft = false;
                IsBotOrbitingRight = true;
            }
        }
        
        CalculateOptimalOrbitVelocity(rocketPos, rocketSpeed, turnRate, botPos, g_bOrbitDirectionLeft, threatScore, closingSpeed, outVelocity);
        
        IsBotOrbiting = true;
        return g_CurrentOrbitPhase;
    }
    if (g_CurrentOrbitPhase == PHASE_BAILOUT) {

        IsBotOrbiting = false;
        IsBotOrbitingLeft = false;
        IsBotOrbitingRight = false;
        g_iBailoutConfirmCounter = 0;
        g_CurrentOrbitPhase = PHASE_IDLE;
        return PHASE_BAILOUT;
    }
    
    return g_CurrentOrbitPhase;
}

float FindClosestHostileRocket(int &outRocket) {
    outRocket = -1;
    
    if (!IsValidClient(bot) || !IsPlayerAlive(bot)) return -1.0;
    
    int iEntity = -1;
    float fBotOrigin[3], fEntityOrigin[3];
    float closestDistance = -1.0;
    
    GetClientEyePosition(bot, fBotOrigin);
    int botTeam = GetClientTeam(bot);
    
    while ((iEntity = FindEntityByClassname(iEntity, "tf_projectile_*")) != INVALID_ENT_REFERENCE) {
        int iTeamRocket = GetEntProp(iEntity, Prop_Send, "m_iTeamNum");
        if (iTeamRocket == botTeam) continue;
        
        GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fEntityOrigin);
        float dist = GetVectorDistance(fBotOrigin, fEntityOrigin, false);
        
        if (closestDistance < 0.0 || dist < closestDistance) {
            closestDistance = dist;
            outRocket = iEntity;
        }
    }
    
    return closestDistance;
}

void ComputeUnifiedMovement(int targetClient) {
    bool allowMovement = g_bBotMovement;
    if (GetConVarInt(g_hBotDifficulty) == 2) {
        if (g_iProgressivePhase == 1) allowMovement = false;
        else allowMovement = true;
    }
    
    if (!allowMovement) return;
    if (!IsValidClient(bot) || !IsPlayerAlive(bot)) return;
    
    static bool initialized = false;
    if (!initialized) {
        InitOrbitPredictionSystem();
        initialized = true;
    }
    
    float mimicVel[3];
    CalculateMimicVelocity(targetClient, mimicVel);
    
    int closestRocket = -1;
    float rocketDistance = FindClosestHostileRocket(closestRocket);
    
    float orbitVel[3] = {0.0, 0.0, 0.0};
    float orbitWeight = 0.0;
    float mimicWeight = 1.0;
    
    if (rocketDistance > 0.0 && closestRocket != -1) {
        if (closestRocket != g_iCurrentRocketTarget) {
            g_iCurrentRocketTarget = closestRocket;
            g_bOrbitDecisionMade = false;
            g_fOrbitStartTime = 0.0;
            g_fCurrentOrbitDuration = 0.0;
        }
        
        if (!g_bOrbitDecisionMade) {
            float baseChance = GetConVarFloat(g_hOrbitChance) / 100.0;
            float difficultyChance = baseChance;
            int difficulty = GetConVarInt(g_hBotDifficulty);
            
            if (difficulty == 0) difficultyChance = baseChance;           
            else if (difficulty == 1) difficultyChance = baseChance + 0.10; 
            else difficultyChance = baseChance + 0.20;                    
            
            if (difficultyChance > 1.0) difficultyChance = 1.0;
            
            g_bShouldOrbit = (GetRandomFloat(0.0, 1.0) <= difficultyChance);
            g_bOrbitDecisionMade = true;
        }

        OrbitPhase phase = ComputeAdvancedOrbit(closestRocket, orbitVel);
        
        if (phase == PHASE_BAILOUT) {
            return;
        }
        
        float rocketVel[3];
        GetEntPropVector(closestRocket, Prop_Data, "m_vecAbsVelocity", rocketVel);
        float rocketSpeed = GetVectorLength(rocketVel);
        
        float speedFactor = rocketSpeed / 1500.0;
        if (speedFactor < 0.8) speedFactor = 0.8;
        if (speedFactor > 2.0) speedFactor = 2.0;
        
        float closeThreshold = 400.0 * speedFactor;  
        float farThreshold = 1500.0 * speedFactor;   
        
        if (phase == PHASE_IDLE) {
            orbitWeight = 0.0;
            mimicWeight = 1.0;
        } else {
            
            if (!g_bOrbitEnabled) {
                orbitWeight = 0.0;
                mimicWeight = 1.0;
            }
            else if (g_bSuperReflectActive) {
                if (g_fOrbitStartTime == 0.0) {
                    g_fOrbitStartTime = GetGameTime();
                    g_fCurrentOrbitDuration = GetRandomFloat(MinOrbitTime, MaxOrbitTime);
                }
                
                float orbitDuration = GetGameTime() - g_fOrbitStartTime;
                
                if (orbitDuration < MinOrbitTime) {
                    orbitWeight = 1.0;
                    mimicWeight = 0.0;
                    IsBotOrbiting = true;
                } else {
                    orbitWeight = 0.0;
                    mimicWeight = 1.0;
                    
                    IsBotOrbiting = false; 
                }
            }
            else if (!g_bShouldOrbit) {
                orbitWeight = 0.0;
                mimicWeight = 1.0;
            }
            else if (phase == PHASE_ORBITING || phase == PHASE_EVADING) {
                if (g_fOrbitStartTime == 0.0) {
                    g_fOrbitStartTime = GetGameTime();
                    g_fCurrentOrbitDuration = GetRandomFloat(MinOrbitTime, MaxOrbitTime);
                }
                
                float orbitDuration = GetGameTime() - g_fOrbitStartTime;
                
                if (orbitDuration > g_fCurrentOrbitDuration) {
                    orbitWeight = 0.0;
                    mimicWeight = 1.0;
                    IsBotOrbiting = false;
                } else {
                    orbitWeight = 1.0;
                    mimicWeight = 0.0;
                }
            }
            else {
                g_fOrbitStartTime = 0.0;
                g_fCurrentOrbitDuration = 0.0;
                
                if (rocketDistance <= closeThreshold) {
                    orbitWeight = 1.0;
                    mimicWeight = 0.0;
                } else if (rocketDistance >= farThreshold) {
                    orbitWeight = 0.3;
                    mimicWeight = 0.7;
                } else {
                    float t = (rocketDistance - closeThreshold) / (farThreshold - closeThreshold);
                    orbitWeight = 1.0 - (t * 0.7);
                    mimicWeight = t * 0.7;
                }
            }
            
            if (g_fLastThreatScore > 0.3 && g_bOrbitEnabled && g_bShouldOrbit) {
                orbitWeight = 1.0;
                mimicWeight = 0.0;
            }
        }
    } else {
        IsBotOrbiting = false;
        IsBotOrbitingRight = false;
        IsBotOrbitingLeft = false;

        
        g_iCurrentRocketTarget = -1;
        g_bOrbitDecisionMade = false;
    }
    
    float finalVel[3];
    finalVel[0] = (orbitVel[0] * orbitWeight) + (mimicVel[0] * mimicWeight);
    finalVel[1] = (orbitVel[1] * orbitWeight) + (mimicVel[1] * mimicWeight);
    finalVel[2] = 0.0;
    
    float currentVel[3];
    GetEntPropVector(bot, Prop_Data, "m_vecVelocity", currentVel);
    
    float lerpFactor = 0.35;  
    
    if (rocketDistance > 0.0 && GetVectorLength(currentVel) < 200.0) {
        lerpFactor = 0.6;  
    }
    
    if (g_fLastThreatScore > 0.4) {
        lerpFactor = 0.8;  
    }
    
    float slidingVel[3];
    LerpVectors(currentVel, finalVel, slidingVel, lerpFactor);
    
    SetEntPropFloat(bot, Prop_Send, "m_flMaxspeed", 3500.0);  
    TeleportEntity(bot, NULL_VECTOR, NULL_VECTOR, slidingVel);
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
