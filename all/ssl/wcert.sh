#!/bin/bash
#------------------------------------------------
# target: web site digital certificate kit
# author: junjiemars@gmail.com
#------------------------------------------------

function usage() {
  echo -e "Usage: $(basename $0) COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "Retrive or Extract digital certificate kit.\n"
  echo -e "Commands:"
  echo -e "\t-r|--retrive\t\tretrive the digital certificate from www.xyz.com:443"
  echo -e "\t-x|--eXtact\t\textract fields from the digital certificate"
}

case "$@" in
	-r*|--retrive=*)
		if [ $# -lt 2 ]; then
			usage	
		else
			openssl s_client -showcerts -connect $2 </dev/null 2>/dev/null \
				| openssl x509 -outform PEM > $3
		fi
		;;
	-x*|--extract=*)
		if [ $# -lt 2 ]; then
			usage
		else
			openssl x509 -in $2 -text -noout | less
		fi
		;;
	-h|--help|*)
		usage
		;;
esac

