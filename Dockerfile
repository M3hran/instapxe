FROM alpine:3.12.0
# authoer: m3hran
#
# NOTE: If you bump the syslinux version here,
#       please also update the README.md.

ADD syslinux-6.04-pre2 /tftpboot

# Add safe defaults that can be overriden easily.
ADD instapxe_bios.cfg /tftpboot/bios/pxelinux.cfg/
ADD instapxe_uefi32.cfg /tftpboot/efi32/pxelinux.cfg/
ADD instapxe_uefi64.cfg /tftpboot/efi64/pxelinux.cfg/

# Support clients that use backslash instead of forward slash.
COPY mapfile /tftpboot/

# Do not track further change to /tftpboot.
VOLUME /tftpboot

# http://forum.alpinelinux.org/apk/main/x86_64/tftp-hpa
RUN apk add --no-cache tftp-hpa

EXPOSE 69/udp

RUN adduser -D tftp

COPY start /usr/sbin/start
ENTRYPOINT ["/usr/sbin/start"]
CMD ["-L", "--verbose", "-m", "/tftpboot/mapfile", "-u", "tftp", "--secure", "/tftpboot"]
