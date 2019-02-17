#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

/* Definitions.  */

#define LF						0x0a
#define CR						0x0d
#define TARGET_CODE_SIZE		131072		// enough for source code?
#define SNAPSHOT_SIZE			49179
#define FONT					( 31232 + 27 - 16384 )
#define MAP_LAYOUT_A			( 31959 + 27 - 16384 )
#define MAP_LAYOUT_B			( 31959 + 27 - 16384 )
#define WINDOW					( 32008 + 27 - 16384 )
#define NUM_SCREENS				( 32018 + 27 - 16384 )
#define POINTERS				( 32059 + 27 - 16384 )
#define POINTERS_A				( 32057 + 27 - 16384 )
#define POINTERS_B				( 32059 + 27 - 16384 )
#define START_SCREEN_A			( 33580 + 27 - 16384 )
#define START_SCREEN_B			( 33615 + 27 - 16384 )
#define KEYS_A					( 35331 + 27 - 16384 )
#define KEYS_B					( 35339 + 27 - 16384 )
#define JUMP_TABLE_A			( 36217 + 27 - 16384 )
#define JUMP_TABLE_B			( 36238 + 27 - 16384 )
#define STUFF_TO_SKIP			( 16384 - 27 )
#define MAP_HGT					8
#define MAP_WID					11
#define NUM_EVENTS				21

// Equates for version 4.7
enum
{
	INS_IF,
	INS_MSU,
	INS_MSD,
	INS_MSL,
	INS_MSR,
	INS_ENDIF,
	INS_CGU,
	INS_CGD,
	INS_CGL,
	INS_CGR,
	INS_LDU,
	INS_LDD,
	INS_DED,
	INS_CUS,
	INS_NUMBER,
	INS_TO,
	INS_FROM,
	INS_BY,
	INS_TYP,
	INS_IMAGE,
	INS_FRAME,
	INS_X,
	INS_Y,
	INS_DIR,
	INS_PMA,
	INS_PMB,
	INS_SCREEN,
	INS_LIVES,
	INS_A,
	INS_B,
	INS_C,
	INS_D,
	INS_E,
	INS_F,
	INS_G,
	INS_H,
	INS_I,
	INS_J,
	INS_K,
	INS_L,
	INS_M,
	INS_N,
	INS_O,
	INS_P,
	INS_Q,
	INS_R,
	INS_S,
	INS_T,
	INS_LINE,
	INS_COLUMN,
	INS_CLOCK,
	INS_RND,
	INS_OBJ,
	INS_OPT,
	INS_GOT,
	INS_KEY,
	INS_COLLISION,
	INS_EQUAL_TO,
	INS_GREATER_THAN,
	INS_NOT_EQUAL_TO,
	INS_LESS_THAN,
	INS_LET,
	INS_ANIMATE,
	INS_ANIMBACK,
	INS_PUTBLOCK,
	INS_NEXTLEVEL,
	INS_RESTART,
	INS_SPAWN,
	INS_REM,
	INS_GRN,
	INS_ELSE,
	INS_DSC,
	INS_SCO,
	INS_SND,
	INS_BEEP,
	INS_CLS,
	INS_BORDER,
	INS_CLR,
	INS_DEL,
	INS_MESSAGE,
	INS_MENU,
	INS_INV,
	INS_KILL,
	INS_ADD,
	INS_SUB,
	INS_DIS,
	INS_SUP,
	INS_SDW,
	INS_SLF,
	INS_SRG,
	INS_PRE,
	INS_JUMP,
	INS_FALL,
	INS_OTHER,
	INS_SPAWNED,
	INS_ORIGINAL,
	INS_EGM,
	INS_GET,
	INS_PUT,
	INS_DET,
	INS_ASM,
	INS_EXIT,
	INS_REPEAT,
	INS_ENDREPEAT,
	INS_MULTIPLY,
	INS_DIVDE,
	INS_SPI,
	INS_TRAIL,
	INS_LASER,
	INS_EXPLODE,
	INS_FADE,
	INS_TICKER,
	INS_BIGMESSAGE,
	INS_REDRAW,
	INS_SIL,
	INS_CON,
	INS_DIG,
	INS_STR,
	INS_BIGSCORE,
	INS_STOPFALL
};

#define INS_ARGUMENTS			INS_CGU

typedef struct
{
	short int top;
	short int bottom;
	short int left;
	short int right;
} RECT;

unsigned char cKeyword[][ 13 ] =
{
	/* Some keywords. */
	"IF",				// if.
	"SPRITEUP",			// move sprite up.
	"SPRITEDOWN",		// move sprite down.
	"SPRITELEFT",		// move sprite left.
	"SPRITERIGHT",		// move sprite right.
	"ENDIF",			// endif.
	"CANGOUP",			// sprite can go up test.
	"CANGODOWN",		// sprite can go down test.
	"CANGOLEFT",		// sprite can go left test.
	"CANGORIGHT",		// sprite can go right test.
	"LADDERABOVE",		// ladder above test.
	"LADDERBELOW",		// ladder below test.
	"DEADLY",			// check if touching deadly block.
	"CUSTOM",    		// check if touching custom block.
	".",				// number.
	"TO",           	// variable to increment.
	"FROM",          	// variable to decrement.
	"BY",	          	// multiply or divide by.

	/* Sprite variables. */

	"TYPE",				// first parameter.
	"IMAGE",			// image number.
	"FRAME",			// frame number.
	"Y",				// vertical position.
	"X",				// horizontal position.
	"DIRECTION",		// user sprite parameter.
	"SETTINGA",			// sprite parameter a.
	"SETTINGB",			// sprite parameter b.
	"SCREEN",			// screen number.
	"LIVES",			// lives.
	"A",				// variable.
	"B",				// variable.
	"C",				// variable.
	"D",				// variable.
	"E",				// variable.
	"F",				// variable.
	"G",				// variable.
	"H",				// variable.
	"I",				// variable.
	"J",				// variable.
	"K",				// variable.
	"L",				// variable.
	"M",				// variable.
	"N",				// variable.
	"O",				// variable.
	"P",				// variable.
	"Q",				// variable.
	"R",				// variable.
	"S",				// variable.
	"T",				// variable.
	"LINE",				// x coordinate.
	"COLUMN",			// y coordinate.
	"CLOCK",			// clock.
	"RND",				// last random number variable.
	"OBJ",				// last object variable.
	"OPT",				// menu option variable.
	"GOT",				// function.
	"KEY",				// function.

	/* Commands. */

	"COLLISION",		// collision with sprite.
	"=",				// equals, ignored.
	">",				// greater than.
	"<>",				// not equal to.
	"<=",				// less than or equal to.
	"LET",				// x = y.
	"ANIMATE",			// animate sprite.
	"ANIMBACK",			// animate sprite backwards.
	"PUTBLOCK",			// put block on screen.
	"NEXTLEVEL",		// next level.
	"RESTART",			// restart game.
	"SPAWN",			// spawn new sprite.
	"REMOVE",			// remove this sprite.
	"GETRANDOM",		// variable.
	"ELSE",				// else.
	"SHOWSCORE",		// show score.
	"SCORE",			// increase score.
	"; SOUND",			// play sound.
	"BEEP",				// play beeper sound.
	"CLS",				// clear screen.
	"; BORDER",			// set border.
	"; COLOUR",			// set all attributes.
	"DELAY",			// pause for a while.
	"MESSAGE",			// display a message.
	"MENU",				// menu in a box.
	"INV",				// inventory menu.
	"KILL",				// kill the player.
	"ADD",				// add to variable.
	"SUBTRACT",			// subtract from variable.
	"DISPLAY",			// display number.
	"SCREENUP",			// up a screen.
	"SCREENDOWN",		// down a screen.
	"SCREENLEFT",		// left a screen.
	"SCREENRIGHT",		// right a screen.
	"WAITKEY",			// wait for keypress.
	"TABLEJUMP",		// jump.
	"TABLEFALL",		// fall.
	"OTHER",			// select second collision sprite.
	"SPAWNED",			// select spawned sprite.
	"ENDSPRITE",		// select original sprite.
	"ENDGAME",			// end game with victory.
	"GET",				// get object.
	"PUT",				// drop object.
	"DETECTOBJ",		// detect object.
	"; ASM",			// encode.
	"EXIT",				// exit.
	"REPEAT",			// repeat.
	"ENDREPEAT",		// endrepeat.
	"MULTIPLY",			// multiply.
	"DIVIDE",			// divide.
	"; SPRITEINK",		// set sprite ink.
	"TRAIL",			// leave a trail.
	"LASER",			// shoot a laser.
	"EXPLODE",			// start a shrapnel explosion.
	"; FADE",			// fade unsupported.
	"TICKER",			// ticker message.
	"MESSAGE",			// big message.
	"REDRAW",			// redraw the play area.
	"; SILENCE",		// silence AY channels.
	"CONTROLMENU",		// controlmenu unsupported.
	"DIG",				// dig.
	"STAR",				// star.
	"SHOWSCORE",		// show score double-height.
	"STOPFALL"			// stop falling.
};

unsigned char cEvent[][ 14 ] =
{
	"PLAYER",			// player.
	"SPRITETYPE1",		// sprite type 1.
	"SPRITETYPE2",		// sprite type 2.
	"SPRITETYPE3",		// sprite type 3.
	"SPRITETYPE4",		// sprite type 4.
	"SPRITETYPE5",		// sprite type 5.
	"SPRITETYPE6",		// sprite type 6.
	"SPRITETYPE7",		// sprite type 7.
	"SPRITETYPE8",		// sprite type 8.
	"INITSPRITE",		// initialise sprite.
	"MAINLOOP1",		// main loop 1.
	"MAINLOOP2",		// main loop 2.
	"INTROMENU",		// main menu.
	"GAMEINIT",			// game initialisation.
	"RESTARTSCREEN",	// restart a screen.
	"FELLTOOFAR",		// sprite fell too far.
	"KILLPLAYER",		// kill player.
	"LOSTGAME",			// game over.
	"COMPLETEDGAME",	// won game.
	"NEWHIGHSCORE",		// new high score.
	"COLLECTBLOCK"		// collected block.
};

/* Table used to convert keycodes to ASCII. */
const unsigned char cKeyTab[ 40 ] =
{
	'B', 'H', 'Y', '6', '5', 'T', 'G', 'V',
	'N', 'J', 'U', '7', '4', 'R', 'F', 'C',
	'M', 'K', 'I', '8', '3', 'E', 'D', 'X',
	'.', 'L', 'O', '9', '2', 'W', 'S', 'Z',
	32, 13,	'P', '0', '1', 'Q', 'A', '~'
};

char cYDither[ 8 ][35] =
{
	" 0 0 0 0 0 0 0 0",
	" 17 0 68 0 17 0 68 0",
	" 85 0 85 0 85 0 85 0",
	" 85 170 85 170 85 170 85 170",
	" 85 170 85 170 85 170 85 170",
	" 170 255 170 255 170 255 170 255",
	" 238 255 238 255 238 255 238 255",
	" 255 255 255 255 255 255 255 255"
};

char cNDither[ 8 ][35] =
{
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0",
	" 0 0 0 0 0 0 0 0"
};

unsigned short int flagB = 0;
unsigned short int flagD = 0;
FILE *fpSource;
FILE *fpObject;
unsigned char *cTgt;
unsigned char *cSrc;
unsigned char *cBuff;
unsigned long int lSize;									/* source file length. */
unsigned short int nFrmlst;
unsigned short int nSprites;
unsigned short int nChgfx;
unsigned short int nBlkcol;
unsigned short int nBprop;
unsigned short int nScdat;
unsigned short int nNmedat;
unsigned short int nSounds;
unsigned short int nText;
unsigned short int nObjects;
unsigned short int nCode;
unsigned short int nControls;
unsigned short int nAddComment = 0;	/* Add comment to outputcode */
short int nTabs;
unsigned char *cTop;
unsigned char *cLeft;
unsigned char *cHeight;
unsigned char *cWidth;
unsigned char cNewLine = 0;
unsigned char cDefaultAttr = 71;
//short int nTop;
//short int nLeft;
//short int nHeight;
//short int nWidth;
short int nRooms;
short int nPrintMode = 0;
short int nVersion;
short int nLastOp = -1;

/* Prototypes. */

void Convert( void );
void OutputWindow( void );
void OutputKeys( void );
void OutputMessages( void );
void OutputFont( void );
void OutputJumpTable( void );
void OutputBlocks( void );
void OutputSprites( void );
void OutputScreens( void );
void OutputObjects( void );
void OutputMap( void );
RECT GetMapEdges( unsigned char *cMap );
void OutputCode( void );
unsigned char ConvertByte( unsigned char cByte );
void CodeLine( char cInstruction, char cNext );
void WriteText( unsigned char *cChar );
void WriteComment( unsigned char *cChar );
void NewLine( void );

int main( int argc, const char* argv[] )
{
	char szSourceFilename[ 128 ];
	char szObjectFilename[ 128 ];
	short int flgParm;

	puts( "AGD extractor tool V0.5" );
	puts( "(C) Jonathan Cauldwell May 2018" );
	puts( "Dragon version by K.v.Oss 2018" );

	if ( argc != 2 && argc !=3 && argc !=4 )
	{
	    // invalid number of command line arguments
		puts( "Usage: CONVERT SNAPSHOT paramB (0 or 1) paramD (0 or 1)" );
		exit( 1 );
	}
	else
	{
		if ( argc == 3  || argc == 4)
		{
 		    flagB = 0;
			flgParm = atoi(argv[2]);
			if ( flgParm == 1 )
			{
			   flagB = 1;
			}
 		    flagD = 0;
			flgParm = atoi(argv[3]);
			if ( flgParm == 1 )
			{
			   flagD = 1;
			}
		}
	}

	/* open source snapshot. */
	sprintf( szSourceFilename, "%s.sna", argv[ 1 ] );
	fpSource = fopen( szSourceFilename, "rb" );
	if ( !fpSource )
	{
       	fprintf( stderr, "Unable to read snapshot file: %s\n", szSourceFilename );
		exit( 1 );
	}

	/* Establish its size. */
	fseek( fpSource, 0, SEEK_END );
	lSize = ftell( fpSource );
	rewind( fpSource );
	if ( lSize != SNAPSHOT_SIZE )
	{
		puts( "Source is not a 48K snapshot" );
		exit( 1 );
	}

	/* Open target file. */
	sprintf( szObjectFilename, "%s.agd", argv[ 1 ] );
	fpObject = fopen( szObjectFilename, "wb" );

	if ( !fpObject )
	{
        fprintf( stderr, "Unable to create target file: %s\n", szObjectFilename );
		exit( 1 );
	}

	/* Allocate buffer for the snapshot. */
	cSrc = ( char* )malloc( SNAPSHOT_SIZE );
	cBuff = cSrc;
	if ( !cSrc )
	{
		fputs( "Out of memory\n", stderr );
		exit( 1 );
	}

	/* Read source file into the buffer. */
	lSize = fread( cBuff, 1, lSize, fpSource );

	Convert();
	free( cSrc );
}

void Convert( void )
{
	unsigned short int nAddr;
	unsigned short int nSkip = STUFF_TO_SKIP;
	unsigned short int nPointers;

	cTop = cBuff + WINDOW;
	cLeft = cBuff + WINDOW + 1;
	cHeight = cBuff + WINDOW + 2;
	cWidth = cBuff + WINDOW + 3;
	nRooms = *( cBuff + NUM_SCREENS );

	/* look for pointers to determine version. */
	nAddr = *( cBuff + POINTERS_A ) + ( *( cBuff + POINTERS_A + 1 ) << 8 );

	/* is this version 4.6 or 4.7? */
	if ( nAddr == 36924 )
	{
		nVersion = 46;
		nPointers = POINTERS_A;
		nControls = KEYS_A;
	}
	else
	{
		nVersion = 47;
		nPointers = POINTERS_B;
		nControls = KEYS_B;
	}

	printf( "\nAssuming version %d.%d\n", nVersion / 10, nVersion % 10 );

	/* Addresses. */
	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Sprite frames list %d\n", nAddr );
	nFrmlst = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Sprite data %d\n", nAddr );
	nSprites = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Block image data %d\n", nAddr );
	nChgfx = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Block attribute data %d\n", nAddr );
	nBlkcol = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Block properties data %d\n", nAddr );
	nBprop = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Screen layouts %d\n", nAddr );
	nScdat = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Enemy positions %d\n", nAddr );
	nNmedat = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "AY sound effects %d\n", nAddr );
	nSounds = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Text %d\n", nAddr );
	nText = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Objects %d\n", nAddr );
	nObjects = nAddr - nSkip;
	cBuff += 2;

	nAddr = *( cBuff + nPointers ) + ( *( cBuff + nPointers + 1 ) << 8 );
	printf( "Events code %d\n", nAddr );
	nCode = nAddr - nSkip;
	cBuff += 2;

	OutputWindow();
	OutputKeys();
	OutputMessages();
	OutputFont();
	OutputJumpTable();
	OutputBlocks();
	OutputSprites();
	OutputScreens();
	OutputObjects();
	OutputMap();
	OutputCode();
}

void OutputWindow( void )
{
	unsigned char cData[ 16 ];

	NewLine();
	WriteText( "DEFINEWINDOW    " );

	sprintf( cData, "%d %d %d %d", *cTop, *cLeft, *cHeight, *cWidth );
	WriteText( cData );
	NewLine();
}

void OutputKeys( void )
{
	unsigned char cData[ 10 ];
	unsigned char cKeys[ 7 ];
	short int nCount;

	NewLine();
	WriteText( "DEFINECONTROLS " );
	cBuff = cSrc + nControls;

	/* Extract the keyboard controls. */
	cKeys[ 3 ] = *cBuff++;
	cKeys[ 2 ] = *cBuff++;
	cKeys[ 1 ] = *cBuff++;
	cKeys[ 0 ] = *cBuff++;
	for ( nCount = 4; nCount < 7; nCount++ )
	{
		cKeys[ nCount ] = *cBuff++;
	}

	for ( nCount = 0; nCount < 7; nCount++ )
	{
		if ( cKeyTab[ cKeys[ nCount ] ] < 32 )
		{
			sprintf( cData, " %d", cKeyTab[ cKeys[ nCount ] ] );
		}
		else
		{
			sprintf( cData, " '%c'", cKeyTab[ cKeys[ nCount ] ] );
		}
		WriteText( cData );
	}

	NewLine();
}

void OutputMessages( void )
{
	unsigned char cData[ 36 ];
	unsigned char cByte;
	unsigned short int nCount = nObjects - nText;
	unsigned short int nNr = 0;

	NewLine();
	WriteText( "DEFINEMESSAGES" );
	NewLine();
	cBuff = cSrc + nText;

	while ( nCount > 0 )
	{
		sprintf( cData, "; Msg %d", nNr++ );
		WriteComment( cData );
		if (nAddComment > 0) NewLine();
		WriteText( "    \"" );
		while ( *cBuff < 128 )
		{
			cByte = *cBuff++;
			if ( cByte == 34 )				/* quotation marks? */
			{
				fwrite( "'", 1, 1, fpObject );		/* replace double quote with single quote. */
			} else {
				fwrite( &cByte, 1, 1, fpObject );	/* write second set of quotes to file. */
			}
			nCount--;
		}

		cByte = *cBuff++;
		cByte &= 127;
		fwrite( &cByte, 1, 1, fpObject );			/* write output to file. */
		WriteText( "\"" );
		NewLine();
		nCount--;
	}
}

void OutputFont( void )
{
	unsigned char cData[ 40 ];
	short int nCount;
	short int nByte;

	cBuff = cSrc + FONT;

	NewLine();
	nCount = 0;

	while ( nCount < 96 )
	{
		if ( nCount == 0 )
		{
			WriteText( "DEFINEFONT     " );
		}
		else
		{
			WriteText( "               " );
		}

		for ( nByte = 0; nByte < 8; nByte++ )
		{
			sprintf( cData, " %d", *cBuff++ );
			WriteText( cData );
		}

		NewLine();
		nCount++;
	}
}

void OutputJumpTable( void )
{
	unsigned char cData[ 10 ];
	unsigned short int nStart;

	if ( nVersion < 47 )
	{
		nStart = JUMP_TABLE_A;
	}
	else
	{
		nStart = JUMP_TABLE_B;
	}

	cBuff = cSrc + nStart;

	NewLine();
	WriteText( "DEFINEJUMP     " );

	while ( *cBuff != 99 )
	{
		sprintf( cData, " %d", *cBuff++ );
		WriteText( cData );
	}

	sprintf( cData, " %d", *cBuff );
	WriteText( cData );
	NewLine();
}

void OutputBlocks( void )
{
	unsigned char *cImg;
	unsigned char *cProp;
	unsigned char *cAttr;
	unsigned char *cText;
	unsigned char cByte;
	unsigned char cData[ 36 ];
	short int nCount = nBprop - nBlkcol;
	short int nNr = 0;
	short int nByte;
	short int nChecksum;
	short int nColour;
	unsigned char cBitmap[ 8 ];
	unsigned char cBlock[][ 14 ] =
	{
		"EMPTYBLOCK",		// empty space.
		"PLATFORMBLOCK",	// platform.
		"WALLBLOCK",		// wall.
		"LADDERBLOCK",		// ladder.
		"FODDERBLOCK",		// fodder.
		"DEADLYBLOCK",		// deadly.
		"CUSTOMBLOCK",		// custom.
		"WATERBLOCK",		// water block.
		"COLLECTABLE"		// collectable.
	};

	cImg = cSrc + nChgfx;
	cProp = cSrc + nBprop;
	cAttr = cSrc + nBlkcol;
	cDefaultAttr = *cAttr;

	NewLine();

	while ( nCount > 0 )
	{
		WriteText( "DEFINEBLOCK     " );
		cByte = *cProp;
//		cText = cBlock[ cByte ];

		if (cByte > 8 )
		{
			cText = cBlock[ 0 ];
		}
		else
		{
			cText = cBlock[ cByte ];
		}

		WriteText( cText );
		NewLine();
		nChecksum =0;
		for ( nByte = 0; nByte < 8; nByte++ )
		{
			cBitmap[ nByte ] = *cImg++;
			nChecksum=nChecksum+cBitmap[ nByte ];
		}

		WriteText( "               " );

		nColour = ( *cAttr >> 3) & 7;
//		printf("\nBlockChecksum: %d, Colour: %d, ", nChecksum, nColour);

		if (nChecksum == 0)
		{
			if ( flagD == 1) {
				WriteText( cYDither[nColour]);
			}  else {
				WriteText( cNDither[nColour]);
			}
		} else {
			for ( nByte = 0; nByte < 8; nByte++ )
			{
				sprintf( cData, " %d", cBitmap[ nByte ] );
				WriteText( cData );
			}

		}
		NewLine();
		sprintf( cData, "                %d", *cAttr );
		WriteText( cData );

		NewLine();
		NewLine();
		nCount--;
		cProp++;
		cAttr++;
	}
}

void OutputSprites( void )
{
	short int nByteMax;
	unsigned char *cImg;
	unsigned char *cFrm;
	unsigned char cByte;
	unsigned char cData[ 50 ];
	unsigned char cBitmap[ 48 ];
	short int nCount = nChgfx - nSprites;
	short int nNr = 0;
	short int nByte;
	short int nFrames;
	short int nGroups;

	cFrm = cSrc + nFrmlst + 1;							/* number of frames. */
	cImg = cSrc + nSprites;								/* sprite image data. */
	NewLine();
	nGroups = ( nSprites - nFrmlst ) / 2;				/* total sprite groups. */
	if ( flagB == 1 )
	{
		nByteMax = 48;
	}
	else
	{
		nByteMax = 32;
	}

	while ( nGroups-- > 0 )
	{
		nFrames = *cFrm;
		sprintf( cData, "; Spritenr %d", nNr++ );
		WriteComment( cData );
//		NewLine();
		sprintf( cData, "DEFINESPRITE    %d", nFrames );
		WriteText( cData );
		NewLine();

		while ( nFrames-- > 0 )
		{
			for ( nByte = 0; nByte < nByteMax; nByte++ )
			{
				cBitmap[ nByte ] = *cImg++;
			}

			WriteText( "               " );

			for ( nByte = 0; nByte < 16; nByte++ )
			{
				sprintf( cData, " %d", cBitmap[ nByte ] );
				WriteText( cData );
			}

			NewLine();
			WriteText( "               " );

			while ( nByte < 32 )
			{
				sprintf( cData, " %d", cBitmap[ nByte++ ] );
				WriteText( cData );
			}

			NewLine();

			if ( flagB == 1 )
			{
				WriteText( "               " );

				while ( nByte < 48 )
				{
					sprintf( cData, " %d", cBitmap[ nByte++ ] );
					WriteText( cData );
				}

				NewLine();
				NewLine();
				nCount -= 192;
				cImg += 144;									/* skip shifted versions. */
			}
			else
			{
				NewLine();
				nCount -= 128;
				cImg += 96;									/* skip shifted versions. */
			}
		}

		cFrm += 2;
	}
}

void OutputScreens( void )
{
	short int nExpand = 0;
	short int nByteToExpand;
	unsigned char *cScrn;
	unsigned char *cNme;
	unsigned char cByte;
	unsigned char cData[ 36 ];
	short int nThisRoom = 0;
	short int nRow;
	short int nCol;
	short int nNr = 0;

	cScrn = cSrc + nScdat + nRooms + nRooms;			/* skip to room data. */
	cNme = cSrc + nNmedat;

	while ( nThisRoom < nRooms )
	{
		nRow = 0;
		nCol = 0;

		while ( nRow < *cHeight )
		{
			nCol = 0;
			NewLine();

			if ( nRow == 0 )
			{
				sprintf( cData, "; Screen nr %d", nNr++ );
				WriteComment( cData );
//				NewLine();
				WriteText( "DEFINESCREEN   " );
			}
			else
			{
				WriteText( "               " );
			}

			while ( nCol++ < *cWidth )
			{
				if ( nExpand > 0 )
				{
					cByte = nByteToExpand;
					nExpand--;
				}
				else
				{
					cByte = *cScrn++;

					if ( cByte == 255 )					/* start of compressed data block. */
					{
						cByte = nByteToExpand = *cScrn++;
						nExpand = *cScrn++;
						if ( nExpand == 0 )				/* 0 indicates 256 bytes to follow. */
						{
							nExpand = 256;
						}
						nExpand--;
					}
				}

				sprintf( cData, " %3d", cByte );
				WriteText( cData );
			}

			nRow++;
		}

		nThisRoom++;
		NewLine();

		cByte = *cNme++;
		while ( cByte != 255 )
		{
			WriteText( "SPRITEPOSITION  " );
			sprintf( cData, "%d", cByte );
			WriteText( cData );
			cByte = *cNme++;
			sprintf( cData, " %d", cByte );
			WriteText( cData );
			cByte = *cNme++;
			sprintf( cData, " %d", cByte );
			WriteText( cData );
			cByte = *cNme++;
			sprintf( cData, " %d", cByte );
			WriteText( cData );
			cByte = *cNme++;
			NewLine();
		}
	}
}

void OutputObjects( void )
{
	unsigned char *cObj;
	short int nCount = nCode - nObjects - 1;			/* ignore marker at end of objects. */
	unsigned char cBitmap[ 32 ];
	unsigned char cData[ 36 ];
	short int nRow;
	short int nByte;
	short int nNr = 0;

	cObj = cSrc + nObjects;								/* point to first object. */
	NewLine();

	while ( nCount > 0 )
	{
		for ( nByte = 0; nByte < 32; nByte++ )
		{
			cBitmap[ nByte ] = *cObj++;
		}

		cObj += 3;
		sprintf( cData, "; Object nr %d", nNr++ );
		WriteComment( cData );
//		NewLine();
		WriteText( "DEFINEOBJECT    " );
		sprintf( cData, "%d", cDefaultAttr );			/* use default attribute as wasn't supported before. */
		WriteText( cData );
		sprintf( cData, " %d", *cObj++ );				/* room. */
		WriteText( cData );
		sprintf( cData, " %d", *cObj++ );				/* x. */
		WriteText( cData );
		sprintf( cData, " %d", *cObj++ );				/* y. */
		WriteText( cData );
		nCount -= 38;
		NewLine();

		for ( nRow = 0; nRow < 2; nRow++ )
		{
			WriteText( "               " );

			for ( nByte = 0; nByte < 16; nByte++ )
			{
				sprintf( cData, " %d", cBitmap[ nRow * 16 + nByte ] );
				WriteText( cData );
			}

			NewLine();
		}

		NewLine();
	}
}

void OutputMap( void )
{
	unsigned char *cMap;
	unsigned short int nMap = nFrmlst - 100;
	unsigned short int nStart;
	short int nRow, nCol;
	unsigned char cData[ 5 ];
	unsigned char cLoc[ 11 ];
	unsigned short int nRoom;
	short int nFound = 0;
	RECT stMap;

	NewLine();

	if ( nVersion < 47 )
	{
		nStart = START_SCREEN_A;
	}
	else
	{
		nStart = START_SCREEN_B;
		nMap=20487;
	}

	cMap = cSrc + nStart;
	nRoom = *cMap;
	cMap = cSrc + nMap;
	stMap = GetMapEdges( cMap );
	WriteText( "MAP             WIDTH " );
	cMap = cSrc + nMap + nRoom;
	sprintf( cData, "%d", 1 + stMap.right - stMap.left );
	WriteText( cData );
	NewLine();
	WriteText( "                STARTSCREEN " );
	sprintf( cData, "%d", *cMap );
	WriteText( cData );
	NewLine();

	cMap = cSrc + nMap;

	for ( nRow = 0; nRow < stMap.top; nRow++ )
	{
		cMap += MAP_WID;
	}

	while ( nRow <= stMap.bottom )
	{
//		WriteText( "                255" );
		WriteText( "                " );
		cMap += stMap.left;

		for ( nCol = stMap.left; nCol <= stMap.right; nCol++ )
		{
			sprintf( cData, " %3d", *cMap++ );
			WriteText( cData );
		}

		cMap += MAP_WID - stMap.right - 1;
//		WriteText( " 255" );
		NewLine();
		nRow++;
	}

	WriteText( "ENDMAP" );
//	NewLine();
}

RECT GetMapEdges( unsigned char *cMap )
{
	RECT edge;
	short int nRow, nCol;

	edge.top = MAP_HGT;
	edge.bottom = 0;
	edge.left = MAP_WID;
	edge.right = 0;

	for ( nRow = 0; nRow < MAP_HGT; nRow++ )
	{
		for ( nCol = 0; nCol < MAP_WID; nCol++ )
		{
			if ( *cMap++ < 255 )
			{
				if ( nRow < edge.top )
				{
					edge.top = nRow;
				}
				if ( nRow > edge.bottom )
				{
					edge.bottom = nRow;
				}
				if ( nCol < edge.left )
				{
					edge.left = nCol;
				}
				if ( nCol > edge.right )
				{
					edge.right = nCol;
				}
			}
		}
	}

	return ( edge );
}

void OutputCode( void )
{
	short int nEvents = 20;
	short int nThisEvent = 0;
	unsigned char *cNme;
	unsigned char cByte;
	short int nIndents;
	unsigned char cData[ 5 ];
	unsigned char cDataX[ 100 ];

	NewLine();
	cNme = cSrc + nCode + 1;							/* first byte is always end marker. */

	while ( nEvents-- > 0 )
	{
		cNewLine = 1;
		nIndents = nTabs = 0;
		NewLine();
		NewLine();
		WriteText( "EVENT " );
		WriteText( cEvent[ nThisEvent ] );
		nThisEvent++;
		cByte = *cNme++;
		cByte = ConvertByte( cByte );
		nPrintMode = 0;

		while ( cByte < 255 )
		{
			if ( cNewLine > 0 && cByte != INS_NUMBER )
			{
				nIndents = nTabs;
				cNewLine = 0;
				NewLine();
				nLastOp = -1;

				while ( nIndents-- > 0 )
				{
					WriteText( "    " );
				}

				if ( nPrintMode > 0 )
				{
					nPrintMode = 0;
					WriteText( "PRINTMODE 0" );
					NewLine();
					for ( nIndents = 0; nIndents < nTabs; nIndents++ )
					{
						WriteText( "    " );
					}
				}
			}
			else
			{
				WriteText( " " );
			}

			if ( cByte == INS_NUMBER )
			{
				cByte = *cNme++;
				sprintf( cData, "%d", cByte );
				WriteText( cData );
			}
			else
			{
				CodeLine( cByte, *cNme );
			}

			if ( cByte == INS_TICKER )
			{
				cByte = *cNme++;
				if ( cByte == INS_NUMBER )
				{
					WriteText( " " );
					cByte = *cNme++;
					if ( cByte == 99 )					/* TICKER 99 x turned off the ticker. */
					{
						WriteText( "0" );				/* it's now TICKER 0. */
						cByte = *cNme++;				/* there might be a second parameter. */
						if ( cByte == INS_NUMBER )
						{
							cNme++;						/* skip it, it's no longer required. */
						}
						else
						{
							cNme--;
						}
					}
					else
					{
						sprintf( cData, "%d", cByte );
						WriteText( cData );
					}
				}
				else
				{
					cNme--;
				}
			}

			if ( cByte == INS_KEY )
			{
				cByte = *cNme++;
				if ( cByte == INS_NUMBER )
				{
					WriteText( " " );
					cByte = *cNme++;
					switch( cByte )
					{
						case 0:
							WriteText( "RIGHT" );
							break;
						case 1:
							WriteText( "LEFT" );
							break;
						case 2:
							WriteText( "DOWN" );
							break;
						case 3:
							WriteText( "UP" );
							break;
						case 4:
							WriteText( "FIRE" );
							break;
						case 5:
							WriteText( "FIRE2" );
							break;
						case 6:
							WriteText( "FIRE3" );
							break;
						default:
							sprintf( cDataX, "%d        ; warning - unrecognised key", cByte );
							WriteText( cDataX );
							break;
					}
				}
				else
				{
					cNme--;
				}
			}

			if ( cByte == INS_DIG )
			{
				cByte = *cNme++;
				if ( cByte == INS_NUMBER )
				{
					WriteText( " " );
					cByte = *cNme++;
					switch( cByte )
					{
						case 0:
							WriteText( "UP" );
							break;
						case 1:
							WriteText( "DOWN" );
							break;
						case 2:
							WriteText( "LEFT" );
							break;
						case 3:
							WriteText( "RIGHT" );
							break;
						default:
							sprintf( cDataX, "%d        ; warning - unrecognised direction", cByte );
							WriteText( cDataX );
							break;
					}
				}
				else
				{
					cNme--;
				}
			}

			if ( cByte == INS_STR )
			{
				cByte = *cNme++;
				if ( cByte == INS_NUMBER )
				{
					WriteText( " " );
					cByte = *cNme++;
					switch( cByte )
					{
						case 0:
							WriteText( "LEFT" );
							break;
						case 1:
							WriteText( "RIGHT" );
							break;
						case 2:
							WriteText( "UP" );
							break;
						case 3:
							WriteText( "DOWN" );
							break;
						default:
							sprintf( cDataX, "%d        ; warning - unrecognised direction", cByte );
							WriteText( cDataX );
							break;
					}
				}
				else
				{
					cNme--;
				}
			}
			cByte = *cNme++;
			cByte = ConvertByte( cByte );

			switch( cByte )
			{
				case INS_ELSE:
				case INS_ENDIF:
				case INS_ENDREPEAT:
					nTabs--;
					if ( nTabs < 0 )
					{
						nTabs = 0;
						NewLine();
						WriteText( "; warning - ENDIF without IF?" );
					}
					break;
			}

			if ( ( cByte < INS_ARGUMENTS ) ||
				 ( cByte >= INS_LET && cByte != INS_BY ) )
			{
				cNewLine++;
			}
		}
		NewLine();

		while ( nTabs > 0 )
		{
			nIndents = --nTabs;
			while ( nIndents-- > 0 )
			{
				WriteText( "    " );
			}
			WriteText( "ENDIF        ; warning - missing ENDIF?" );
			NewLine();
		}
	}

	/* write empty routines for new events not present in previous versions. */
	while ( nThisEvent < NUM_EVENTS )
	{
		NewLine();
		NewLine();
		WriteText( "EVENT " );
		WriteText( cEvent[ nThisEvent++ ] );
	}

	NewLine();
}

unsigned char ConvertByte( unsigned char cByte )
{
	/* There were no S and T variables vefore version 4.7 */
	if ( nVersion < 47 )
	{
		if ( cByte > INS_R && cByte != 255 )
		{
			cByte += 2;
		}
	}

	return ( cByte );
}

void CodeLine( char cInstruction, char cNext )
{
	short int nIndents;

	switch( cInstruction )
	{
		case INS_IF:
			nLastOp = cInstruction;
		case INS_ELSE:
		case INS_REPEAT:
			nTabs++;
			break;
		case INS_BIGMESSAGE:
		case INS_BIGSCORE:
			nPrintMode++;
			WriteText( "PRINTMODE 1" );
			NewLine();
			for ( nIndents = 0; nIndents < nTabs; nIndents++ )
			{
				WriteText( "    " );
			}
			break;
		case INS_TO:
			if ( nLastOp == INS_SUB && cInstruction == INS_TO )
			{
				cInstruction = INS_FROM;
			}
			break;
		case INS_LET:
		case INS_SUB:
			nLastOp = cInstruction;
			break;
	}

	WriteText( cKeyword[ cInstruction ] );

	switch( cInstruction )
	{
		case INS_PUT:									/* put now takes two arguments for x and y. */
			WriteText( " X Y" );
			break;
	}
}

void WriteText( unsigned char *cChar )
{
	char cByte;

	while ( *cChar )
	{
		cByte = *cChar++;
		fwrite( &cByte, 1, 1, fpObject );			/* write output to file. */
	}
}

void WriteComment( unsigned char *cChar )
{
	char cByte;

	if (nAddComment > 0)
	{
		while ( *cChar )
		{
			cByte = *cChar++;
			fwrite( &cByte, 1, 1, fpObject );			/* write output to file. */
		}
	}
}

void NewLine( void )
{
	unsigned char cLine[ 2 ] = { CR, LF };

	fwrite( &cLine[ 0 ], 1, 2, fpObject );			/* write output to file. */
}
