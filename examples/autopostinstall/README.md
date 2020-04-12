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

The autopostinstall.pl will create an temporary inventory file and execute autopostinstall.pl.sh for each client it finds on the jrecdb server.

An example of autopostinstall.pl.sh

<PRE>
#!/bin/sh

echo "Starting $0"
echo "Env"
env | grep ^JRECDB
echo "Args: $*"

for playbook in postinstall.yml site.yml prodinstall.yml; do
   ANSIBLE_PLAYBOOK="ansible-playbook $playbook ";

   if [ ! -z ${JRECDB_INVENTORY} ]; then
      ANSIBLE_PLAYBOOK="$ANSIBLE_PLAYBOOK -i $JRECDB_INVENTORY"
   fi

   if [ ! -z ${JRECDB_CLIENT} ]; then
      ANSIBLE_PLAYBOOK="$ANSIBLE_PLAYBOOK -l $JRECDB_CLIENT"
   fi
   echo $ANSIBLE_PLAYBOOK
done

echo "Done $0"
</PRE>

## Detailed output
autopostinstall.pl --debug

This will give you more logs then you wants

# Example output with --debug
<PRE>
% ./autopostinstall.pl --debug
DEBUG(1,1,Jrecdb::new:88): setting ansible=[./autopostinstall.pl.sh]
DEBUG(1,1,Jrecdb::new:88): setting logdir=[/tmp/loggy.d/autopostinstall/2020/04/12]
DEBUG(1,1,Jrecdb::new:88): setting debug=[1]
DEBUG(1,1,Jrecdb::new:88): setting jobtype=[autopostinstall]
DEBUG(1,1,Jrecdb::new:88): setting url=[https://10.0.0.254:4443/dbread?jobtype=autopostinstall&remove=1&sha1=mmGynTGXHa99SDUg]
DEBUG(1,1,Jrecdb::doit:138): Job number 1 is starting
DEBUG(1,1,Jrecdb::dojob:162): tmpdir: /tmp/mEvXW3zK1Y
DEBUG(1,1,Jrecdb::dojob:185): Created log at /tmp/loggy.d/autopostinstall/2020/04/12/autopostinstall.82OyY.log
DEBUG(1,1,Jrecdb::dojob:194): Creating inventory at /tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory
DEBUG(1,1,Jrecdb::dojob:221): ./autopostinstall.pl.sh 
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_CLASS=linux
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_CLIENT=10.0.0.10
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_JOBTYPE=autopostinstall
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_LOCALTIME=1586707494
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_RECORD=1
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_SHA1=0c0e8f420a05d1d5cf8200833d6ae4bb5761081c
DEBUG(1,1,Jrecdb::dojob:234): Setting ENV JRECDB_TIME=1586707483
DEBUG(1,1,Jrecdb::dojob:236): Setting ENV JRECDB_INVENTORY=/tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory
DEBUG(1,1,Jrecdb::dojob:238): Setting ENV JRECDB_PROGRAM=./autopostinstall.pl.sh
DEBUG(1,1,Jrecdb::dojob:267): Appending log at /tmp/loggy.d/autopostinstall/2020/04/12/autopostinstall.82OyY.log
DEBUG(1,1,Jrecdb::doit:140): Job number 1 is done
</PRE>

# And the logfile of the execution above
% cat /tmp/loggy.d/autopostinstall/2020/04/12/autopostinstall.82OyY.log
<PRE>
Starting ./autopostinstall.pl at Sun Apr 12 18:04:54 2020

Inventory at /tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory
[autopostinstall]
10.0.0.10

Command:
./autopostinstall.pl.sh 

--- Output start ---

Starting ./autopostinstall.pl.sh
Env
JRECDB_INVENTORY=/tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory
JRECDB_CLIENT=10.0.0.10
JRECDB_RECORD=1
JRECDB_CLASS=linux
JRECDB_PROGRAM=./autopostinstall.pl.sh
JRECDB_TIME=1586707483
JRECDB_JOBTYPE=autopostinstall
JRECDB_SHA1=0c0e8f420a05d1d5cf8200833d6ae4bb5761081c
JRECDB_LOCALTIME=1586707494
Args: 
ansible-playbook postinstall.yml -i /tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory -l 10.0.0.10
ansible-playbook site.yml -i /tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory -l 10.0.0.10
ansible-playbook prodinstall.yml -i /tmp/mEvXW3zK1Y/autopostinstall.5mzd0.inventory -l 10.0.0.10
Done ./autopostinstall.pl.sh

--- Output end ---

Runtime: 0 seconds

Done ./autopostinstall.pl at Sun Apr 12 18:04:54 2020

</PRE>
   

