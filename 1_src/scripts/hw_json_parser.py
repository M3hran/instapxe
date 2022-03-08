#! /usr/bin/python3

import json,re,collections
filename = 'sample.txt'
dict1= {}
data = collections.defaultdict(list)

with open(filename) as fh:


    for line in fh:
        
        if not re.match(r'[ \s]', line):
            component = line.splitlines()[0] 
        
        else:
            if line != "\n":
                kv =  line.strip().split(":",1)
                
                if len(kv) == 2:
                    dict1[kv[0]]=kv[1].strip()
                else:
                    if dict1[[*dict1.keys()][-1]]=="":
                        dict1[[*dict1.keys()][-1]]= dict1[[*dict1.keys()][-1]] + line.strip()
                    else:
                        dict1[[*dict1.keys()][-1]]= dict1[[*dict1.keys()][-1]] + ", " + line.strip()
            else:
                data[component].append(dict1)
                dict1= {}

out_file= open("hw.json", "w")
json.dump(data, out_file, indent = 4)
print(json.dumps(data))
