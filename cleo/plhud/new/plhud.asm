;; _ASM_HOOKADDR: 0058EAF1
; _ASM_HOOKADDR: 0058FBC5
; _ASM_JUMP: true
; _ASM_CORRECT_OFFSETS: true
; _ASM_COMMENTS: false
; _ASM_GCC: S:\broftware\perl\c\bin\gcc.exe
; _ASM_OBJDUMP: S:\broftware\perl\c\bin\objdump.exe
; _ASM_TARGETFILE: plhud-asm.txt
; _ASM_PREPROCONLY: false
; _ASM_LF: true

; hook on 0058EAF0 _DrawHud (0058EAF1 in asmtool)

; _DEFINE:NULL=0
; _DEFINE:__drawText=0x71A700
; _DEFINE:CText__SetBorderEffectRGBA=0x719510
; _DEFINE:CText__SetFont=0x719490
; _DEFINE:CText__SetTextAlignment=0x719610
; _DEFINE:CText__SetTextBackground=0x7195C0
; _DEFINE:CText__SetTextColour=0x719430
; _DEFINE:CText__SetTextLetterSize=0x719380
; _DEFINE:CText__SetTextOutline=0x719590
; _DEFINE:CText__SetTextUseProportionalValues=0x7195B0
; _DEFINE:dummy_7194F0=0x7194F0
; _DEFINE:CText__SetWrappingCoordinateForLeftAlignedText=0x7194D0
; _DEFINE:getPlayerCoords=0x56E010

; _DEFINE:_menutxt=_var01
; _DEFINE:_options=_var02
; _DEFINE:_menuidx=_var03
; _DEFINE:_viewdis=_var04
; _DEFINE:_sprintf=_var05
; _DEFINE:_runways=_var06
; _DEFINE:_espcolr=_var07
; _DEFINE:_lastrdr=_var08

; _DEFINE:MAXMENUIDX=3
; _DEFINE:MENUITEMS=MAXMENUIDX+1

; _DEFINE:FONT_SIZE_X=0x3f000000 ; 0.5
; _DEFINE:FONT_SIZE_Y=0x3e8ccccd ; 0.275
; _DEFINE:MENU_POS_X=0x3e800000 ; 0.25
; _DEFINE:MENU_POS_Y=0x3ee66666 ; 0.45

; !!MENUOFFSET
; _DEFINE:MENU_OFFSET_SMARTMODE_ONOFF=0xAA ; N char
; _DEFINE:MENU_OFFSET_VIEWDISTANCE=0xC3 ; _ char
; _DEFINE:MENU_OFFSET_FIRST_OPTION=0x7E ; > char
; _DEFINE:MENU_OFFSET_OPTION_LINE_LENGTH=0x1A
; _DEFINE:MENU_OFFSET_COLOR=0xD5 ; P char
; _DEFINE:MENU_OFFSET_RUNWAYCOUNT=0xED ; _ char
; _DEFINE:MENU_OFFSET_BRANDING=0xFB ; _ char

; _DEFINE:OPTION_BIT_ENABLED=0x00000001
; _DEFINE:OPTION_BIT_SMART_MODE=0x00000002
; _DEFINE:OPTION_BIT_KEY_F10=0x00000004
; _DEFINE:OPTION_BIT_KEY_RARR=0x00000008
; _DEFINE:OPTION_BIT_KEY_DARR=0x00000010
; _DEFINE:OPTION_BIT_KEY_UARR=0x00000020
; _DEFINE:OPTION_BIT_KEY_LARR=0x00000040
; _DEFINE:OPTION_BIT_ALL_KEYS=0x0000007C
; _DEFINE:OPTION_BIT_ALL_KEYS_NOT=0xFFFFFF83
; _DEFINE:OPTION_BIT_ARR_KEYS=0x00000078
; _DEFINE:OPTION_BIT_ARR_KEYS_NOT=0xFFFFFF87
; _DEFINE:OPTION_BIT_ARR_KEYS_UPDOWN=0x00000030
; _DEFINE:OPTION_BIT_SHOW_MENU=0x00000080
; _DEFINE:OPTION_BIT_SHOW_MENU_NOT=0xFFFFFF7F
; _DEFINE:OPTION_BIT_RUNONCE=0x00000100
; _DEFINE:OPTION_BIT_RUNONCE_NOT=0xFFFFFEFF
; _DEFINE:OPTION_BIT_RESULT_[REDACTED]=0x00000200

; _DEFINE:_airstrip_location=0xBA8300

entry:
	test dword ptr [_options], OPTION_BIT_KEY_F10
	jz no_enable_keypress
	xor dword ptr [_options], OPTION_BIT_ENABLED
	and dword ptr [_options], OPTION_BIT_ALL_KEYS_NOT
	or dword ptr [_options], OPTION_BIT_SHOW_MENU
	mov dword ptr [_lastrdr], 0
	mov dword ptr [_airstrip_location], 3
	call fixairstrip
no_enable_keypress:
	test dword ptr [_options], OPTION_BIT_ENABLED
	jz _exit
	test dword ptr [_options], OPTION_BIT_RESULT_[REDACTED]
	jnz _exit

main:
	push edi
	push ebx
	push edx
	push ecx
	; don't push eax, is overwritten anyways
	; run once
	test dword ptr [_options], OPTION_BIT_RUNONCE
	jz skiprunonce
	and dword ptr [_options], OPTION_BIT_RUNONCE_NOT
	call runonce
skiprunonce:
	; handle menu keys if menu is shown
	test dword ptr [_options], OPTION_BIT_SHOW_MENU
	jnz menunav
menunav_ret:
	call breakairstrip
	; set textdraw stuff for runways
	push 0 ; a2
	push 0 ; a1
	call CText__SetTextBackground
	;add esp, 0x8
	;;push 0
	call dummy_7194F0
	;;add esp, 0x4
	;;push 0 ; 0 center 1 left 2 right
	call CText__SetTextAlignment
	;;add esp, 0x4
	push FONT_SIZE_X ; y
	push FONT_SIZE_Y ; x
	call hud2screen
	call CText__SetTextLetterSize ; flip x/y when alignment is center
	;add esp, 0x8
	push 1
	call CText__SetTextUseProportionalValues
	;add esp, 0x4
	;;push 1
	call CText__SetFont
	;;add esp, 0x4
	;;push 1
	call CText__SetTextOutline
	;;add esp, 0x4
	push 0xFF000000 ; ARGB
	call CText__SetBorderEffectRGBA
	;add esp, 0x4
	push [_espcolr] ; ARGB
	call argb2abgr ; AGBR
	or byte ptr [esp+0x3], 0xFF
	call CText__SetTextColour
	;add esp, 0x4
	add esp, 0x1C
	; smart mode
	; >>>>>>> get checkpoint
	test dword ptr [_options], OPTION_BIT_SMART_MODE
	jz dont_get_checkpoint
	mov ebx, 0xC7F158
smart_next_checkpoint:
	cmp byte ptr [ebx+0x2], 1
	je smart_got_checkpoint
	add ebx, 0x38
	cmp ebx, 0xC7F858
	jae exit ; fix radar first?
	jmp smart_next_checkpoint
smart_got_checkpoint:
	push [ebx+0x10] ; checkpoint x
	push [ebx+0x14] ; checkpoint y
	; <<<<<<< get checkpoint
dont_get_checkpoint:
	push 0 ; viewdistance^2 (int)
	fild dword ptr [_viewdis]
	fmul ST(0), ST(0)
	fistp dword ptr [esp]
	push 0x5F5E1000 ; closest distance (for radar) 1.6B (int)
	push 0xFFFFFFFF ; ptr to closest runway (for radar)
	sub esp, 0xC ; player coords
	mov eax, esp
	push 0
	push eax
	call getPlayerCoords
	add esp, 0x8
	;
	mov ebx, _runways
runwayloop:
	; end check
	mov eax, dword ptr [ebx]
	test eax, eax
	jz runwayloop@end
	; calculate distance (into eax), check later
	push 0x40000000 ; 2.0
	fld dword ptr [ebx] ; rnwy x 1
	fadd dword ptr [ebx+0xC] ; rnwy x 2
	fld dword ptr [esp]
	fdivp
	fld ST(0) ; save for later
	fsub dword ptr [esp+0x4] ; player x
	fmul ST(0), ST(0)
	fld dword ptr [ebx+0x4] ; rnwy y 2
	fadd dword ptr [ebx+0x10] ; rnwy y 2
	fld dword ptr [esp]
	fdivp
	fld ST(0) ; save for later
	fsub dword ptr [esp+0x8] ; player y
	fmul ST(0), ST(0)
	fxch ST(1)
	fxch ST(2)
	faddp
	fistp dword ptr [esp]
	pop eax
	; smart mode check
	test dword ptr [_options], OPTION_BIT_SMART_MODE
	jz runwayloop@nosmart
	; checkpoint to middle < length * 1.4
	fld dword ptr [ebx+0xC] ; rnwy x 2
	fsub dword ptr [ebx] ; rnwy x 1
	fmul ST(0)
	fld dword ptr [ebx+0x10] ; rnwy y 2
	fsub dword ptr [ebx+0x4] ; rnwy y 1
	fmul ST(0)
	faddp
	push 0x3fb33333 ; 1.4
	fmul dword ptr [esp]
	add esp, 0x4
	fld ST(2) ; mx
	fsub dword ptr [esp+0x1C] ; chkpnt x
	fmul ST(0)
	fld ST(2) ; my
	fsub dword ptr [esp+0x18] ; chkpnt y
	fmul ST(0)
	faddp
	fcomip ST, ST(1)
	fstp ST(0) ; dist b
	ja runwayloop@clean@next
runwayloop@nosmart:
	; radar
	cmp dword ptr [esp+0x10], eax
	jl runwayloop@skipradar
	mov dword ptr [esp+0xC], ebx
	mov dword ptr [esp+0x10], eax
runwayloop@skipradar:
	; real distance check
	cmp eax, dword ptr [esp+0x14]
	jg runwayloop@clean@next
	; esp
	call dorunway
runwayloop@clean@next:
	fstp ST(0) ; my
	fstp ST(0) ; mx
runwayloop@next:
	movzx eax, byte ptr [ebx+0x18]
	add ebx, eax
	add ebx, 0x19
	jmp runwayloop
runwayloop@end:
	; radar
	mov ebx, dword ptr [esp+0xC]
	cmp ebx, 0xFFFFFFFF
	je runwayloop@noradar
	fld dword ptr [ebx+0x4] ; y1
	fadd dword ptr [ebx+0x10] ; y2
	fld dword ptr [ebx] ; x1
	fadd dword ptr [ebx+0xC] ; x2
	fld1
	fadd ST(0), ST(0)
	fdiv ST(2), ST(0)
	fdivp
	fstp dword ptr [0x8D06E0] ; mx
	fstp dword ptr [0x8D06E0+0x4] ; my
	push eax
	sub esp, 0x8
	fld dword ptr [ebx+0xC] ; x2
	fsub dword ptr [ebx] ; x1
	fst dword ptr [esp+0x4] ; dx
	fld dword ptr [ebx+0x10] ; y2
	fsub dword ptr [ebx+0x4] ; y1
	fst dword ptr [esp] ; dy
	; _DEFINE:CGeneral__getATanOfXY=0x53CC70
	;             ^ modifies eax
	call CGeneral__getATanOfXY
	mov dword ptr [esp], 0x43340000 ; 180.0
	fmul dword ptr [esp]
	fldpi
	fdivp
	mov dword ptr [esp], 0x42b40000 ; 90.0
	fadd dword ptr [esp]
	fstp dword ptr [0x8D06E0+0x8] ; ang
	fmul ST(0), ST(0)
	fxch
	fmul ST(0), ST(0)
	faddp
	fsqrt
	mov dword ptr [esp], 0x43960000 ; 300.0
	fadd dword ptr [esp]
	fstp dword ptr [0x8D06E0+0xC] ; radius
	add esp, 0x8
	pop eax
	; force radar update if needed
	cmp dword ptr [_lastrdr], ebx
	je runwayloop@noradar
	mov dword ptr [_airstrip_location], 1
	mov dword ptr [_lastrdr], ebx
runwayloop@noradar:
	; cleanup & exit
	add esp, 0x18 ; 0xC player coords + 0xC viewdist + radar stuff
	test dword ptr [_options], OPTION_BIT_SMART_MODE
	jz exit
	add esp, 0x8
exit:
	; show menu if needed
	test dword ptr [_options], OPTION_BIT_SHOW_MENU
	jnz menushow
menushow_ret:
	pop ecx
	pop edx
	pop ebx
	pop edi

_exit:
	;sub esp, 0x1A0
	;jmp 0x58EAF6
	; _DEFINE:_menu.EnableHudInOptions=0xBA6769
	mov al, _menu.EnableHudInOptions
	jmp 0x58FBC9

; modifies eax, edx
menunav:
	test dword ptr [_options], OPTION_BIT_ARR_KEYS
	jz menunav_ret
	test dword ptr [_options], OPTION_BIT_ARR_KEYS_UPDOWN
	jz menu_rl_nav
	; >>> updown nav
	mov dl, 0x5F ; "_"
	call menu_write_mark
	test dword ptr [_options], OPTION_BIT_KEY_UARR
	jz menu_keys_down
	sub byte ptr [_menuidx], 1
	mov al, MAXMENUIDX
	jmp menu_idx_boundscheck
menu_keys_down:
	add byte ptr [_menuidx], 1
	mov al, 0
menu_idx_boundscheck:
	cmp byte ptr [_menuidx], MENUITEMS
	jb menu_update_idx
	mov byte ptr [_menuidx], al
menu_update_idx:
	mov dl, 0x3E ; ">"
	call menu_write_mark
	; <<< updown nav
menu_show_clearkeys:
	and dword ptr [_options], OPTION_BIT_ARR_KEYS_NOT
	jmp menunav_ret
menu_rl_nav:
	mov eax, [_menuidx]
	imul eax, 4
	add eax, __BASEADDR
	mov eax, [eax+menujmptable]
	add eax, __BASEADDR
	jmp eax
menu_rl_continue:
	xor dword ptr [_options], OPTION_BIT_SHOW_MENU
	and dword ptr [_options], OPTION_BIT_ARR_KEYS_NOT
	jmp menunav_ret
menu_rl_smartmode:
	xor dword ptr [_options], OPTION_BIT_SMART_MODE
	mov eax, _menutxt
	add eax, MENU_OFFSET_SMARTMODE_ONOFF
	lea edx, [eax-0x3]
	test dword ptr [_options], OPTION_BIT_SMART_MODE
	jz menu_rl_smartmode@off
	mov word ptr [eax], 0x5F4E ; "_N"
	mov byte ptr [edx], 0x67 ; "g"
	jmp menu_show_clearkeys
menu_rl_smartmode@off:
	mov word ptr [eax], 0x4646 ; "FF"
	mov byte ptr [edx], 0x72 ; "r"
	jmp menu_show_clearkeys
menu_rl_viewdistance:
	; _DEFINE:VIEWDISTANCEDELTA=0x01F4FE0C ; 500/-500
	; _DEFINE:VIEWDISTANCEMAX=0x7530 ; 30000
	; _DEFINE:VIEWDISTANCEDEFAULT=0x5DC ; 1500
	mov eax, VIEWDISTANCEDELTA
	test dword ptr [_options], OPTION_BIT_KEY_RARR
	jz menu_rl_viewdistance@decrease
	shr eax, 16
menu_rl_viewdistance@decrease:
	add word ptr [_viewdis], ax
	cmp word ptr [_viewdis], VIEWDISTANCEMAX
	jb menu_rl_viewdistance@updatetxt
	mov word ptr [_viewdis], VIEWDISTANCEDEFAULT
menu_rl_viewdistance@updatetxt:
	sub esp, 0x8
	mov eax, esp
	push 0x643525 ; %5d\0
	mov edx, esp
	push [_viewdis] ; ...
	push edx ; pFormat
	push eax ; pResult
	call [_sprintf] ; _sprintf
	add esp, 0x10
	mov edx, _menutxt
	pop dword ptr [edx+MENU_OFFSET_VIEWDISTANCE]
	pop eax
	mov byte ptr [edx+MENU_OFFSET_VIEWDISTANCE+0x4], al
	jmp menu_show_clearkeys
menu_rl_color:
	mov eax, 0x8
	test dword ptr [_options], OPTION_BIT_KEY_LARR
	jz menu_rl_color@next
	neg eax
menu_rl_color@next:
	push ecx
	mov edx, __BASEADDR
	sub edx, 0x8
menu_rl_color@loop:
	add edx, 0x8
	mov ecx, dword ptr [edx+espcolors]
	cmp ecx, dword ptr [_espcolr]
	jne menu_rl_color@loop
	add edx, eax
	mov ecx, dword ptr [edx+espcolors]
	mov dword ptr [_espcolr], ecx
	mov ecx, dword ptr [edx+espcolors+0x4]
	mov edx, _menutxt
	mov dword ptr [edx+MENU_OFFSET_COLOR], ecx
	pop ecx
	jmp menu_show_clearkeys

menushow:
	; >>>>>>> menu text
	push 0 ; a2
	push 0 ; a1
	call CText__SetTextBackground
	;add esp, 0x8
	;;push 0
	call dummy_7194F0
	;;add esp, 0x4
	push FONT_SIZE_X ; y
	push FONT_SIZE_Y ; x
	call hud2screen
	call CText__SetTextLetterSize ; flip x/y when alignment is center
	;add esp, 0x8
	push 1
	call CText__SetTextUseProportionalValues
	;add esp, 0x4
	;;push 1
	call CText__SetFont
	;;add esp, 0x4
	;;push 1 ; 0 center 1 left 2 right
	call CText__SetTextAlignment
	;;add esp, 0x4
	;;push 1
	call CText__SetTextOutline
	;;add esp, 0x4
	push 0xFF000000 ; ABGR
	call CText__SetBorderEffectRGBA
	;add esp, 0x4
	push 0xFFFFFFFF; ABGR
	call CText__SetTextColour
	;add esp, 0x4
	push 0x461c4000 ; 10000.0
	call CText__SetWrappingCoordinateForLeftAlignedText
	;add esp, 0x4
	push _menutxt ; str
	push MENU_POS_Y ; y
	push MENU_POS_X ; x
	call norm2screen
	call __drawText
	;add esp, 0xC
	add esp, 0x2C
	; <<<<<<< menu text
	jmp menushow_ret

;menu_write_mark
menu_write_mark:
	mov eax, [_menuidx]
	imul eax, MENU_OFFSET_OPTION_LINE_LENGTH
	add eax, _menutxt
	mov byte ptr [eax+MENU_OFFSET_FIRST_OPTION], dl
	ret

; ebx: ptr to runway
; eax: distance^2 (int)
; nothing interesting in stack
; rnwy middle y, x in fpu stack
dorunway:
	; reserve a buffer for the airport name + distance
	; _DEFINE:ESP_EXTRA_BUFFER_LENGTH=0xE ; ~n~2400000000m\0
	push edx
	mov dl, [ebx+0x18]
	movzx edx, dl
	add edx, ESP_EXTRA_BUFFER_LENGTH
	sub esp, edx
	; project middle first and see if it's on screen
	sub esp, 0xC
	fstp dword ptr [esp+0x4] ; my
	fstp dword ptr [esp] ; mx
	fld dword ptr [ebx+0x8] ; rnwy z1
	fadd dword ptr [ebx+0x14] ; rnwy z2
	push 0x40000000 ; 2.0
	fdiv dword ptr [esp]
	add esp, 0x4
	fstp dword ptr [esp+0x8] ; mz
	;project
	call world2screen
	cmp dword ptr [esp+0x8], 0 ; mz'
	jl dorunway@notonscreen
	; prepare the name and text in stack (used just before ret)
	push 0
	push 0x6D69257E ; mi%~
	push 0x6E7E7325 ; n~s%
	push eax
	fild dword ptr [esp]
	fsqrt
	fistp dword ptr [esp] ; ... (dist)
	lea eax, [ebx+0x19]
	push eax ; ... (name)
	lea eax, [esp+0x8]
	push eax ; pFormat
	lea eax, [esp+0x24]
	mov dword ptr [esp+0x20], eax ; str (for __drawText; see below)
	push eax ; pResult
	call [_sprintf] ; _sprintf
	add esp, 0x1C
	; param y already in place by world2screen
	; param x already in place by world2screen
	;
	; draw stuff
	; get 4 points
	; _DEFINE:CGeneral__getATanOfXY=0x53CC70
	;             ^ modifies eax
	sub esp, 0x8
	fld dword ptr [ebx+0xC] ; rnwy x2
	fsub dword ptr [ebx] ; rnwy x1
	fstp dword ptr [esp+0x4] ; dx
	fld dword ptr [ebx+0x10] ; rnwy y2
	fsub dword ptr [ebx+0x4] ; rnwy y1
	fstp dword ptr [esp] ; dy
	call CGeneral__getATanOfXY
	fld ST(0)
	fldpi
	fld1
	fadd ST(0)
	fdivp
	fsub ST(2), ST(0)
	faddp
	; ST(1) angle-90deg
	; ST(0) angle+90deg
	fsincos
	fxch ST(2)
	fsincos
	; ST(3) cos(angle+90deg)
	; ST(2) sin(angle+90deg)
	; ST(1) sin(angle-90deg)
	; ST(0) cos(angle-90deg)
	mov dword ptr [esp], 0x41980000 ; 19.0
	fld dword ptr[esp]
	add esp, 0x8
	fmul ST(4), ST(0)
	fmul ST(3), ST(0)
	fmul ST(2), ST(0)
	fmulp
	;
	;     3
	;      / 4
	;     /
	;    /
	; 1 /
	;    2
	;
	; tri strip
	;
	; 3|\\``|4
	;  | \\ |
	; 1|..\\|2
	;
	; _DEFINE:_ZBufferNear=0x00000000
	; _DEFINE:_FogPlane=0x40555556 ; 3.333333492
	push edx
	xor edx, edx
	; p1
	inc edx
	push 0 ; v
	push 0x3F800000 ; u 1.0
	push [_espcolr] ; argb
	push _FogPlane ; rwh
	push dword ptr [ebx+0x8] ; z1 z1
	sub esp, 0x8
	fld dword ptr [ebx+0x4] ; y1
	fsub ST(0), ST(4) ; y1 - cos(angle+90deg)
	fstp dword ptr [esp+0x4] ; y1 y1
	fld dword ptr [ebx] ; x1
	fsub ST(0), ST(3) ; x1 - sin(angle+90deg)
	fstp dword ptr [esp] ; x1 x1
	call world2screen
	cmp dword ptr [esp+0x8], 1
	mov dword ptr [esp+0x8], _ZBufferNear
	jl dorunway@skipesp
	; p2
	inc edx
	push 0 ; v
	push 0x3F800000 ; u 1.0
	push [_espcolr] ; argb
	push _FogPlane ; rwh
	push dword ptr [ebx+0x8] ; z1 z2
	sub esp, 0x8
	fld dword ptr [ebx+0x4] ; y1
	fsub ST(0), ST(1) ; y1 - cos(angle-90deg)
	fstp dword ptr [esp+0x4] ; y1 y2
	fld dword ptr [ebx] ; x1
	fsub ST(0), ST(2) ; x1 - sin(angle-90deg)
	fstp dword ptr [esp] ; x1 x2
	call world2screen
	cmp dword ptr [esp+0x8], 1
	mov dword ptr [esp+0x8], _ZBufferNear
	jl dorunway@skipesp
	; p3
	inc edx
	push 0 ; v
	push 0x3F800000 ; u 1.0
	push [_espcolr] ; argb
	push _FogPlane ; rwh
	push dword ptr [ebx+0x14] ; z2 z3
	sub esp, 0x8
	fld dword ptr [ebx+0x10] ; y2
	fsub ST(0), ST(4)
	fstp dword ptr [esp+0x4] ; y2 y3
	fld dword ptr [ebx+0xC] ; x2
	fsub ST(0), ST(3)
	fstp dword ptr [esp] ; x2 x3
	call world2screen
	cmp dword ptr [esp+0x8], 1
	mov dword ptr [esp+0x8], _ZBufferNear
	jl dorunway@skipesp
	; p4
	inc edx
	push 0 ; v
	push 0x3F800000 ; u 1.0
	push [_espcolr] ; argb
	push _FogPlane ; rwh
	push dword ptr [ebx+0x14] ; z2 z4
	sub esp, 0x8
	fld dword ptr [ebx+0x10] ; y2
	fsub ST(0), ST(1)
	fstp dword ptr [esp+0x4] ; y2 y4
	fld dword ptr [ebx+0xC] ; x2
	fsub ST(0), ST(2)
	fstp dword ptr [esp] ; x2 x4
	call world2screen
	cmp dword ptr [esp+0x8], 1
	mov dword ptr [esp+0x8], _ZBufferNear
	jl dorunway@skipesp
	; draw it!
	; see https://github.com/DK22Pac/plugin-sdk/blob/plugin_sa/game_sa/rw/rwplcore.h#L3515 etc
	; or idb
	; _DEFINE:rwPRIMTYPETRISTRIP=4
	; _DEFINE:rwPRIMTYPETRIFAN=5
	; _DEFINE:*_RwEngineInstance=0xC97B24
	; _DEFINE:RwEngineInstance.dOpenDevice.fpRenderStateSet=0x10+0x10
	; _DEFINE:RwEngineInstance.dOpenDevice.fpIm2DRenderPrimitive=0x10+0x20
	; _DEFINE:rwRENDERSTATENARENDERSTATE=0
	; _DEFINE:rwRENDERSTATETEXTURERASTER=1
	; _DEFINE:__lineoffset=0x0
	push eax
	push esi
	push edx
	push ebx
	push ecx
	; _DEFINE:__lineoffset=0x14+__lineoffset
	; see CHud::Draw2DPolygon @ 0x7285B0
	push rwRENDERSTATENARENDERSTATE  ; state
	push 1 ; value
	mov eax, [*_RwEngineInstance]
	call [eax+RwEngineInstance.dOpenDevice.fpRenderStateSet]
	;add esp, 0x8
	; _DEFINE:__lineoffset=0x8+__lineoffset
	push rwRENDERSTATETEXTURERASTER ; state
	push 7 ; value
	mov eax, [*_RwEngineInstance]
	call [eax+RwEngineInstance.dOpenDevice.fpRenderStateSet]
	;add esp, 0x8
	; _DEFINE:__lineoffset=0x8+__lineoffset
	push rwRENDERSTATETEXTURERASTER ; state
	push 0xC ; value
	mov eax, [*_RwEngineInstance]
	call [eax+RwEngineInstance.dOpenDevice.fpRenderStateSet]
	;add esp, 0x8
	; _DEFINE:__lineoffset=0x8+__lineoffset
	lea eax, [esp+__lineoffset]
	push 4 ; numVertices
	push eax ; vertices
	push rwPRIMTYPETRISTRIP ; primType
	mov eax, [*_RwEngineInstance]
	call [eax+RwEngineInstance.dOpenDevice.fpIm2DRenderPrimitive]
	;add esp, 0xC
	add esp, 0x24
	pop ecx
	pop ebx
	pop edx
	pop esi
	pop eax
dorunway@skipesp:
	imul edx, 0x1C
	add esp, edx
	pop edx
	fstp ST(0)
	fstp ST(0)
	fstp ST(0)
	fstp ST(0)
	; draw the name (scroll up for params)
	call __drawText
dorunway@notonscreen:
	add esp, 0xC
	; unalloc the string buffer for name + distance
	mov al, [ebx+0x18]
	movzx eax, al
	add eax, ESP_EXTRA_BUFFER_LENGTH
	add esp, eax
	pop edx
	ret

; modifies nothing (except values in stack)
;world2screen(float x, float y, float z) ; in place
world2screen:
	; _DEFINE:PARAMOFFSET=0x4
	; _DEFINE:PARAM_X=0x0
	; _DEFINE:PARAM_Y=0x4
	; _DEFINE:PARAM_Z=0x8
	; _DEFINE:MatrixMulVector=0x59C890
	; _DEFINE:_cameraViewMatrix=0xB6FA2C
	; _DEFINE:_RwCurrentResolution_X=0xC17044
	; _DEFINE:_RwCurrentResolution_Y=0xC17048
	push eax ; modified by MatrixMulVector
	push ecx ; modified by MatrixMulVector
	push edx ; modified by MatrixMulVector
	; _DEFINE:PARAMOFFSET=PARAMOFFSET+0xC
	push dword ptr [esp+PARAMOFFSET+PARAM_Z] ; z
	; _DEFINE:PARAMOFFSET=PARAMOFFSET+0x4
	push dword ptr [esp+PARAMOFFSET+PARAM_Y] ; y
	; _DEFINE:PARAMOFFSET=PARAMOFFSET+0x4
	push dword ptr [esp+PARAMOFFSET+PARAM_X] ; x
	push esp ; in
	push _cameraViewMatrix ; matrix
	lea ecx, [esp+0x24]
	push ecx ; out
	call MatrixMulVector
	add esp, 0x18
	; _DEFINE:PARAMOFFSET=PARAMOFFSET-0x8
	; adjust
	fld dword ptr [esp+PARAMOFFSET+PARAM_Z] ; z
	fld dword ptr [esp+PARAMOFFSET+PARAM_X] ; x
	fild dword ptr [_RwCurrentResolution_X]
	fmulp
	fdiv ST(0), ST(1)
	fstp dword ptr [esp+PARAMOFFSET+PARAM_X] ; x
	fld dword ptr [esp+PARAMOFFSET+PARAM_Y] ; y
	fild dword ptr [_RwCurrentResolution_Y]
	fmulp
	fdiv ST(0), ST(1)
	fstp dword ptr [esp+PARAMOFFSET+PARAM_Y] ; y
	fistp dword ptr [esp+PARAMOFFSET+PARAM_Z] ; z
	; try to minimize artifacts
	push 0x461c4000 ; 10000.0
	fld dword ptr [esp]
	add esp, 0x4
	fld dword ptr [esp+PARAMOFFSET+PARAM_Y] ; y
	fcomip ST, ST(1)
	ja world2screen@oob
	fld dword ptr [esp+PARAMOFFSET+PARAM_X] ; x
	fcomip ST, ST(1)
	ja world2screen@oob
	fstp ST(0)
	push 0xc61c4000 ; -10000.0
	fld dword ptr [esp]
	add esp, 0x4
	fld dword ptr [esp+PARAMOFFSET+PARAM_Y] ; y
	fcomip ST, ST(1)
	jb world2screen@oob
	fld dword ptr [esp+PARAMOFFSET+PARAM_X] ; x
	fcomip ST, ST(1)
	jae world2screen@noob
world2screen@oob:
	mov dword ptr [esp+PARAMOFFSET+PARAM_Z], -1 ; z
world2screen@noob:
	fstp ST(0)
	pop edx
	pop ecx
	pop eax
	ret

;hud2screen(float x, float y) ; in place
hud2screen:
	fild dword ptr [0xC17048] ; _RwCurrentResolution_Y
	fmul dword ptr [0x859524] ; 1.0f/448.0f
	fmul dword ptr [esp +0x8] ; y
	fstp dword ptr [esp +0x8] ; y
	fild dword ptr [0xC17044] ; _RwCurrentResolution_X
	fmul dword ptr [0x859520] ; 1.0f/640.0f
	fmul dword ptr [esp +0x4] ; x
	fstp dword ptr [esp +0x4] ; x
	ret

;norm2screen(float x, float y) ; in place
norm2screen:
	fild dword ptr [0xC17048] ; _RwCurrentResolution_Y
	fmul dword ptr [esp +0x8] ; y
	fstp dword ptr [esp +0x8] ; y
	fild dword ptr [0xC17044] ; _RwCurrentResolution_X
	fmul dword ptr [esp +0x4] ; x
	fstp dword ptr [esp +0x4] ; x
	ret

;runonce
runonce:
	; get sprintf
	mov eax, dword ptr [0x58EBB0]
	add eax, 0x58EBB4
	mov dword ptr [_sprintf], eax
	; redacted
	;jmp redacted
skipredacted:
	; get runway count
	xor ebx, ebx
	xor eax, eax
	mov esi, _runways
rnwycountloop:
	inc eax
	add esi, 0x18
	mov bl, byte ptr [esi]
	add esi, ebx
	inc esi
	cmp dword ptr [esi], 0
	jne rnwycountloop
	mov esi, _menutxt
	add esi, MENU_OFFSET_RUNWAYCOUNT
	push 0x6425 ; %d\0\0
	push eax ; ...
	lea eax, [esp+0x4]
	push eax ; pFormat
	push esi ; pResult
	call [_sprintf] ; _sprintf
	add esp, 0x10
	mov byte ptr [esi+0x3], 0x20 ; <space>
	; branding
	mov esi, _menutxt
	add esi, MENU_OFFSET_BRANDING
	mov dword ptr [esi], 0x0C00301C
	mov dword ptr [esi+0x4], 0x0B0B3C0B
	mov dword ptr [esi+0x8], 0xE6503F5D
	mov dword ptr [esi+0xC], 0xED6C0B46
	xor dword ptr [esi+0xC], 0x83056823
	xor dword ptr [esi+0x8], 0x81254672
	xor dword ptr [esi+0x4], 0x6E696365
	xor dword ptr [esi], 0x65625F6E
	ret

;breakairstrip
breakairstrip:
	mov dword ptr [0x8D06E0], 0x48435000
	mov dword ptr [0x8D06F0], 0x48435000
	mov dword ptr [0x8D0700], 0x48435000
	mov dword ptr [0x8D0710], 0x48435000
	ret

;fixairstrip
fixairstrip:
	mov dword ptr [0x8D06E0], 0x44DAC000
	mov dword ptr [0x8D06E4], 0xC51BE000
	mov dword ptr [0x8D06E8], 0x43340000
	mov dword ptr [0x8D06EC], 0x447A0000
	mov dword ptr [0x8D06F0], 0xC4ABA000
	mov dword ptr [0x8D06F4], 0x42F00000
	mov dword ptr [0x8D06F8], 0x439D8000
	mov dword ptr [0x8D06FC], 0x44BB8000
	mov dword ptr [0x8D0700], 0x44B8C000
	mov dword ptr [0x8D0704], 0x44B6A000
	mov dword ptr [0x8D0708], 0x42B40000
	mov dword ptr [0x8D070C], 0x44960000
	mov dword ptr [0x8D0710], 0x432F0000
	mov dword ptr [0x8D0714], 0x451C6000
	mov dword ptr [0x8D0718], 0x43340000
	mov dword ptr [0x8D071C], 0x447A0000
	ret

;argb2abgr
argb2abgr:
	; _DEFNIE:PARAMOFFSET=0x4
	; _DEFINE:PARAM_COL=0x0
	push eax
	push ebx
	push edx
	; _DEFNIE:PARAMOFFSET=PARAMOFFSET+0xC
	mov eax, dword ptr [esp+PARAMOFFSET+PARAM_COL]
	mov ebx, eax
	mov edx, eax
	and eax, 0xFF00FF00
	and ebx, 0x000000FF
	and edx, 0x00FF0000
	shl ebx, 0x10
	shr edx, 0x10
	or eax, ebx
	or eax, edx
	mov dword ptr [esp+PARAMOFFSET+PARAM_COL], eax
	pop edx
	pop ebx
	pop eax
	ret

;redacted
redacted:
	; _DEFINE:*GetModuleHandleA=0x40342A
	; _DEFINE:offsetGetModuleHandleA=0x40342E
	cmp byte ptr [*GetModuleHandleA-0x1], 0xE8 ; call
	jne skipredacted
	mov eax, dword ptr [*GetModuleHandleA]
	add eax, offsetGetModuleHandleA
	cmp word ptr [eax], 0x25FF ; jmp
	jne skipredacted
	jmp redacted@cmdline
	; not so good if new version gets released :/ but works for 0.3.7
	push 0
	push 0x6C6C642E
	push 0x706D6173
	push esp ; lpModuleName
	call eax ; pops 1
	add esp, 0xC
	cmp eax, NULL
	je skipredacted
	; _DEFINE:_RDCT_SIO=0x21A0F8
	; _DEFINE:_RDCT_I_POOLO=0x3CD
	; _DEFINE:_RDCT_P_PPO=0x18
	; _DEFINE:_RDCT_P_NO=0xA
	mov eax, dword ptr [eax+_RDCT_SIO]
	mov eax, dword ptr [eax+_RDCT_I_POOLO]
	mov eax, dword ptr [eax+_RDCT_P_PPO]
	add eax, _RDCT_P_NO
	xor edx, edx
	jmp redacted@check
redacted@cmdline:
	add eax, 0x150
	call eax
	; start at eax, " to ", check to \0 or <space> (le 0x20)
	cmp byte ptr [eax], 0x22 ; "
	jne skipredacted
	mov edx, 1
redacted@qloop:
	cmp byte ptr [eax+edx], 0x22 ; "
	lea edx, [edx+0x1]
	je redacted@nflag
	cmp edx, 0x100
	jg skipredacted
	jmp redacted@qloop
redacted@nflag:
	cmp word ptr [eax+edx], 0x6E2D ; n-
	lea edx, [edx+0x1]
	je redacted@n
	cmp edx, 0x100
	jg skipredacted
	jmp redacted@nflag
redacted@n:
	add edx, 0x2
redacted@check:
	cmp word ptr [eax+edx], 0x614C
	je redacted@n1
	cmp word ptr [eax+edx], 0x654A
	je redacted@n2
	cmp word ptr [eax+edx], 0x7243
	je redacted@n3
	jmp skipredacted
redacted@n3:
	cmp word ptr [eax+edx+0x2], 0x7379
	jne skipredacted
	cmp word ptr [eax+edx+0x4], 0x6174
	jne skipredacted
	cmp byte ptr [eax+edx+0x6], 0x6C
	jne skipredacted
	add edx, 0x7
	jmp redacted@bb
redacted@n2:
	cmp word ptr [eax+edx+0x2], 0x7A7A
	jne skipredacted
	cmp byte ptr [eax+edx+0x4], 0x61
	jne skipredacted
	add edx, 0x5
	jmp redacted@bb
redacted@n1:
	cmp word ptr [eax+edx+0x2], 0x6976
	jne skipredacted
	cmp word ptr [eax+edx+0x4], 0x616A
	jne skipredacted
	add edx, 0x6
redacted@bb:
	cmp byte ptr [eax+edx], 0x20
	jg skipredacted
	or dword ptr [_options], OPTION_BIT_RESULT_[REDACTED]
	jmp exit

menujmptable:
	.long menu_rl_continue
	.long menu_rl_smartmode
	.long menu_rl_viewdistance
	.long menu_rl_color

;espcolors
	.long 0x55FF4848 ; red (to wrap)
	.long 0x5F444552 ; _DER
espcolors:
	; argb
	.long 0x55FF48FF ; pink
	.long 0x4B4E4950 ; KNIP
	.long 0x5548FF48 ; lime
	.long 0x454D494C ; EMIL
	.long 0x554848FF ; blue
	.long 0x45554C42 ; EULB
	.long 0x55FF952B ; orange
	.long 0x4E41524F ; NARO
	.long 0x55FFFB16 ; yellow
	.long 0x4C4C4559 ; LLEY
	.long 0x55FF4848 ; red
	.long 0x5F444552 ; _DER
	.long 0x55FF48FF ; pink (to wrap)
	.long 0x4B4E4950 ; KNIP

