#!/bin/bash
glabels-3-batch -i labels.csv -o test.pdf template.glabels
lp -d dymo -o media=w79h252 -o orientation-requested=4 -o cpi=13 -o page-left=12 -o page-top=12 test.pdf 
