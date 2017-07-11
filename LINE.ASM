


; Trace de ligne en mode graphique 320x200 256 couleurs
;

dosseg
.model small
.stack 512
.data

; Parametres Souris

mouse_ok	dw 0		; retourn‚ par init_mouse
mouse_bt	db 0		; etat des boutons

; Parametres de la ligne

ok_line 	dw 1		; Validation du trac‚
p1x		dw 10
p1y		dw 10		; point de depart
p2x		dw 150
p2y		dw 50		; point d arrivee
ad		dw 0		; adresse du point en cours
co		db 10		; couleur du point en cours

; Variables calcul‚es par INIT_LINE

dtx		dw 0
dty		dw 0		; Delta X & Y
sx		dw 0
sy		dw 0		; Sens X & Y
ligne		dw 0		; Compteur pour TRACE_LINE
delta		dw 0		; Master Delta
ts		dw 0		; Taile d'un segment
tbs		dw 0		; Taille de basculement vers nouveau segment
tsc		dw 0		; Taille du segment en cours

; /////////////////////////////////
; /////////////////////////////////
; /////////////////////////////////

.code

		mov ax, @data
		mov ds,ax
		mov ax,0A000h
		mov es,ax		; initialise les segments

init_graph:	mov al,13h		; passe en mode 320x200
		mov ah,0
		int 10h

		call init_mouse 	; initialise souris
		mov ax,mouse_ok 	;
		cmp ax,0		;
		je rest_graph		; si probleme goto DOS
		call gere_mouse 	; et on commence.
		call wait_kb

rest_graph:	mov al,3		; passe en mode text 80x25
		mov ah,0
		int 10h

		mov ax,4c00h		; retour au DOS
		int 21h


;////////////// PROCEDURE D'INITIALISATION DES PARAMETRES DE LA LIGNE

Init_line:	mov ax,1
		mov ok_line,ax		; OK_LINE = 1
		mov ax,p1x
		cmp ax,p2x
		jne calc_dtx		; si P1X = P2X
		mov ax,p1y
		cmp ax,p2y
		jne calc_dtx		; et P1Y = P2Y
		mov ax,0
		mov ok_line,ax		; OK_LINE = 0
		jmp fin_init_line

; Calcul Delta et Direction pour X

calc_dtx:	mov bx,01h		; Sens = +1
		mov ax,p2x
		sub ax,p1x		; AX = P2X - P1X
		jnc st_dtx
		dec ax			; si AX est n‚gatif
		not ax			; Complement … deux
		mov bx,0FFFFh		; Sens = -1
st_dtx: 	mov dtx,ax
		mov sx,bx

; Calcul Delta et Direction pour Y

		mov bx,0140h		; Sens = +320
		mov ax,p2y
		sub ax,p1y		; AX = P2Y - P1Y
		jnc st_dty
		dec ax			; si AX est n‚gatif
		not ax			; Complement … deux -> valeur absolue
		mov bx,0FEC0h		; Sens = -320
st_dty: 	mov dty,ax
		mov sy,bx

; Calcule Master Delta & TS

		mov ax,dtx
		cmp ax,dty		; si DTY > DTX
		ja dtx_sup_dty
		mov ax,sx
		mov bx,sy
		mov sx,bx
		mov sy,ax		; Echange SX <> SY
		mov bx,dty
		mov ax,dty
		mov cx,100
		mul cx
		mov cx,dtx		; TS = 100*DTY/DTX  DELTA = DTY
		cmp cx,0
		je st_delta		; (si DTX=0, TS=100*DTY)
		inc cx
		div cx
		jmp st_delta
dtx_sup_dty:	mov bx,dtx		; sinon
		mov cx,100
		mul cx
		mov cx,dty
		cmp cx,0
		je st_delta		; (si DTY=0, TS=100*DTX)
		inc cx
		div cx			; TS = 100*DTX/DTY  DELTA = DTX
st_delta:	mov delta,bx
		mov ts,ax

; Stocke l'adresse de P1x

		mov ax,p1y
		mov cx,320
		mul cx
		add ax,p1x
		mov ad,ax		; AD = (320* P1Y) + P1X

fin_init_line:	mov ax,ok_line		; AX = OK_line
		ret

; ///////////// TRACE DE LA LIGNE

trace_line:	nop
		call init_line
		cmp ax,0
		je fin_trace_line
		mov ax,ts
		mov tbs,ax
		mov ax,0
		mov ligne,ax
		mov tsc,ax		; LIGNE=0   TSC=0
bcl_line:	call aff_point		; affiche point
		inc ligne		; Ligne = ligne +1
		mov ax,tsc
		add ax,100
		mov tsc,ax		; Tsc = tsc + 100
		mov ax,ad
		add ax,sx
		mov ad,ax		; AD=AD+SX
		mov ax,tsc
		cmp ax,tbs
		jb  bcl_line		; encore si TSC<TS
		mov ax,tbs
		add ax,ts
		mov tbs,ax		; TBS = TBS + TS
		mov ax,ad
		add ax,sy
		mov ad,ax		; AD=AD+SY
		mov ax,ligne
		cmp ax,delta
		jb  bcl_line		; encore si LIGNE<DELTA

fin_trace_line: ret

; ///////////// AFFICHAGE D'UN POINT

aff_point:	mov bx,ad
		mov al,co
		mov es:[bx],al

		ret

; ///////////// ATTEND UNE TOUCHE

wait_kb:	mov ah,6
		mov dl,0FFh
		int 21h
		cmp al,0
		je wait_kb

		ret

;///////////////PROCEDURE INITIALISE SOURIS

init_mouse:	mov ax,0		; initialise driver
		int 33h
		mov mouse_ok,ax 	; stocke mouse_ok (0000 = probleme)
		mov ax,1		; affiche/gere pointeur
		int 33h
		ret

;///////////////PROCEDURE GERE SOURIS

gere_mouse:	mov ax,3
		int 33h
		shr cx,1		; ajuste Mickeys -> Pixels
		mov mouse_bt,bl
		and bl,00000011b	; les deux boutons : on sort
		cmp bl,00000011b
		je fin_mouse

bt_droit:	mov bl,mouse_bt
		and bl,00000001b	; bouton droit : on stocke la position
		cmp bl,00000001b	; comme la coordonn‚‚ de depart
		jne bt_gauche
		mov p1x,cx
		mov p1y,dx

bt_gauche:	mov bl,mouse_bt
		and bl,00000010b	; bouton gauche : on stocke comme
		cmp bl,00000010b	; coordonn‚‚ de d'arriv‚e,
		jne gere_mouse
		mov p2x,cx
		mov p2y,dx
		mov ax,2		; on supprime le pointeur souris
		int 33h
		call trace_line 	; on affiche la ligne
		call aff_points
		mov ax,1		; on remet le pointeur souris
		int 33h
		mov ax,p2x		; et on memorise comme coordonn‚‚
		mov p1x,ax		; de depart
		mov ax,p2y
		mov p1y,ax
		jmp gere_mouse

fin_mouse:	ret

aff_points	proc	near
		mov al,2
		mov co,al
		mov ax,p1y
		mov cx,320
		mul cx
		add ax,p1x
		mov bx,ax
		call aff_point
		mov ax,p2y
		mov cx,320
		mul cx
		add ax,p2x
		mov bx,ax
		call aff_point
		mov al,10
		mov co,al
		ret
aff_points	endp


; ////////////////////////////
; ////////////////////////////
; ////////////////////////////


end
