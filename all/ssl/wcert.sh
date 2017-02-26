#!/bin/bash
#------------------------------------------------
# target: web site digital certificate kit
# author: junjiemars@gmail.com
#------------------------------------------------

function usage() {
  echo -e "Usage: $(basename $0) COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help | -v | --version ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\t\t\tPrint this message"
  echo -e "A digital certificate retriving/extract kit.\n"
  echo -e "Commands:"
  echo -e "\t-r=|--retrive=<host:port>\tretrive digital certificate"
  echo -e "\t-x=|--extact=<where-pem>\teXtract fields from digital certificate"
}

case "$@" in
	-r=*|--retrive=*)
		KIT_RETRIVE="${@#*=}"
		if [ -z "$KIT_RETRIVE" ]; then
			usage	
			exit 1
		else
			openssl s_client -showcerts -connect $KIT_RETRIVE </dev/null 2>/dev/null \
				| openssl x509 -outform PEM 
		fi
		;;
	-x*|--extract=*)
		KIT_EXTRACT="${@#*=}"
		if [ -z "$KIT_EXTRACT" ]; then
			usage
			exit 1
		else
			openssl x509 -in $KIT_EXTRACT -text -noout
		fi
		;;
	-h|--help|*)
		usage
		exit 1
		;;
esac

