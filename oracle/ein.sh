
#!/bin/bash
#------------------------------------------------
# author: junjiemars@gmail.com
# target: SQL*Plus Kits
# note: suit for multiple Oracle coexisting env
#------------------------------------------------



PREFIX=${PREFIX:-"ein"}

TABLE_LIST=${TABLE_LIST:-"table.lst"}
NUMBER=${NUMBER:-100}

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
		mkdir -p $PREFIX
	fi
}

nl2c() {
	local c=`cat $1 | tr -d ' ' | tr '\n' "$2"`
	echo ${c[@]%$2}
}

out_filename() {
	echo "${PREFIX%/}/$1$2"
}

exp() {
	check_list_file $TABLE_LIST
	check_ei_dir $PREFIX	

	local t_list=( $(nl2c $TABLE_LIST "\ ") )
	
	for t in ${t_list[@]};do 
		exp.sh $USERID \
			tables=$t \
			file=$(out_filename $t '.dmp') \
			log=$(out_filename $t '.log') \
			indexes=y \
			query=\"where rownum \<= $NUMBER\"
	done	
	
	cp $TABLE_LIST $PREFIX
}

imp() {
	if [ ! -d $PREFIX ]; then
		echo "$PREFIX no found, where are dmp files?"
		exit 1
	fi

	check_list_file ${PREFIX%/}/$TABLE_LIST

	local t_list=( $(nl2c ${PREFIX%/}/$TABLE_LIST "\ ") )

	for t in ${t_list[@]}; do
		local dmp=$(out_filename $t '.dmp')	
		if [ -f $dmp ]; then
			imp.sh $USERID \
				file=$dmp \
				fromuser=$E_USER \
				touser=$I_USER \
				log=$(out_filename $t '_imp.log') \
				ignore=y
		fi
	done
}
	
usage() {
  echo -e "Usage: $(basename $0) [OPTIONS] COMMAND [arg...]"
  echo -e "       $(basename $0) [ -h | --help ]\n"
  echo -e "Options:"
  echo -e "  -h, --help\t\tPrint usage"
  echo -e "Exp/Imp oracle tables with specified Number.\n"
  echo -e "Commands:"
  echo -e "\texp\t\tExport oracle objects"
  echo -e "\timp\t\tImport oracle objects"
  echo -e "Environemnt Variables:"
	echo -e "\tPREFIX=$PREFIX"
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
