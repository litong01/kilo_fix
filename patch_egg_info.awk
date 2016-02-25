BEGIN { match_count = 0; FS = "="; }
{
   if (/\s*#/) { print;}
   else if (console == 1) {
      if (/\[*\]/) {
         print "ceilometer-consumer = ceilometer.cmd.consumer:main"; 
         print "";
         print;
         ++console;
      }
      else if (/ceilometer-consumer = /) { next;}
      else {print;}
   }
   else if (dispatcher == 1) {
      if (/\[*\]/) {
         print "http = ceilometer.dispatcher.http:HttpDispatcher";
         print "";
         print;
         ++dispatcher;
      }
      else if (/http = ceilometer/) { next;}
      else {print;}
   }
   else if (/\[console_scripts\]/){
      console = 1;
      print;
   }
   else if (/\[ceilometer.dispatcher\]/){
      dispatcher = 1;
      print;
   }
   else { print; }
}
