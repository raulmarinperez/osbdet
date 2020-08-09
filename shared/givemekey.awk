#!/bin/awk -f
BEGIN {
  pub_flag=0; key=0;
  
  # A pattern must be provided via command line
  if (pattern=="") {
    print "Error: pattern input variable not provided."
    print
    print "awk -v pattern=yourpattern"
    exit;
  }
}
{
  # For every entry, get key (next line) and check it connects to the patter (next line)
  if (index($0, "pub ") > 0) {
    pub_flag=1;
  } else if (pub_flag==1) {
    pub_flag=0; key=$0;
  } else if (key!=0) {
    if (index($0, pattern) > 0) {
      exit;
    }
    key=0;
  }
}
END {
# end, now output the total
  if (pattern!="" && key!=0) 
    print key;
  else if (pattern!="" && key==0) 
    print "Key not found";
}
