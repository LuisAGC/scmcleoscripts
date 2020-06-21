#include "opcodes.h"
#include "commonhandlers.h"
#include "SRaceCheckpoint.h"
#include "theme_robin.h"
#include <math.h>

BOOL InitOpcodes()
{
	return
#if SNOOP
			CLEO_RegisterOpcode(0x6C36, &op6C36) &&
#endif
			CLEO_RegisterOpcode(0x6C37, &op6C37) &&
			setupTextdraws();
}

#if DOTRACE
void trace(const char *f)
{
	static HANDLE hDbgFile = NULL;
	if (hDbgFile == NULL) {
		hDbgFile = CreateFileA("tddbg.txt", FILE_GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
		SetFilePointer(hDbgFile, 0, NULL, FILE_END);
	}
	DWORD gDbgW;
	WriteFile(hDbgFile, f, strlen(f), &gDbgW, NULL);
}
#endif

struct SPLHXTEXTDRAW pltextdraws[PLTDCOUNT];
struct SGAMEDATA gamedata;
struct stTextdrawPool *tdpool;

int isTextdrawValid(SPLHXTEXTDRAW *hxtd)
{
	if (hxtd->iHandle == INVALID_TEXTDRAW || !tdpool->iIsListed[hxtd->iHandle]) {
		return 0;
	}
	if (tdpool->textdraw[hxtd->iHandle]->fX == hxtd->fTargetX &&
			tdpool->textdraw[hxtd->iHandle]->fY == hxtd->fTargetY) {
		return 1;
	}
	if (tdpool->textdraw[hxtd->iHandle]->fX == hxtd->fX &&
			tdpool->textdraw[hxtd->iHandle]->fY == hxtd->fY) {
		hxtd->handler(hxtd, tdpool->textdraw[hxtd->iHandle], TDHANDLER_ATTACH);
		return 1;
	}
	return 0;
}

int isPTextdrawValid(SPLHXTEXTDRAW *hxtd)
{
	if (hxtd->iHandle == INVALID_TEXTDRAW || !tdpool->iPlayerTextDraw[hxtd->iHandle]) {
		return 0;
	}
	if (tdpool->playerTextdraw[hxtd->iHandle]->fX == hxtd->fTargetX &&
			tdpool->playerTextdraw[hxtd->iHandle]->fY == hxtd->fTargetY) {
		return 1;
	}
	if (tdpool->playerTextdraw[hxtd->iHandle]->fX == hxtd->fX &&
			tdpool->playerTextdraw[hxtd->iHandle]->fY == hxtd->fY) {
		hxtd->handler(hxtd, tdpool->playerTextdraw[hxtd->iHandle], TDHANDLER_ATTACH);
		return 1;
	}
	return 0;
}

void setupTD(int tdidx, unsigned int x, unsigned int y, unsigned int targetX, unsigned int targetY, TDHANDLER handler)
{
	pltextdraws[tdidx].iHandle = INVALID_TEXTDRAW;
	pltextdraws[tdidx].handler = handler;
	memcpy(&(pltextdraws[tdidx].fX), &x, 4);
	memcpy(&(pltextdraws[tdidx].fY), &y, 4);
	memcpy(&(pltextdraws[tdidx].fTargetX), &targetX, 4);
	memcpy(&(pltextdraws[tdidx].fTargetY), &targetY, 4);
	if (targetX == 0) {
		pltextdraws[tdidx].fTargetX = 2000.0f;
	}
	if (targetY == 0) {
		pltextdraws[tdidx].fTargetY = 2000.0f + 1.0f * (float) tdidx;
	}
}

DWORD hookedcall = NULL;
DWORD *samp_21A0B4 = NULL;
DWORD samp_21A0B4_val;

void __cdecl update_textdraws()
{
	samp_21A0B4_val = *samp_21A0B4;

	TRACE("updating toupdate\n");
	int tdstoupdate[PLTDCOUNT];
	int tdstoupdatecount = 0;
	for (int i = 0; i < PLTDCOUNT; i++) {
		if (pltextdraws[i].handler == NULL) {
			continue;
		}
		int valid;
		if (isplayertd(i)) {
			valid = isPTextdrawValid(&pltextdraws[i]);
		} else {
			valid = isTextdrawValid(&pltextdraws[i]);
		}
		if (!valid) {
			tdstoupdate[tdstoupdatecount++] = i;
			pltextdraws[i].iHandle = INVALID_TEXTDRAW;
		}
	}

	TRACE("updating handles\n");
	for (int i = 0; i < tdstoupdatecount; i++) {
		SPLHXTEXTDRAW *hxtd = &pltextdraws[tdstoupdate[i]];
		if (isplayertd(tdstoupdate[i])) {
			for (int j = 0; j < SAMP_MAX_PLAYERTEXTDRAWS; j++) {
				if (tdpool->iPlayerTextDraw[j] &&
						tdpool->playerTextdraw[j]->fX == hxtd->fX &&
						tdpool->playerTextdraw[j]->fY == hxtd->fY) {
					TRACE1("assigned a handle to a textdraw %d\n", tdstoupdate[i]);
					hxtd->iHandle = j;
					hxtd->handler(hxtd, tdpool->playerTextdraw[hxtd->iHandle], TDHANDLER_ATTACH);
					break;
				}
			}
			continue;
		}
		for (int j = 0; j < SAMP_MAX_TEXTDRAWS; j++) {
			if (tdpool->iIsListed[j] &&
					tdpool->textdraw[j]->fX == hxtd->fX &&
					tdpool->textdraw[j]->fY == hxtd->fY) {
				TRACE1("assigned a handle to a textdraw %d\n", tdstoupdate[i]);
				hxtd->iHandle = j;
				hxtd->handler(hxtd, tdpool->textdraw[hxtd->iHandle], TDHANDLER_ATTACH);
				break;
			}
		}
	}

	gamedata.carspeed = sqrt(gamedata.carspeedx * gamedata.carspeedx + gamedata.carspeedy * gamedata.carspeedy + gamedata.carspeedz * gamedata.carspeedz);
	if (gamedata.carhp == 999) gamedata.carhp = 1000; // adjust anticheat hp
	int destinationtdhandle = pltextdraws[PLTD_DESTNEAREST].iHandle;
	struct SRaceCheckpoint *racecheckpoint = (SRaceCheckpoint*)(SA_RACECHECKPOINTS);
	gamedata.missiondistance = -1;
	if (destinationtdhandle != INVALID_TEXTDRAW && tdpool->textdraw[destinationtdhandle]->szString[0] == 'D') {
		for (int i = 0; i < MAX_RACECHECKPOINTS; i++) {
			if (racecheckpoint[i].byteUsed) {
				float dx = gamedata.carx - racecheckpoint[i].fX;
				float dy = gamedata.cary - racecheckpoint[i].fY;
				float dz = gamedata.carz - racecheckpoint[i].fZ;
				gamedata.missiondistance = (int) sqrt(dx * dx + dy * dy + dz * dz);
				break;
			}
		}
	}

	TRACE("invoking handles\n");
	for (int i = 0; i < PLTDCOUNT; i++) {
		SPLHXTEXTDRAW *hxtd = &pltextdraws[i];
		if (hxtd->iHandle != INVALID_TEXTDRAW && hxtd->handler != NULL) {
			TRACE1("textdraw with a handle %d\n", i);
			struct stTextdraw *samptd = tdpool->textdraw[hxtd->iHandle];
			if (isplayertd(i)) {
				samptd = tdpool->playerTextdraw[hxtd->iHandle];
			}
			hxtd->handler(hxtd, samptd, TDHANDLER_UPDATE);
		}
	}
}

void __declspec(naked) hookstuff()
{
	_asm {
		push ebx
		push ecx
		push edx
		push esi
		push edi
		push ebp
	}

	update_textdraws();

	_asm {
		pop ebp
		pop edi
		pop esi
		pop edx
		pop ecx
		pop ebx
		mov eax, samp_21A0B4_val
		ret
	}
}

OpcodeResult WINAPI op6C37(CScriptThread *thread)
{
	static struct stSAMP *g_SAMP = NULL;

	gamedata.carhp = CLEO_GetIntOpcodeParam(thread);
	gamedata.carheading = CLEO_GetIntOpcodeParam(thread);
	gamedata.carspeedx = CLEO_GetFloatOpcodeParam(thread);
	gamedata.carspeedy = CLEO_GetFloatOpcodeParam(thread);
	gamedata.carspeedz = CLEO_GetFloatOpcodeParam(thread);
	gamedata.carx = CLEO_GetFloatOpcodeParam(thread);
	gamedata.cary = CLEO_GetFloatOpcodeParam(thread);
	gamedata.carz = CLEO_GetFloatOpcodeParam(thread);
	gamedata.isplane = CLEO_GetIntOpcodeParam(thread);
	gamedata.blinkstatus = CLEO_GetIntOpcodeParam(thread);

	if (g_SAMP == NULL) {
		g_SAMP = getSamp();
		if (g_SAMP == NULL) {
			goto exitzero;
		}
		if (g_SAMP->pPools == NULL || g_SAMP->pPools->pTextdraw == NULL ||
				g_SAMP->ulPort != 7777 || strcmp("51.178.2.56", g_SAMP->szIP) != 0) {
			goto exitzero;
		}
		tdpool = g_SAMP->pPools->pTextdraw;

		HMODULE samp_dll = GetModuleHandle("samp.dll");
		/* 0.3.7-R1
		DWORD mem = (DWORD)samp_dll + 0x1AD40;
		DWORD *sub = (DWORD*)(mem);
		hookedcall = *sub;
		hookedcall += mem + 5;
		samp_21A0B4 = (DWORD*)((DWORD)samp_dll + 0x21A0B4);*/

		/* 0.3.7-R4*/
		DWORD mem = (DWORD)samp_dll + 0x1E7E0;
		DWORD *sub = (DWORD*)(mem);
		hookedcall = *sub;
		hookedcall += mem + 5;
		samp_21A0B4 = (DWORD*)((DWORD)samp_dll + 0x26E9C4);

		CLEO_SetIntOpcodeParam(thread, mem);
		CLEO_SetIntOpcodeParam(thread, ((DWORD) &hookstuff) - mem + 1 - 4 - 2);
		CLEO_SetIntOpcodeParam(thread, ROBINHOOKADDR);
		return OR_CONTINUE;
	}

exitzero:
	CLEO_SetIntOpcodeParam(thread, 0);
	CLEO_SetIntOpcodeParam(thread, 0);
	CLEO_SetIntOpcodeParam(thread, 0);
	return OR_CONTINUE;
}
