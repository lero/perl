#!/usr/bin/perl
# adf version 0.2.3
# Copyright (c) 2001 by arj_
# arj_: #22638227 irc.brasnet.org #linuxnews
# Thanks to ntp <ntp@brasnet.org>
# Thanks to acidx <leandro@linuxmag.com.br>

# usage bar color 
# you can also comment this line, cool effect
$barcolor = "\033[0;34;44m";

# background of usage bar - recommended: white 
# you can also comment this line, cool effect 
$bbarcolor = "\033[0;37;47m";

# text colors 
$color1 = "\033[1;36m";
 
# separators colors (, ), /, :
$color2 = "\033[1;34m";

# default options
# showp=percentage, showd=diskusage
# showm=mountpoint, showa=availablespace
# set it to "on" to activate 
$showp = "on";
$showm = "off";
$showd = "on";
$showa = "off";
$showt = "on";
  
# graph bar size, default is 30 
$barsize = "30";

###########################################################################
# DON'T CHANGE ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING #
###########################################################################

$ncolor = "\033[0;0;0m";
$comparer = "on";
chomp($prognm = `basename $0`);

if ($showa ne "on") { $showa = ""; }
if ($showd ne "on") { $showd = ""; }
if ($showm ne "on") { $showm = ""; }
if ($showp ne "on") { $showp = ""; }

sub adfver() {
  print "adf version 0.2.3 release\n";
  print "Copyright (c) 2001 by arj_ <icq# 22638227>\n";
  print "Thanks to ntp <ntp\@brasnet.org>\n";
  print "Thanks to acidx <leandro\@linuxmag.com.br>\n";
  exit 0;
}

sub adfhelp() {
  print "Copyright (c) 2001 by arj_\n";
  print "version 0.2.3 release\n";
  print "$prognm [-a] [-d] [-m] [-p] [-t] [-s] [-b size] [-h] [-v]\n\n";
  print "  -a\t\t show available space\n";
  print "  -d\t\t show disk usage\n";
  print "  -m\t\t show mount point\n";
  print "  -p\t\t show percentage\n";
  print "  -t\t\t show fsystem type\n";
  print "  -s\t\t short device names\n";
  print "  -b(size)\t set bar size\n";
  print "  -h\t\t this help screen\n";
  print "  -v\t\t version and author informations\n\n";
  print "any other argument from the command line will be passed to
df, e.g: ./adf /dev/hda1 will print information about /dev/hda1\n";
  exit 0;
}

sub gettype {
  $tmptype = "";
  @tmptype = `df -T $_[0]`;
  for $a (0..$#tmptype) {
    if ($tmptype[$a] =~ /$_[0]/) {
	@argstype=split(/ /, `echo $tmptype[$a]`);
    }
  }
  return "$argstype[1]";
}

for $i (0..$#ARGV) {
    if ($ARGV[$i] eq "-a") { $showa = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-d") { $showd = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-m") { $showm = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-p") { $showp = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-t") { $showt = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-T") { $showt = "1"; $comparer = "1"; }
    if ($ARGV[$i] eq "-s") { $shows = "on"; }
    if ($ARGV[$i] eq "--print-type") { $showt = "1"; $comparer = "1"; }
    if ($ARGV[$i] =~ /^-b/) {
        $temp = "";
        $temp = "$ARGV[$i]";
        $temp=~s/-b//g;
        if ($temp eq "") { die("usage ./adf -b(size)\ne.g: ./adf -p -m -b30\n"); }
        if (!int($temp)) { die("$temp is not a valid number\n"); }
        if ($temp < 15) { die("barsize must be greater than 15\n"); }
        $barsize = "$temp";
    }
    if ($ARGV[$i] eq "-h") { adfhelp(); }
    if ($ARGV[$i] eq "-help") { adfhelp(); }
    if ($ARGV[$i] eq "-v") { adfver(); }
    if ($ARGV[$i] eq "-version") { adfver(); }
    if ($ARGV[$i] ne "-a" && $ARGV[$i] ne "-d" && $ARGV[$i] ne "-m"
    && $ARGV[$i] ne "-p" && $ARGV[$i] !~ /^-b/ && $ARGV[$i] ne "-h"
    && $ARGV[$i] ne "-t" && $ARGV[$i] ne "-T" && $ARGV[$i] ne "--print-type"
    && $ARGV[$i] ne "-help" && $ARGV[$i] ne "-v" && $ARGV[$i] ne "-version"
    && $ARGV[$i] ne "-s")
    { if (!$parms) { $parms = "$ARGV[$i]"; } else { $parms = "$parms $ARGV[$i]"; } }
}

@df = `df -h $parms`;

for ($i = 0; $i <= $#df; $i++) {
  if ($df[$i] =~ /\// && $df[$i] !~ /^none/) {
    chomp($temp = "$df[$i]"); $temp=~s/%//g; 
    @args=split(/ /, `echo $temp`);
    chomp($device = "$args[0]");
    chomp($total = "$args[1]");
    chomp($used = "$args[2]");
    chomp($avail = "$args[3]");
    chomp($perc = "$args[4]");
    chomp($mount = "$args[5]");
    if ($showt eq $comparer) { $type = ""; chomp($type = gettype("$mount")); }
    if (!$mount && !$total && !$used && !$avail && !$perc) { 
      chomp($temp = "$df[$i+1]"); $temp=~s/%//g;
      @args=split(/ /, `echo $temp`);
      chomp($total = "$args[0]");
      chomp($used = "$args[1]");
      chomp($avail = "$args[2]");
      chomp($perc = "$args[3]");
      chomp($mount = "$args[4]");
      $i = $i+1;
      reset;
    } 
    $full = int($perc * ($barsize)/100);
    $empty = $barsize-$full;
    if ($shows eq "on") { chomp($device = `basename $device`); }
    print "$color1$device$color2:\t"; print "$barcolor";
    print "#" x $full . $bbarcolor . "." x $empty; print "$ncolor ";
    if ($showp eq $comparer && $perc < 10) { print "$color2($color1$perc%  $color2)$ncolor "; }
    if ($showp eq $comparer && $perc > 9 && $perc < 100) { print "$color2($color1$perc% $color2)$ncolor "; }
    if ($showp eq $comparer && $perc > 99) { print "$color2($color1$perc%$color2)$ncolor "; }
    if ($showd eq $comparer) { print "$color2($color1$used$color2/$color1$total$color2)$ncolor "; }
    if ($showa eq $comparer) { print "$color2($color1$avail$color2)$ncolor "; }
    if ($showm eq $comparer) { print "$color2($color1$mount$color2)$ncolor "; }
    if ($showt eq $comparer) { print "$color2($color1$type$color2)$ncolor "; }
    print "$ncolor\n";
  }
}
