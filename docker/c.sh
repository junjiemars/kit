CONTAINER_ID=${CONTAINER_ID:-"<container-id>"}
SH_NAME=`basename $0`
HELP="usage:\t$SH_NAME <start|stop|logs>"

case ".$1" in
    .start) docker start $CONTAINER_ID;;
    .stop) docker stop $CONTAINER_ID;;
    .logs) docker logs $CONTAINER_ID;;
    .) echo -e $HELP;;
esac

