#import numpy as np
import sys

def calculate(files):
    total = 0
    total2 = 0
    
    for file_name in files:
        fp = open(file_name,"r")
        lines = fp.readlines()
        
        for i in range(0,2,2):
            lines[i] = lines[i].strip('\n')
            lines[i] = float(lines[i])
            lines[i+1] = int(lines[i+1])
        
        first_time = lines[0]
        total += lines[1]

        for i in range(2,len(lines),2):
            
            lines[i] = lines[i].strip('\n')
            lines[i] = float(lines[i])
            #print("time ",lines[i])

            if float(lines[i]-first_time) < 60.0:
                lines[i+1] = int(lines[i+1])
                total+=lines[i+1]
            elif float(lines[i]-first_time) < 120.0:
                lines[i+1] = int(lines[i+1])
                total2+=lines[i+1]
            else:
                break

    print("first min: ",total)
    print("second min: ",total2)

if __name__ == '__main__':
    calculate(sys.argv[1:])
