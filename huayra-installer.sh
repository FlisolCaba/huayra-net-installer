#!/usr/bin/env bash
# vim: set tabstop=2 softtabstop=2 shiftwidth=2 noexpandtab fenc=utf-8 ff=unix ft=sh:
# #############################################################################
# FLISoL Post Install script
# Copyright (C) 2016 by SnKisuke (https://linuxnoblog.net)
# & HacKan (https://hackan.net)
# para FLISoL CABA (https://flisolcaba.usla.org.ar)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# #############################################################################
#
# Este script permite instalar Huayra desde el modo en vivo (live) vía PXE.
# Probado con Huayra 3.2 (Sud).
#
# #############################################################################

if [ "$(whoami)" != "root" ]; then
	echo "!!! Error: debe ejecutar este script como root"
	echo "*** Ejecutando sudo \
$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )/$(basename "${0}")..."
	sudo "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )/$(basename "${0}")"
	exit $?
fi

cat <<EOF
Bienvenido al instalador de Huayra, realizado con amor por colaboradores de
FLISoL CABA (https://flisolcaba.usla.org.ar).

A continuacion, le ayudaremos a instalar Huayra Linux en su maquina.  Es importante saber que si la instalacion o este script falla en algun punto, debera reiniciar la maquina y volver a intentar.  Cualquier duda, consulte al Coordinado de instaladores.

Comencemos...

EOF

echo "*** Instalando requisitos..."
apt install -y rsync
echo "*** Terminado"

echo "*** Ejecutando instalador de Huayra..."
debian-installer-launcher -e & > /dev/null 2>&1
pid=$!

cat<<EOF
*** Continue la instalación normalmente en el instalador, pero NO CIERRE ESTA TERMINAL

**! NO CIERRE ESTA TERMINAL !**

*** Ahora, un poco de magia negra que +10hs de analisis continuado del sistema nos ha enseñado...

*** El instalador rompera el sistema si reconfigura la interfaz de red, porque no podra continuar cargando archivos.

*** A fin de evitar esto, reemplazamos el archivo responsable por uno
trucado.
EOF

# Debo reemplazar ethdetect para evitar que el instalador corte la conexión
# al intentar configurar la red...
# Creamos uno falso que simplemente genere una salida exitosa:
cat > /tmp/fake_ethdetect.c <<EOF
int main() {
	return 0;
}
EOF

gcc -Os /tmp/fake_ethdetect.c -o /tmp/fake_ethdetect

# Esperar a que aparezca el archivo para reemplazarlo
while [ ! -f "/lib/live/installer/target/bin/ethdetect" ]; do
	sleep 0.2
done

rsync /tmp/fake_ethdetect /lib/live/installer/target/bin/ethdetect

cat<<EOF
*** Luego, ocurre algo muy peculiar: el instalador modifica las fuentes del repositorio cayendo en un bucle infinito al solicitar que se inserte el CD del sistema.
Para solucionarlo, forzamos el contenido del mismo por un valor correcto y esperamos a que la instalacion concluya...
EOF

# Es seguro esperar un rato antes de lanzar este bucle
sleep 60
dot=0
while [ $? -eq 0 ]; do
	let "dot++" && [[ $dot -gt 1000 ]] && echo -n "."

	[[ -f /lib/live/installer/target/etc/apt/sources.list ]] && \
		rsync /etc/apt/sources.list /lib/live/installer/target/etc/apt/sources.list

	# Bucle hasta que finalice la instalacion, no tengo otra forma de saber
	# con certeza
	ps -sp ${pid} > /dev/null 2>&1
done

echo "*** Instalacion concluida :)"
echo "*** Reinicie el sistema para comenzar a disfrutar su Huayra Linux."

echo "*** Terminado."
exit 0
