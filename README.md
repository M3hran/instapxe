## Quick reference:

Maintained by: m3hran ( instaPXE member)

## Where to get help: 
https://instapxe.com/docs

## Where to file issues: 
https://instapxe.com/contact

## What is instaPXE? 
InstaPXE is a Preboot eXecution Environment needed to boot client systems from a network repository instead of classical local storage or media (SD/SSD/HDD/USB/DVD).

## How to use this image? 
Use like you would any other base image:

## Usage:
docker run -p 69:69 instapxe/instapxe:latest -v ./bootfiles:/instapxe/boot -v ./menufiles/mybios.menu:/instapxe/instapxe.menu -v ./menufiles/myuefi.menu:/instapxe/instapxe.menu64

## License: 
View license information for the software contained in this image. https://instapxe.com/eula

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
