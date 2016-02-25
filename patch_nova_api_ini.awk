BEGIN { FS = "="; }
{
   if (/\s*#/) { print;}
   else {
      if (/\[*\]/) {
         if (/\[composite:openstack_compute_api_v[1-3]+\]/) {
            sec_id = 1;
            print;
         }
         else if (/\[filter\:audit\]/) {
            sec_id = 2;
            next;
         }
         else {
            sec_id = 0;
            print;
         }
      }
      else if (sec_id == 0) { print; }
      else if (sec_id == 1) {
         if (/keystone = / || /keystone_nolimit = /) {
            n = split($2, values, " ");
            values[n] = "audit " values[n];
            new_value = $1 "=";
            for (x = 1; x <= n; x++) {
               if (values[x] != "audit") {
                  new_value = new_value " " values[x];
               }
            }
            print new_value;
         }
         else {
            print;
         }
      }
      else if (sec_id == 2) { next; }
   }
}
END {
   print "";
   print "[filter:audit]"; 
   print "paste.filter_factory=keystonemiddleware.audit:filter_factory";
   print "audit_map_file = /etc/nova/api_audit_map.conf";
   print "";
}