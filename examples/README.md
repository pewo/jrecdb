# Examples

# On the client

On a systemd client machine you can install the "autopostinstall.service"
This will on every boot update the data on the Jrecdb server.
Please change the IP address in this service file

It is a simple command executed
<PRE>
/usr/bin/wget --no-check-certificate -O /dev/null -o /dev/null --quiet 'https://"dockerhost-ip-address":4443/dbwrite?jobtype=autopostinstall&sha1=0c0e8f420a05d1d5cf8200833d6ae4bb5761081c'
</PRE>

<PRE>
[Unit]
Description=Autopostinstallation
After=network.target 

[Service]
RemainAfterExit=true
ExecStart=-/usr/bin/wget --no-check-certificate -O /dev/null -o /dev/null --quiet 'https://"dockerhost-ip-address":4443/dbwrite?jobtype=autopostinstall&sha1=0c0e8f420a05d1d5cf8200833d6ae4bb5761081c'

[Install]
WantedBy=multi-user.target
</PRE>


# On some server ( i.e. ansible... )

Execute the autopostinstall.pl script. This script will try to download the data written by the client above.
The entry above is password protected by sha1, so the autopostinstall.pl has to have the cleartext version of the sha1.
The cleartext of the sha1 "0c0e8f420a05d1d5cf8200833d6ae4bb5761081c" is "mmGynTGXHa99SDUg"

The url in the autopostinstall.pl is 'https://"dockerhost-ip-address":4443/dbread?jobtype=autopostinstall&remove=1&sha1=mmGynTGXHa99SDUg'


The jobtype is the same as in the service file "autopostinstall"


