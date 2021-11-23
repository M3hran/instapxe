#!/bin/bash
glabels-3-batch -i /instapxe/print_server/labeldata.csv -o /instapxe/print_server/label.pdf /instapxe/print_server/template.glabels 
for (( n=0; n<2; n++ ))
do
	lp -d dymo -o media=w79h252 -o orientation-requested=4 -o cpi=13 -o page-left=12 -o page-top=12 /instapxe/print_server/label.pdf 
done
