=====
Email
=====

Configure los servicios de correo electrónico

Dominios
========

La tabla contiene la lista de nombres de dominio de Internet para los que el servidor acepta correo electrónico entrante.

Crear / Modificar
-----------------

Agregar un dominio a la lista de los configurados para la recepción de correo electrónico.


Dominio
    El nombre de dominio, por ejemplo *nethesis.it*.

Descripción
    Campo opcional útil para el administrador del sistema para tomar nota de la información del dominio.

Entrega local 
    Seleccione esta opción para configurar el servidor para entregar correo entrante dirigido al dominio especificado en las carpetas locales.

Reenviar a otro servidor
    Si selecciona esta opción, el correo entrante será transmitido al servidor especificado.

Disclaimer (aviso legal)
    Añadir automáticamente un mensaje legal (disclaimer) a todos los mensajes salientes (no dirigidos al dominio). 

Borrar
------

Retire el dominio de los gestionados por el servidor. Cualquier correo electrónico destinado para el dominio serán rechazadas.


Filtro
=======

Configure las opciones de filtrado de correo electrónico (antivirus, antispam, adjuntos prohibidos, etc.) 

Antivirus
    Habilitar la detección de virus de correos electrónicos en tránsito. 

Antispam
    Activar el análisis antispam de mensajes de correo electrónico entrantes. 

Prefijo Spam 
    Este prefijo se agrega al objeto subyacente a los correos electrónicos reconocidos como spam.

Bloqueo de archivos adjuntos
    El servidor de correo electrónico bloquea mensajes de correo electrónico que contengan archivos adjuntos del tipo especificado.

Ejecutable
    El servidor de correo electrónico bloqueará programas ejecutables en archivos adjuntos de correo electrónico.

Archivos
    El servidor de correo electrónico bloquea mensajes de correo electrónico con archivos adjuntos que contienen archivos comprimidos (ZIP, rar, etc.)

Lista personalizada
    Definir una lista de extensiones que serán bloqueadas, tales como doc, pdf, etc (sin arrancar punto, es decir, doc y no. doc).


Buzones
=======


En esta ficha, puede configurar algunos parámetros relacionados con las carpetas de correo locales.

IMAP
    Habilitar el acceso a carpetas a través del protocolo IMAP (recomendado).

POP3
    Habilitar el acceso a carpetas a través del protocolo POP3 (no recomendado).

Permitir conexiones sin cifrar
    Permite habilitar el acceso a las carpetas que utilizan protocolos no encriptados (no recomendado).

Espacio en disco
    Le permite limitar el uso del disco por correo electrónico.
    
    * Ilimitado: seleccionar de no imponer límites
    * Aplicar cuota: límite de espacio máximo de correo para cada usuario con el valor indicado (cuota de correo electrónico). 

Movera la carpeta *junkmail* 
    Mensajes de correo electrónico identificado como spam se mueven a cada carpeta de usuario *Junkmail* en lugar de ser entregado a la bandeja de entrada.


Mensajes
========

Configurar la gestión de mensajes de correo electrónico.

Acepte el tamaño del mensaje a
    Utilice el cursor para seleccionar el tamaño máximo de cada mensaje de correo electrónico. El servidor rechazará el correo electrónico más grande que el valor establecido y devolverá un error explicativo.

Vuelva a intentar el envío de
    Utilice el cursor para seleccionar el tiempo máximo durante el cual el servidor tratará de enviar un mensaje. Cuando llega el tiempo máximo y el correo electrónico no ha sido entregado, el remitente recibirá un error y el mensaje se elimina de la cola de envío, el servidor no intentará entregarlo.

Enviar usando un host inteligente
    El servidor intentará enviar correos electrónicos directamente a sudestino (recomendado en la mayoría de los casos). Selecciona en lugar de enviar a través de un host inteligente, se intentará entregar a través de la El servidor SMTP del ISP (se recomienda en caso de una conexión poco fiable o ADSL residencial, IP dinámica, etc.) 

Nombre de host
    El nombre del servidor de correo del proveedor.

Puerto
    El puerto del servidor de correo del proveedor.

Nombre de usuario
    Si el servidor del proveedor requiere autenticación, especifique el nombre de usuario.

Contraseña 
    La contraseña requerida por el proveedor.

Permitir conexión no cifrada
    Normalmente, si se utiliza una conexión autenticada (con nombre de usuario y contraseña), se requiere una conexión cifrada para proteger la contraseña. Al seleccionar esta opción, se permite una conexión no segura para conectarse al proveedor (no se recomienda, utilizar solamente si el ISP tiene problemas).

Gestión de Colas
================

Esta ficha le permite gestionar la cola de mensajes de correo electrónico en tránsito en el servidor. La tabla recoge todo el correo en espera de ser entregado, y está normalmente vacía. Los siguientes campos se mostrarán:

* Id: identificador del mensaje
* Remitente: desde la dirección de correo electrónico (que envió el mensaje)
* Tamaño: El tamaño en bytes de la dirección de correo electrónico
* Fecha: La fecha de la creación del correo electrónico 
* Destinatarios: la lista de destinatarios


Borrar
------

Es posible eliminar un e-mail en la cola, por ejemplo, un correo electrónico enviado por error o demasiado grande.

Retire todo
-----------

El botón se borrarán todos los mensajes de correo electrónico en la cola.

Pruebe a enviar
---------------

Normalmalmente, el servidor, en caso de problemas al enviar el correo electrónico, lo reintenta a intervalos regulares. Al hacer clic en el intento de enviar mensajes de correo electrónico, será enviado de inmediato.

Actualización
-------------

Actualizar la lista de mensajes de correo electrónico en la cola.
