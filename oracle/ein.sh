
#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------



TABLE_LIST=${TABLE_LIST:-"table_list"}
NUMBER=${NUMBER:-100}

EI_PREFIX=${EI_PREFIX:-"ein"}

USERID=${USERID:-"system/oracle@localhost:1521/XE"}
E_USER=${EUSER:-`echo $USERID | sed 's#\([_a-zA-Z0-9]*\)\/.*#\1#'`}
I_USER=${IUSER:-$E_USER}

check_list_file() {
	if [ ! -f $1 ]; then
		echo "$1 no found, stop!"
		exit 1
	fi	
}

check_ei_dir() {
	if [ ! -d $1 ]; then
		echo "$1 no found, create ..."
		mkdir -p $1
	fi
}

nl2c() {
	local c=`cat $1 | tr -d ' ' | tr '\n' ' '`
	echo ${c[@]%,}
}

exp() {
	check_list_file $TABLE_LIST
	check_ei_dir $EI_PREFIX	

	local declare -a t_list=( $(nl2c $TABLE_LIST) )
	
	for t in ${t_list[@]};do 
		exp.sh $USERID \
			tables=$t \
			file=${EI_PREFIX%/}/${t}.dmp \
			log=${EI_PREFIX%/}/${t}.log\
			indexes=y \
			query=\"where rownum \<= $NUMBER\"
	done	
}

imp() {
	check_list_file $TABLE_LIST
	if [ ! -d $EI_PREFIX ]; then
		echo "$EI_PREFIX no found, where are dmp files?"
		exit 1
	fi

	for f in `find $EI_PREFIX -maxdepth 1 -type f -name '*.dmp'`; do
		imp.sh $USERID \
			file=$f \
			fromuser=$E_USER \
			touser=$I_USER \
			log=${f}_imp.log \
			ignore=y
	done
}
	
usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage\n"
  echo -e "Exp/Imp oracle tables with specified Number.\n"
  echo -e "Commands:"
  echo -e "\texp\t\tExport oracle objects"
  echo -e "\timp\t\tImport oracle objects\n"
  echo -e "Environemnt Variables:"
	echo -e "\tTABLE_LIST=$TABLE_LIST"
	echo -e "\tNUMBER=$NUMBER"	
	echo -e "\tUSERID=$USERID"
	echo -e "\tE_USER=$E_USER"
	echo -e "\tI_USER=$I_USER"
}

case ".$@" in
  .exp) exp ;;
  .imp) imp ;;
  .-h|.--help) usage ;;
  .*) usage ;;
esac
