# pip install nacos-sdk-python

import sys
import nacos

# service registration:
# curl -X POST 'http://127.0.0.1:8848/nacos/v1/ns/instance?serviceName=nacos.naming.serviceName&ip=20.18.7.10&port=8080'

# service discovery:
# curl -X GET 'http://127.0.0.1:8848/nacos/v1/ns/instances?serviceName=nacos.naming.serviceName'

# publish configuration
# curl -X POST "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test&content=HelloWorld"

# receive configuration
# curl -X GET "http://127.0.0.1:8848/nacos/v1/cs/configs?dataId=nacos.cfg.dataId&group=test"


# EOF
