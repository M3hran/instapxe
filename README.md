# Quick reference: 
-  **Maintained by:** m3hran ( instaPXE member )
-  **Where to get help:** https://instapxe.com
- **Where to file issues:** https://instapxe.com/contact

# What is instaPXE? 
InstaPXE is a network management, automation, monitoring, operating tool suite of tools, platform based on "Preboot eXecution Environment" layer, needed to send instructions to boot clients from a network/cloud repository instead of local. (reknown as MaaS)


![logo](https://github.com/M3hran/instapxe/blob/main/http/instapxe_agent/site-logo-color.png)


## How to use this image? 
Use like you would any other image:


```console
$ docker run -p 69:69 \
-v ./bootfiles:/instapxe/boot \
-v ./menufiles/mybios.menu:/instapxe/instapxe.menu \
-v ./menufiles/myuefi.menu:/instapxe/instapxe.menu64 \
instapxe/instapxe:latest
```
### Ports:
- 69                     
 this port is used for netboot/pxe access

### Volumes:  
- /instapxe/boot                               
 place your kernel files to boot from in here
- /instapxe/instapxe.menu              
map your bios menu here
- /instapxe/instapxe.menu32          
map your uefi32 menu here if any
- /instapxe/instapxe.menu64          
map your uefi64 menu here if any

### Environment Variable:
- HTTP_HOST=x.x.x.x                
   you can set this variable to IP address of the HTTP host and use $HTTP_HOST variable in your menu to serve files via HTTP

- NFS_HOST=x.x.x.x                   
  you can set this variable to IP address of the NFS host and use $NFS_HOST variable in your menu to serve files via NFS

### Dependencies: (external setup) 
- DHCP (required)
- HTTP (optional)
- NFS (optional)


# License: 
This image is free for non-commercial use. View license information for the software contained in this image. https://instapxe.com/eula

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
