#!/bin/bash
#set +x
 
# Titulo        : "InstalacaoBacula.sh"
# Descricao     : Este script realiza a instalacao e configuracao do agente do bacula 7.
# Autor         : Aecio Junior <aeciojr@gmail.com
# Data          : 10-Setembro-2016.
# Versao        : 0.5
# Usage         : Este deve ser executado na shell do servidor desejado.
#               : Via wget: $ wget --output-document - http://10.81.100.93/bacula/InstalacaoBacula.sh | bash
#               : Via curl: $ curl http://10.81.100.93/bacula/InstalacaoBacula.sh | bash -s -- 
 
URLPackages="http://10.81.100.93/bacula/packages/"
 
PKG_Debian_5_amd64="bacula-fd_7.4.1-2_Debian5_amd64.deb"
PKG_Debian_6_amd64="bacula-fd_7.4.1-1_Debian6_amd64.deb"
PKG_Debian_5_x86="bacula-fd_7.4.1-2_Debian5_i386.deb"
PKG_Debian_6_x86="bacula-fd_7.4.1-2_Debian6_i386.deb"
PKG_Ubuntu_10_amd64="bacula-fd_7.4.1-2_Ubuntu12_amd64.deb"
PKG_Ubuntu_12_amd64="bacula-fd_7.4.1-2_Ubuntu12_amd64.deb"
PKG_Ubuntu_14_amd64="bacula-fd_7.4.1-2_Ubuntu14_amd64.deb"
PKG_Ubuntu_10_x86="bacula-fd_7.4.1-2_Ubuntu10_i386.deb"
PKG_Ubuntu_12_x86="bacula-fd_7.4.1-2_Ubuntu10_i386.deb"
PKG_Ubuntu_14_x86="bacula-fd_7.4.1-2_Ubuntu10_i386.deb"
 
_BitImutavel(){
   if [ $# -eq 2 ]; then
      local Operacao="$1"
      local Arquivo="$2"
      if [ "$Operacao" == "on" ]; then
         sudo chattr +i $Arquivo
      elif [ "$Operacao" == "off" ]; then
         sudo chattr -i $Arquivo
      else
         echo "usage: _BitImutavel on|off Arquivo"
      fi
   else
      echo "usage: _BitImutavel on|off Arquivo"
   fi
}
 
_ProtecaoArquivos(){
   local Operacao="$1"
   if [ "$Operacao" == "ativar" ]; then
      _BitImutavel on "/etc/passwd"
      _BitImutavel on "/etc/shadow"
      _BitImutavel on "/etc/gshadow"
      _BitImutavel on "/etc/group"
      sudo test -f "/etc/iptables.regras" && _BitImutavel on "/etc/iptables.regras"
   elif [ "$Operacao" == "desativar" ]; then
      _BitImutavel off "/etc/passwd"
      _BitImutavel off "/etc/shadow"
      _BitImutavel off "/etc/gshadow"
      _BitImutavel off "/etc/group"
      sudo test -f "/etc/iptables.regras" && _BitImutavel off "/etc/iptables.regras"
   fi
}
 
_Description(){
   local RC=0
   if which lsb_release > /dev/null 2>&1
   then
      local ArquivoTemporario=$( mktemp -p $HOME )
      lsb_release --description > $ArquivoTemporario
      if grep --ignore-case --silent ubuntu < $ArquivoTemporario
      then
         local Distro=ubuntu
      elif grep --ignore-case --silent debian < $ArquivoTemporario
      then
         local Distro=debian
      else
         local Distro=unknown
         local RC=2
      fi
      echo $Distro
      [[ -f $ArquivoTemporario ]] && rm -rf $ArquivoTemporario > /dev/null 2>&1
   else
      echo Comando lsb_release inexistente
      local RC=1
   fi
   return $RC
}
 
_Release(){
   local RC=0
   if which lsb_release > /dev/null 2>&1
   then
      local ArquivoTemporario=$( mktemp -p $HOME )
      lsb_release --release --short > $ArquivoTemporario || local RC=$?
      if [ $RC -eq 0 ]; then
         local Release=$( cut -d \. -f1 $ArquivoTemporario )
         echo $Release
      else
         echo Erro no comando lsb_release
      fi
      [[ -f $ArquivoTemporario ]] && rm -rf $ArquivoTemporario > /dev/null 2>&1
   else
      echo Comando lsb_release inexistente
      local RC=1
   fi
   return $RC
}
 
_Arquitetura(){
   local RC=0
   if which uname > /dev/null 2>&1
   then
      local Arquitetura=$( uname --machine)
   elif which arch > /dev/null 2>&1
   then
      local Arquitetura=$( arch )
   else
      local Arquitetura=unknown
      local RC=1
   fi
   echo $Arquitetura
   return $RC
}
 
_VerificaInstalacao(){
   local RC=1
   { dpkg --list | grep --silent bacula; } && local RC=$?
   return $RC 
}
 
_VerificaVersao(){
   local RC=0
   local ArquivoTemporario=$( mktemp -p $HOME )
   local Versao=$( dpkg --list | grep --ignore-case bacula | head -n1 | awk '{ print $3 }'| cut -c1 )
   echo $Versao
   [[ -f $ArquivoTemporario ]] && rm -rf $ArquivoTemporario > /dev/null 2>&1
   return $RC
}
 
_RealizaBackupArquivos(){
   local RC=0
   local DirBacula="/etc/bacula"
   local DirDestino="$HOME"
   local Conf=bacula-fd.conf
   sudo test -d $DirBacula && { sudo tar -czvf $DirDestino/etc.bacula.`date +%F`.tar.gz $DirBacula || local RC=$?; } 
   return $RC
}
 
_RemoveBacula(){
   local RC=0
   _ProtecaoArquivos desativar
   dpkg --get-selections | grep --extended-regexp --ignore-case 'bacula' | cut -f1 | \
   while read PKG
   do
      sudo mv -v /var/lib/dpkg/info/*bacula* /tmp
      sudo dpkg --purge --force-all $PKG || sudo dpkg --remove $PGK || local RC=$?
   done
   _ProtecaoArquivos ativar
   return $RC
}
 
_InstalaBacula(){
   local RC=0
   if [ $# -eq 1 ]
   then
      local Pacote=$1
      local URLPacote="$URLPackages/$Pacote"
      local DestinoPacote="$HOME/$Pacote"
      if which wget
      then
         wget --output-document "$DestinoPacote" "$URLPacote" || local RC=$?
      elif which curl
      then
         curl --output "$DestinoPacote" "$URLPacote" || local RC=$?
      else
         echo Sem curl/wget
         local RC=1
      fi
      if [ $RC -eq 0 ]
      then
 
         _ProtecaoArquivos desativar
         sudo dpkg --install --force-confold $DestinoPacote || local RC=$?
         _ProtecaoArquivos ativar
      fi
   else
      echo "Usage _InstalaBacula pacote.deb"
      local RC=1
   fi
   [ -f $DestinoPacote ] && rm -rf $DestinoPacote
   return $RC
}
 
_ObterPacoteDeb(){
   local RC=0
   if [ $# -eq 3 ]
   then
      local Distro=$1
      local Release=$2
      local Arquitetura=$3
      if [ "$Distro" == "debian" ]; then
         case $Arquitetura
         in
            *64)
               if [[ "$Release" == "5" ]]; then
                  PacoteDEB="$PKG_Debian_5_amd64"
               elif [[ "$Release" == "6" ]]; then
                  PacoteDEB="$PKG_Debian_6_amd64"
               else
                  Mensagem="Release nao suportado pelos pacotes customizados."
                  PacoteDEB="unknown"
                  RC=3
               fi
            ;;
            *32)
               if [[ "$Release" == "5" ]]; then
                  PacoteDEB="$PKG_Debian_5_x86"
               elif [[ "$Release" == "6" ]]; then
                  PacoteDEB="$PKG_Debian_6_x86"
               else
                  Mensagem="Release nao suportado pelos pacotes customizados."
                  PacoteDEB="unknown"
                  RC=3
               fi
            ;;
            *)
               Mensagem="Arquitetura nao suportada."
               RC=3
            ;;
         esac
      elif [[ "$Distro" == "ubuntu" ]]; then
         case $Arquitetura
         in
            *64)
               if [[ "$Release" == "10" ]]; then
                  PacoteDEB="$PKG_Ubuntu_10_amd64"
               elif [[ "$Release" == "12" ]]; then
                  PacoteDEB="$PKG_Ubuntu_12_amd64"
               elif [[ "$Release" == "14" ]]; then
                  PacoteDEB="$PKG_Ubuntu_14_amd64"
               else
                  Mensagem="Release nao suportado pelos pacotes customizados."
                  PacoteDEB="unknown"
                  RC=3
               fi
            ;;
            *32)
               if [[ "$Release" == "10" ]]; then
                  PacoteDEB="$PKG_Ubuntu_10_x86"
               elif [[ "$Release" == "12" ]]; then
                  PacoteDEB="$PKG_Ubuntu_12_x86"
               elif [[ "$Release" == "14" ]]; then
                  PacoteDEB="$PKG_Ubuntu_14_x86"
               else
                  Mensagem="Release nao suportado pelos pacotes customizados."         	
                  PacoteDEB="unknown"
                  RC=3
               fi
            ;;
            *)
               Mensagem="Arquitetura nao suportada."
               RC=3
            ;;
         esac
      else
         echo "Distro nao suportada. Tente instalar via srouce"
         RC=3
      fi
   else
      echo Usage _ObterPacoteDeb Distro Release arquitetura
      RC=1
   fi
   echo $PacoteDEB
   [[ ! -z $Mensagem ]] && export $Mensagem
   return $RC
}
 
_Print(){
   local Line="=================="
   echo -e "\n$Line $@ $Line\n"; 
}
 
_Plataforma(){
   # Usage _Plataforma distribuicao|release|arquitetura
   local RC=0
   local Informacao=$1
   case $Informacao
   in
      distribuicao)
         local Plataforma=$( python -c 'import platform; print platform.dist()' ) || local RC=$?
         local Distribuicao=$( echo $Plataforma | cut -d\' -f2 | tr [:upper:] [:lower:]) || local RC=$?
         echo $Distribuicao
      ;;
      release)
         local Plataforma=$( python -c 'import platform; print platform.dist()' ) || local RC=$?
         local Release=$( echo $Plataforma | cut -d\' -f4 | cut -d\. -f1 ) || local RC=$?
         echo $Release
      ;;
      arquitetura)
         local PlataformaArq=$( python -c 'import platform; print platform.architecture()' ) || local RC=$?
         local Arquitetura=$( echo $PlataformaArq | cut -d \' -f2 | tr -d "[a-z][A-Z]" ) || local RC=$?
         echo $Arquitetura
      ;;
   esac
   return $RC
}
 
_ValidaInstalacao(){
   _Print "Endereco IP"
   /sbin/ifconfig | grep -E '172.25|200.238|10.10'
   _Print "Checando INSTALACAO"
   dpkg -l | grep bacula | grep -v grep
   _Print "Checando EXECUCAO"
   ps aux | grep bacula | grep -v grep
   sudo netstat -tpln | grep 9102 | grep -v grep
   _Print "Checando FW"
   sudo iptables -L -nv | grep 9102 | grep -v grep
   _Print "Checando CONF"
   sudo cat /etc/bacula/bacula-fd.conf
   _Print "Checando INCLUDE"
   sudo cat /etc/bacula/bacula_include.txt
}
 
#--- Inicio do script ---#
RC=0
#Distribuicao=$( _Description ) || RC=$?
#     Release=$( _Release     )
# Arquitetura=$( _Arquitetura )
 
Distribuicao=$( _Plataforma distribuicao ) || RC=$?
     Release=$( _Plataforma release )
 Arquitetura=$( _Plataforma arquitetura )
 
if [ $RC -eq 0 ]
then
   case $Distribuicao
   in
      debian|ubuntu)
         if _VerificaInstalacao
	 then
	    VersaoFD=$( _VerificaVersao ) || RC=1
	    if [ $VersaoFD -ne 7 ]
	    then
	       _RealizaBackupArquivos || RC=$?
	       if [ $RC -eq 0 ]
	       then
	          _RemoveBacula || RC=$?
		  if [ $RC -eq 0 ]
		  then
		     PacoteDEB=$( _ObterPacoteDeb $Distribuicao $Release $Arquitetura ) && \
		     _InstalaBacula $PacoteDEB || { echo $Mensagem; unset Mensagem; RC=$?; }
		     if [ $RC -eq 0 ]
		     then
                        echo Bacula 7 instalado com sucesso. Ajuste o client no DIR
		     else
		        echo "Erro instalando o bacula 7 (garanta acesso sudo sem senha)"
			RC=3
		     fi
		  else
		     echo Erro removendo bacula
		  fi
	       else
	          echo Erro realizando o backup original dos arquivos bacula
	       fi
	    else
	       echo Bacula ja instalado na versao 7, valide conf/include/exclude
	    fi
	 else
	    PacoteDEB=$( _ObterPacoteDeb $Distribuicao $Release $Arquitetura ) && \
	    _InstalaBacula $PacoteDEB || RC=$?
	    if [ $RC -eq 0 ]
	    then
	       echo Bacula 7 instalado com sucesso. Ajuste o client no DIR
	    else
	       echo Erro instalando o bacula 7
	       RC=3
	    fi
         fi
      ;;
      *)
         echo Distro desconhecida, instale o bacula-fd via source
	 RC=2
      ;;
   esac
else
   echo Erro obtendo distribuicao
   RC=1
fi
exit $RC
#--- Fim do script ---#
