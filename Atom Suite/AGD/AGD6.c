/* Atomic AGD SCript Compiler                    Version 6 */
/*
/*   ZX Spectrum/CPC version written by Jonathan Cauldwell */
/*   Atom version written by Kees van Oss 2018             */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* Definitions. */

#define LF						0x0a
#define CR						0x0d

enum
{
	EVENT_SPRITE_0,
	EVENT_SPRITE_1,
	EVENT_SPRITE_2,
	EVENT_SPRITE_3,
	EVENT_SPRITE_4,
	EVENT_SPRITE_5,
	EVENT_SPRITE_6,
	EVENT_SPRITE_7,
	EVENT_SPRITE_8,
	EVENT_INITIALISE_SPRITE,
	EVENT_MAIN_LOOP_1,
	EVENT_MAIN_LOOP_2,
	EVENT_INTRO_MENU,
	EVENT_GAME_INITIALISATION,
	EVENT_RESTART_SCREEN,
	EVENT_FELL_TOO_FAR,
	EVENT_KILL_PLAYER,
	EVENT_LOST_GAME,
	EVENT_COMPLETED_GAME,
	EVENT_NEW_HIGH_SCORE,
	EVENT_COLLECTED_BLOCK,
	NUM_EVENTS												/* number of separate events to compile. */
};

#define MAX_EVENT_SIZE			65536						/* maximum size of compiled event routines. */
#define NUM_NESTING_LEVELS		12
#define NUM_REPEAT_LEVELS		3
#define SNDSIZ				41							/* size of each AY sound. */
#define NO_ARGUMENT			255
#define SPRITE_PARAMETER		0
#define NUMERIC				1
/* Game engine labels. */

#define PAM1ST				5							/* ix+5 is first sprite parameter. */
#define X				8							/* ix+8 is x coordinate of sprite. */
#define Y				9							/* ix+9 is y coordinate of sprite. */
#define GLOBALS				( VAR_EDGET - SPR_X + X )	/* global variables. */
#define IDIFF				( SPR_TYP - PAM1ST )		/* diff between type and first sprite param. */
#define ASMLABEL_DUMMY			1366


/* Here's the vocabulary. */

enum
{
	INS_IF = 1,
	INS_WHILE,
	INS_SPRITEUP,
	INS_SPRITEDOWN,
	INS_SPRITELEFT,
	INS_SPRITERIGHT,
	INS_ENDIF,
	INS_ENDWHILE,
	INS_CANGOUP,
	INS_CANGODOWN,
	INS_CANGOLEFT,
	INS_CANGORIGHT,
	INS_LADDERABOVE,
	INS_LADDERBELOW,
	INS_DEADLY,
	INS_CUSTOM,
	INS_TO,
	INS_FROM,
	INS_BY,

	FIRST_PARAMETER,
	SPR_TYP = FIRST_PARAMETER,
	SPR_IMG,
	SPR_FRM,
	SPR_X,
	SPR_Y,
	SPR_DIR,
	SPR_PMA,
	SPR_PMB,
	SPR_AIRBORNE,
	SPR_SPEED,

	FIRST_VARIABLE,
	VAR_EDGET = FIRST_VARIABLE,
	VAR_EDGEL,
	VAR_EDGEB,
	VAR_EDGER,
	VAR_SCREEN,
	VAR_LIV,
	VAR_A,
	VAR_B,
	VAR_C,
	VAR_D,
	VAR_E,
	VAR_F,
	VAR_G,
	VAR_H,
	VAR_I,
	VAR_J,
	VAR_K,
	VAR_L,
	VAR_M,
	VAR_N,
	VAR_O,
	VAR_P,
	VAR_Q,
	VAR_R,
	VAR_S,
	VAR_T,
	VAR_U,
	VAR_V,
	VAR_W,
	VAR_Z,
	VAR_CONTROL,
	VAR_LINE,
	VAR_COLUMN,
	VAR_CLOCK,
	VAR_RND,
	VAR_OBJ,
	VAR_OPT,
	VAR_BLOCK,
	LAST_PARAMETER = VAR_BLOCK,

	INS_GOT,
	INS_KEY,
	INS_DEFINEKEY,
	INS_COLLISION,
	INS_NUM,												/* number follows this marker. */
	OPE_EQU,												/* operators. */
	OPE_GRTEQU,
	OPE_GRT,
	OPE_NOT,
	OPE_LESEQU,
	OPE_LES,
	INS_LET,
	INS_ANIM,
	INS_ANIMBACK,
	INS_PUTBLOCK,
	INS_DIG,
	INS_NEXTLEVEL,
	INS_RESTART,
	INS_SPAWN,
	INS_REMOVE,
	INS_GETRANDOM,
	INS_RANDOMIZE,
	INS_ELSE,
	INS_DISPLAYHIGH,
	INS_DISPLAYSCORE,
	INS_DISPLAYBONUS,
	INS_SCORE,
	INS_BONUS,
	INS_ADDBONUS,
	INS_ZEROBONUS,
	INS_SOUND,
	INS_BEEP,
	INS_CRASH,
	INS_CLS,
	INS_BORDER,
	INS_COLOUR,
	INS_PAPER,
	INS_INK,
	INS_CLUT,
	INS_DELAY,
	INS_PRINT,
	INS_PRINTMODE,
	INS_AT,
	INS_CHR,
	INS_MENU,
	INS_INVENTORY,
	INS_KILL,
	INS_ADD,
	INS_SUB,
	INS_DISPLAY,
	INS_SCREENUP,
	INS_SCREENDOWN,
	INS_SCREENLEFT,
	INS_SCREENRIGHT,
	INS_WAITKEY,
	INS_JUMP,
	INS_FALL,
	INS_TABLEJUMP,
	INS_TABLEFALL,
	INS_OTHER,
	INS_SPAWNED,
	INS_ORIGINAL,
	INS_ENDGAME,
	INS_GET,
	INS_PUT,
	INS_REMOVEOBJ,
	INS_DETECTOBJ,
	INS_ASM,
	INS_EXIT,
	INS_REPEAT,
	INS_ENDREPEAT,
	INS_MULTIPLY,
	INS_DIVIDE,
	INS_SPRITEINK,
	INS_TRAIL,
	INS_LASER,
	INS_STAR,
	INS_EXPLODE,
	INS_REDRAW,
	INS_SILENCE,
	INS_CLW,
	INS_PALETTE,
	INS_GETBLOCK,
	INS_PLOT,
	INS_UNDOSPRITEMOVE,
	INS_READ,
	INS_DATA,
	INS_RESTORE,
	INS_TICKER,
	INS_USER,
	INS_DEFINEPARTICLE,
	INS_PARTICLEUP,
	INS_PARTICLEDOWN,
	INS_PARTICLELEFT,
	INS_PARTICLERIGHT,
	INS_DECAYPARTICLE,
	INS_NEWPARTICLE,
	INS_MESSAGE,
	INS_STOPFALL,
	INS_GETBLOCKS,
	INS_CONTROLMENU,
	INS_DOUBLEDIGITS,
	INS_TRIPLEDIGITS,
	INS_CLOCK,

	CMP_EVENT,
	CMP_DEFINEBLOCK,
	CMP_DEFINEWINDOW,
	CMP_DEFINESPRITE,
	CMP_DEFINESCREEN,
	CMP_SPRITEPOSITION,
	CMP_DEFINEOBJECT,
	CMP_MAP,
	CMP_STARTSCREEN,
	CMP_WIDTH,
	CMP_ENDMAP,
	CMP_DEFINEPALETTE,
	CMP_DEFINEMESSAGES,
	CMP_DEFINEFONT,
	CMP_DEFINEJUMP,
	CMP_DEFINECONTROLS,

	CON_RIGHT,
	CON_LEFT,
	CON_DOWN,
	CON_UP,
	CON_FIRE,
	CON_FIRE2,
	CON_FIRE3,
	CON_OPTION1,
	CON_OPTION2,
	CON_OPTION3,
	CON_OPTION4,
	CON_BULLET,
	CON_KEYBOARD,
	CON_JOYKEY,
	CON_JOYMMC,
	CON_BPROP0,
	CON_BPROP1,
	CON_BPROP2,
	CON_BPROP3,
	CON_BPROP4,
	CON_BPROP5,
	CON_BPROP6,
	CON_BPROP7,
	CON_BPROP8,
	CON_FAST,
	CON_MEDIUM,
	CON_SLOW,
	CON_VERYSLOW,

	CON_PLAYER,
	CON_TYPE1,
	CON_TYPE2,
	CON_TYPE3,
	CON_TYPE4,
	CON_TYPE5,
	CON_TYPE6,
	CON_TYPE7,
	CON_TYPE8,
	CON_TYPE9,
	CON_TYPE10,
	CON_TYPE11,
	CON_TYPE12,
	CON_TYPE13,
	CON_TYPE14,
	CON_TYPE15,
	CON_TYPE16,
	CON_TYPE17,
	CON_TYPE18,
	CON_TYPE19,
	CON_TYPE20,
	LAST_CONSTANT,
	FINAL_INSTRUCTION = LAST_CONSTANT,
	INS_STR
};


/****************************************************************************************************************/
/* Function prototypes.                                                                                         */
/****************************************************************************************************************/

void StartEvent( unsigned short int nEvent );
void BuildFile( void );
void EndEvent( void );
void EndDummyEvent( void );
void CreateMessages( void );
void CreateBlocks( void );
void CreateSprites( void );
void CreateScreens( void );
void CreatePositions( void );
void CreateObjects( void );
void CreatePalette( void );
void CreateFont( void );
void CreateHopTable( void );
void CreateKeyTable( void );
unsigned short int NextKeyword( void );
void CountLines( char cSrc );
unsigned short int GetNum( short int nBits );
void Compile( unsigned short int nInstruction );
void ResetIf( void );
void CR_If( void );
void CR_While( void );
void CR_SpriteUp( void );
void CR_SpriteDown( void );
void CR_SpriteLeft( void );
void CR_SpriteRight( void );
void CR_EndIf( void );
void CR_EndWhile( void );
void CR_CanGoUp( void );
void CR_CanGoDown( void );
void CR_CanGoLeft( void );
void CR_CanGoRight( void );
void CR_LadderAbove( void );
void CR_LadderBelow( void );
void CR_Deadly( void );
void CR_Custom( void );
void CR_To( void );
void CR_By( void );
void CR_ClS( void );
void CR_Got( void );
void CR_Key( void );
void CR_DefineKey( void );
void CR_Collision( void );
void CR_Anim( void );
void CR_AnimBack( void );
void CR_PutBlock( void );
void CR_Dig( void );
void CR_NextLevel( void );
void CR_Restart( void );
void CR_Spawn( void );
void CR_Remove( void );
void CR_GetRandom( void );
void CR_Randomize( void );
void CR_DisplayHighScore( void );
void CR_DisplayScore( void );
void CR_DisplayBonus( void );
void CR_Score( void );
void CR_Bonus( void );
void CR_AddBonus( void );
void CR_ZeroBonus( void );
void CR_Sound( void );
void CR_Beep( void );
void CR_Crash( void );
void CR_Border( void );
void CR_Colour( void );
void CR_Paper( void );
void CR_Ink( void );
void CR_Clut( void );
void CR_Delay( void );
void CR_Print( void );
void CR_PrintMode( void );
void CR_At( void );
void CR_Chr( void );
void CR_Menu( void );
void CR_Inventory( void );
void CR_Kill( void );
void CR_AddSubtract( void );
void CR_Display( void );
void CR_ScreenUp( void );
void CR_ScreenDown( void );
void CR_ScreenLeft( void );
void CR_ScreenRight( void );
void CR_WaitKey( void );
void CR_Jump( void );
void CR_Fall( void );
void CR_TableJump( void );
void CR_TableFall( void );
void CR_Other( void );
void CR_Spawned( void );
void CR_Original( void );
void CR_EndGame( void );
void CR_Get( void );
void CR_Put( void );
void CR_RemoveObject( void );
void CR_DetectObject( void );
void CR_Asm( void );
void CR_Exit( void );
void CR_Repeat( void );
void CR_EndRepeat( void );
void CR_Multiply( void );
void CR_Divide( void );
void CR_SpriteInk( void );
void CR_Trail( void );
void CR_Laser( void );
void CR_Star( void );
void CR_Explode( void );
void CR_Redraw( void );
void CR_Silence( void );
void CR_ClW( void );
void CR_Palette( void );
void CR_GetBlock( void );
void CR_Read( void );
void CR_Data( void );
void CR_Restore( void );
void CR_Plot( void );
void CR_UndoSpriteMove( void );
void CR_Ticker( void );
void CR_User( void );
void CR_DefineParticle( void );
void CR_ParticleUp( void );
void CR_ParticleDown( void );
void CR_ParticleLeft( void );
void CR_ParticleRight( void );
void CR_ParticleTimer( void );
void CR_StartParticle( void );
void CR_Message( void );
void CR_StopFall( void );
void CR_GetBlocks( void );
void CR_ControlMenu( void );
void CR_Event( void );
void CR_DefineBlock( void );
void CR_DefineWindow( void );
void CR_DefineSprite( void );
void CR_DefineScreen( void );
void CR_SpritePosition( void );
void CR_DefineObject( void );
void CR_Map( void );
void CR_DefinePalette( void );
void CR_DefineMessages( void );
void CR_DefineFont( void );
void CR_DefineJump( void );
void CR_DefineControls( void );
unsigned char ConvertKey( short int nNum );

char SpriteEvent( void );
void CompileShift( short int nArg );
unsigned short int CompileArgument( void );
unsigned short int CompileKnownArgument( short int nArg );
unsigned short int NumberOnly( void );
void CR_Operator( unsigned short int nOperator );
void CR_Else( void );
void CR_Arg( void );
void CR_Pam( unsigned short int nParam );
void CR_ArgA( short int nNum );
void CR_ArgB( short int nNum );
void CR_PamA( short int nNum );
void CR_PamB( short int nNum );
void CR_PamC( short int nNum );
void CR_StackIf( void );
short int Joystick( short int nArg );
void CompileCondition( void );
void WriteJPNZ( void );
void WriteNumber( unsigned short int nInteger );
void WriteText( unsigned char *cChar );
void WriteInstruction( unsigned char *cCommand );
void WriteInstructionAndLabel( unsigned char *cCommand );
void WriteInstructionArg( unsigned char *cCommand, unsigned short int nNum );
void WriteLabel( unsigned short int nWhere );
void NewLine( void );
void Error( unsigned char *cMsg );

/* Constants. */

unsigned const char *keywrd =
{
	/* Some keywords. */

	"IF."			// if.
	"WHILE."		// while.
	"SPRITEUP."		// move sprite up.
	"SPRITEDOWN."		// move sprite down.
	"SPRITELEFT."		// move sprite left.
	"SPRITERIGHT."		// move sprite right.
	"ENDIF."		// endif.
	"ENDWHILE."		// endwhile.
	"CANGOUP."		// sprite can go up test.
	"CANGODOWN."		// sprite can go down test.
	"CANGOLEFT."		// sprite can go left test.
	"CANGORIGHT."		// sprite can go right test.
	"LADDERABOVE."		// ladder above test.
	"LADDERBELOW."		// ladder below test.
	"DEADLY."		// check if touching deadly block.
	"CUSTOM."    		// check if touching custom block.
	"TO."           	// variable to increment.
	"FROM."          	// variable to decrement.
	"BY."	          	// multiply or divide by.

	/* Sprite variables. */

	"TYPE."			// first parameter.
	"IMAGE."		// image number.
	"FRAME."		// frame number.
	"Y."			// vertical position.
	"X."			// horizontal position.
	"DIRECTION."		// user sprite parameter.
	"SETTINGA."		// sprite parameter a.
	"SETTINGB."		// sprite parameter b.
	"AIRBORNE."		// sprite airborne flag.
	"JUMPSPEED."		// sprite jump/fall speed.

	/* Global variables.  There's a table of labels for these lower down. */

	"TOPEDGE."		// screen edge.
	"LEFTEDGE."		// screen edge.
	"BOTTOMEDGE."		// screen edge.
	"RIGHTEDGE."		// screen edge.
	"SCREEN."		// screen number.
	"LIVES."		// lives.
	"A."			// variable.
	"B."			// variable.
	"C."			// variable.
	"D."			// variable.
	"E."			// variable.
	"F."			// variable.
	"G."			// variable.
	"H."			// variable.
	"I."			// variable.
	"J."			// variable.
	"K."			// variable.
	"L."			// variable.
	"M."			// variable.
	"N."			// variable.
	"O."			// variable.
	"P."			// variable.
	"Q."			// variable.
	"R."			// variable.
	"S."			// variable.
	"T."			// variable.
	"U."			// variable.
	"V."			// variable.
	"W."			// variable.
	"Z."			// variable.
	"CONTROL."		// control.
	"LINE."			// x coordinate.
	"COLUMN."		// y coordinate.
	"CLOCK."		// clock.
	"RND."			// last random number variable.
	"OBJ."			// last object variable.
	"OPT."			// menu option variable.
	"BLOCK."		// block type variable.
	"GOT."			// function.
	"KEY."			// function.

	/* Commands. */

	"DEFINEKEY."		// define key.
	"COLLISION."		// collision with sprite.
	" ."			// number to follow.
	"=."			// equals, ignored.
	">=."			// greater than or equal to, ignored.
	">."			// greater than, ignored.
	"<>."			// not equal to, ignored.
	"<=."			// less than or equal to, ignored.
	"<."			// less than, ignored.
	"LET."			// x=y.
	"ANIMATE."		// animate sprite.
	"ANIMBACK."		// animate sprite backwards.
	"PUTBLOCK."		// put block on screen.
	"DIG."			// dig.
	"NEXTLEVEL."		// next level.
	"RESTART."		// restart game.
	"SPAWN."		// spawn new sprite.
	"REMOVE."		// remove this sprite.
	"GETRANDOM."		// variable.
	"RANDOMIZE."		// randomize.
	"ELSE."			// else.
	"SHOWHIGH."		// show highscore.
	"SHOWSCORE."		// show score.
	"SHOWBONUS."		// show bonus.
	"SCORE."		// increase score.
	"BONUS."			// increase bonus.
	"ADDBONUS."			// add bonus to score.
	"ZEROBONUS."		// add bonus to score.
	"SOUND."			// play sound.
	"BEEP."				// play beeper sound.
	"CRASH."			// play white noise sound.
	"CLS."				// clear screen.
	"BORDER."			// set border.
	"COLOUR."			// set all attributes.
	"PAPER."			// set PAPER attributes.
	"INK."				// set INK attributes.
	"CLUT."				// set CLUT attributes.
	"DELAY."			// pause for a while.
	"PRINT."			// display message.
	"PRINTMODE."		// changes text mode, 0 or 1.
	"AT."				// coordinates.
	"CHR."				// show character.
	"MENU."				// menu in a box.
	"INV."				// inventory menu.
	"KILL."				// kill the player.
	"ADD."				// add to variable.
	"SUBTRACT."			// subtract from variable.
	"DISPLAY."			// display number.
	"SCREENUP."			// up a screen.
	"SCREENDOWN."		// down a screen.
	"SCREENLEFT."		// left a screen.
	"SCREENRIGHT."		// right a screen.
	"WAITKEY."			// wait for keypress.
	"JUMP."				// jump.
	"FALL."				// fall.
	"TABLEJUMP."		// jump.
	"TABLEFALL."		// fall.
	"OTHER."			// select second collision sprite.
	"SPAWNED."			// select spawned sprite.
	"ENDSPRITE."		// select original sprite.
	"ENDGAME."			// end game with victory.
	"GET."				// get object.
	"PUT."				// drop object.
	"REMOVEOBJ."		// remove object.
	"DETECTOBJ."		// detect object.
	"ASM."				// encode.
	"EXIT."				// exit.
	"REPEAT."			// repeat.
	"ENDREPEAT."		// endrepeat.
	"MULTIPLY."			// multiply.
	"DIVIDE."			// divide.
	"SPRITEINK."		// set sprite ink.
	"TRAIL."			// leave a trail.
	"LASER."			// shoot a laser.
	"STAR."				// starfield.
	"EXPLODE."			// start a shrapnel explosion.
	"REDRAW."			// redraw the play area.
	"SILENCE."			// silence AY channels.
	"CLW."				// clear play area window.
	"PALETTE."			// set palette entry.
	"GETBLOCK."			// get block at screen position.
	"PLOT."				// plot pixel.
	"UNDOSPRITEMOVE."	// undo last sprite movement.
	"READ."				// read data.
	"DATA."				// block of data.
	"RESTORE."			// restore to start of list.
	"TICKER."			// ticker message.
	"USER."				// user routine.
	"DEFINEPARTICLE."	// define the user particle behaviour.
	"PARTICLEUP."		// move up.
	"PARTICLEDOWN."		// move down.
	"PARTICLELEFT."		// move left.
	"PARTICLERIGHT."	// move right.
	"PARTICLEDECAY."	// decrement timer and remove.
	"NEWPARTICLE."		// start a new user particle.
	"MESSAGE."			// display a message.
	"STOPFALL."			// stop falling.
	"GETBLOCKS."		// get collectable blocks.
	"CONTROLMENU."		// controlmenu
	"DOUBLEDIGITS."		// show as double digits.
	"TRIPLEDIGITS."		// show as triple digits.
	"SECONDS."			// show as timer.

	/* compiler keywords. */
	"EVENT."			// change event.
	"DEFINEBLOCK."		// define block.
	"DEFINEWINDOW."		// define window.
	"DEFINESPRITE."		// define sprite.
	"DEFINESCREEN."		// define screen.
	"SPRITEPOSITION."	// define sprite position.
	"DEFINEOBJECT."		// define object.
	"MAP."				// set up map.
	"STARTSCREEN."		// start screen.
	"WIDTH."			// map width.
	"ENDMAP."			// end of map.
	"DEFINEPALETTE."	// define palette.
	"DEFINEMESSAGES."	// define messages.
	"DEFINEFONT."		// define font.
	"DEFINEJUMP."		// define jump table.
	"DEFINECONTROLS."	// define key table.

	/* Constants. */
	"RIGHT."			// right constant (keys).
	"LEFT."				// left constant (keys).
	"DOWN."				// down constant (keys).
	"UP."				// up constant (keys).
	"FIRE2."			// fire2 constant (keys).
	"FIRE3."			// fire3 constant (keys).
	"FIRE."				// fire constant (keys).
	"OPTION1."			// option constant (keys).
	"OPTION2."			// option constant (keys).
	"OPTION3."			// option constant (keys).
	"OPTION4."			// option constant (keys).
	"BULLET."			// collision bullet.
	"KEYBOARD."			// control option.
	"JOYKEY."			// control option.
	"JOYMMC."			// control option.
	"EMPTYBLOCK."		// empty space.
	"PLATFORMBLOCK."	// platform.
	"WALLBLOCK."		// wall.
	"LADDERBLOCK."		// ladder.
	"FODDERBLOCK."		// fodder.
	"DEADLYBLOCK."		// deadly.
	"CUSTOMBLOCK."		// custom.
	"WATERBLOCK."		// water.
	"COLLECTABLE."		// collectable.
	"FAST."				// animation speed.
	"MEDIUM."			// animation speed.
	"SLOW."				// animation speed.
	"VERYSLOW."			// animation speed.
	"PLAYER."			// player.
	"SPRITETYPE1."		// sprite type 1.
	"SPRITETYPE2."		// sprite type 2.
	"SPRITETYPE3."		// sprite type 3.
	"SPRITETYPE4."		// sprite type 4.
	"SPRITETYPE5."		// sprite type 5.
	"SPRITETYPE6."		// sprite type 6.
	"SPRITETYPE7."		// sprite type 7.
	"SPRITETYPE8."		// sprite type 8.
	"INITSPRITE."		// initialise sprite.
	"MAINLOOP1."		// main loop 1.
	"MAINLOOP2."		// main loop 2.
	"INTROMENU."		// main menu.
	"GAMEINIT."			// game initialisation.
	"RESTARTSCREEN."	// restart a screen.
	"FELLTOOFAR."		// sprite fell too far.
	"KILLPLAYER."		// kill player.
	"LOSTGAME."			// game over.
	"COMPLETEDGAME."	// won game.
	"NEWHIGHSCORE."		// new high score.
	"COLLECTBLOCK."		// collected block.
};

const short int nConstantsTable[] =
{
	0, 1, 2, 3, 5, 6, 4,		// keys left, right, up, down, fire, fire2, fire3.
	7, 8, 9, 10,			// keys option1, option2, option3, option4.
	10,				// laser bullet.
	0, 1, 2,			// keyboard and joystick controls.
	0, 1, 2, 3, 4, 5, 6, 7, 8,	// block types.
	0, 1, 3, 7,			// animation speeds.
	EVENT_SPRITE_0,			// events.
	EVENT_SPRITE_1,
	EVENT_SPRITE_2,
	EVENT_SPRITE_3,
	EVENT_SPRITE_4,
	EVENT_SPRITE_5,
	EVENT_SPRITE_6,
	EVENT_SPRITE_7,
	EVENT_SPRITE_8,
	EVENT_INITIALISE_SPRITE,
	EVENT_MAIN_LOOP_1,
	EVENT_MAIN_LOOP_2,
	EVENT_INTRO_MENU,
	EVENT_GAME_INITIALISATION,
	EVENT_RESTART_SCREEN,
	EVENT_FELL_TOO_FAR,
	EVENT_KILL_PLAYER,
	EVENT_LOST_GAME,
	EVENT_COMPLETED_GAME,
	EVENT_NEW_HIGH_SCORE,
	EVENT_COLLECTED_BLOCK,
};

const unsigned char cVariables[][ 7 ] =
{
	"wntopx",			// top edge.
	"wnlftx",			// left edge.
	"wnbotx",			// bottom edge.
	"wnrgtx",			// right edge.
	"scno",				// screen number.
	"numlif",			// lives.
	"vara",				// variable.
	"varb",				// variable.
	"varc",				// variable.
	"vard",				// variable.
	"vare",				// variable.
	"varf",				// variable.
	"varg",				// variable.
	"varh",				// variable.
	"vari",				// variable.
	"varj",				// variable.
	"vark",				// variable.
	"varl",				// variable.
	"varm",				// variable.
	"varn",				// variable.
	"varo",				// variable.
	"varp",				// variable.
	"varq",				// variable.
	"varr",				// variable.
	"vars",				// variable.
	"vart",				// variable.
	"varu",				// variable.
	"varv",				// variable.
	"varw",				// variable.
	"varz",				// variable.
	"contrl",			// keyboard/joykey/joymmc controls.
	"chary",			// y coordinate.
	"charx",			// x coordinate.
	"clock",			// last clock reading.
	"varrnd",			// last random number variable.
	"varobj",			// last object variable.
	"varopt",			// last option chosen.
	"varblk"			// block variable.
};

unsigned char cDefaultPalette[] =
{
	0, 2, 20, 19, 128, 227, 200, 146, 0, 2, 20, 19, 128, 227, 200, 146,
	0, 35, 60, 63, 224, 227, 252, 255, 0, 35, 60, 63, 224, 227, 252, 255,
	0, 33, 39, 162, 243, 64, 128, 244, 0, 33, 39, 162, 243, 64, 128, 244,
	0, 44, 80, 120, 108, 109, 146, 219, 0, 44, 80, 120, 108, 109, 146, 219
};

unsigned char cDefaultFont[ 768 ];

/* Hop/jump table. */
unsigned char cDefaultHop[ 25 ] =
{
	248,250,252,254,254,255,255,255,0,0,0,1,1,1,2,2,4,6,8,8,8,99
};

unsigned char cDefaultKeys[ 11 ] =
{
	0x35,0x15,0x93,0x22,0x90,0x04,0x14,0x21,0x11,0x01,0x92
};

const unsigned char cKeyOrder[ 11 ] =
{
	3,2,1,0,4,5,6,7,8,9,10
};


/* Variables. */

unsigned long int nErrors = 0;
unsigned short int nSourceLength = 0;
unsigned long int lSize;									/* source file length. */
unsigned short int nLine;
unsigned short int nAddress = 0;							/* compilation start address. */
unsigned short int nCurrent;								/* current compilation address. */
unsigned char *cBufPos;
unsigned char *cBuff;
unsigned char *cObjt;
unsigned char *cStart;
unsigned short int nIfBuff[ NUM_NESTING_LEVELS ][ 2 ];		/* nested IF addresses. */
unsigned short int nNumIfs;									/* number of IFs. */
unsigned short int nReptBuff[ NUM_REPEAT_LEVELS ];			/* nested REPEAT addresses. */
unsigned short int nNumRepts;								/* number of REPEATs. */
unsigned short int nWhileBuff[ NUM_NESTING_LEVELS ][ 3 ];	/* nested WHILE addresses. */
unsigned short int nNumWhiles;								/* number of WHILEs. */
unsigned short int nGravity;								/* gravity call flag. */
unsigned short int nIfSet;
unsigned short int nPamType;								/* parameter type. */
unsigned short int nPamNum;									/* parameter number. */
unsigned short int nLastOperator;							/* last operator. */
unsigned short int nLastCondition;							/* IF or WHILE. */
unsigned short int nOpType;									/* operation type, eg add or subtract. */
unsigned short int nIncDec = 0;								/* non-zero when only inc or dec needed. */
unsigned short int nNextLabel;								/* label to write. */
unsigned short int nEvent;									/* event number passed to compiler */
unsigned short int nAnswerWantedHere;						/* where to put the result of add, sub, mul or div. */
char cSingleEvent;											/* whether we're building one event or rebuilding the lot. */
char cConstant;												/* non-zero when dealing with a constant. */
unsigned short int nConstant;								/* last constant. */
unsigned short int nMessageNumber = 0;						/* number of text messages in the game. */
unsigned short int nScreen = 0;								/* number of screens. */
unsigned short int nPositions = 0;							/* number of sprite positions. */
unsigned short int nObjects = 0;							/* number of objects. */
unsigned short int nParticle = 0;							/* non-zero when user has written custom routine. */
unsigned short int nReadingControls = 0;					/* Non-zero when reading controls in a WHILE loop. */
unsigned char cData = 0;									/* non-zero when we've encountered a data statement. */
unsigned char cDataRequired = 0;							/* non-zero when we need to find data. */
unsigned char cWindow = 0;									/* non-zero when window defined. */
unsigned char cPalette = 0;
unsigned short int nList[ NUM_EVENTS ];						/* number of data elements in each event. */
short int nWinTop = 0;										/* window position. */
short int nWinLeft = 0;
short int nWinHeight = 0;									/* window dimensions. */
short int nWinWidth = 0;
short int nStartScreen = -1;								/* starting screen. */
unsigned char cMapWid = 0;									/* width of map. */
short int nStartOffset = 0;									/* starting screen offset. */
short int nUseFont = 1;										/* use custom font when non-zero. */
short int nUseHopTable = 0;									/* use jump table when non-zero. */

FILE *pObject;												/* output file. */
FILE *pEngine;												/* engine source file. */
FILE *pWorkMsg;												/* message work file. */
FILE *pWorkBlk;												/* block work file. */
FILE *pWorkSpr;												/* sprite work file. */
FILE *pWorkScr;												/* screen layout work file. */
FILE *pWorkNme;												/* sprite position work file. */
FILE *pWorkObj;												/* objects work file. */

/* Functions */
int main( int argc, const char* argv[] )
{
	short int nChr = 0;
	short int nTmp;
	FILE *pSource;
	char szEngineFilename[ 13 ] = { "engine.inc" };
	char szSourceFilename[ 128 ] = { "" };
	char szObjectFilename[ 128 ] = { "" };
	char szWorkFile1Name[ 128 ] = { "" };
	char szWorkFile2Name[ 128 ] = { "" };
	char szWorkFile3Name[ 128 ] = { "" };
	char szWorkFile4Name[ 128 ] = { "" };
	char szWorkFile5Name[ 128 ] = { "" };
	char szWorkFile6Name[ 128 ] = { "" };
	char *cChar;

	puts( "AGD Compiler for ZX Spectrum Version 0.6" );
	puts( "(C) Jonathan Cauldwell February 2018" );
	puts( "Atom version by Kees van Oss March 2018 \n" );

    if ( argc == 2 )
	{
		cSingleEvent = 0;
		nEvent = -1;
		nMessageNumber = 0;
	}
	else
	{
		fputs( "Usage: Agd ProjectName\neg: AGD TEST\n", stderr );
	    // invalid number of command line arguments
		exit ( 1 );
	}

	/* Open target files. */
	sprintf( szObjectFilename, "%s.inc", argv[ 1 ], nEvent );
	pObject = fopen( szObjectFilename, "wb" );

	if ( !pObject )
	{
        fprintf( stderr, "Unable to create target file: %s\n", szObjectFilename );
		exit ( 1 );
	}

	sprintf( szWorkFile1Name, "%s.txt", argv[ 1 ] );
	pWorkMsg = fopen( szWorkFile1Name, "wb" );
	if ( !pWorkMsg )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile1Name );
		exit ( 1 );
	}

	sprintf( szWorkFile2Name, "%s.blk", argv[ 1 ] );
	pWorkBlk = fopen( szWorkFile2Name, "wb" );
	if ( !pWorkBlk )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile2Name );
		exit ( 1 );
	}

	sprintf( szWorkFile3Name, "%s.spr", argv[ 1 ] );
	pWorkSpr = fopen( szWorkFile3Name, "wb" );
	if ( !pWorkSpr )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile3Name );
		exit ( 1 );
	}

	sprintf( szWorkFile4Name, "%s.scl", argv[ 1 ] );
	pWorkScr = fopen( szWorkFile4Name, "wb" );
	if ( !pWorkScr )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile4Name );
		exit ( 1 );
	}

	sprintf( szWorkFile5Name, "%s.nme", argv[ 1 ] );
	pWorkNme = fopen( szWorkFile5Name, "wb" );
	if ( !pWorkNme )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile5Name );
		exit ( 1 );
	}

	sprintf( szWorkFile6Name, "%s.ojt", argv[ 1 ] );
	pWorkObj = fopen( szWorkFile6Name, "wb" );
	if ( !pWorkObj )
	{
       	fprintf( stderr, "Unable to create work file: %s\n", szWorkFile6Name );
		exit ( 1 );
	}

	/* Copy the engine to the target file. */
	pEngine = fopen( szEngineFilename, "r" );
	if ( !pEngine )
	{
		fputs( "Cannot find engine.inc\n", stderr );
		exit ( 1 );
	}

	lSize = fread( cChar, 1, 1, pEngine );			/* read first character of engine source. */

	while ( lSize > 0 )
	{
		fwrite( cChar, 1, 1, pObject );				/* write code to output file. */
		lSize = fread( cChar, 1, 1, pEngine );		/* read next byte of source. */
	}

	/* Allocate buffer for the target code. */
	cObjt = ( char* )malloc( MAX_EVENT_SIZE );
	cStart = cObjt;
	if ( !cObjt )
	{
		fputs( "Out of memory\n", stderr );
		exit ( 1 );
	}

	/* Process single file. */
	sprintf( szSourceFilename, "%s.agd", argv[ 1 ] );
	printf( "Sourcename: %s\n", szSourceFilename );

	/* Open source file. */
	pSource = fopen( szSourceFilename, "r" );
	lSize = fread( cBuff, 1, lSize, pSource );

	if ( pSource )
	{
		/* Establish its size. */
		fseek( pSource, 0, SEEK_END );
		lSize = ftell( pSource );
		rewind( pSource );

		/* Allocate buffer for the script source code. */
		cBuff = ( char* )malloc( sizeof( char )*lSize );
		if ( !cBuff )
		{
			fputs( "Out of memory\n", stderr );
			exit ( 1 );
		}

		/* Read source file into the buffer. */
		lSize = fread( cBuff, 1, lSize, pSource );

		/* Compile our target */
		cBufPos = cBuff;								/* start of buffer */
		nLine = 1;										/* line number */

		BuildFile();

		/* Close source file and free up the memory. */
		fclose( pSource );
		free( cBuff );

		/* user particle routine not defined, put a ret here. */
		if ( nParticle == 0 )
		{
			WriteInstructionAndLabel( "ptcusr: rts" );
		}

		if ( cWindow == 0 )
		{
			fputs( "DEFINEWINDOW missing\n", stderr );
			exit ( 1 );
		}

		fwrite( cStart, 1, nCurrent - nAddress, pObject );	/* write output to file. */
	}

	/* output textfile messages to assembly. */
	fclose( pWorkMsg );
	pWorkMsg = fopen( szWorkFile1Name, "rb" );
	if ( !pWorkMsg )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile1Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkMsg, 0, SEEK_END );
	lSize = ftell( pWorkMsg );
	rewind( pWorkMsg );

	/* Allocate buffer for the work file text. */
	cBuff = ( char* )malloc( sizeof( char )*lSize );

	if ( !cBuff )
	{
		fputs( "Out of memory\n", stderr );
		exit ( 1 );
	}

	cBufPos = cBuff;								/* start of buffer */

	/* Read text file into the buffer. */
	lSize = fread( cBuff, 1, lSize, pWorkMsg );

	CreateMessages();
	fwrite( cStart, 1, nCurrent - nAddress, pObject );
	free( cBuff );

	/* Now process the blocks. */
	fclose( pWorkBlk );
	pWorkBlk = fopen( szWorkFile2Name, "rb" );
	if ( !pWorkBlk )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile2Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkBlk, 0, SEEK_END );
	lSize = ftell( pWorkBlk );
	rewind( pWorkBlk );

	if ( lSize > 0 )
	{
		/* Allocate buffer for the work file text. */
		cBuff = ( char* )malloc( sizeof( char )*lSize );

		if ( !cBuff )
		{
			fputs( "Out of memory\n", stderr );
			exit ( 1 );
		}

		cBufPos = cBuff;								/* start of buffer */

		/* Read data file into the buffer. */
		lSize = fread( cBuff, 1, lSize, pWorkBlk );

		CreateBlocks();
		fwrite( cStart, 1, nCurrent - nAddress, pObject );
		free( cBuff );
	}

	/* Now process the sprites. */
	fclose( pWorkSpr );
	pWorkSpr = fopen( szWorkFile3Name, "rb" );
	if ( !pWorkSpr )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile3Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkSpr, 0, SEEK_END );
	lSize = ftell( pWorkSpr );
	rewind( pWorkSpr );

	if ( lSize > 0 )
	{
		/* Allocate buffer for the work file text. */
		cBuff = ( char* )malloc( sizeof( char )*lSize );

		if ( !cBuff )
		{
			fputs( "Out of memory\n", stderr );
			exit ( 1 );
		}

		cBufPos = cBuff;								/* start of buffer */

		/* Read data file into the buffer. */
		lSize = fread( cBuff, 1, lSize, pWorkSpr );

		CreateSprites();
		fwrite( cStart, 1, nCurrent - nAddress, pObject );
		free( cBuff );
	}

	/* Now process the screen layouts. */
	fclose( pWorkScr );
	pWorkScr = fopen( szWorkFile4Name, "rb" );
	if ( !pWorkScr )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile4Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkScr, 0, SEEK_END );
	lSize = ftell( pWorkScr );
	rewind( pWorkScr );

	if ( lSize > 0 )
	{
		/* Allocate buffer for the work file text. */
		cBuff = ( char* )malloc( sizeof( char )*lSize );

		if ( !cBuff )
		{
			fputs( "Out of memory\n", stderr );
			exit ( 1 );
		}

		cBufPos = cBuff;								/* start of buffer */

		/* Read data file into the buffer. */
		lSize = fread( cBuff, 1, lSize, pWorkScr );

		CreateScreens();
		fwrite( cStart, 1, nCurrent - nAddress, pObject );
		free( cBuff );
	}

	/* Now process the sprite positions. */
	fclose( pWorkNme );
	pWorkNme = fopen( szWorkFile5Name, "rb" );
	if ( !pWorkNme )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile5Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkNme, 0, SEEK_END );
	lSize = ftell( pWorkNme );
	rewind( pWorkNme );

	if ( lSize > 0 )
	{
		/* Allocate buffer for the work file text. */
		cBuff = ( char* )malloc( sizeof( char )*lSize );

		if ( !cBuff )
		{
			fputs( "Out of memory\n", stderr );
			exit ( 1 );
		}

		cBufPos = cBuff;								/* start of buffer */

		/* Read data file into the buffer. */
		lSize = fread( cBuff, 1, lSize, pWorkNme );

		CreatePositions();
		fwrite( cStart, 1, nCurrent - nAddress, pObject );
		free( cBuff );
	}

	/* generate assembly data for objects. */
	fclose( pWorkObj );
	pWorkObj = fopen( szWorkFile6Name, "rb" );
	if ( !pWorkObj )
	{
       	fprintf( stderr, "Unable to read work file: %s\n", szWorkFile6Name );
		exit ( 1 );
	}

	/* Establish its size. */
	fseek( pWorkObj, 0, SEEK_END );
	lSize = ftell( pWorkObj );
	rewind( pWorkObj );

	/* Allocate buffer for the work file text. */
	cBuff = ( char* )malloc( sizeof( char )*lSize );

	if ( !cBuff )
	{
		fputs( "Out of memory\n", stderr );
		exit ( 1 );
	}

	cBufPos = cBuff;								/* start of buffer */

	/* Read file into the buffer. */
	lSize = fread( cBuff, 1, lSize, pWorkObj );

	CreateObjects();
	CreatePalette();
	CreateFont();
	CreateHopTable();
	CreateKeyTable();

	fwrite( cStart, 1, nCurrent - nAddress, pObject );
	free( cBuff );

	/* Close target file and free up the memory. */
	fclose( pObject );
	free( cStart );

	printf( "Output: %s\n", szObjectFilename );

	return ( nErrors );
}

/* Sets up the label at the start of each event. */
void StartEvent( unsigned short int nEvent )
{
	unsigned short int nCount;
	unsigned char cLine[ 14 ];
	unsigned char *cChar = cLine;

	/* reset compilation address. */
	nCurrent = nAddress;
	nOpType = 0;
//	nRepeatAddress = ASMLABEL_DUMMY;
	nNextLabel = 0;
	nNumRepts = 0;
	for ( nCount = 0; nCount < NUM_REPEAT_LEVELS; nCount++ )
	{
		nReptBuff[ nCount ] = ASMLABEL_DUMMY;
	}

	cObjt = cStart + ( nCurrent - nAddress );
	if ( nEvent < 99 )
	{
		sprintf( cLine, "\nevnt%02d:", nEvent );		/* don't write label for dummy event. */
	}

	while ( *cChar )
	{
		*cObjt = *cChar++;
		cObjt++;
		nCurrent++;
	}

	/* Reset the IF address stack. */
	nNumIfs = 0;
	nIfSet = 0;
	nNumWhiles = 0;
	nGravity = 0;
	ResetIf();

	/* Reset number of DATA statement elements. */
	nList[ nEvent ] = 0;
	cData = 0;
	cDataRequired = 0;

	for ( nCount = 0; nCount < NUM_NESTING_LEVELS; nCount++ )
	{
		nIfBuff[ nCount ][ 0 ] = 0;
		nIfBuff[ nCount ][ 1 ] = 0;
		nWhileBuff[ nCount ][ 0 ] = 0;
		nWhileBuff[ nCount ][ 1 ] = 0;
		nWhileBuff[ nCount ][ 2 ] = 0;
	}
}

/* Build our object file */
void BuildFile( void )
{
//	unsigned short int nCount;
	unsigned short int nKeyword;

//	for ( nCount = 0; nCount < NUM_NESTING_LEVELS; nCount++ )
//	{
//		nIfBuff[ nCount ][ 0 ] = 0;
//		nIfBuff[ nCount ][ 1 ] = 0;
//		nWhileBuff[ nCount ][ 0 ] = 0;
//		nWhileBuff[ nCount ][ 1 ] = 0;
//		nWhileBuff[ nCount ][ 2 ] = 0;
//	}

	do
	{
		nKeyword = NextKeyword();
		if ( nKeyword < FINAL_INSTRUCTION &&
			 nKeyword > 0 )
		{
			Compile( nKeyword );
		}
	}
	while ( cBufPos < ( cBuff + lSize ) );

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();											/* always put a ret at the end. */
	}
}

void EndEvent( void )
{
	if ( nGravity > 0 )										/* did we use jump or fall? */
	{
		WriteInstruction( "jmp grav" );						/* finish with call to gravity routine. */
	}
	else
	{
		WriteInstruction( "rts" );							/* always put a ret at the end. */
	}

	if ( nNumIfs > 0 )
	{
		Error( "Missing ENDIF" );
	}

	if ( nNumRepts > 0 )
	{
		Error( "Missing ENDREPEAT" );
	}

	if ( nNumWhiles > 0 )
	{
		Error( "Missing ENDWHILE" );
	}

	if ( cDataRequired != 0 && cData == 0 )
	{
		Error( "Missing DATA" );
	}

	fwrite( cStart, 1, nCurrent - nAddress, pObject );		/* write output to file. */
	nEvent = -1;
	nCurrent = nAddress;
}

void EndDummyEvent( void )
{
	fwrite( cStart, 1, nCurrent - nAddress, pObject );		/* write output to file. */
	nEvent = -1;
	nCurrent = nAddress;
}

void CreateMessages( void )
{
	unsigned char *cSrc;									/* source pointer. */
	short int nStart = 1;

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nmsgdat:" );

	while ( ( cSrc - cBuff ) < lSize )
	{
		while ( *cSrc < 128 )								/* end marker? */
		{
			if ( *cSrc == 13 || *cSrc == 39 )
			{
				if ( nStart )
				{
					WriteText( "\n        .byte " );						/* start of text message */
				}
				else
				{
					WriteText( "\"," );						/* end quote and comma */
				}
				WriteNumber( *cSrc++ );						/* write as numeric outside quotes */
				nStart = 1;
			}
			else
			{
				if ( nStart )
				{
					WriteText( "\n        .byte \"" );						/* start of text message */
					nStart = 0;
				}
				*cObjt = *cSrc++;
				cObjt++;
				nCurrent++;
			}
		}

		if ( nStart )
		{
			WriteText( "\n        .byte " );						/* start of text message */
		}
		else
		{
			WriteText( "\"," );								/* end quote and comma */
		}

		WriteNumber( *cSrc++ );								/* write last char with terminator bit */
		nStart = 1;
	}

	/* Number of messages */
	WriteText( "\nnummsg:" );
	WriteText( "\n        .byte " );						/* start of text message */
	WriteNumber( nMessageNumber );
}

void CreateBlocks( void )
{
	short int nData;
	unsigned char *cSrc;									/* source pointer. */
	short int nCounter = 0;
	char cType[ 256 ];
	short int nAttr[ 256 ];

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nchgfx:" );

	do
	{
		WriteText( "\n        .byte " );						/* start of text message */
		nData = 0;
		cType[ nCounter ] = *cSrc++;						/* store type in array */
		while ( nData++ < 7 )
		{
			WriteNumber( *cSrc++ );							/* write byte of data */
			WriteText( "," );								/* put a comma */
		}

		WriteNumber( *cSrc++ );								/* write final byte of graphic data */
		nAttr[ nCounter ] = *cSrc++;						/* store attribute in array */
		nCounter++;
	}
	while ( ( cSrc - cBuff ) < lSize );

//	/* Now do the block attributes. */
//	WriteText( "\nbcol:" );
//	nData = 0;
//	while ( nData < nCounter )
//	{
//		WriteText( "\n        .byte " );
//		WriteNumber( nAttr[ nData++ ] );
//	}

	/* Now do the block properties. */
	WriteText( "\nbprop:" );
	nData = 0;
	while ( nData < nCounter )
	{
		WriteText( "\n        .byte " );
		WriteNumber( cType[ nData++ ] );
	}
}

void CreateSprites( void )
{
	short int nData;
	unsigned char *cSrc;									/* source pointer. */
	short int nCounter = 0;
	short int nFrame = 0;
	short int nShifts = 0;
	short int nLoop = 0;
	unsigned char cByte[ 3 ];
	char cFrames[ 256 ];

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nsprgfx:" );
	cSrc = cBufPos;

	do
	{
		cFrames[ nCounter ] = *cSrc++;						/* store frames in array. */
		cBufPos = cSrc;

		for ( nFrame = 0; nFrame < cFrames[ nCounter ]; nFrame++ )
		{
			for ( nShifts = 0; nShifts < 4; nShifts++ )
			{
				cSrc = cBufPos;
				WriteText( "\n        .byte " );						/* start of text message */
				nData = 0;
				while ( nData++ < 16 )
				{
					cByte[ 0 ] = *cSrc++;
					cByte[ 1 ] = *cSrc++;
					cByte[ 2 ] = 0;

					for( nLoop = 0; nLoop < nShifts; nLoop++ )		/* pre-shift the sprite */
					{
						cByte[ 2 ] = cByte[ 1 ] << 6;
						cByte[ 1 ] >>= 2;
						cByte[ 1 ] |= cByte[ 0 ] << 6;
						cByte[ 0 ] >>= 2;
						cByte[ 0 ] |= cByte[ 2 ];
					}

					WriteNumber( cByte[ 0 ] );						/* write byte of data */
					WriteText( "," );								/* put a comma */
					WriteNumber( cByte[ 1 ] );						/* write byte of data */
					if ( nData < 16 )
					{
						WriteText( "," );							/* more to come; put a comma */
					}
				}
			}

			cBufPos = cSrc;
		}

		nCounter++;
	}
	while ( ( cSrc - cBuff ) < lSize );

	/* Now do the frame list. */
	WriteText( "\nfrmlst:" );
	nData = 0;
	nFrame = 0;
	while ( nData < nCounter )
	{
//		WriteText( "\n      .byte " );
		WriteInstruction( ".byte " );
		WriteNumber( nFrame );
		WriteText( "," );
		WriteNumber( cFrames[ nData ] );
		nFrame += cFrames[ nData++ ];
	}

	WriteText( "," );
	WriteNumber( nFrame );
	WriteText( ",0" );
}

void CreateScreens( void )
{
	short int nThisScreen = 0;
	short int nBytes = 0;										/* bytes to write. */
	short int nByteCount;
	short int nColumn = 0;
	short int nCount = 0;
	short int nByte = 0;
	short int nFirstByte = -1;
	short int nScreenSize = 0;
	unsigned char *cSrc;										/* source pointer. */

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nscdat:" );

	/* write compressed screen sizes */
	nColumn = 99;

	while ( nThisScreen++ < nScreen )
	{
		nScreenSize = 0;
		nBytes = nWinWidth * nWinHeight;

		while ( nBytes > 0 )
		{
			nCount = 0;
			nFirstByte = *cSrc;									/* fetch first byte. */

			do
			{
				nByte = *++cSrc;
				nCount++;										/* count the bytes. */
				nBytes--;
			}
			while ( nByte == nFirstByte && nCount < 256 && nBytes > 0 );

			if ( nCount > 3 )
			{
				nScreenSize += 3;
			}
			else
			{
				while ( nCount-- > 0 )
				{
					nScreenSize++;
				}
			}
		}

		if ( nColumn > 24 )
		{
			WriteInstruction( ".word " );
			nColumn = 0;
		}
		else
		{
			WriteText( "," );
			nColumn++;
		}

		WriteNumber( nScreenSize );
	}

	/* Restore source address. */
	cSrc = cBufPos;

	/* Now do the compression. */
	nThisScreen = 0;

	while ( nThisScreen++ < nScreen )
	{
		nBytes = nWinWidth * nWinHeight;
		nColumn = 99;											/* fresh .byte line for each screen. */

		while ( nBytes > 0 )
		{
			nCount = 0;
			nFirstByte = *cSrc;									/* fetch first byte. */

			do
			{
				nCount++;										/* count the bytes. */
				nBytes--;
				nByte = *++cSrc;
			}
			while ( nByte == nFirstByte && nCount < 256 && nBytes > 0 );

			if ( nColumn > 32 )
			{
				nColumn = 0;
				WriteInstruction( ".byte " );
			}
			else
			{
				WriteText( "," );
			}

			if ( nCount > 3 )
			{
				WriteNumber( 255 );
				WriteText( "," );
				WriteNumber( nFirstByte );
				WriteText( "," );
				WriteNumber( nCount & 255 );
				nColumn += 3;
			}
			else
			{
				while ( nCount-- > 0 )
				{
					WriteNumber( nFirstByte );
					nColumn++;
					if ( nCount > 0 )
					{
						WriteText( "," );
					}
				}
			}
		}
	}

	/* Now store the number of screens in the game. */
	WriteText( "\nnumsc:" );
	WriteText( "\n        .byte " );
	WriteNumber( nScreen );
}

void CreateScreens2( void )
{
	short int nThisScreen = 0;
	short int nBytes = nWinWidth * nWinHeight;				/* bytes to write. */
	short int nColumn = 0;
	short int nCount = 0;
	unsigned char *cSrc;									/* source pointer. */

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nscdat:" );
	nCount = 0;

	while ( nThisScreen < nScreen )
	{
		WriteInstruction( ".word " );
		WriteNumber( nBytes );
		nCount = 0;
		nColumn = 33;
		while ( nCount < nBytes )
		{
			if ( nColumn >= nWinWidth )
			{
				WriteInstruction( ".byte " );
				nColumn = 0;
			}
			else
			{
				WriteText( "," );
			}

			WriteNumber( *cSrc++ );							/* write byte of data */
			nColumn++;
			nCount++;
		}
		nThisScreen++;
	}

	/* Now store the number of screens in the game. */
	WriteText( "\nnumsc:");
	WriteText( "        .byte " );
	WriteNumber( nScreen );
}

void CreatePositions( void )
{
	short int nThisScreen = 0;
	short int nCount;
	short int nData;
	short int nPos = 0;
	char cScrn;
	unsigned char *cSrc;									/* source pointer. */

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nnmedat:" );
	WriteText( "\n        .byte " );
	cScrn = *cSrc++;										/* get screen. */

	while ( nPos < nPositions && nThisScreen < nScreen )
	{
		while ( cScrn > nThisScreen )						/* write null entries for screens with no sprites. */
		{
			WriteNumber( 255 );
			nThisScreen++;
			WriteText( "," );
		}

		for ( nCount = 0; nCount < 4; nCount++ )
		{
			nData = *cSrc++;
			WriteNumber( nData );
			WriteText( "," );
		}

		nPos++;												/* one more position defined. */

		if ( nPos < nPositions )
		{
			cScrn = *cSrc++;								/* get screen. */
			if ( cScrn != nThisScreen )
			{
				WriteNumber( 255 );							/* end marker for screen. */
				WriteInstruction( ".byte " );
//				WriteText( "\n" );
				nThisScreen++;
			}
		}
		else
		{
			WriteNumber( 255 );								/* end marker for whole game. */
			nThisScreen = nScreen;
		}
	}
}

void CreateObjects( void )
{
	unsigned char *cSrc;									/* source pointer. */
	short int nCount = 0;
	short int nDatum;
	unsigned char cAttr, cScrn, cX, cY, cDatum;

	/* Set up source address. */
	cSrc = cBufPos;

	/* reset compilation address. */
	nCurrent = nAddress;
	nNextLabel = 0;

	cObjt = cStart + ( nCurrent - nAddress );
	WriteText( "\nNUMOBJ = " );
	WriteNumber( nObjects );

	if ( nObjects == 0 )
	{
		WriteText( "\nobjdta:");
		WriteText( ".word 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0" );
		WriteInstruction( ".byte 0,254,0,0,254,0,0" );
	}
	else
	{
		WriteText( "\nobjdta:" );

		for ( nCount = 0; nCount < nObjects; nCount++ )
		{
			cAttr = *cSrc++;								/* get attribute. */
			cScrn = *cSrc++;								/* get screen. */
			cY = *cSrc++;									/* get x. */
			cX = *cSrc++;									/* get y. */
			WriteInstruction( ".byte " );

			for( nDatum = 0; nDatum < 32; nDatum++ )
			{
				cDatum = *cSrc++;
				WriteNumber( cDatum );
				WriteText( "," );
			}

//			WriteNumber( cAttr );
//			WriteText( "," );
			WriteNumber( cScrn );
			WriteText( "," );
			WriteNumber( cY );
			WriteText( "," );
			WriteNumber( cX );
			WriteText( "," );
			WriteNumber( cScrn );
			WriteText( "," );
			WriteNumber( cY );
			WriteText( "," );
			WriteNumber( cX );
		}
	}
}

void CreatePalette( void )
{
	cPalette = 0;
//	WriteText( "\npalett:" );

//	while ( cPalette < 64 )
//	{
//		if ( ( cPalette & 15 ) == 0 )
//		{
//			WriteInstruction( ".byte " );
//		}
//		else
//		{
//			WriteText( "," );
//		}
//
//		WriteNumber( cDefaultPalette[ cPalette++ ] );
//	}
}

void CreateFont( void )
{
	short int nChar = 0;
	short int nByte;

	if ( nUseFont > 0 )
	{
		WriteText( "\nfont:" );
		for ( nChar = 0; nChar < 96; nChar++ )
		{
			WriteInstruction( ".byte " );
			for ( nByte = 0; nByte < 8; nByte++ )
			{
				WriteNumber( cDefaultFont[ nChar * 8 + nByte ] );
				if ( nByte < 7 )
				{
					WriteText( "," );
				}
			}
		}
	}
	else
	{
		WriteText( "\nfont:   = $9800" );
	}
}

void CreateHopTable( void )
{
	short int nChar = 0;

	WriteText( "\njtab:" );
	nChar = 0;
	WriteInstruction( ".byte " );

	if ( nUseHopTable > 0 )
	{
		while ( cDefaultHop[ nChar ] != 99 )
		{
			WriteNumber( cDefaultHop[ nChar++ ] );
			WriteText( "," );
		}
	}

	WriteNumber( 99 );
}

void CreateKeyTable( void )
{
	short int nKey;

	WriteText( "\nkeys:   .byte " );

	for ( nKey = 0; nKey < 10; nKey++ )
	{
		WriteNumber( cDefaultKeys[ nKey ] );
		WriteText( "," );
	}

	WriteNumber( cDefaultKeys[ nKey ] );
}

/* Return next keyword number */
unsigned short int NextKeyword( void )
{
	unsigned short int nFound;
	unsigned short int nSrc = 0;
	unsigned short int nResWord = INS_IF;					/* ID of reserved word we're checking. */
	unsigned short int nWord = 0;
	unsigned short int nLength = 0;							/* length of literal string. */
	const unsigned char *cRes;								/* reserved word pointer. */
	unsigned char *cSrcSt;									/* source pointer, word start. */
	unsigned char *cSrc;									/* source pointer. */
	unsigned char cText;
	unsigned char cEnd = 0;

	/* Set up source address. */
	cSrc = cBufPos;
	nFound = 0;

	/* Skip spaces, newlines, comments etc. */
	do
	{
		if ( *cSrc == ';' )									/* comment marker? */
		{
			do												/* skip to next line */
			{
				cSrc++;
			}
			while ( *cSrc != LF && *cSrc != CR );
//			nLine++;
		}
		else
		{
			if ( isdigit( *cSrc ) ||						/* valid character? */
				 isalpha( *cSrc ) ||
				 *cSrc == '$' ||
				 ( *cSrc >= '<' && *cSrc <= '>' ) )
			{
				nFound++;									/* flag as legitimate. */
			}
			else											/* treat as space. */
			{
				CountLines( *cSrc );

				if ( *cSrc == '"' )							/* found a string? */
				{
					nLength = 0;
					cSrc++;									/* skip to first letter */
					while( *cSrc != '"' || cEnd > 0 )
					{
						CountLines( *cSrc );				/* line feed inside quotes */
						cText = *cSrc;						/* this is the character to write */
						cSrc++;
						if ( ( cSrc - cBuff ) >= lSize )
						{
							cText |= 128;					/* terminate the end of the string */
							cEnd++;
						}
						if ( *cSrc == '"' || cEnd > 0 )
						{
							cText |= 128;					/* terminate the end of the string */
						}
						fwrite( &cText, 1, 1, pWorkMsg );	/* write character to workfile. */
						nLength++;
					}
					if ( nLength > 0 )
					{
						nFound++;
						cBufPos = ++cSrc;
						return( INS_STR );
					}
				}
				else
				{
					if ( *cSrc == '\'' )					/* found an ASCII character? */
					{
						if ( *( cSrc + 2 ) == '\'' &&		/* single char within single quote? */
							 ( 2 + cSrc - cBuff ) < lSize )
						{
							cBufPos = cSrc;
							return( INS_NUM );
						}
					}
				}
				cSrc++;										/* skip character */
			}
		}
	}
	while ( !nFound && ( ( cSrc - cBuff ) < lSize ) );

	if ( !nFound )											/* end of file */
	{
		cBufPos = cBuff + lSize + 1;
		return( 0 );
	}

	if ( isdigit( *cSrc ) ||								/* encountered a number. */
		 *cSrc == '$' )
	{
		cBufPos = cSrc;
		return( INS_NUM );
	}

	/* Point to the reserved words and off we go */
	cSrcSt = cSrc;
	cRes = keywrd;
	nFound = 0;

	do
	{
		if ( toupper( *cSrc ) == *cRes )
		{
			cSrc++;
			cRes++;
		}
		else
		{
			if ( *cRes == '.' &&							/* end marker for reserved word? */
//				 ( *cSrc <= '<' || *cSrc >= '>' ) &&
				 ( toupper( *cSrc ) < 'A' ||				/* no more of source word? */
				   toupper( *cSrc ) > 'Z' ||
				   cSrc >= ( cBuff + lSize ) ) )			/* EOF before NL/CR. */
			{
				nFound++;									/* great, matched a reserved word. */
			}
			else
			{
				nResWord++;									/* keep tally of words we've skipped. */
				if ( nResWord < FINAL_INSTRUCTION )
				{
					while ( *cRes++ != '.' );				/* find next reserved word. */
					cSrc = cSrcSt;							/* back to start of source word. */
				}
				else
				{
					while ( isalpha( *cSrc ) ||				/* find end of unrecognised word. */
						 ( *cSrc >= '<' && *cSrc <= '>' ) )
					{
						cSrc++;
					}
				}
			}
		}
	}
	while ( !nFound && nResWord < FINAL_INSTRUCTION );

	if ( !nFound )
	{
		Error( "Unrecognised instruction" );
	}

	cBufPos = cSrc;

	/* Treat constants as numbers */
	if ( nResWord >= CON_RIGHT &&
		 nResWord < LAST_CONSTANT )
	{
		cConstant++;
		nConstant = nConstantsTable[ nResWord - CON_RIGHT ];
		nResWord = INS_NUM;
	}

	return ( nResWord );
}

void CountLines( char cSrc )
{
	if ( cSrc == LF )
	{
		nLine++;											/* count lines */
	}
}

/* Return number. */
unsigned short int GetNum( short int nBits )
{
	unsigned long int lNum = 0;
	unsigned short int nNum = 0;
	unsigned char *cSrc;									/* source pointer. */

	if ( cConstant > 0 )									/* dealing with a constant? */
	{
		cConstant = 0;										/* expect a number next time. */
		return ( nConstant );
	}

	cSrc = cBufPos;

	if ( isdigit( *cSrc ) )									/* plain old numeric */
	{
		while( isdigit( *cSrc ) && cSrc < ( cBuff + lSize ) )
		{
			lNum = 10 * lNum + ( *cSrc - '0' );
			cSrc++;
		}
	}
	else
	{
		if ( *cSrc == '$' )									/* hexadecimal */
		{
			cSrc++;											/* skip to digits */
			while( isdigit( *cSrc ) ||
				 ( toupper( *cSrc ) >= 'A' && toupper( *cSrc ) <= 'F' ) )
			{
				lNum <<= 4;
				if ( isdigit( *cSrc ) )
				{
					lNum += ( *cSrc - '0' );
				}
				else
				{
					lNum += ( toupper( *cSrc ) - 55 );
				}
				cSrc++;
			}
		}
		else												/* ASCII char within single quotes */
		{
			lNum = *( ++cSrc );
			cSrc += 2;
		}
	}

	if ( nBits == 8 && lNum > 255 )
	{
		Error( "Number too big, must be between 0 and 255" );
	}
	else
	{
		if ( lNum > 65535 )
		{
			Error( "Number too big, must be between 0 and 65535" );
		}
	}

	nNum = ( short int )lNum;

	if ( nBits == 8 )
	{
		nNum &= 0xff;
	}

	cBufPos = cSrc;

	return ( nNum );
}


/* Parsed an instruction, this routine deals with it. */

void Compile( unsigned short int nInstruction )
{
	switch( nInstruction )
	{
		case INS_IF:
			CR_If();
			break;
		case INS_WHILE:
			CR_While();
			break;
		case INS_SPRITEUP:
			CR_SpriteUp();
			break;
		case INS_SPRITEDOWN:
			CR_SpriteDown();
			break;
		case INS_SPRITELEFT:
			CR_SpriteLeft();
			break;
		case INS_SPRITERIGHT:
			CR_SpriteRight();
			break;
		case INS_ENDIF:
			CR_EndIf();
			break;
		case INS_ENDWHILE:
			CR_EndWhile();
			break;
		case INS_CANGOUP:
			CR_CanGoUp();
			break;
		case INS_CANGODOWN:
			CR_CanGoDown();
			break;
		case INS_CANGOLEFT:
			CR_CanGoLeft();
			break;
		case INS_CANGORIGHT:
			CR_CanGoRight();
			break;
		case INS_LADDERABOVE:
			CR_LadderAbove();
			break;
		case INS_LADDERBELOW:
			CR_LadderBelow();
			break;
		case INS_DEADLY:
			CR_Deadly();
			break;
		case INS_CUSTOM:
			CR_Custom();
			break;
		case INS_TO:
		case INS_FROM:
			CR_To();
			break;
		case INS_BY:
			CR_By();
			break;
		case INS_NUM:
			CR_Arg();
			break;
		case OPE_EQU:
		case OPE_GRT:
		case OPE_GRTEQU:
		case OPE_NOT:
		case OPE_LESEQU:
		case OPE_LES:
			CR_Operator( nInstruction );
			break;
		case INS_LET:
			ResetIf();
			break;
		case INS_ELSE:
			CR_Else();
			break;
		case VAR_EDGET:
		case VAR_EDGEB:
		case VAR_EDGEL:
		case VAR_EDGER:
		case VAR_SCREEN:
		case VAR_LIV:
		case VAR_A:
		case VAR_B:
		case VAR_C:
		case VAR_D:
		case VAR_E:
		case VAR_F:
		case VAR_G:
		case VAR_H:
		case VAR_I:
		case VAR_J:
		case VAR_K:
		case VAR_L:
		case VAR_M:
		case VAR_N:
		case VAR_O:
		case VAR_P:
		case VAR_Q:
		case VAR_R:
		case VAR_S:
		case VAR_T:
		case VAR_U:
		case VAR_V:
		case VAR_W:
		case VAR_Z:
		case VAR_CONTROL:
		case VAR_LINE:
		case VAR_COLUMN:
		case VAR_CLOCK:
		case VAR_RND:
		case VAR_OBJ:
		case VAR_OPT:
		case VAR_BLOCK:
		case SPR_TYP:
		case SPR_IMG:
		case SPR_FRM:
		case SPR_X:
		case SPR_Y:
		case SPR_DIR:
		case SPR_PMA:
		case SPR_PMB:
		case SPR_AIRBORNE:
		case SPR_SPEED:
			CR_Pam( nInstruction );
			break;
		case INS_GOT:
			CR_Got();
			break;
		case INS_KEY:
			CR_Key();
			break;
		case INS_DEFINEKEY:
			CR_DefineKey();
			break;
		case INS_COLLISION:
			CR_Collision();
			break;
		case INS_ANIM:
			CR_Anim();
			break;
		case INS_ANIMBACK:
			CR_AnimBack();
			break;
		case INS_PUTBLOCK:
			CR_PutBlock();
			break;
		case INS_DIG:
			CR_Dig();
			break;
		case INS_NEXTLEVEL:
			CR_NextLevel();
			break;
		case INS_RESTART:
			CR_Restart();
			break;
		case INS_SPAWN:
			CR_Spawn();
			break;
		case INS_REMOVE:
			CR_Remove();
			break;
		case INS_GETRANDOM:
			CR_GetRandom();
			break;
		case INS_RANDOMIZE:
			CR_Randomize();
			break;
		case INS_DISPLAYHIGH:
			CR_DisplayHighScore();
			break;
		case INS_DISPLAYSCORE:
			CR_DisplayScore();
			break;
		case INS_DISPLAYBONUS:
			CR_DisplayBonus();
			break;
		case INS_SCORE:
			CR_Score();
			break;
		case INS_BONUS:
			CR_Bonus();
			break;
		case INS_ADDBONUS:
			CR_AddBonus();
			break;
		case INS_ZEROBONUS:
			CR_ZeroBonus();
			break;
		case INS_SOUND:
			CR_Sound();
			break;
		case INS_BEEP:
			CR_Beep();
			break;
		case INS_CRASH:
			CR_Crash();
			break;
		case INS_CLS:
			CR_ClS();
			break;
		case INS_BORDER:
			CR_Border();
			break;
		case INS_COLOUR:
			CR_Colour();
			break;
		case INS_PAPER:
			CR_Paper();
			break;
		case INS_INK:
			CR_Ink();
			break;
		case INS_CLUT:
			CR_Clut();
			break;
		case INS_DELAY:
			CR_Delay();
			break;
		case INS_PRINTMODE:
			CR_PrintMode();
			break;
		case INS_PRINT:
			CR_Print();
			break;
		case INS_AT:
			CR_At();
			break;
		case INS_CHR:
			CR_Chr();
			break;
		case INS_MENU:
			CR_Menu();
			break;
		case INS_INVENTORY:
			CR_Inventory();
			break;
		case INS_KILL:
			CR_Kill();
			break;
		case INS_ADD:
			nOpType = 129;									/* code for ADD A,C (needed by CR_To). */
			CR_AddSubtract();
			break;
		case INS_SUB:
			nOpType = 145;									/* code for SUB C (needed by CR_To). */
			CR_AddSubtract();
			break;
		case INS_DISPLAY:
			CR_Display();
			break;
		case INS_SCREENUP:
			CR_ScreenUp();
			break;
		case INS_SCREENDOWN:
			CR_ScreenDown();
			break;
		case INS_SCREENLEFT:
			CR_ScreenLeft();
			break;
		case INS_SCREENRIGHT:
			CR_ScreenRight();
			break;
		case INS_WAITKEY:
			CR_WaitKey();
			break;
		case INS_JUMP:
			CR_Jump();
			break;
		case INS_FALL:
			CR_Fall();
			break;
		case INS_TABLEJUMP:
			CR_TableJump();
			break;
		case INS_TABLEFALL:
			CR_TableFall();
			break;
		case INS_OTHER:
			CR_Other();
			break;
		case INS_SPAWNED:
			CR_Spawned();
			break;
		case INS_ORIGINAL:
			CR_Original();
			break;
		case INS_ENDGAME:
			CR_EndGame();
			break;
		case INS_GET:
			CR_Get();
			break;
		case INS_PUT:
			CR_Put();
			break;
		case INS_REMOVEOBJ:
			CR_RemoveObject();
			break;
		case INS_DETECTOBJ:
			CR_DetectObject();
			break;
		case INS_ASM:
			CR_Asm();
			break;
		case INS_EXIT:
			CR_Exit();
			break;
		case INS_REPEAT:
			CR_Repeat();
			break;
		case INS_ENDREPEAT:
			CR_EndRepeat();
			break;
		case INS_MULTIPLY:
			CR_Multiply();
			break;
		case INS_DIVIDE:
			CR_Divide();
			break;
		case INS_SPRITEINK:
			CR_SpriteInk();
			break;
		case INS_TRAIL:
			CR_Trail();
			break;
		case INS_LASER:
			CR_Laser();
			break;
		case INS_STAR:
			CR_Star();
			break;
		case INS_EXPLODE:
			CR_Explode();
			break;
		case INS_REDRAW:
			CR_Redraw();
			break;
		case INS_SILENCE:
			CR_Silence();
			break;
		case INS_CLW:
			CR_ClW();
			break;
		case INS_PALETTE:
			CR_Palette();
			break;
		case INS_GETBLOCK:
			CR_GetBlock();
			break;
		case INS_PLOT:
			CR_Plot();
			break;
		case INS_UNDOSPRITEMOVE:
			CR_UndoSpriteMove();
			break;
		case INS_READ:
			CR_Read();
			break;
		case INS_DATA:
			CR_Data();
			break;
		case INS_RESTORE:
			CR_Restore();
			break;
		case INS_TICKER:
			CR_Ticker();
			break;
		case INS_USER:
			CR_User();
			break;
		case INS_DEFINEPARTICLE:
			CR_DefineParticle();
			break;
		case INS_PARTICLEUP:
			CR_ParticleUp();
			break;
		case INS_PARTICLEDOWN:
			CR_ParticleDown();
			break;
		case INS_PARTICLELEFT:
			CR_ParticleLeft();
			break;
		case INS_PARTICLERIGHT:
			CR_ParticleRight();
			break;
		case INS_DECAYPARTICLE:
			CR_ParticleTimer();
			break;
		case INS_NEWPARTICLE:
			CR_StartParticle();
			break;
		case INS_MESSAGE:
			CR_Message();
			break;
		case INS_STOPFALL:
			CR_StopFall();
			break;
		case INS_GETBLOCKS:
			CR_GetBlocks();
			break;
		case INS_CONTROLMENU:
			CR_ControlMenu();
			break;
		case CMP_EVENT:
			CR_Event();
			break;
		case CMP_DEFINEBLOCK:
			CR_DefineBlock();
			break;
		case CMP_DEFINEWINDOW:
			CR_DefineWindow();
			break;
		case CMP_DEFINESPRITE:
			CR_DefineSprite();
			break;
		case CMP_DEFINESCREEN:
			CR_DefineScreen();
			break;
		case CMP_SPRITEPOSITION:
			CR_SpritePosition();
			break;
		case CMP_DEFINEOBJECT:
			CR_DefineObject();
			break;
		case CMP_MAP:
			CR_Map();
			break;
		case CMP_DEFINEPALETTE:
			CR_DefinePalette();
			break;
		case CMP_DEFINEMESSAGES:
			CR_DefineMessages();
			break;
		case CMP_DEFINEFONT:
			CR_DefineFont();
			break;
		case CMP_DEFINEJUMP:
			CR_DefineJump();
			break;
		case CMP_DEFINECONTROLS:
			CR_DefineControls();
			break;
		default:
			printf( "Instruction %d not handled\n", nInstruction );
			break;
	}
}

void ResetIf( void )
{
	nIfSet = 0;
	nPamType = NO_ARGUMENT;
	nPamNum = 255;
}

/****************************************************************************************************************/
/* Individual compilation routines.                                                                             */
/****************************************************************************************************************/

void CR_If( void )
{
	nLastOperator = OPE_EQU;
	nLastCondition = INS_IF;
	ResetIf();
	nIfSet = 1;
}

void CR_While( void )
{
	nLastOperator = OPE_EQU;
	nLastCondition = INS_WHILE;
	ResetIf();
	nIfSet = 1;
	nNextLabel = nCurrent;									/* label for unconditional jump to start of while loop. */
	nWhileBuff[ nNumWhiles ][ 2 ] = nCurrent;				/* remember label for ENDWHILE. */
	nReadingControls = 0;									/* haven't read the joystick/keyboard in this loop yet. */
}

void CR_SpriteUp( void )
{
	WriteInstruction( "ldy #8" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "sec" );
	WriteInstruction( "sbc #2" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_SpriteDown( void )
{
	WriteInstruction( "ldy #8" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "clc" );
	WriteInstruction( "adc #2" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_SpriteLeft( void )
{
	WriteInstruction( "ldy #9" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "sec" );
	WriteInstruction( "sbc #2" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_SpriteRight( void )
{
	WriteInstruction( "ldy #9" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "clc" );
	WriteInstruction( "adc #2" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_EndIf( void )
{
	unsigned short int nAddr1;
	unsigned short int nAddr2;

	if ( nNumIfs > 0 )
	{
		nAddr2 = nCurrent;									/* where we are is ENDIF address. */

		if ( nIfBuff[ --nNumIfs ][ 1 ] > 0 )				/* is there a second jump address to write? */
		{
			nAddr1 = nIfBuff[ nNumIfs ][ 1 ];				/* where to put label after conditional jump. */
			nCurrent = nAddr1;								/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful IF. */
			nCurrent = nIfBuff[ nNumIfs ][ 0 ];				/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful IF. */

			nIfBuff[ nNumIfs ][ 1 ] = 0;					/* done with this now, don't rewrite address later. */
		}
		else
		{
			nAddr1 = nIfBuff[ nNumIfs ][ 0 ];				/* where to put label after conditional jump. */
//			nAddr2 = nCurrent;								/* where we are is ENDIF address. */
			nCurrent = nAddr1;								/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful IF. */
		}

		nNextLabel = nCurrent;
		nCurrent = nAddr2;
		nNextLabel = nAddr2;
	}
	else
	{
		Error( "ENDIF without IF" );
	}
}

void CR_EndWhile( void )
{
	unsigned short int nAddr1;
	unsigned short int nAddr2;
	unsigned short int nAddr3;

	if ( nNumWhiles > 0 )
	{
		if ( nReadingControls > 0 )							/* are we reading the joystick in this loop? */
		{
			WriteInstruction( "jsr joykey" );				/* user might be writing a sub-game! */
			nReadingControls = 0;							/* not foolproof, but it's close enough. */
		}

		WriteInstruction( "jmp " );
		WriteLabel( nWhileBuff[ --nNumWhiles ][ 2 ] );		/* unconditional loop back to start of while. */

		nAddr2 = nCurrent;									/* where we are is ENDIF address. */

//		if ( nWhileBuff[ --nNumWhiles ][ 1 ] > 0 )			/* is there a second jump address to write? */
		if ( nWhileBuff[ nNumWhiles ][ 1 ] > 0 )			/* is there a second jump address to write? */
		{
			nAddr1 = nWhileBuff[ nNumWhiles ][ 1 ];			/* where to put label after conditional jump. */
			nCurrent = nAddr1;								/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful WHILE. */
			nCurrent = nWhileBuff[ nNumWhiles ][ 0 ];		/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful WHILE. */
			nWhileBuff[ nNumWhiles ][ 1 ] = 0;				/* done with this now, don't rewrite address later. */
		}
		else
		{
			nAddr1 = nWhileBuff[ nNumWhiles ][ 0 ];			/* where to put label after conditional jump. */
			nCurrent = nAddr1;								/* go back to end of original condition. */
			WriteLabel( nAddr2 );							/* set jump address for unsuccessful WHILE. */
		}

		nNextLabel = nCurrent;
		nCurrent = nAddr2;
		nNextLabel = nAddr2;
//		WriteInstruction( "jmp " );
//		WriteLabel( nWhileBuff[ nNumWhiles ][ 2 ] );		/* unconditional loop back to start of while. */
		nWhileBuff[ nNumWhiles ][ 2 ] = 0;
	}
	else
	{
		Error( "ENDWHILE without WHILE" );
	}
}

void CR_CanGoUp( void )
{
	WriteInstruction( "jsr cangu" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_CanGoDown( void )
{
	WriteInstruction( "jsr cangd" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_CanGoLeft( void )
{
	WriteInstruction( "jsr cangl" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_CanGoRight( void )
{
	WriteInstruction( "jsr cangr" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_LadderAbove( void )
{
	WriteInstruction( "jsr laddu" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_LadderBelow( void )
{
	WriteInstruction( "jsr laddd" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_Deadly( void )
{
	WriteInstruction( "lda #DEADLY" );
	WriteInstruction( "sta z80_b");
	WriteInstruction( "jsr tded" );
	WriteInstruction( "cmp z80_b" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_Custom( void )
{
	WriteInstruction( "lda #CUSTOM" );
	WriteInstruction( "sta z80_b");
	WriteInstruction( "jsr tded" );
	WriteInstruction( "cmp z80_b" );
	WriteInstruction( "beq :+" );
	WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_To( void )
{
	if ( nOpType > 0 )
	{
		nAnswerWantedHere = CompileArgument();
		if ( nOpType == 129 )
		{
			if ( nIncDec > 0 )
			{
				WriteInstruction( "clc" );
				WriteInstruction( "adc #1" );
			}
			else
			{
				WriteInstruction( "clc" );
				WriteInstruction( "adc z80_c" );
			}
		}
		else
		{
			if ( nIncDec > 0 )
			{
				WriteInstruction( "sec" );
				WriteInstruction( "sbc #1" );
			}
			else
			{
				WriteInstruction( "sec" );
				WriteInstruction( "sbc z80_c" );
			}
		}
		if ( nAnswerWantedHere >= FIRST_PARAMETER &&
			 nAnswerWantedHere <= LAST_PARAMETER )
		{
			CR_PamC( nAnswerWantedHere );					/* put accumulator in variable or sprite parameter. */
		}
		nIncDec = nOpType = 0;
	}
	else
	{
		Error( "ADD or SUBTRACT missing" );
	}
}

void CR_By( void )
{
	char cGenericCalculation = 0;
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nOpType > 0 )
	{
		if ( nArg1 == INS_NUM )								/* it's a number, check if we can do a shift instead. */
		{
			nArg2 = GetNum( 8 );
			switch( nArg2 )
			{
				case 1:										/* multiply/divide by 1 has no effect. */
					break;

				case 3:
				case 5:
				case 6:
				case 10:
					if ( nOpType == INS_MULTIPLY )
					{
						CompileShift( nArg2 );				/* compile a shift instead. */
					}
					else
					{
						cGenericCalculation++;
					}
					break;
				case 2:
				case 4:
				case 8:
				case 16:
				case 32:
				case 64:
				case 128:
					CompileShift( nArg2 );					/* compile a shift instead. */
					break;
				default:
					cGenericCalculation++;
			}
		}
		else												/* not a number, don't know what this will be. */
		{
			cGenericCalculation++;
		}

		if ( cGenericCalculation > 0 )
		{
			WriteInstruction( "sta z80_d" );
			if ( nArg1 == INS_NUM )
			{
				WriteInstruction( "lda #" );
				WriteNumber( nArg2 );
			}
			else
			{
				CompileKnownArgument( nArg1 );
			}

			if ( nOpType == INS_MULTIPLY )
			{
				WriteInstruction( "sta z80_h" );
				WriteInstruction( "jsr imul" );			/* hl = h * d. */
				WriteInstruction( "lda z80_l" );
			}
			else
			{
				WriteInstruction( "sta z80_e" );
				WriteInstruction( "jsr idiv" );			/* d = d/e, remainder in a. */
				WriteInstruction( "lda z80_d" );
			}
			if ( nAnswerWantedHere >= FIRST_PARAMETER &&
				 nAnswerWantedHere <= LAST_PARAMETER )
			{
				CR_PamC( nAnswerWantedHere );				/* put accumulator in variable or sprite parameter. */
			}
		}
	}
	else
	{
		Error( "MULTIPLY or DIVIDE missing" );
	}

	nOpType = 0;
}

/* We can optimise the multiplication or division by using shifts. */
void CompileShift( short int nArg )
{
	if ( nOpType == INS_MULTIPLY )
	{
		switch ( nArg )
		{
			case 2:
				WriteInstruction( "asl a" );
				break;
			case 3:
				WriteInstruction( "sta z80_d" );
				WriteInstruction( "asl a" );
				WriteInstruction( "clc" );
				WriteInstruction( "adc z80_d" );
				break;
			case 4:
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				break;
			case 5:
				WriteInstruction( "sta z80_d" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "clc" );
				WriteInstruction( "adc z80_d" );
				break;
			case 6:
				WriteInstruction( "asl a" );
				WriteInstruction( "sta z80_d" );
				WriteInstruction( "asl a" );
				WriteInstruction( "clc" );
				WriteInstruction( "adc z80_d" );
				break;
			case 8:
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				break;
			case 10:
				WriteInstruction( "asl a" );
				WriteInstruction( "sta z80_d" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "clc" );
				WriteInstruction( "adc z80_d" );
				break;
			case 16:
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				break;
			case 32:
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				break;
			case 64:
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				WriteInstruction( "asl a" );
				break;
			case 128:
				WriteInstruction( "lsr a" );
				WriteInstruction( "ror a" );
				WriteInstruction( "and #128" );
				break;
		}
	}
	else
	{
		switch ( nArg )
		{
			case 2:
				WriteInstruction( "lsr a" );
				break;
			case 4:
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				break;
			case 8:
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				break;
			case 16:
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				break;
			case 32:
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				break;
			case 64:
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				WriteInstruction( "lsr a" );
				break;
			case 128:
				WriteInstruction( "asl a" );
				WriteInstruction( "rol a" );
				WriteInstruction( "and #1" );
				break;
		}
	}

	if ( nAnswerWantedHere >= FIRST_PARAMETER &&
		 nAnswerWantedHere <= LAST_PARAMETER )
	{
		CR_PamC( nAnswerWantedHere );				/* put accumulator in variable or sprite parameter. */
	}
}

void CR_Got( void )
{
	CompileArgument();
	WriteInstruction( "jsr gotob" );
	WriteInstruction( "cmp #255" );
	WriteInstruction( "beq :+" );
        WriteInstruction( "jmp       " );
	CompileCondition();
	WriteText("\n:" );
	ResetIf();
}

void CR_Key( void )
{
	unsigned short int nArg = NextKeyword();
	unsigned short int nArg2;
	char szInstruction[ 16 ];

	if ( nArg == INS_NUM )										/* good, it's a number. */
	{
		nArg = GetNum( 8 );
		if ( nArg < 7 )
		{
			nArg2 = Joystick( nArg );
			nArg2 = nArg;
			WriteInstruction( "lda joyval" );
		sprintf( szInstruction, "and #%d", 1 << nArg2 );	/* get key from table. */
			WriteInstruction( szInstruction );
			WriteInstruction( "beq :+" );
			WriteInstruction( "jmp       " );
			nReadingControls++;									/* set flag to read joystick in WHILE loop. */
		}
		else
		{
			sprintf( szInstruction, "ldy #%d", nArg );	/* get key from table. */
			WriteInstruction( szInstruction );
			WriteInstruction( "lda keys,y" );
			WriteInstruction( "jsr ktest" );					/* test it. */
			WriteInstruction( "bcc :+" );
			WriteInstruction( "jmp       " );
		}
	}
	else														/* cripes, we need to do this longhand. */
	{
		CompileKnownArgument( nArg );							/* puts argument into accumulator. */
		WriteInstruction( "tay" );						/* keys. */
		WriteInstruction( "lda keys,y" );							/* key number in de. */
		WriteInstruction( "jsr ktest" );						/* test it now. */
		WriteInstruction( "bcc :+" );
		WriteInstruction( "jmp       " );
	}

	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_DefineKey( void )
{
	char szInstruction[ 15 ];
	unsigned short int nNum = NumberOnly();

	sprintf( szInstruction, "lda #%d", Joystick( nNum ) );
	WriteInstruction( szInstruction );
	WriteInstruction( "tax" );
	WriteInstruction( "jsr kget" );
	WriteInstruction( "sta keys,x" );
	
//	WriteInstruction( "call 654" );
//	WriteInstruction( "inc e" );
//	WriteInstruction( "jr z,$-4" );
//	sprintf( szInstruction, "; DEFINEKEY %d command", Joystick( nNum ) );
//	WriteInstruction( szInstruction );
//	WriteInstruction( "dec e" );
//	WriteInstruction( "ld (hl),e" );
}

void CR_Collision( void )
{
	unsigned short int nArg = NextKeyword();

	/* Literal number */
	if ( nArg == INS_NUM )
	{
		nArg = GetNum( 8 );
		if ( nArg == 10 )										/* it's a laser bullet. */
		{
			WriteInstruction( "jsr lcol" );
			WriteInstruction( "bcs :+" );
			WriteInstruction( "jmp       " );
		}
		else													/* it's a sprite type. */
		{
			WriteInstruction( "lda #" );
			WriteNumber( nArg );								/* sprite type to find. */
			WriteInstruction( "sta z80_b" );
			WriteInstruction( "jsr sktyp" );
			WriteInstruction( "bcs :+" );
			WriteInstruction( "jmp       " );
		}
	}
	else
	{
		CompileKnownArgument( nArg );							/* puts argument into accumulator */
		WriteInstruction( "sta z80_b" );
		WriteInstruction( "jsr sktyp" );
		WriteInstruction( "bcs :+" );
		WriteInstruction( "jmp       " );
	}

	CompileCondition();
	WriteText( "\n:" );
	ResetIf();
}

void CR_Anim( void )
{
	unsigned short int nArg;
	unsigned char *cSrc;									/* source pointer. */
	short int nCurrentLine = nLine;

	/* Store source address so we don't skip first instruction after messages. */
	cSrc = cBufPos;
	nArg = NextKeyword();

	if ( nArg == INS_NUM )									/* first argument is numeric. */
	{
		nArg = GetNum( 8 );									/* store first argument. */
	}
	else
	{
		cBufPos = cSrc;										/* restore source address so we don't miss the next line. */
		nLine = nCurrentLine;
		nArg = 0;
	}

	if ( nArg == 0 )
	{
		WriteInstruction( "lda #0" );
	}
	else
	{
		WriteInstruction( "lda #" );
		WriteNumber( nArg );								/* first argument in c register. */
	}
	WriteInstruction( "jsr animsp" );
}

void CR_AnimBack( void )
{
	unsigned short int nArg;
	unsigned char *cSrc;									/* source pointer. */
	short int nCurrentLine = nLine;

	/* Store source address so we don't skip first instruction after messages. */
	cSrc = cBufPos;
	nArg = NextKeyword();

	if ( nArg == INS_NUM )									/* first argument is numeric. */
	{
		nArg = GetNum( 8 );									/* store first argument. */
	}
	else
	{
		cBufPos = cSrc;										/* restore source address so we don't miss the next line. */
		nLine = nCurrentLine;
		nArg = 0;
	}

	if ( nArg == 0 )
	{
		WriteInstruction( "lda #0" );
	}
	else
	{
		WriteInstruction( "lda #," );
		WriteNumber( nArg );								/* first argument in c register. */
	}
	WriteInstruction( "jsr animbk" );
}

void CR_PutBlock( void )
{
	WriteInstruction( "lda charx" );
	WriteInstruction( "sta dispx" );
	WriteInstruction( "lda chary" );
	WriteInstruction( "sta dispy" );
	CompileArgument();
	WriteInstruction( "jsr pattr" );
}

void CR_Dig( void )
{
	CompileArgument();
	WriteInstruction( "jsr dig" );
}

void CR_NextLevel( void )
{
	WriteInstruction( "lda #1" );
	WriteInstruction( "sta nexlev" );
}

void CR_Restart( void )
{
	WriteInstruction( "lda #1" );
	WriteInstruction( "sta restfl" );
}

void CR_Spawn( void )
{
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */
		nArg2 = NextKeyword();
								/* get second argument. */
		if ( nArg2 == INS_NUM )								/* second argument is numeric too. */
		{
//			nArg2 = 256 * GetNum( 8 ) + nArg1;
			nArg2 = GetNum( 8 );
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );							/* pass both parameters as 16-bit argument. */
			WriteInstruction( "sta z80_c");
			WriteInstruction( "lda #" );
			WriteNumber( nArg2 );							/* pass both parameters as 16-bit argument. */
			WriteInstruction( "sta z80_b");
		}
		else
		{
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );							/* first argument in c register. */
			WriteInstruction( "sta z80_c");
			CompileKnownArgument( nArg2 );					/* puts argument into accumulator. */
			WriteInstruction( "sta z80_b" );					/* put that into b. */
		}
	}
	else
	{
		CompileKnownArgument( nArg1 );						/* puts first argument into accumulator. */
		WriteInstruction( "sta z80_c" );						/* copy into c register. */
		CompileArgument();									/* puts second argument into accumulator. */
		WriteInstruction( "sta z80_b" );						/* put that into b. */
	}

	WriteInstruction( "jsr spawn" );
}

void CR_Remove( void )
{
	WriteInstruction( "lda #255" );
	WriteInstruction( "ldy #5" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_GetRandom( void )
{
	CompileArgument();										/* maximum number in accumulator. */
	WriteInstruction( "sta z80_d" );							/* multiplication parameter. */
	WriteInstruction( "jsr random" );						/* random number 0 - 255. */
	WriteInstruction( "sta z80_h" );							/* second multiplication parameter. */
	WriteInstruction( "jsr imul" );						/* multiply together. */
	WriteInstruction( "lda z80_h" );							/* put result in accumulator. */
	WriteInstruction( "sta varrnd" );					/* write to random variable. */
}

void CR_Randomize( void )
{
	CompileArgument();										/* maximum number in accumulator. */
	WriteInstruction( "sta seed" );						/* write to random seed. */
}

void CR_DisplayHighScore( void )
{
	WriteInstruction( "jsr dhisc" );
}

void CR_DisplayScore( void )
{
	WriteInstruction( "jsr dscor" );
}

void CR_DisplayBonus( void )
{
	WriteInstruction( "jsr swpsb" );						/* swap bonus into score. */
	WriteInstruction( "jsr dscor" );						/* show it. */
	WriteInstruction( "jsr swpsb" );						/* swap back again. */
}

void CR_Score( void )
{
	unsigned short int nArg = NextKeyword();
	unsigned short int nArg1;
	unsigned short int nArg2;

	if ( nArg == INS_NUM )									/* literal number, could be 16 bits. */
	{
		nArg = GetNum( 16 );
//		nArg1 = nArg && 0xff;
//		nArg2 = nArg >> 8;
		WriteInstruction( "lda #<" );
		WriteNumber( nArg );
		WriteInstruction( "sta z80_l" );
		WriteInstruction( "lda #>" );
		WriteNumber( nArg );
		WriteInstruction( "sta z80_h" );
	}
	else													/* work out 8-bit argument to add. */
	{
		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
		WriteInstruction( "sta z80_l" );						/* low byte of parameter in l. */
		WriteInstruction( "lda #0" );
		WriteInstruction( "sta z80_h" );						/* no high byte. */
	}

	WriteInstruction( "jsr addsc" );
}

void CR_Bonus( void )
{
	WriteInstruction( "jsr swpsb" );						/* swap bonus into score. */
	CR_Score();												/* score the points. */
	WriteInstruction( "jsr swpsb" );						/* swap back again. */
}

void CR_AddBonus( void )
{
	WriteInstruction( "jsr addbo" );						/* add bonus to score. */
}

void CR_ZeroBonus( void )
{
	WriteInstruction( "lda #48" );
	WriteInstruction( "ldy #5" );
	WriteText("\n:");
	WriteInstruction( "sta bonus,y" );
	WriteInstruction( "dey" );
	WriteInstruction( "bpl :-" );
}

void CR_Sound( void )
{
//	unsigned short int nArg = NextKeyword();
//
//	if ( nArg == INS_NUM )									/* literal number. */
//	{
//		nArg = GetNum( 16 ) * SNDSIZ;
//		WriteInstruction( "lda fx1" );
//		WriteInstruction( "sta z80_l" );
//		WriteInstruction( "lda fx1+1" );
//		WriteInstruction( "sta z80_h" );
//		WriteInstruction( "lda #<" );
//		WriteNumber( nArg );
//		WriteInstruction( "sta z80_e" );
//		WriteInstruction( "lda #>" );
//		WriteNumber( nArg );
//		WriteInstruction( "sta z80_d" );
//	}
//	else													/* work out sound address. */
//	{
//		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
//		WriteInstruction( "sta z80_d" );						/* first parameter. */
//		WriteInstruction( "lda #" );						/* size of each sound. */
//		WriteNumber( SNDSIZ );
//		WriteInstruction( "sta z80_h" );
//		WriteInstruction( "jsr imul" );					/* find distance to sound. */
//		WriteInstruction( "lda fx1" );
//		WriteInstruction( "sta z80_e" );
//		WriteInstruction( "lda fx1+1" );
//		WriteInstruction( "sta z80_d" );
//	}
//
//	WriteInstruction( "clc" );
//	WriteInstruction( "lda z80_e" );
//	WriteInstruction( "adc z80_l" );
//	WriteInstruction( "sta z80_l" );
//	WriteInstruction( "lda z80_d" );
//	WriteInstruction( "adc z80_h" );
//	WriteInstruction( "sta z80_h" );
//	WriteInstruction( "jsr isnd" );
	WriteInstruction( "; SOUND command");
}

void CR_Beep( void )
{
	unsigned short int nArg = NextKeyword();

	if ( nArg == INS_NUM )									/* literal number. */
	{
		nArg = GetNum( 8 );
//		if ( nArg > 127 )
//		{
//			nArg = 127;
//		}
		WriteInstruction( "lda #" );
		WriteNumber( nArg );
	}
	else													/* work out sound address. */
	{
		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
//		WriteInstruction( "and 127" );						/* reset white noise flag. */
	}

	WriteInstruction( "asl a" );
	WriteInstruction( "sta sndtyp" );
}

void CR_Crash( void )
{
//	unsigned short int nArg = NextKeyword();
//
//	if ( nArg == INS_NUM )									/* literal number. */
//	{
//		nArg = GetNum( 8 );
//		if ( nArg < 128 )
//		{
//			nArg += 128;
//		}
//		else
//		{
//			nArg = 255;
//		}
//		WriteInstruction( "ld a," );
//		WriteNumber( nArg );
//	}
//	else													/* work out sound address. */
//	{
//		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
//		WriteInstruction( "or 128" );						/* set white noise flag. */
//	}
//
//	WriteInstruction( "ld (sndtyp),a" );
	WriteInstruction( "; CRASH command");
}

void CR_ClS( void )
{
	WriteInstruction( "jsr cls" );
}

void CR_Border( void )
{
//	CompileArgument();
	WriteInstruction( "; BORDER command" );						/* address of ROM BORDER routine. */
}

void CR_Colour( void )
{
//	CompileArgument();
	WriteInstruction( "; COLOUR command" );						/* set the permanent attributes. */
}

void CR_Paper( void )
{
//	CompileArgument();
	WriteInstruction( "; PAPER command" );								/* multiply by 8 to get paper. */
}

void CR_Ink( void )
{
//	CompileArgument();
	WriteInstruction( "; INK command" );
}

void CR_Clut( void )
{
//	CompileArgument();
	WriteInstruction( "; CLUT command" );								/* multiply by 64 for colour look-up table. */
}

void CR_Delay( void )
{
	unsigned short int nArg = NextKeyword();

//	WriteInstruction( "push ix" );							/* DELAY command causes ix to be corrupted. */

	if ( nArg == INS_NUM )									/* literal number. */
	{
		nArg = GetNum( 8 );
		WriteInstruction( "lda #" );
		WriteNumber( nArg );
	}
	else													/* work out 8-bit argument to add. */
	{
		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
		WriteInstruction( "sta z80_b" );
	}

	WriteInstruction( "jsr delay" );
//	WriteInstruction( "pop ix" );
}

void CR_Print( void )
{
	CompileArgument();
	WriteInstruction( "jsr dmsg" );
}

void CR_PrintMode( void )
{
	CompileArgument();
	WriteInstruction( "sta prtmod" );					/* set print mode. */
}

void CR_At( void )
{
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */
		nArg2 = NextKeyword();								/* get second argument. */
//		if ( nArg2 == INS_NUM )								/* second argument is numeric too. */
//		{
//			nArg2 = 256 * GetNum( 8 ) + nArg1;	/* pass both parameters as 16-bit argument. */
			nArg2 = GetNum( 8 );
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );
			WriteInstruction( "sta chary");
			WriteInstruction( "lda #" );
			WriteNumber( nArg2 );
			WriteInstruction( "sta charx");
//		}
//		else
//		{
//			WriteInstruction( "ld l," );
//			WriteNumber( nArg1 );
//			CompileKnownArgument( nArg2 );					/* puts argument into accumulator. */
//			WriteInstruction( "ld h,a" );					/* put that into h. */
//		}
	}
	else
	{
		CompileKnownArgument( nArg1 );						/* puts first argument into accumulator. */
		WriteInstruction( "sta chary ;" );						/* copy into c register. */
		CompileArgument();									/* puts second argument into accumulator. */
		WriteInstruction( "sta charx" );						/* put that into b. */
	}

//	WriteInstruction( "ld (charx),hl" );

//	CompileArgument();
//	WriteInstruction( "ld (charx),a" );
//	CompileArgument();
//	WriteInstruction( "ld (chary),a" );
}

void CR_Chr( void )
{
	CompileArgument();
	WriteInstruction( "jsr achar" );
}

void CR_Menu( void )
{
	CompileArgument();
	WriteInstruction( "tax" );
	WriteInstruction( "jsr mmenu" );
}

void CR_Inventory( void )
{
	CompileArgument();
//	unsigned short int nArg1 = NextKeyword();
//	fprintf( stderr, "INVENTORY %u",nArg1);
	WriteInstruction( "tax" );
	WriteInstruction( "jsr minve" );
}

void CR_Kill( void )
{
	WriteInstruction( "lda #1" );						/* player dead flag. */
	WriteInstruction( "sta deadf" );						/* set to non-zero. */
}

void CR_AddSubtract( void )
{
	unsigned short int nArg = NextKeyword();

	if ( nArg == INS_NUM )									/* literal number. */
	{
		nArg = GetNum( 8 );
		if ( nArg == 1 )
		{
			nIncDec++;										/* increment/decrement will suffice. */
		}
		else
		{
			WriteInstruction( "lda #" );					/* put number to add/subtract into c register. */
			WriteNumber( nArg );
			WriteInstruction( "sta z80_c" );					/* put number to add/subtract into c register. */
		}
	}
	else													/* work out 8-bit argument to add. */
	{
		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
		WriteInstruction( "sta z80_c" );					/* put number to add/subtract into c register. */
	}
}

void CR_Display( void )
{
	unsigned char *cSrc;									/* source pointer. */
	unsigned short int nArg;

	cSrc = cBufPos;											/* store position in buffer. */
	nArg = NextKeyword();

	switch( nArg )
	{
		case INS_DOUBLEDIGITS:
			WriteInstruction( "lda #<displ0" );
			WriteInstruction( "sta z80_c" );
			WriteInstruction( "lda #>displ0" );
			WriteInstruction( "sta z80_b" );
			CompileArgument();
			WriteInstruction( "jsr num2dd" );
			WriteInstruction( "jsr displ1" );
			break;
		case INS_TRIPLEDIGITS:
			WriteInstruction( "lda #<displ0" );
			WriteInstruction( "sta z80_c" );
			WriteInstruction( "lda #>displ0" );
			WriteInstruction( "sta z80_b" );
			CompileArgument();
			WriteInstruction( "jsr num2td" );
			WriteInstruction( "jsr displ1" );
			break;
		case INS_CLOCK:
			CompileArgument();
			WriteInstruction( "sta z80_d" );
			WriteInstruction( "lda #60" );
			WriteInstruction( "sta z80_e" );
			WriteInstruction( "jsr idiv" );			/* d = d/e, remainder in a. */
			WriteInstruction( "pha" );
			WriteInstruction( "lda z80_d" );
			WriteInstruction( "jsr disply" );
			WriteInstruction( "inc charx" );
			WriteInstruction( "lda #<displ0" );
			WriteInstruction( "sta z80_c" );
			WriteInstruction( "lda #>displ0" );
			WriteInstruction( "sta z80_b" );
			WriteInstruction( "pla" );
			WriteInstruction( "jsr num2dd" );
			WriteInstruction( "jsr displ1" );
			break;
		default:
			cBufPos = cSrc;									/* restore buffer position and compile standard DISPLAY command. */
			CompileArgument();
			WriteInstruction( "jsr disply" );
			break;
	}
}

void CR_ScreenUp( void )
{
	WriteInstruction( "jsr scru" );
}

void CR_ScreenDown( void )
{
	WriteInstruction( "jsr scrd" );
}

void CR_ScreenLeft( void )
{
	WriteInstruction( "jsr scrl" );
}

void CR_ScreenRight( void )
{
	WriteInstruction( "jsr scrr" );
}

void CR_WaitKey( void )
{
	WriteInstruction( "jsr prskey" );
}

void CR_Jump( void )
{
	WriteInstruction( "jsr jump" );
	nGravity++;
	nUseHopTable++;
}

void CR_Fall( void )
{
	WriteInstruction( "jsr ifall" );
	nGravity++;
	nUseHopTable++;
}

void CR_TableJump( void )
{
	WriteInstruction( "jsr jump" );
	nGravity++;
	nUseHopTable++;
}

void CR_TableFall( void )
{
	WriteInstruction( "jsr ifall" );
	nGravity++;
	nUseHopTable++;
}

void CR_Other( void )
{
	WriteInstruction( "lda skptr" );
	WriteInstruction( "sta z80_x" );
	WriteInstruction( "lda skptr+1" );
	WriteInstruction( "sta z80_i" );
}

void CR_Spawned( void )
{
	WriteInstruction( "lda spptr" );
	WriteInstruction( "sta z80_x" );
	WriteInstruction( "lda spptr+1" );
	WriteInstruction( "sta z80_i" );
}

void CR_Original( void )
{
	WriteInstruction( "lda ogptr" );
	WriteInstruction( "sta z80_x" );
	WriteInstruction( "lda ogptr+1" );
	WriteInstruction( "sta z80_i" );
}

void CR_EndGame( void )
{
	WriteInstruction( "lda #1" );
	WriteInstruction( "sta gamwon" );
}

void CR_Get( void )
{
	CompileArgument();
	WriteInstruction( "jsr getob" );
}

void CR_Put( void )
{
//	CompileArgument();
//	WriteInstruction( "pha; CR_PUT" );							/* remember object number. */
//	CompileArgument();										/* put object number in accumulator. */
//	WriteInstruction( "sta dispx" );							/* remember object number. */
//	CompileArgument();
//	WriteInstruction( "sta dispy" );							/* remember object number. */
//	WriteInstruction( "pla" );
//	WriteInstruction( "jsr drpob" );
	CompileArgument();
	WriteInstruction( "sta dispx" );							/* remember object number. */
	CompileArgument();
	WriteInstruction( "sta dispy" );							/* remember object number. */
	CompileArgument();
	WriteInstruction( "jsr drpob" );
}

void CR_RemoveObject( void )
{
	CompileArgument();
	WriteInstruction( "jsr remob" );
}

void CR_DetectObject( void )
{
	WriteInstruction( "jsr skobj" );
	WriteInstruction( "sta varobj" );
}

void CR_Asm( void )											/* this is undocumented as it's dangerous! */
{
	unsigned short int nNum = NumberOnly();
	WriteInstruction( ".byte " );

	WriteNumber( nNum );									/* write opcode straight to code. */
}

void CR_Exit( void )
{
	WriteInstruction( "rts" );								/* finish event. */
}

void CR_Repeat( void )
{
	char szInstruction[ 13 ];

	if ( nNumRepts < NUM_REPEAT_LEVELS )
	{
		CompileArgument();
		sprintf( szInstruction, "sta loop%c", nNumRepts + 'a' );
//		WriteInstruction( "sta loopc" );
		WriteInstruction( szInstruction );
		nReptBuff[ nNumRepts ] = nCurrent;					/* store current address. */
		nNextLabel = nCurrent;
		nNumRepts++;
	}
	else
	{
		Error( "Too many REPEATs" );
		CompileArgument();
	}

//	if ( nRepeatAddress == ASMLABEL_DUMMY )
//	{
//		CompileArgument();
//		WriteInstruction( "ld (loopc),a" );
//		nRepeatAddress = nCurrent;							/* store current address. */
//		nNextLabel = nRepeatAddress;
//	}
//	else
//	{
//		Error( "Nested REPEAT" );
//		CompileArgument();
//	}
}

void CR_EndRepeat( void )
{
	char szInstruction[ 12 ];

	if ( nNumRepts > 0 )
	{
		nNumRepts--;
		sprintf( szInstruction, "dec loop%c", nNumRepts + 'a' );
		WriteInstruction( szInstruction );
		WriteInstruction( "beq :+" );
		WriteInstruction( "jmp " );
		WriteLabel( nReptBuff[ nNumRepts ] );
		WriteText( "\n:" );
		nReptBuff[ nNumRepts ] = ASMLABEL_DUMMY;
	}
	else
	{
		Error( "ENDREPEAT without REPEAT" );
	}

}

void CR_Multiply( void )
{
	nOpType = INS_MULTIPLY;									/* remember instruction is multiply (needed by CR_By). */
	nAnswerWantedHere = CompileArgument();					/* stores the place where we want the answer. */
}

void CR_Divide( void )
{
	nOpType = INS_DIVIDE;									/* remember it's a divide (needed by CR_By). */
	nAnswerWantedHere = CompileArgument();					/* stores the place where we want the answer. */
}

void CR_SpriteInk( void )
{
//	CompileArgument();
//	WriteInstruction( "and #7" );
//	WriteInstruction( "sta z80_c" );
//	WriteInstruction( "jsr cspr" );
	WriteInstruction( "; SPRITEINK command" );
}

void CR_Trail( void )
{
	WriteInstruction( "jsr vapour" );
//	WriteInstruction( "; VAPOUR command" );
}

void CR_Laser( void )
{
	CompileArgument();										/* 0 or 1 for direction. */
	WriteInstruction( "jsr shoot" );
//	WriteInstruction( "; LASER command" );
}

void CR_Star( void )
{
	CompileArgument();										/* direction 0 - 3. */
	WriteInstruction( "sta z80_c" );
	WriteInstruction( "jsr qrand" );
	WriteInstruction( "and #3" );
	WriteInstruction( "bne :+" );
	WriteInstruction( "jsr star" );
	WriteText( "\n:" );
//	WriteInstruction( "; STAR command" );
}

void CR_Explode( void )
{
	CompileArgument();										/* number of particles required. */
	WriteInstruction( "jsr explod" );
//	WriteInstruction( "; EXPLODE command" );
}

void CR_Redraw( void )
{
	WriteInstruction( "jsr redraw" );
}

void CR_Silence( void )
{
//	WriteInstruction( "jsr silenc" );
	WriteInstruction( "; SILENCE command" );
}

void CR_ClW( void )
{
//	WriteInstruction( "jsr clw" );
	WriteInstruction( "; CLW command" );
}

void CR_Palette( void )
{
//	CompileArgument();										/* palette register to write. */
//	WriteInstruction( "ld bc,64" );							/* register select. */
//	WriteInstruction( "out (c),a" );
//	CompileArgument();										/* palette data to write. */
//	WriteInstruction( "ld bc,65" );							/* data select. */
//	WriteInstruction( "out (c),a" );
	WriteInstruction( "; PALETTE command" );							/* register select. */
}

void CR_GetBlock( void )
{
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */
		nArg2 = NextKeyword();								/* get second argument. */
//		if ( nArg2 == INS_NUM )								/* second argument is numeric too. */
//		{
//			nArg2 = 256 * nArg1 + GetNum( 8 );
//			WriteInstruction( "ld hl," );
//			WriteNumber( nArg2 );							/* pass both parameters as 16-bit argument. */
//		}
//		else
//		{
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );							/* first argument in c register. */
			WriteInstruction( "sta dispx" );
			CompileKnownArgument( nArg2 );					/* puts argument into accumulator. */
			WriteInstruction( "sta dispy" );					/* put that into b. */
//		}
	}
	else
	{
		CompileKnownArgument( nArg1 );						/* puts first argument into accumulator. */
		WriteInstruction( "sta dispx" );						/* copy into c register. */
		CompileArgument();									/* puts second argument into accumulator. */
		WriteInstruction( "sta dispy" );						/* put that into b. */
	}

//	WriteInstruction( "ld (dispx),hl" );					/* set the test coordinates. */
	WriteInstruction( "jsr tstbl" );						/* get block there. */
	WriteInstruction( "sta varblk" );					/* write to block variable. */
}

void CR_Read( void )
{
	char szInstruction[ 12 ];

	cDataRequired = 1;										/* need to find data at the end. */
	sprintf( szInstruction, "jsr read%02d", nEvent );
	WriteInstruction( szInstruction );

	nAnswerWantedHere = NextKeyword();
	if ( nAnswerWantedHere >= FIRST_PARAMETER &&
		 nAnswerWantedHere <= LAST_PARAMETER )
	{
		CR_PamC( nAnswerWantedHere );						/* put accumulator in variable or sprite parameter. */
	}
}

void CR_Data( void )
{
	short int nDataNums = 0;
	unsigned short int nArg = 0;
	unsigned short int nValue = 0;
	unsigned char *cSrc;									/* source pointer. */
	char szInstruction[ 22 ];
	unsigned short int nList = 0;

	do
	{
		cSrc = cBufPos;										/* store position in buffer. */
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nValue = GetNum( 16 );							/* get the value. */
			if ( nDataNums == 0 )
			{
				if ( nList == 0 )
				{
					WriteInstruction( "rts" );				/* make sure we don't drop into data. */
				}
				if ( nList == 0 && cData == 0 )
				{
					sprintf( szInstruction, "rptr%02d: .byte 0", nEvent );
					WriteInstructionAndLabel( szInstruction );
					sprintf( szInstruction, "rdat%02d: .byte %d", nEvent, nValue );
					WriteInstructionAndLabel( szInstruction );
				}
				else
				{
					sprintf( szInstruction, ".byte %d", nValue );
					WriteInstruction( szInstruction );
				}
			}
			else
			{
				sprintf( szInstruction, ",%d", nValue );
				WriteText( szInstruction );
			}

			if ( ++nDataNums > 10 )
			{
				nDataNums = 0;
			}

			nList++;										/* tally number in list. */
		}

		if ( nArg != INS_NUM && nArg != INS_DATA )			/* another data statement could follow. */
		{
			cBufPos = cSrc;									/* go back to previous position. */
		}
	}
	while ( ( ( cBufPos - cBuff ) < lSize ) && ( nArg == INS_NUM || nArg == INS_DATA ) );

	if ( cData == 0 )
	{
		/* Now we set up a read routine. */
		if ( SpriteEvent() )
		{
			sprintf( szInstruction, "read%02d: ldy #16", nEvent, nEvent );
			WriteInstructionAndLabel( szInstruction );
			WriteInstruction( "lda (z80_ix),y" );
			WriteInstruction( "pha" );
			WriteInstruction( "clc" );
			WriteInstruction( "adc #1" );
			WriteInstruction( "sta (z80_ix),y" );
			WriteInstruction( "pla" );
			WriteInstruction( "tay" );
		}
		else
		{
			sprintf( szInstruction, "read%02d: ldy rptr%02d", nEvent, nEvent );
			WriteInstructionAndLabel( szInstruction );
			sprintf( szInstruction, "inc rptr%02d", nEvent );
			WriteInstruction( szInstruction );
		}
//		sprintf( szInstruction, "ld de,rdat%02d+%d", nEvent, nList );
//		WriteInstruction( szInstruction );
//		WriteInstruction( "scf" );
//		WriteInstruction( "ex de,hl" );
//		WriteInstruction( "sbc hl,de" );
//		WriteInstruction( "ex de,hl" );
//		WriteInstruction( "jr nc,$+5" );
		sprintf( szInstruction, "lda rdat%02d,y", nEvent, nEvent );
		WriteInstruction( szInstruction );
//		WriteInstruction( "ld a,(hl)" );
//		WriteInstruction( "inc hl" );

//		if ( SpriteEvent() )
//		{
//			WriteInstruction( "ld (ix+15),l" );
//			WriteInstruction( "ld (ix+16),h" );
//		}
//		else
//		{
//			sprintf( szInstruction, "ld (rptr%02d),hl", nEvent );
//			WriteInstruction( szInstruction );
//		}

		WriteInstruction( "rts" );
	}

	cData = 1;												/* flag that we've found data. */

	if ( nDataNums == 0 )
	{
		Error( "No data found" );
	}
}

void CR_Restore( void )
{
	char szInstruction[ 15 ];

	cDataRequired = 1;										/* need to find data at the end. */

	if ( SpriteEvent() )
	{
		WriteInstruction( "lda #0" );				/* set data pointer to beyond range. */
		WriteInstruction( "ldy #16" );
		WriteInstruction( "sta (z80_ix),y" );
	}
	else
	{
		WriteInstruction( "lda #0" );
		sprintf( szInstruction, "sta rptr%02d", nEvent );
		WriteInstruction( szInstruction );
	}
}

void CR_DefineParticle( void )
{
	if ( nParticle != 0 )
	{
		Error( "User particle already defined" );
	}
	else
	{
		nParticle++;
		WriteInstruction( "rts" );							/* make sure we don't drop through from elsewhere. */
		WriteInstructionAndLabel( "ptcusr:" );
	}
}

void CR_ParticleUp( void )
{
	WriteInstruction( "ldy #3" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "sec" );
	WriteInstruction( "sbc #1" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_ParticleDown( void )
{
	WriteInstruction( "ldy #3" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "clc" );
	WriteInstruction( "adc #1" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_ParticleLeft( void )
{
	WriteInstruction( "ldy #5" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "sec" );
	WriteInstruction( "sbc #1" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_ParticleRight( void )
{
	WriteInstruction( "ldy #5" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "clc" );
	WriteInstruction( "adc #1" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_ParticleTimer( void )
{
	WriteInstruction( "ldy #1" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "sec" );
	WriteInstruction( "sbc #1" );
	WriteInstruction( "sta (z80_ix),y" );
	WriteInstruction( "bne :+" );
	WriteInstruction( "jmp trailk" );						/* reached zero, kill it off. */
	WriteText( "\n:" );
}

void CR_StartParticle( void )
{
	WriteInstruction( "lda z80_i" );
	WriteInstruction( "pha" );
	WriteInstruction( "lda z80_x" );
	WriteInstruction( "pha" );
	CompileArgument();										/* palette register to write. */
	WriteInstruction( "jsr ptusr" );
	WriteInstruction( "pla" );
	WriteInstruction( "sta z80_x" );
	WriteInstruction( "pla" );
	WriteInstruction( "sta z80_i" );
}

void CR_Message( void )
{
	CompileArgument();										/* message number to display. */
	WriteInstruction( "jsr dmsg" );
}

void CR_StopFall( void )
{
	WriteInstruction( "jsr gravst" );
}

void CR_GetBlocks( void )
{
	WriteInstruction( "jsr getcol" );
}

void CR_ControlMenu( void )
{
	WriteInstruction( "\nrtcon:" );
	WriteInstruction( "jsr vsync" );
	WriteInstruction( "lda #0" );
	WriteInstruction( "sta contrl" );
	WriteInstruction( "lda keys+7" );
	WriteInstruction( "jsr ktest" );
	WriteInstruction( "bcc rtcon1" );
	WriteInstruction( "lda #1" );
	WriteInstruction( "sta contrl" );
	WriteInstruction( "lda keys+8" );
	WriteInstruction( "jsr ktest" );
	WriteInstruction( "bcc rtcon1" );
	WriteInstruction( "lda #2" );
	WriteInstruction( "sta contrl" );
	WriteInstruction( "lda keys+9" );
	WriteInstruction( "jsr ktest" );
	WriteInstruction( "bcs rtcon" );
	WriteInstruction( "rtcon1:" );
}

void CR_Plot( void )
{
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */
		nArg2 = NextKeyword();								/* get second argument. */
		if ( nArg2 == INS_NUM )								/* second argument is numeric too. */
		{
			nArg2 = GetNum( 8 );
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );
			WriteInstruction( "sta dispx" );
			WriteInstruction( "lda #" );
			WriteNumber( nArg2 );							/* pass both parameters as 16-bit argument. */
			WriteInstruction( "sta dispy" );
		}
		else
		{
			WriteInstruction( "lda #" );
			WriteNumber( nArg1 );							/* first argument in c register. */
			WriteInstruction( "sta dispx" );
			CompileKnownArgument( nArg2 );					/* puts argument into accumulator. */
			WriteInstruction( "sta dispy" );
		}
	}
	else
	{
		CompileKnownArgument( nArg1 );						/* puts first argument into accumulator. */
		WriteInstruction( "sta dispx" );
		CompileArgument();									/* puts second argument into accumulator. */
		WriteInstruction( "sta dispy" );
	}

	WriteInstruction( "jsr plot0" );						/* plot the pixel. */
	WriteText( "\n");
}

void CR_UndoSpriteMove( void )
{
	WriteInstruction( "ldy #3" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "ldy #8" );
	WriteInstruction( "sta (z80_ix),y" );
	WriteInstruction( "ldy #4" );
	WriteInstruction( "lda (z80_ix),y" );
	WriteInstruction( "ldy #9" );
	WriteInstruction( "sta (z80_ix),y" );
}

void CR_Ticker( void )
{
	unsigned short int nArg1 = NextKeyword();
	unsigned short int nArg2;

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */
		if ( nArg1 == 0 )
		{
			WriteInstruction( "lda #96" );  // RTS opcode
			WriteInstruction( "sta scrly" );
		}
		else
		{
			nArg2 = NextKeyword();							/* get second argument. */
			if ( nArg2 == INS_STR )							/* second argument should be a string. */
			{
				nArg2 = nMessageNumber++;
				WriteInstruction( "lda #" );
				WriteNumber( nArg1 );						/* pass both parameters as 16-bit argument. */
				WriteInstruction( "sta z80_c" );
				WriteInstruction( "lda #" );
				WriteNumber( nArg2 );						/* pass both parameters as 16-bit argument. */
				WriteInstruction( "sta z80_b" );
				WriteInstruction( "jsr iscrly" );
			}
			else
			{
				if ( nArg2 == INS_NUM )						/* if not a string, must be a message number. */
				{
					nArg2 = GetNum( 8 );
					WriteInstruction( "lda #" );
					WriteNumber( nArg2 );					/* pass both parameters as 16-bit argument. */
					WriteInstruction( "sta z80_c" );
					WriteInstruction( "lda #" );
					WriteNumber( nArg1 );						/* pass both parameters as 16-bit argument. */
					WriteInstruction( "sta z80_b" );
					WriteInstruction( "jsr iscrly" );
				}
				else
				{
					Error( "Invalid argument for TICKER" );
				}
			}
		}
	}
	else
	{
		CompileKnownArgument( nArg1 );						/* puts first argument into accumulator. */
		WriteInstruction( "sta z80_b" );						/* copy into c register. */
		CompileArgument();									/* puts second argument into accumulator. */
		WriteInstruction( "sta z80_c" );						/* put that into b. */
		WriteInstruction( "jsr iscrly" );
	}
//		WriteInstruction( "; TICKER" );
}

void CR_User( void )
{
	unsigned short int nArg;
	unsigned char *cSrc;									/* source pointer. */

	cSrc = cBufPos;											/* store position in buffer. */
	nArg = NextKeyword();

	if ( nArg == INS_NUM ||
		 nArg == INS_STR ||
		 ( nArg >= FIRST_PARAMETER && nArg <= LAST_PARAMETER ) )
	{
		CompileKnownArgument( nArg );						/* puts argument into accumulator. */
	}
	else
	{
		cBufPos = cSrc;										/* no argument, restore position. */
	}

	WriteInstruction( "jsr user" );
}

void CR_Event( void )
{
	unsigned short int nArg1 = NextKeyword();

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();											/* always put a ret at the end. */
	}

	if ( nArg1 == INS_NUM )									/* first argument is numeric. */
	{
		nArg1 = GetNum( 8 );								/* store first argument. */

		if ( nArg1 >= 0 && nArg1 < NUM_EVENTS )
		{
			nEvent = nArg1;
			StartEvent( nEvent );							/* write event label and header. */
		}
		else
		{
			Error( "Invalid event" );
		}
	}
	else
	{
		Error( "Invalid event" );
	}
}

void CR_DefineBlock( void )
{
	unsigned short int nArg;
	char cChar;
	short int nDatum = 0;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();											/* always put a ret at the end. */
		nEvent = -1;
	}

	do
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			cChar = ( char )nArg;
			fwrite( &cChar, 1, 1, pWorkBlk );				/* write character to blocks workfile. */
			nDatum++;
		}
		else
		{
			Error( "Missing data for DEFINEBLOCK" );
			nDatum = 10;
		}
	}
	while ( nDatum < 10 );
}

void CR_DefineWindow( void )
{
	char szInstruction[ 18 ];
	unsigned short int nArg;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();											/* always put a ret at the end. */
		nEvent = -1;
	}

	if ( cWindow == 0 )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			nWinTop = nArg;
			sprintf( szInstruction, "WINDOWTOP = %d", nArg );
			WriteInstructionAndLabel( szInstruction );
		}
		else
		{
			Error( "Invalid top edge for DEFINEWINDOW" );
		}

		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			nWinLeft = nArg;
			sprintf( szInstruction, "WINDOWLFT = %d", nArg );
			WriteInstructionAndLabel( szInstruction );
		}
		else
		{
			Error( "Invalid left edge for DEFINEWINDOW" );
		}

		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			nWinHeight = nArg;
			sprintf( szInstruction, "WINDOWHGT = %d", nArg );
			WriteInstructionAndLabel( szInstruction );
		}
		else
		{
			Error( "Invalid height for DEFINEWINDOW" );
		}

		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			nWinWidth = nArg;
			sprintf( szInstruction, "WINDOWWID = %d ;", nArg );
			WriteInstructionAndLabel( szInstruction );
		}
		else
		{
			Error( "Invalid width for DEFINEWINDOW" );
		}

		cWindow++;
		fwrite( cStart, 1, nCurrent - nAddress, pObject );	/* write output to file. */
	}
	else
	{
		Error( "Window already defined" );
	}

	if ( nWinTop + nWinHeight > 24 )
	{
		Error( "Window extends beyond bottom of screen" );
	}

	if ( nWinLeft + nWinWidth > 32 )
	{
		Error( "Window extends beyond right edge of screen" );
	}
}

void CR_DefineSprite( void )
{
	unsigned short int nArg;
	char cChar;
	short int nDatum = 0;
	short int nFrames = 0;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();											/* always put a ret at the end. */
		nEvent = -1;
	}

	nArg = NextKeyword();
	if ( nArg == INS_NUM )
	{
		nFrames = GetNum( 8 );
		fwrite( &nFrames, 1, 1, pWorkSpr );						/* write character to sprites workfile. */
	}
	else
	{
		Error( "Number of frames undefined for DEFINESPRITE" );
	}

	while ( nFrames-- > 0 )
	{
		nDatum = 0;
		do
		{
			nArg = NextKeyword();
			if ( nArg == INS_NUM )
			{
				nArg = GetNum( 8 );
				cChar = ( char )nArg;
				fwrite( &cChar, 1, 1, pWorkSpr );				/* write character to sprites workfile. */
				nDatum++;
			}
			else
			{
				Error( "Missing data for DEFINESPRITE" );
				nDatum = 32;
			}
		}
		while ( nDatum < 32 );
	}
}

void CR_DefineScreen( void )
{
	unsigned short int nArg;
	char cChar;
	short int nBytes = nWinWidth * nWinHeight;
	char szMsg[ 41 ];

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();												/* always put a ret at the end. */
		nEvent = -1;
	}

	if ( cWindow == 0 )
	{
		Error( "Window must be defined before screen layouts" );
	}

	while ( nBytes > 0 )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			cChar = ( char )nArg;
			fwrite( &cChar, 1, 1, pWorkScr );					/* write character to screen workfile. */
			nBytes--;
		}
		else
		{
			sprintf( szMsg, "Missing DEFINESCREEN data for screen %d", nScreen );
			Error( szMsg );
			nBytes = 0;
		}
	}

	nScreen++;
}

void CR_SpritePosition( void )
{
	unsigned short int nArg;
	short int nCount = 0;
	char cChar;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();												/* always put a ret at the end. */
		nEvent = -1;
	}

	cChar = ( char )( nScreen - 1 );
	fwrite( &cChar, 1, 1, pWorkNme );

	for( nCount = 0; nCount < 4; nCount++ )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nArg = GetNum( 8 );
			cChar = ( char )nArg;
			fwrite( &cChar, 1, 1, pWorkNme );					/* write character to screen workfile. */
		}
		else
		{
			Error( "Missing SPRITEPOSITION data" );
		}
	}

	nPositions++;
}

void CR_DefineObject( void )
{
	unsigned short int nArg;
	short int nDatum = 0;
	unsigned char cChar;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();												/* always put a ret at the end. */
		nEvent = -1;
	}

	do
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			cChar = ( char )GetNum( 8 );
			fwrite( &cChar, 1, 1, pWorkObj );					/* write character to objects workfile. */
			nDatum++;
		}
		else
		{
			Error( "Missing data for DEFINEOBJECT" );
			nDatum = 36;
		}
	}
	while ( nDatum < 36 );

	nObjects++;
}

void CR_Map( void )
{
	unsigned short int nArg;
	unsigned short int nScreen = 0;
	short int nCol = 0;
	short int nDatum = 0;
	short int nDone = 0;

	if ( nEvent >= 0 && nEvent < NUM_EVENTS )
	{
		EndEvent();												/* always put a ret at the end. */
	}

	StartEvent( 99 );											/* use dummy event as map doesn't use a workfile. */

	nArg = NextKeyword();
	if ( nArg == CMP_WIDTH )									/* first argument is width, WIDTH clause optional */
	{
		nArg = NextKeyword();
	}

	if ( nArg == INS_NUM )
	{
		cMapWid = ( char )GetNum( 8 );
		WriteText( "\nMAPWID = " );
		WriteNumber( cMapWid );

		/* seal off the upper edge of the map. */
		WriteInstruction( ".byte " );
		nDone = cMapWid - 1;
		while ( nDone > 0 )
		{
			WriteText( "255," );
			nDone--;
		}
		WriteText( "255" );
	}
	else
	{
		Error( "Map WIDTH not defined" );
	}

	WriteText( "\nmapdat:" );

	nArg = NextKeyword();
	if ( nArg == CMP_STARTSCREEN )								/* first argument is width, WIDTH clause optional */
	{
		nArg = NextKeyword();
	}

	if ( nArg == INS_NUM )
	{
		nStartScreen = GetNum( 8 );
	}
	else
	{
		Error( "Invalid screen number for STARTSCREEN" );
	}

	do
	{
		nArg = NextKeyword();
		switch( nArg )
		{
			case INS_NUM:
				nScreen = GetNum( 8 );
				if ( nScreen == nStartScreen )
				{
					nStartOffset = nDatum;
				}
				if ( nCol == 0 )
				{
					WriteInstruction( ".byte " );
				}
				else
				{
					WriteText( "," );
				}
				WriteNumber( nScreen );
				nDatum++;
				nCol++;
				break;
			case CMP_ENDMAP:
				nDone++;
				break;
		}
	}
	while ( nDone == 0 );

	/* Now write block of 255 bytes to seal the map lower edge */
	WriteInstruction( ".byte " );
	nDone = cMapWid - 1;

	while ( nDone > 0 )
	{
		WriteText( "255," );
		nDone--;
	}

	WriteText( "255" );

	WriteText( "\nstmap:  .byte " );
	WriteNumber( nStartOffset );
	WriteText( "\n");
	EndDummyEvent();											/* write output to target file. */
}

void CR_DefinePalette( void )
{
	unsigned short int nArg;

	while ( cPalette < 64 )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			cDefaultPalette[ cPalette ] = ( unsigned char )GetNum( 8 );
		}
		else
		{
			Error( "DEFINEPALETTE requires 64 RGB definitions" );
		}

		cPalette++;
	}
}

void CR_DefineMessages( void )
{
	unsigned short int nArg;
	unsigned char *cSrc;									/* source pointer. */
	short int nCurrentLine = nLine;

	/* Store source address so we don't skip first instruction after messages. */
	cSrc = cBufPos;
	nArg = NextKeyword();

	if ( nMessageNumber > 0 )
	{
		Error( "MESSAGES must be defined before events" );
	}

	while ( nArg == INS_STR )						/* go through until we find something that isn't a string. */
	{
		cSrc = cBufPos;
		nCurrentLine = nLine;
		CR_ArgA( nMessageNumber++ );				/* number of this message. */
		nArg = NextKeyword();
	}

	cBufPos = cSrc;									/* restore source address so we don't miss the next line. */
	nLine = nCurrentLine;
}

void CR_DefineFont( void )
{
	unsigned short int nArg;
	short int nByte = 0;

	nUseFont = 1;

	while ( nByte < 768 )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			cDefaultFont[ nByte++ ] = ( unsigned char )GetNum( 8 );
		}
		else
		{
			Error( "DEFINEFONT missing data" );
			nByte = 768;
			nUseFont = 0;
		}
	}
}

void CR_DefineJump( void )
{
	unsigned short int nArg;
	unsigned short int nNum = 0;
	short int nByte = 0;

	while ( nNum != 99 )
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nNum = ( unsigned char )GetNum( 8 );
			cDefaultHop[ nByte ] = nNum;
			if ( nByte < 25 )
			{
				nByte++;
			}
			else
			{
				Error( "DEFINEJUMP table too big" );
				nNum = 99;
			}
		}
		else
		{
			Error( "DEFINEJUMP missing 99 end marker" );
			nNum = 99;
		}
	}

	cDefaultHop[ 24 ] = 99;
}

void CR_DefineControls( void )
{
	unsigned char *cSrc;									/* source pointer. */
	unsigned short int nArg;
	unsigned short int nNum = 0;
	short int nByte = 0;
	short int nCount = 0;
	short int nCurrentLine = nLine;

	/* Store source address so we don't skip first instruction after messages. */
	cSrc = cBufPos;

	do
	{
		nArg = NextKeyword();
		if ( nArg == INS_NUM )
		{
			nNum = ( unsigned char )GetNum( 8 );
			if ( nCount < 11 )
			{
				cDefaultKeys[ cKeyOrder[ nCount++ ] ] = ConvertKey( nNum );
			}
		}
	}
	while ( nArg == INS_NUM );

	cBufPos = cSrc;									/* restore source address so we don't miss the next line. */
	nLine = nCurrentLine;
}

unsigned char ConvertKey( short int nNum )
{
	short int nCode = 40;

	/* Convert to upper case. */
	if ( nNum > 96 && nNum < 123 )
	{
		nNum -= 32;
	}

	switch( nNum )
	{

	// row 0
		case 0x33:		// 3
			nCode = 0x01;
			break;
		case 0xbd:		// -
			nCode = 0x02;
			break;
		case 0x47:		// G
			nCode = 0x03;
			break;
		case 0x51:		// Q
			nCode = 0x04;
			break;
		case 0x1b:		// ESC
			nCode = 0x05;
			break;

	// row 1
		case 0x32:		// 2
			nCode = 0x11;
			break;
		case 0x2c:		// ,
			nCode = 0x12;
			break;
		case 0x46:		// F
			nCode = 0x13;
			break;
		case 0x50:		// P
			nCode = 0x14;
			break;
		case 0x5a:		// Z
			nCode = 0x15;
			break;

	// row 2
		case 0x26:		// UP/DOWN
			nCode = 0x20;
			break;
		case 0x31:		// 1
			nCode = 0x21;
			break;
		case 0x3b:		// ;
			nCode = 0x22;
			break;
		case 0x45:		// E
			nCode = 0x23;
			break;
		case 0x4f:		// O
			nCode = 0x24;
			break;
		case 0x59:		// Y
			nCode = 0x25;
			break;

	// row 3
		case 0x27:		// LINKS/RECHTS
			nCode = 0x30;
			break;
		case 0x30:		// 0
			nCode = 0x31;
			break;
		case 0x3a:		// :
			nCode = 0x32;
			break;
		case 0x44:		// D
			nCode = 0x33;
			break;
		case 0x4e:		// N
			nCode = 0x34;
			break;
		case 0x58:		// X
			nCode = 0x35;
			break;

	// row 4
		case 0x14:		// LOCK
			nCode = 0x40;
			break;
		case 0x08:		// DELETE
			nCode = 0x41;
			break;
		case 0x39:		// 9
			nCode = 0x42;
			break;
		case 0x43:		// C
			nCode = 0x43;
			break;
		case 0x4d:		// M
			nCode = 0x44;
			break;
		case 0x57:		// W
			nCode = 0x45;
			break;

	// row 5
		case 0x5e:		// UP
			nCode = 0x50;
			break;
		case 0xf2:		// COPY
			nCode = 0x51;
			break;
		case 0x38:		// 8
			nCode = 0x52;
			break;
		case 0x42:		// B
			nCode = 0x53;
			break;
		case 0x4c:		// L
			nCode = 0x54;
			break;
		case 0x56:		// V
			nCode = 0x55;
			break;

	// row 6
		case 0x5d:		// ]
			nCode = 0x60;
			break;
		case 0x0d:		// RETURN
			nCode = 0x61;
			break;
		case 0x37:		// 7
			nCode = 0x62;
			break;
		case 0x41:		// A
			nCode = 0x63;
			break;
		case 0x4b:		// K
			nCode = 0x64;
			break;
		case 0x55:		// U
			nCode = 0x65;
			break;

	// row 7
		case 0x5c:		// \
			nCode = 0x70;
			break;
		case 0x36:		// 6
			nCode = 0x72;
			break;
		case 0x40:		// @
			nCode = 0x73;
			break;
		case 0x4a:		// J
			nCode = 0x74;
			break;
		case 0x54:		// T
			nCode = 0x75;
			break;

	// row 8
		case 0x5b:		// [
			nCode = 0x80;
			break;
		case 0x35:		// 5
			nCode = 0x82;
			break;
		case 0x2f:		// /
			nCode = 0x83;
			break;
		case 0x49:		// I
			nCode = 0x84;
			break;
		case 0x53:		// S
			nCode = 0x85;
			break;

	// row 9
		case 0x20:		// SPACE
			nCode = 0x90;
			break;
		case 0x34:		// 4
			nCode = 0x92;
			break;
		case 0x2e:		// .
			nCode = 0x93;
			break;
		case 0x48:		// H
			nCode = 0x94;
			break;
		case 0x52:		// R
			nCode = 0x95;
			break;
	}

	return ( nCode );
}

char SpriteEvent( void )
{
	char cSpriteEvent = 0;

	if ( nEvent <= EVENT_INITIALISE_SPRITE ||
		 nEvent == EVENT_FELL_TOO_FAR )
	{
		cSpriteEvent = 1;
	}

	return ( cSpriteEvent );
}

/****************************************************************************************************************/
/* Command requires a number, variable or sprite parameter as an argument.                                      */
/****************************************************************************************************************/
unsigned short int CompileArgument( void )
{
	unsigned short int nArg = NextKeyword();

	if ( nArg == INS_NUM )
	{
		CR_ArgA( GetNum( 8 ) );
	}
	else
	{
		if ( nArg >= FIRST_PARAMETER &&
			 nArg <= LAST_PARAMETER )
		{
			CR_PamA( nArg );
		}
		else
		{
			if ( nArg == INS_STR )							/* it was a string argument. */
			{
				CR_ArgA( nMessageNumber++ );				/* number of this message. */
			}
			else
			{
				Error( "Not a number or variable" );
			}
		}
	}

	return ( nArg );
}

/****************************************************************************************************************/
/* Command requires a number, variable or sprite parameter as an argument.                                      */
/****************************************************************************************************************/
unsigned short int CompileKnownArgument( short int nArg )
{
	if ( nArg == INS_NUM )
	{
		CR_ArgA( GetNum( 8 ) );
	}
	else
	{
		if ( nArg >= FIRST_PARAMETER &&
			 nArg <= LAST_PARAMETER )
		{
			CR_PamA( nArg );
		}
		else
		{
			if ( nArg == INS_STR )							/* it was a string argument. */
			{
				CR_ArgA( nMessageNumber++ );				/* number of this message. */
			}
			else
			{
				Error( "Not a number or variable" );
			}
		}
	}

	return ( nArg );
}

unsigned short int NumberOnly( void )
{
	unsigned short int nArg = NextKeyword();

	if ( nArg == INS_NUM )
	{
		nArg = GetNum( 8 );
	}
	else
	{
		Error( "Only a number will do" );
		nArg = 0;
	}

	return ( nArg );
}

void CR_Operator( unsigned short int nOperator )
{
	nLastOperator = nOperator;
}

void CR_Else( void )
{
	unsigned short int nAddr1;
	unsigned short int nAddr2;
	unsigned short int nAddr3;

	if ( nNumIfs > 0 )
	{
		WriteInstruction( "jmp " );							/* jump over the ELSE to the ENDIF. */
		nAddr2 = nCurrent;									/* store where we are. */
		nAddr1 = nIfBuff[ nNumIfs - 1 ][ 0 ];				/* original conditional jump. */
		nIfBuff[ nNumIfs - 1 ][ 0 ] = nAddr2;				/* store ELSE address so we can write it later. */
		nCurrent = nAddr2;
		WriteLabel( nAddr2 );								/* set jump address before ELSE. */

		nAddr3 = nCurrent;									/* where to resume after the ELSE. */
		nCurrent = nAddr1;
		WriteLabel( nAddr3 );								/* set jump address before ELSE. */
		nCurrent = nAddr3;
		nNextLabel = nCurrent;

		ResetIf();											/* no longer in an IF clause. */
	}
	else
	{
		Error( "ELSE without IF" );
	}
}

/****************************************************************************************************************/
/* We've hit a loose numeric value, so it's an argument for something.                                          */
/* We need to establish how it fits in to the code.                                                             */
/****************************************************************************************************************/
void CR_Arg( void )
{
	if ( nPamType == 255 )									/* this is the first argument we've found. */
	{
		nPamType = NUMERIC;									/* set flag to say we've found a number. */
		nPamNum = GetNum( 8 );
	}
	else													/* this is the second argument. */
	{
		if ( nIfSet > 0 )									/* we're in an IF or WHILE. */
		{
			CR_ArgA( GetNum( 8 ) );							/* compile code to set up this argument. */

			if ( nPamType == NUMERIC )
			{
				CR_ArgB( nPamNum );							/* compile second argument: numeric. */
				CR_StackIf();
			}

			if ( nPamType == SPRITE_PARAMETER )
			{
				CR_PamB( nPamNum );							/* compile second argument: variable or sprite parameter. */
				CR_StackIf();
			}
		}
		else												/* not a comparison, so we're setting a sprite parameter. */
		{
			if ( nPamType == SPRITE_PARAMETER )
			{
				CR_ArgA( GetNum( 8 ) );						/* compile second argument: variable or sprite parameter. */
				CR_PamC( nPamNum );							/* compile code to set variable or sprite parameter. */
			}
			else											/* trying to assign a number to another number. */
			{
				GetNum( 16 );								/* ignore the number. */
			}
			ResetIf();
		}
	}
}

/****************************************************************************************************************/
/* We've hit a loose variable or sprite parameter, so it's an argument for something.                           */
/* We need to establish how it fits in to the code.                                                             */
/****************************************************************************************************************/
void CR_Pam( unsigned short int nParam )
{
	if ( nPamType == 255 )									/* this is the first argument we've found. */
	{
		nPamType = SPRITE_PARAMETER;
		nPamNum = nParam;
	}
	else													/* this is the second argument. */
	{
		if ( nIfSet > 0 )									/* we're in an IF. */
		{
			CR_PamA( nParam );								/* compile second argument: variable or sprite parameter. */
			if ( nPamType == SPRITE_PARAMETER )
			{
				CR_PamB( nPamNum );							/* compare with first argument. */
			}
			else
			{
				CR_ArgB( nPamNum );							/* compare with first argument. */
			}
			CompileCondition();
//			WriteText( "\n:" );
			ResetIf();
		}
		else												/* not an IF, we must be assigning a value. */
		{
			if ( nPamType == SPRITE_PARAMETER )
			{
				CR_PamA( nParam );							/* set up the value. */
				CR_PamC( nPamNum );
			}
			else
			{
				ResetIf();
			}
		}
	}
}


/****************************************************************************************************************/
/* CR_ArgA, CR_PamA compile code to put the number or parameter in the accumulator.                             */
/* CR_ArgB, CR_PamB compile code to compare the number or parameter with the number already in the accumulator. */
/****************************************************************************************************************/
void CR_ArgA( short int nNum )
{
	if ( nNum == 0 )
	{
		WriteInstruction( "lda #0" );
	}
	else
	{
		WriteInstruction( "lda #" );
		WriteNumber( nNum );
	}
}

void CR_ArgB( short int nNum )
{
	WriteInstruction( "cmp #" );
	WriteNumber( nNum );
	WriteJPNZ();
}

void CR_PamA( short int nNum )
{
	char cVar[ 14 ];

	if ( nNum >= FIRST_VARIABLE )							/* load accumulator with global variable. */
	{
		sprintf( cVar, "lda %s", cVariables[ nNum - FIRST_VARIABLE ] );
		WriteInstruction( cVar );
	}
	else													/* load accumulator with sprite parameter. */
	{
		WriteInstructionArg( "ldy #?", nNum - IDIFF );
		WriteInstruction( "lda (z80_ix),y" );
	}
}

void CR_PamB( short int nNum )
{
	char cVar[ 13 ];

	if ( nNum >= FIRST_VARIABLE )							/* compare accumulator with global variable. */
	{
		sprintf( cVar, "cmp %s", cVariables[ nNum - FIRST_VARIABLE ] );
		WriteInstruction( cVar );
	}
	else													/* compare accumulator with sprite parameter. */
	{
		WriteInstructionArg( "ldy #?", nNum - IDIFF );
		WriteInstruction( "cmp (z80_ix),y" );
	}

	WriteJPNZ();											/* write conditional jump at end of if. */
}

void CR_PamC( short int nNum )
{
	char cVar[ 14 ];

	if ( nNum >= FIRST_VARIABLE )							/* compare accumulator with global variable. */
	{
		sprintf( cVar, "sta %s", cVariables[ nNum - FIRST_VARIABLE ] );
		WriteInstruction( cVar );

		if ( nNum == VAR_SCREEN )							/* is this code changing the screen? */
		{
			WriteInstruction( "jsr nwscr" );				/* address of routine to display the new screen. */
		}
	}
	else													/* compare accumulator with sprite parameter. */
	{
		WriteInstructionArg( "ldy #?", nNum - IDIFF );
		WriteInstruction( "sta (z80_ix),y" );
	}
}


void CR_StackIf( void )
{
	CompileCondition();
	ResetIf();
}

/****************************************************************************************************************/
/* Converts up/down/left/right to Kempston joystick right/left/down/up.                                         */
/****************************************************************************************************************/
short int Joystick( short int nArg )
{
	short int nArg2;

//	switch( nArg )										/* conversion to Kempston bit order. */
//	{
//		case 0:
//			nArg2 = 0;
//			break;
//		case 1:
//			nArg2 = 1;
//			break;
//		case 2:
//			nArg2 = 2;
//			break;
//		case 3:
//			nArg2 = 3;
//			break;
//		default:
			nArg2 = nArg;
//			break;
//	}
//
	return ( nArg2 );
}

/****************************************************************************************************************/
/* We don't yet know where we want to jump following the condition, so remember address where label will be     */
/* written when we have that address.                                                                           */
/****************************************************************************************************************/
void CompileCondition( void )
{
	if ( nLastCondition == INS_IF )
	{
		if ( nNumIfs < NUM_NESTING_LEVELS )
		{
			nIfBuff[ nNumIfs ][ 0 ] = nCurrent - 6;			/* minus 6 for label after conditional jump. */
			nNumIfs++;
		}
		else
		{
			fputs( "Too many IFs\n", stderr );
		}
	}
	else
	{
		if ( nNumWhiles < NUM_NESTING_LEVELS )
		{
			nWhileBuff[ nNumWhiles ][ 0 ] = nCurrent - 6;	/* minus 6 for label after conditional jump. */
			nNumWhiles++;
		}
		else
		{
			fputs( "Too many WHILEs\n", stderr );
		}
	}
}

/****************************************************************************************************************/
/* Writes the conditional jump at the end of an IF.                                                             */
/****************************************************************************************************************/
void WriteJPNZ( void )
{
	if ( nLastCondition == INS_IF )
	{
		nIfBuff[ nNumIfs ][ 1 ] = 0;
	}
	else
	{
		nWhileBuff[ nNumWhiles ][ 1 ] = 0;
	}

	switch ( nLastOperator )
	{
		case OPE_NOT:
			WriteInstruction( "bne *+5" );
			WriteInstruction( "jmp xxxxxx" );
			break;
		case OPE_GRTEQU:
			WriteInstruction( "beq *+4" );					/* test succeeded, skip jp nc instruction */
			WriteInstruction( "bcs xxxxxx" );
			break;
		case OPE_GRT:
			WriteInstruction( "bcc *+5" );
			WriteInstruction( "jmp xxxxxx" );
			break;
		case OPE_LESEQU:
			WriteInstruction( "bcs *+5" );
			WriteInstruction( "jmp xxxxxx" );
			break;
		case OPE_LES:
			WriteInstruction( "bcc *+4");
//			WriteInstruction( "jmp xxxxxx" );
//			if ( nLastCondition == INS_IF )
//			{
//				nIfBuff[ nNumIfs ][ 1 ] = nCurrent - 6;		/* minus 6 for label after conditional jump. */
//			}
//			else
//			{
//				nWhileBuff[ nNumWhiles ][ 1 ] = nCurrent - 6;
//			}
			WriteInstruction( "bne *+5" );
			WriteInstruction( "jmp xxxxxx" );
			break;
		case OPE_EQU:
		default:
			WriteInstruction( "beq *+5" );
			WriteInstruction( "jmp xxxxxx" );
			break;
	}
}

void WriteNumber( unsigned short int nInteger )
{
	unsigned char cNum[ 6 ];
	unsigned char *cChar = cNum;

	sprintf( cNum, "%d", nInteger );
	cObjt = cStart + ( nCurrent - nAddress );

	while ( *cChar )
	{
		*cObjt = *cChar++;
		cObjt++;
		nCurrent++;
	}
}

void WriteText( unsigned char *cChar )
{
	while ( *cChar )
	{
		*cObjt = *cChar++;
		cObjt++;
		nCurrent++;
	}
}

void WriteInstruction( unsigned char *cCommand )
{
	NewLine();
	cObjt = cStart + ( nCurrent - nAddress );

	while ( *cCommand )
	{
		*cObjt = *cCommand++;
		cObjt++;
		nCurrent++;
	}
}

void WriteInstructionAndLabel( unsigned char *cCommand )
{
	short int nChar = 0;
	unsigned char cLine[ 3 ] = "\n";

	cObjt = cStart + ( nCurrent - nAddress );

	while ( cLine[ nChar ] )
	{
		*cObjt = cLine[ nChar++ ];
		cObjt++;
		nCurrent++;
	}

	while ( *cCommand )
	{
		*cObjt = *cCommand++;
		cObjt++;
		nCurrent++;
	}
}

void WriteInstructionArg( unsigned char *cCommand, unsigned short int nNum )
{
	NewLine();
	cObjt = cStart + ( nCurrent - nAddress );

	while ( *cCommand )
	{
		if ( *cCommand == '?' )
		{
			WriteNumber( nNum );
			cCommand++;
		}
		else
		{
			*cObjt = *cCommand++;
			cObjt++;
			nCurrent++;
		}
	}
}

void WriteLabel( unsigned short int nWhere )
{
	unsigned char cLabel[ 7 ];
	unsigned char *cChar = cLabel;

	sprintf( cLabel, "%c%05d", nEvent + 'a', nWhere >> 2 );
	cObjt = cStart + ( nCurrent - nAddress );

	while ( *cChar )
	{
		*cObjt = *cChar++;
		cObjt++;
		nCurrent++;
	}
}

void NewLine( void )
{
	unsigned char cLine[ 10 ] = "\n        ";
	unsigned char *cChar = cLine;

	cObjt = cStart + ( nCurrent - nAddress );

	if ( nNextLabel > 0 )
	{
		sprintf( cLine, "\n%c%05d  ", nEvent + 'a', nNextLabel >> 2 );
		cLine[7] = ':';
		nNextLabel = 0;
	}
	else
	{
		strcpy( cLine, "\n        " );
	}

	while ( *cChar )
	{
		*cObjt = *cChar++;
		cObjt++;
		nCurrent++;
	}
}

void Error( unsigned char *cMsg )
{
	fprintf( stderr, "%s on line %d\n", cMsg, nLine );
	nErrors++;
}
