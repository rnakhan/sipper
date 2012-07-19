#!/bin/awk -f
BEGIN {module="none:"; modarg=0;} 
/module/ { module = $2 ":"; modarg=ARGIND;}
/SipTestDriverController/ {
if (ARGIND != modarg)
{
   module = "none:";
}
gsub(/\r/, "", module);
gsub(/\n/, "", module);
name=$2;
gsub(/<.*/, "", name);

filename=ARGV[ARGIND]
gsub(/ /, "", filename);

print filename " " module name 
}
