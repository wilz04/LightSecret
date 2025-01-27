.model small

.data
	file dB 16 dup(0)
	handle dW 0
	text dB 1024 dup(0)
	len dW 1024
	
	sector dB 4 dup(0)
	op dB 4 dup(0)
	
	pwd dB 0
	pURL dB "A:\Pwd.dat"

.stack
	dW 4 dup(0)

.code
	mov ax, @data
	mov ds, ax
	
	include File.asm                      ;incluimos el archivo File.asm
	
	mov si, 128                           ;copiamos un 128 en si
	xor ch, ch                            ;limpiamos ch
	mov cl, es:[si]                       ;copiamos el byte al que apunta si del segmento extra (contiene el numero de bytes de parametros)
	
	cmp cl, 6                             ;lo comparamos con 6..
	jl exit_                              ;y si es menor brincamos a exit_ [1b(archivo) + 1b(/) + 1b(sector) + 1b(espacio) + 2b(operacion)]
	
	add si, 2                             ;le sumamos 2 a si para que en el segmento extra apunte al primer byte del nombre del archivo
	
	lea di, file                          ;apuntamos con di al buffer donde copiaremos el nombre del archivo
	mov dh, '/'                           ;copiamos a dh un '/', el delimitador del nombre del archivo y el sector (para parsear los params)
	jmp next_                             ;brincamos a next_, por ahora no son importantes las lineas siguientes
	
	sGet:
	lea di, sector                        ;apuntamos con di al buffer donde copiaremos el sector que esta enformato cadena de caracteres
	mov dh, ' '                           ;copiamos a dh un ' ', el delimitador del sector y la operacion
	inc ch                                ;incrementamos ch en 1 (se usa como boolean para saber si termino de copiar el sector)
	jmp next_
	
	oGet:
	lea di, op                            ;apuntamos con di al buffer donde copiaremos la operacion ("-e" o "-d")
	
	next_:
	mov dl, es:[si]                       ;copiamos a dl el byte de parametros en el segmento extra al que apunta si
	mov [di], dl                          ;copiamos a donde apunta di el contenido de dl
	inc si                                ;incrementamos si en 1 para que apunte al siguiente byte
	inc di                                ;incrementamos di en 1 para que apunte al siguiente byte
	dec cl                                ;decrementamos cl para restarle el byte copiado
	jz end_                               ;si cl es 0 (es porque terminamos de copiar los parametros) brincamos a end_
	cmp es:[si], dh                       ;comparamos el contenido de lo que apunta si en el segmento extra con dh (delimitador de params)
	jne next_                             ;si no son iguales brincamos a next_ para seguimos copiando
	xor dh, dh                            ;limpiamos dh..
	mov [di], dh                          ;para comparar lo que apunta di con el (0) ya que no se puede hacer directamente
	inc si                                ;incrementamos si en 1 porque hay que saltar este byte porque es un ' '
	dec cl                                ;decrementamos cl en 1 para restarle el ' '
	cmp ch, 0                             ;comparamos ch y 0 preguntando si se termino de copiar el nombre de archivo..
	je sGet                               ;si son iguales brincamos a sGet
	cmp ch, 1                             ;comparamos ch y 1 preguntando si se termino de copiar el sector..
	je oGet                               ;si son iguales brincamos a oGet
	
	end_:
	xor dl, dl                            ;limpiamos dl..
	lea bx, sector                        ;apuntamos con bx al sector..
	cmp [bx], dl                          ;y comparamos lo que apunta el contenido de bx con dl (el primer byte del sector con 0)..
	je exit_                              ;si son iguales brincamos a exit_ porque el sector no es valido
	lea bx, op                            ;apuntamos con bx a la operacion..
	cmp [bx], dl                          ;y comparamos lo que apunta el contenido de bx con dl (el primer byte de la operacion con 0)..
	je exit_                              ;si son iguales brincamos a exit_ (porque la operacion no es valida)
	
	jmp skip_                             ;brincamos a skip_, por ahora no son importantes las lineas siguientes
	exit_:
	jmp exit___                           ;brincamos a exit___, no se hace directo, en un solo salto porque hay mucha distancia
	skip_:
	
	open file, handle                     ;llamamos a la macro open para abrir el archivo <file> y devuelbe el manejador <handle>..
	jc exit_                              ;si hay un error brincamos a exit_
	load handle, text, len                ;llamamos a la macro load para cargar el texto del archivo de <handle>, lo devuelbe en <text>..
	jc exit_                              ;si hay un error brincamos a exit_
	close handle                          ;llamamos a la macro close que cierra el archivo apuntado por <handle>
	jc exit_                              ;si hay un error brincamos a exit_
	erase file                            ;llamamos a la macro erase que elimina el archivo <file>
	jc exit_                              ;si hay un error brincamos a exit_
	
	lea bx, sector                        ;apuntamos con bx al sector para convertirlo de cadena de bytes a un byte (de string a int)
	xor dh, dh                            ;limpiamos dh para usarlo como delimitador de cadena (0)
	xor ch, ch                            ;limpiamos ch para usarlo como contador
	next__:
	mov dl, [bx]                          ;copiamos a dl el byte al que apunta bx
	sub dl, 48                            ;le restamos 48 a dl para convertir el caracter a numero, ej: de '1' a 1
	mov [bx], dl                          ;copiamos al byte al que apunta bx dl para lo devolberlo convertido
	inc ch                                ;incrementamos ch en para sumarle el byte convertido
	inc bx                                ;incrementamos bx en 1 para que apunte al siguiente byte
	cmp [bx], dh                          ;comparamos lo que apunta el contenido de bx con dh (0)..
	jne next__                            ;si no son iguales brincamos a next__ para seguir convirtiendo y contando
	
	xor dh, dh                            ;limpiamos dh para usarlo como acumulador de bytes, aca quedara el resultado de la conversion
	dec bx                                ;decrementamos bx en 1 para devolbernos una posicion es caso de que solo sea un byte..
	dec ch                                ;ya que si al decrementamos ch en 1 el resultado es 0
	jz skip__                             ;brincamos a skip__ porque no hace falta multiplicar los bytes del sector por las potencias de 10

	lea bx, sector                        ;apuntamos con bx al sector para convertirlo de unidades a unidades, decenas y centenas
	next___:
	mov dl, 10                            ;copiamos a dl un 10 para luego multiplicarlo y sacar sus potencias
	mov al, 1                             ;copiamos a al un 1 para multiplicarlo por dl..
	mov cl, ch                            ;copiamos a cl el contenido de ch para usarlo tambien como contador porque son dos ciclos
	next____:
	mul dl                                ;multiplicamos dl por al, y el resultado queda en ax
	dec cl                                ;decrementamos cl en 1 para restarle el 10 multiplicado
	jnz next____                          ;si cl no es igual a 0 brinca a next____ para seguir elevando al
	mov dl, [bx]                          ;copiamos a dl el byte al que apunta bx
	mul dl                                ;multiplicamos dl por al y el resultado queda en ax, para convertir la unidad en numero pocisional
	add dh, al                            ;le sumamos al a dh acumular el resultado total
	inc bx                                ;incrementamos bx en 1 para que apunte al siguiente byte
	dec ch                                ;decrementamos ch en 1..
	jnz next___                           ;si ch no es igual a 0 brincamos a next___ para seguir con el siguiente byte
	
	skip__:
	add dh, [bx]                          ;le sumamos el contenido de lo que apunta bx a dh (acumulamos el ultimo byte)
	;cmp dh, 0
	;je exit_
	;cmp dh, 128
	;jg exit_
	mov sector, dh                        ;copiamos el contenido de dh a sector, ahora sector contiene el numero
	
	lea bx, op                            ;apuntamos con bx a la operacion para evaluarla
	mov dl, '-'                           ;copiamos a dl un '-'..
	cmp [bx], dl                          ;lo comparamos con el contenido de lo que apunta bx..
	jne exit__                            ;y si no son iguales brincamos a exit__ porque la operacion no es valida
	inc bx                                ;incrementamos bx en 1 para que apunte al siguiente byte
	mov dl, 'e'                           ;copiamos a dl una 'e'..
	cmp [bx], dl                          ;lo comparamos con el contenido de lo que apunta bx..
	je pSet                               ;y si son iguales brincamos a pSet porque la operacion es encriptar, hay que generar un password
	mov dl, 'd'                           ;copiamos a dl una 'd'..
	cmp [bx], dl                          ;lo comparamos con el contenido de lo que apunta bx..
	je pGet                               ;y si son iguales brincamos a pGet porque la operacion es desencriptar, hay que cargar el password
	jmp exit___                           ;brincamos a exit___ porque la operacion no es valida (no es "-e" ni "-d")
	
	pSet:
	mov ah, 2Ch
	int 21h                               ;llamamos a la interrupcion 21, 2C para generar el password
	lea bx, pwd                           ;apuntamos con bx al password
	mov [bx], dl                          ;copiamos dl al byte que apunta bx, guardamos el password en lo que apunta pwd
	
	new pURL, handle                      ;llamamos a la macro new para crear el archivo <pURL> y devuelbe el manejador <handle>..
	jc exit__                             ;si hay un error brincamos a exit_
	save handle, pwd, 1                   ;llamamos a la macro save para guardar el texto <pwd> (password) del archivo de <handle>..
	jc exit___                            ;si hay un error brincamos a exit_
	close handle                          ;llamamos a la macro close que cierra el archivo apuntado por <handle>
	jc exit___                            ;si hay un error brincamos a exit_
	jmp skip___                           ;brincamos a skip___ porque no hay que cargar el password
	
	pGet:
	open pURL, handle                     ;llamamos a la macro open para abrir el archivo <pURL> y devuelbe el manejador <handle>..
	jc exit___                            ;si hay un error brincamos a exit_
	mov cx, 1                             ;copiamos a dl un 1 para enviarlo como cantidad de caracteres que queremos leer:
	load handle, pwd, cx                  ;llamamos a la macro load para cargar el texto del archivo de <handle>, lo devuelbe en <pwd>..
	jc exit___                            ;si hay un error brincamos a exit_
	close handle                          ;llamamos a la macro close que cierra el archivo apuntado por <handle>
	jc exit___                            ;si hay un error brincamos a exit_
	
	jmp skip____                          ;brincamos a skip_, por ahora no son importantes las lineas siguientes
	exit__:
	jmp exit___                           ;brincamos a exit___, no se hace directo, en un solo salto porque hay mucha distancia
	skip____:
	
	skip___:
	mov cx, len                           ;copiamos a cx la longitud del texto, para usar a cx como contador y procesar el texto byte/byte
	lea bx, text                          ;apuntamos con bx al texto
	next_____:
	mov dl, [bx]                          ;copiamos a dl el byte al que apunta bx
	xor dl, pwd                           ;codifica dl con el password (encripta o desencripta)
	mov [bx], dl                          ;copiamos dl al byte que apunta bx, sustituimos este contenido por el byte codificado
	inc bx                                ;incrementamos bx en 1 para que apunte al siguiente byte
	loop next_____                        ;brincamos a next_____, mientras cx sea diferente de 0
	
	new file, handle                      ;llamamos a la macro new para crear el archivo <file> y devuelbe el manejador <handle>..
	jc exit___                            ;si hay un error brincamos a exit_
	save handle, text, len                ;llamamos a la macro save para guardar el texto <pwd> (password) del archivo de <handle>..
	jc exit___                            ;si hay un error brincamos a exit_
	close handle                          ;llamamos a la macro close que cierra el archivo apuntado por <handle>
	
	exit___:
	mov ax, 4C00h
	int 21h                               ;llamamos a la interrupcion 21, 4C para salir devolbiendo 0 en al
end
