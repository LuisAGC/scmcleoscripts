
#include "opcodes.h"

void headinghandler(struct SPLHXTEXTDRAW *hxtd, struct stTextdraw *samptd, int reason)
{
	TRACE("headinghandler\n");
	REPOSITION_ON_ATTACH();
	if (!INCAR) {
		return;
	}
#define HEADINGSTRLEN (3 + 1 + 3 + 1 + 3 + 1 + 5 + 1 + 3 + 1 + 3 + 1 + 3 + 1)
	char headingstring[HEADINGSTRLEN];
	int n[7];
	for (int i = 0; i < 7; i++) {
		n[i] = (360 - gamedata.carheading) - 3 + i;
		if (n[i] < 1) n[i] += 360;
		if (n[i] > 360) n[i] -= 360;
	}
	sprintf(headingstring, "%03d %03d %03d [%03d] %03d %03d %03d", n[0], n[1], n[2], n[3], n[4], n[5], n[6]);
	memcpy(samptd->szText, headingstring, HEADINGSTRLEN);
	memcpy(samptd->szString, headingstring, HEADINGSTRLEN);
#undef HEADINGSTRLEN
}

void removehandler(struct SPLHXTEXTDRAW *hxtd, struct stTextdraw *samptd, int reason)
{
	TRACE("removehandler\n");
	REPOSITION_ON_ATTACH();
}

void boxremovehandler(struct SPLHXTEXTDRAW *hxtd, struct stTextdraw *samptd, int reason)
{
	TRACE("boxremovehandler\n");
	if (reason == TDHANDLER_ATTACH) {
		samptd->byteBox = 0;
		samptd->fX = hxtd->fTargetX;
		samptd->fY = hxtd->fTargetY;
		return;
	}
}

void carspeedtdhandler(struct SPLHXTEXTDRAW *hxtd, struct stTextdraw *samptd, int reason)
{
	TRACE("carspeedtdhandler\n");
	REPOSITION_ON_ATTACH();
	if (!INCAR) {
		return;
	}
	char carspeedstring[10];
	sprintf(carspeedstring, "%d KPH", GROUNDSPEED(gamedata.carspeed));
	memcpy(&samptd->szText[13], carspeedstring, 10);
	memcpy(&samptd->szString[13], carspeedstring, 10);
}

