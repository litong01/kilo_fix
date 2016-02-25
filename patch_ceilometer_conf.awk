BEGIN { match_count = 0; }
{
   if (/\s*#/) { print;}
   else if (match_count == 1 && /\[*\]/) {
       ++match_count;
       print "dispatcher = http"; print "";
       print "[dispatcher_http]";
       print "target = " ep;
       print "cadf_only = true";
       print "";
       print "[consumer]";
       print "topic = qradar_bus";
       print "priority = info"
       print "requeue_on_error = false"
       print ""; print;
   }
   else if (/\[*\]/){
      ++match_count;
      print;
   }
   else if (/dispatcher/) { next;}
   else { print; }
}
