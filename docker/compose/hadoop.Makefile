
start-hadoop-single-node: hadoop/hadoop-single-node.yaml
	docker-compose -f $< up -d

exec-hadoop-single-node: start-hadoop-single-node
	docker exec -e LINES=$(LINES) \
							-e COLUMNS=$(COLUMNS) \
							-e TERM=$(TERM) \
							-e OPT_LAB=$(OPT_LAB) \
							-e M2_DIR=$(M2_DIR) \
							-it -u u \
							hadoop-single-node-dev /bin/bash

stop-hadoop-single-node: hadoop/hadoop-single-node.yaml
	docker-compose -f $< stop

rm-hadoop-single-node: hadoop/hadoop-single-node.yaml stop-hadoop-single-node
	docker-compose -f $< rm --force

config-hadoop-single-node: hadoop/hadoop-single-node.yaml
	docker-compose -f $< config


.PHONY: start-hadoop-single-node \
				stop-hadoop-single-node \
				exec-hadoop-single-node \
				rm-hadoop-single-node \
				config-hadoop-single-node
