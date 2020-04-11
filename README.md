# jrecdb
Simple Json RECord DataBase

This is a simple tool to save som data on a webserver and be able to collect it from another server
My primary objective is to automate postinstallation tasks using ansible

This is not completed yet, but the server side is almost there.


# Create and start the docker container

% cd docker && docker-compose up -d --build

# Save som data

From some client point your browser to
https://your-dockerhost-ip:4443/dbwrite?command=autopostinstall
We assume that your client ip address is 192.168.1.10
The resulting page should look like:
<PRE>
{
   "client" : "192.168.1.10",
   "command" : "autopostinstall",
   "time" : 1586601089
}
</PRE>
  
# Read the data
From another ( or the same client ) point your browser to
https://your-dockerhost-ip:4443/dbread?command=autopostinstall
The resulting page should look like:
<PRE>
{"time":1586601089,"record":1,"client":"192.168.1.10","command":"autopostinstall"}
</PRE>
 
# Some features

From the client who is writing some data ( /dbwrite?... )
You can add some special arguments

# secret|password
This saves a clear text password in the database which is required to read the data 
https://your-dockerhost-ip:4443/dbwrite?command=autopostinstall&password=mysecretpassword

To read the data again, you have to specify the same password
https://your-dockerhost-ip:4443/dbread?command=autopostinstall&password=mysecretpassword

# sha1|md5
This saves an encrypted password in the database which is required to read the data 
https://your-dockerhost-ip:4443/dbwrite?command=autopostinstall&sha1=043cbda32fa05b7db969b63431d8eab73d36426c

To read the data again, you have to specify the corresponding clear text password
https://<your-dockerhost-ip>:4443/dbread?command=autopostinstall&sha1=bepa
  
If the password is incorrect, you can't retreive the data.

From the client who is reading the data ( /dbread?... )
You can add some special arguments
# remove
This will remove the selected record after been read.
https://your-dockerhost-ip:4443/dbread?command=autopostinstall&sha1=bepa&remove=1


# Create sha1/md5 tokens
https://your-dockerhost-ip:4443/digest?md5=bepa&sha1=bepa
<PRE>
{
   "sha1" : "bepa",
   "md5" : "bepa",
   "sha1_hex" : "043cbda32fa05b7db969b63431d8eab73d36426c",
   "md5_hex" : "0043420cc320fd84d1b05886d177560a"
}
</PRE>



