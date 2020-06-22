#!/usr/bin/python3
import requests
import json

from requests.packages.urllib3.exceptions import InsecureRequestWarning

requests.packages.urllib3.disable_warnings(InsecureRequestWarning)



try:
  r = requests.get('https://127.0.0.1:4443/dbread?jobtype=autopostinstall&remove=0', verify=False, timeout=3)
  r.raise_for_status()
except requests.exceptions.RequestException as err:
  raise SystemExit(err)

content = r.text
#print("content: ",content)

json_data = {}
for line in content.splitlines():
  #print("line: ", line)
  try:
    json_data = json.loads(line)
    break
  except:
    pass
    

for k in json_data:
    print(k, '->', json_data[k])

