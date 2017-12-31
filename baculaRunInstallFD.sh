#!/bin/bash
#set +x
 
URLInstalaHTTP="http://10.81.25.88/bacula/InstalacaoBacula.sh"
Hostname=WIKI
Script=$HOME/InstalarBacula.sh
UsuarioSSH=user
 
 
_WgetBash(){
   if [ $# -eq 1 ]; then
      local URL=$1
      wget --output-document - $URL | bash
   else
      echo Usage _WgetBash http://url/script
   fi
}
 
_CurlBash(){
   if [ $# -eq 1 ]; then
      local URL=$1
      curl $URL | bash -s --
   else
      echo Usage _WgetBash http://url/script
   fi
}
 
if [ $# -eq 1 ]; then
   EnderecoIP=$1
   ssh -p 7654 -l $UsuarioSSH -T $EnderecoIP < $Script
elif [ $# -eq 0 ]; then
   if [ "${Hostname}X" != "`hostname`X" ]; then
      if [ -x /usr/bin/wget ]; then
         _WgetBash $URLInstalaHTTP 2>/dev/null
      elif [ -x /usr/bin/curl ]; then
         _CurlBash $URLInstalaHTTP 2>/dev/null
      else
         echo wget/curl nao encontrado
      fi
   else
      echo Use Basename0 enderecoIP
   fi
fi
