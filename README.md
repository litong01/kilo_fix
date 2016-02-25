Instructions to setup OpenStack to send cadf messages to QRadar:

Clone this project to a directory by running the following command:

   git clone git://github.com/litong01/juno_fix.git

On nova api node::

   1.	Run sudo ./patch_nova.sh
   2.	Restart node api service.

On ceilometer node::

   1.	Get the QRadar http end point first
   2.	Run sudo ./patch_ceilometer.sh HttpEndpoint>
   3.	Start consumer service (this is new) by running this command:

   ceilometer-consumer –config-file /etc/ceilometer/consumer.conf

Checking keystonemiddleware juno is installed. If not, you have to
install it.

Note: The scripts change few files . For each file changed the script
make backup by attaching suffix “.back” to the original name and place
them in the same directory where the original file is. If you want to
make similar changes to Cinder, Neutron or Glance, please make copy of
patch_nova.sh and make changes to it  so that the scripts will work for
patching Cinder, Neutron and Glance.

If everything is running OK, then you have completed the OpenStack
side of work and you can move on to QRadar configuration.

