BEGIN { match_count = 0; FS = "="; }
{
   if (/\s*#/) { print;}
   else if (match_count == 1 && /\[*\]/) {
       if (topics) { 
          print "notification_topics = " topics ",qradar_bus";
       }
       else {
          print "notification_topics = notifications,qradar_bus"; 
       }
       print "";
       print;
       ++match_count;
   }
   else if (/\[DEFAULT\]/){
      match_count = 1;
      print;
   }
   else if (/notification_topics/) {
      topics = $2;
   }
   else { print; }
}
