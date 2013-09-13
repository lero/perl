#!/usr/bin/perl -X
## sysinfo displays some
## pretty well organized
## info. 'bout your machine.
## contact:
## arj_ @ irc.brasnet.org / #linuxnews
## arj@arj.yi.org or icq#22638227
## TODO:
## X server version
## More clean diskspace scan
## 
## IMPORTANT
## If you are not using a vga font or cp437 chars
## you must use sysinfo [OPTIONS] -n
## otherwise you'll see some strange symbols
## 
## THANKS
## to chsh (my friend and also my tester) ;]

## Default options, use sysinfo --help for a commented list
## Each letter has a diferent meaning
$my_options = "-kchmsDfbrdpuiv";

## Comma separated list of your net interfaces (e.g: eth0,ppp0,eth1,etc)
## If you leave it blank I will scan all up interfaces
$DEV = "eth0";

####################################################
#### do not change anything else mother fucker #####
####################################################

# just a lame help
$ARGV[0] = "" if (!$ARGV[0]);
if ($ARGV[0] eq "--help" || $ARGV[0] eq "-help") {
    print "sysinfo version 1.0 by arj_\n";
    print "Usage: sysinfo [--help] [-kchmsDfbrdpuivn]\n";
    print "default: sysinfo $options\n";
    print "  -k\tprint kernel information\n";
    print "  -c\tprint CPU model/MHz information\n";
    print "  -h\tprint system full hostname\n";
    print "  -m\tprint memory status\n";
    print "  -s\tprint swap partition status\n";
    print "  -D\tprint hard disk information\n";
    print "  -f\tprint mounted file systems\n";
    print "  -b\tprint cpu bogomips\n";
    print "  -r\tprint X screen resolution\n";
    print "  -d\tprint X screen depth\n";
    print "  -p\tprint proc info\n";
    print "  -u\tprint system uptime\n";
    print "  -i\tprint information about net interface(s)\n";
    print "  -v\tprint sysinfo (this program +_+) version\n";
    print "  -n\tdo not print box around text\n";
    exit(0);
}

$box = 1;
$options = "$my_options";

# i may have to use it sometime
$def_options = "-kchmsDfbrdpuiv";

# you didn't leave $my_options blank, did you ?
$options = "$def_options" if (!$my_options);

## are these options valid ?

# if you used any argument on the command line
# $options will now be overwriten
$options = "" if ($ARGV[0]);
foreach $i (0..$#ARGV) {
	$options = "$options$ARGV[$i] ";
}
$options=~s/-//g;
$options=~s/\ //g;

# $options is now known as $args
$args = "$options";

# taking valid options from $options
# leaving only unvalid options
$options=~s/[kchmsDfbrdpuivn]//g;

# if there are unvalid options, exit the program
if ($options) {
	print "sysinfo: invalid option -- " . substr($options, 0, 1);
	print "\n";
	exit(1);
}

chomp($args);
if ($args eq "n") {
	$args = "$my_options" if ($my_options);
	$args = "$def_options" if (!$my_options);
	$box = 0;
}

$box = 0 if ("$args" =~ /n/);

# if you left $DEV blank I will have to scan your up interfaces 
if (!$DEV) {
        # Too lazy to make a perl func to do this -- very simple sh :)
	$DEV=`echo -n \$(ifconfig | grep -v lo | cut -d\" \" -f1)`;
	$DEV=~s/ /,/g;
}

# If you set $DEV you might have left some blank spaces
# Let's remove it to avoid any trouble +_+
$DEV=~s/\ //g;
@DEV=split(",", $DEV);

## THIS IS THE MAIN WORK ;]

sub sys
{  
    # SYSINFO VER
    $SYSV = "\033[0;31msysinfo\033[0;0;0m: 1.0 by arj_";
    
    # UNAME
    chomp($UNAME = `uname -sr`);
    
    # MODEL
    open(INFO, "/proc/cpuinfo");
    while (<INFO>) {
        if ("$_" =~ /^model name/) {
                $_=~s/.*: //; chomp;
                $MODEL = "$_";
                close(INFO);
                last;
        }
    }

    # HOW MANY CPUS
    $NUM=0;
    open(INFO, "/proc/cpuinfo");
    while (<INFO>) {
        if ("$_" =~ /model name/) {
                $NUM++;
        }
    }
    close(INFO);
    
    # PROCESSOR SPEED
    open(INFO, "/proc/cpuinfo");
    while (<INFO>) {
        if ("$_" =~ /^cpu MHz/) {
                $_=~s/.*: //; chomp;
                $CPU = "$_";
                close(INFO);
                last;
        }
    }
    
    # PROCS RUNNING
    opendir(INFO, "/proc");
    $PROCS=0;
    foreach my $file (readdir(INFO)) {
        if ("$file" =~ /^[123456789]/) {
                $PROCS++;
        }
    }
    $PROCS--;
    closedir(INFO);

    # UPTIME
    open(INFO, "/proc/uptime");
    while (<INFO>) {
        chomp($UPTIME = "$_");
        close(INFO);
	last;
    }
    $UPTIME=~s/ .*//;
    $DAYS = sprintf ("%d", $UPTIME/(60*60*24));
    $HOURS = sprintf ("%.2d", $UPTIME/(60*60)%24);
    $MINUTES = sprintf ("%.2d", $UPTIME/60%60);
    $UPTIME = "$DAYS days $HOURS:$MINUTES hours";
    
    # Get all memory information
    open(INFO, "/proc/meminfo");
    while (<INFO>) {
        if ("$_" =~ /^Mem:/) {
                @temp = split(" ", "$_");
                close(INFO);
                last;
        }
    }
    # TOTAL MEMORY
    chomp($MEMTOTAL = "$temp[1]");
    $MEMTOTAL = $MEMTOTAL/1024/1024;
    $MEMTOTAL = sprintf ("%d", $MEMTOTAL);
    $MEMTOTAL = $MEMTOTAL."Mb";

    # FREE MEMORY
    chomp($MEMFREE = $temp[2]-($temp[5]+$temp[6]));
    $MEMFREE = $MEMFREE/1024/1024;
    $MEMFREE = sprintf ("%d", $MEMFREE);

    # PERCENTAGE OF FREE MEMORY
    chomp($MEMPERCENT = ($temp[2]-($temp[5]+$temp[6]))/$temp[1]*100);
    $MEMPERCENT = sprintf ("%d", $MEMPERCENT);

    # BARGRAPH OF MEMORY FREE
    $FREEBAR = int($MEMPERCENT/10);
    $MEMBAR = "\033[0;37m[\033[0;31m";
    for ( $x = 0; $x < 10; $x++ )
    {
        if ( $x eq $FREEBAR )
                {     
                $MEMBAR = "$MEMBAR\033[0;32m";
                }   
        $MEMBAR = "$MEMBAR\#";
    }
    $MEMBAR = "$MEMBAR\033[0;37m]\033[0;0;0m " . int($MEMPERCENT);
    $MEMBAR = "$MEMBAR%";

    # Get all swap memory information
    open(INFO, "/proc/meminfo");
    while (<INFO>) {
        if ("$_" =~ /^Swap:/) {
                @temp = split(" ", "$_");
                close(INFO);
                last;
        }
    }
    
    # TOTAL SWAP MEMORY
    chomp($SWAPTOTAL = "$temp[1]");
    $SWAPTOTAL = $SWAPTOTAL/1024/1024;
    $SWAPTOTAL = sprintf ("%d", $SWAPTOTAL);
    $SWAPTOTAL = $SWAPTOTAL."Mb";

    # FREE SWAP MEMORY
    chomp($SWAPFREE = $temp[2]);
    $SWAPFREE = $SWAPFREE/1024/1024;
    $SWAPFREE = sprintf ("%d", $SWAPFREE);

    # PERCENTAGE OF FREE SWAP MEMORY
    chomp($SWAPPERCENT = $temp[2]/$temp[1]*100);
    $SWAPPERCENT = sprintf ("%d", $SWAPPERCENT);

    # BARGRAPH OF SWAP FREE
    $SFREEBAR = int($SWAPPERCENT/10);
    $SMEMBAR = "\033[0;37m[\033[0;31m";
    for ( $x = 0; $x < 10; $x++ )
    {
        if ( $x eq $SFREEBAR )
                {
                $SMEMBAR = "$SMEMBAR\033[0;32m";
                }
        $SMEMBAR = "$SMEMBAR\#";
    }
    $SMEMBAR = "$SMEMBAR\033[0;37m]\033[0;0;0m " . int($SWAPPERCENT);
    $SMEMBAR = "$SMEMBAR%";

    # SCREEN RESOLUTION
    if ($ENV{DISPLAY}) {
    	$RES = `xdpyinfo | grep dimensions | awk '{print \$2}'`;
    	chomp ($RES);
    } else { $RES = "X server not running"; }

    # SCREEN DEPTH
    if ($ENV{DISPLAY}) {
    	$DEPTH = `echo \$(xdpyinfo | grep depth | grep root) | cut -d" " -f5`;
    	chomp ($DEPTH); $DEPTH = "$DEPTH bits";
    } else { $DEPTH = "X server not running"; }

    # DISKSPACE
    @temp = ();
    @temp = ();
    @df=`df`;
    foreach $i (0..$#df) {
        if ("$df[$i]" =~ /\//) {
                @temp = split(" ", $df[$i]);
                push(@devices, "$temp[5]");
        }
    }
    foreach $i (0..$#devices) {
        @temp = split(" ", `echo \$(df $devices[$i] | grep \"/\")`);
        push(@dft, "$temp[1]");
        push(@dff, "$temp[3]");
    }

    # Diskspace
    $HDD=0;
    foreach $i (0..$#dft) {
        $HDD = $HDD+$dft[$i];
    }
    $HDD = $HDD/1024;
    $HDD = $HDD/1024;
    $HDD = sprintf("%2.2f", $HDD)."GB";

    # Disk free space
    $HDDFREE=0;
    foreach $i (0..$#dff) {
        $HDDFREE = $HDDFREE+$dff[$i];
    }
    $HDDFREE = $HDDFREE/1024;
    $HDDFREE = $HDDFREE/1024;
    $HDDFREE = sprintf("%2.2f", $HDDFREE)."GB";
    chomp($HDD); chomp($HDDFREE);

    # FILESYSTEMS
    # MOUNTS
    open(INFO, "/proc/mounts");
    $FSN=0;
    $FS="";
    while (<INFO>) {
        if ("$_" =~ /^\// && "$_" !~ /^\/proc/) {
                @temp = split(" ", "$_");
                $FS="$FS$temp[2],";
                $FSN++;
        }
    }
    close(INFO); chop($FS);

    # BOGOMIPS
    open(INFO, "/proc/cpuinfo");
    while (<INFO>) {
        if ("$_" =~ /^bogomips/) {
                $_=~s/.*: //; chomp;
                $MIPS = "$_";
                close(INFO);
                last;
        }
    }
    
    # INTERFACES
    sub iface {
	$face = "$_[0]";
	$PACKIN = "0";
	$PACKOUT = "0";
        open(INFO, "/proc/net/dev");
        while (<INFO>) {
            if ("$_" =~ /$face/) {
                @temp = split(" ", "$_");
                @temp = split(" ", "$_");
		if ($temp[0] eq "$face:") {
                	chomp($PACKIN = "$temp[1]");
                	chomp($PACKOUT = "$temp[9]");
		} else {
			chomp($PACKIN = "$temp[0]");
			chomp($PACKOUT = "$temp[8]");
		}
                $PACKIN=~s/$face://g;
            }
        }
        # PACKETS IN
        $sufix = "B";
        $PACKIN = $PACKIN/1024, $sufix = "K" if ($PACKIN > 1024);
        $PACKIN = $PACKIN/1024, $sufix = "M" if ($PACKIN > 1024);
        $PACKIN = $PACKIN/1024, $sufix = "G" if ($PACKIN > 1024);
        $PACKIN = sprintf("%2.2f" , $PACKIN) if ($sufix ne "B");
        $PACKIN = $PACKIN."$sufix";

        # PACKETS OUT
        $sufix = "B";
        $PACKOUT = $PACKOUT/1024, $sufix = "K" if ($PACKOUT > 1024);
        $PACKOUT = $PACKOUT/1024, $sufix = "M" if ($PACKOUT > 1024);
        $PACKOUT = $PACKOUT/1024, $sufix = "G" if ($PACKOUT > 1024);
        $PACKOUT = sprintf("%2.2f" , $PACKOUT) if ($sufix ne "B");
        $PACKOUT = $PACKOUT."$sufix";

	# ADD TO TABLE
	push(@LINE, "$_[0]: In: $PACKIN Out: $PACKOUT");
    }
    # HOSTNAME
    chomp($HOST = `hostname`);

    # SUPPORT FOR DUAL PROCS
    unless($NUM eq 1) { $MODEL="Dual $MODEL"; }
    chomp ($MODEL);

    # NUMBER OF USERS
    chomp($USERS = `echo \$(finger | wc -l)`); $USERS--;

    # SHOW EVERYTHING IN A NICE BOX
    push(@LINE, "System: $UNAME") if ("$args" =~ /k/);
    push(@LINE, "$MODEL $CPU MHz") if ("$args" =~ /c/); 
    push(@LINE, "Hostname: $HOST") if ("$args" =~ /h/);
    push(@LINE, "Mem: $MEMFREE/$MEMTOTAL $MEMBAR") if ("$args" =~ /m/);
    push(@LINE, "Swap: $SWAPFREE/$SWAPTOTAL $SMEMBAR") if ("$args" =~ /s/);
    push(@LINE, "Disk: $HDD / Free: $HDDFREE") if ("$args" =~ /D/);
    push(@LINE, "Mounted: $FSN ($FS)") if ("$args" =~ /f/);
    push(@LINE, "Bogomips: $MIPS") if ("$args" =~ /b/);
    push(@LINE, "Screen Res: $RES") if ("$args" =~ /r/);
    push(@LINE, "Screen Depth: $DEPTH") if ("$args" =~ /d/);
    push(@LINE, "Procs: $PROCS / Users: $USERS") if ("$args" =~ /p/);
    push(@LINE, "Uptime: $UPTIME") if ("$args" =~ /u/);
    if ("$args" =~ /i/) {
	foreach $i (0..$#DEV) {
		iface($DEV[$i]);
	}
    }
    push(@LINE, "$SYSV") if ("$args" =~ /v/);
    $max_len = 0;

    # i had to get the length of the biggest 
    # line to align all other lines
    foreach $i (0..$#LINE) {
        # since colors count as chars I had to take them
	$text = "$LINE[$i]";
	$text=~s/\033\[0;31m//g;
        $text=~s/\033\[0;37m//g;
        $text=~s/\033\[0;32m//g;
        $text=~s/\033\[0;0;0m//g;
	$len = length($text);
	$max_len = $len if ($len > $max_len);
    }

    # prints "д" $max_len times if -n isin't in $args
    if ("$box" ne 0) {
	print "жд";
	foreach $i (0..$max_len) {
		print "д";
	}
	print "╥\n";
    }
    # add spaces to the end of line till $len is equal to $max_len
    foreach $i (0..$#LINE) {
        $text = "$LINE[$i]";
        $text=~s/\033\[0;31m//g;
        $text=~s/\033\[0;37m//g;
        $text=~s/\033\[0;32m//g;
        $text=~s/\033\[0;0;0m//g;
        $len = length($text);
	print "╨" if ("$box" ne 0);
	print " $LINE[$i]";
	$spaces = $max_len-$len;
	print " " x $spaces;
	print " ╨" if ("$box" ne 0);
	print "\n";
    }
    # prints "д" $max_len times if -n isin't in $args
    if ("$box" ne 0) {
	print "сд";
	foreach $i (0..$max_len) {  
		print "д";
    	}
        # closes box :)
        print "╫\n";
    }
    return 1;
}

# runs everything, don't ask me why
# i didn't put everything in the main scope
sys;
