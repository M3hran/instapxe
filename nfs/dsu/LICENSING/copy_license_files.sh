#!/bin/sh

echo "PWD = $PWD"
echo "Dollor 0 = $0";
cd `dirname $0`

LICENSE_DIR=license_files

if [ -d $LICENSE_DIR ]; then rm -rf $LICENSE_DIR; fi

# Copy the required files
mkdir $LICENSE_DIR
for file_type in LICEN COPY GPL LGPL; do
    for file in $(find . -name ${file_type}*); do
        dirname=`dirname $file`
        mkdir -p $LICENSE_DIR/$dirname;
        cp $file $LICENSE_DIR/$dirname -va;
    done
done

cd -
exit 0

