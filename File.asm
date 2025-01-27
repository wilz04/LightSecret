new macro url, handle
	lea dx, url                           ;apuntamos con dx al nombre del archivo
	xor cx, cx                            ;no necesitamos especificar sus atributos, esto se hace en cx
	mov ah, 3Ch
	int 21h                               ;llamamos a la interrupcion 21, 3C; para crearlo
	mov handle, ax                        ;ella devuelbe en ax el manejador del archivo y lo guardamos en handle
endM

open macro url, handle
	lea dx, url                           ;apuntamos con dx al nombre del archivo
	mov ax, 3D00h                         ;limpiamos al para..
	int 21h                               ;abrirlo llamando a la interrupcion 21, 3D
	mov handle, ax                        ;ella devuelbe en ax el manejador del archivo, lo guardamos en handle
endM

load macro handle, text, len
	mov bx, handle                        ;copiamos el manejador en el registro bx
	lea dx, text                          ;apuntamos con dx al buffer donde se copiara el texto del archivo
	mov cx, len                           ;copiamos la cantidad de bytes en cx que queremos que se copien
	mov ah, 3Fh
	int 21h                               ;llamamos a la interrupcion 21, 3F para leerlo
	mov len, ax                           ;ella devuelbe en ax la cantidad de bytes leidos realmente, lo guardamos en len
endM

save macro handle, text, len
	mov bx, handle                        ;copiamos el manejador en el registro bx
	lea dx, text                          ;apuntamos con dx al buffer de donde se copiara el texto del archivo
	mov cx, len                           ;copiamos la cantidad de bytes en cx que queremos que se copien
	mov ah, 40h
	int 21h                               ;llamamos a la interrupcion 21, 40 para guardarlo
endM

close macro handle
	mov bx, handle                        ;copiamos el manejador en el registro bx
	mov ah, 3Eh
	int 21h                               ;llamamos a la interrupcion 21, 3E para cerrarlo
endM

erase macro url
	lea dx, url                           ;apuntamos con dx al nombre del archivo
	mov ah, 41h
	int 21h                               ;llamamos a la interrupcion 21, 41 para borrarlo
endM
