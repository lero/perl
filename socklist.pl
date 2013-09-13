#!/usr/bin/perl

opendir (PROC, "/proc") || die "proc";
for $f (readdir(PROC)) {
    next if (! ($f=~/[0-9]+/) );
    if (! opendir (PORTS, "/proc/$f/fd")) {
        closedir PORTS;
        next;
    }
    for $g (readdir(PORTS)) {
        next if (! ($g=~/[0-9]+/) );
        $r=readlink("/proc/$f/fd/$g");

        ($dev,$ino)=($r=~/^(socket|\[[0-9a-fA-F]*\]):\[?([0-9]*)\]?$/);
	if ($dev == "[0000]" || $dev == "socket") {$sock_proc{$ino}=$f.":".$g;}
    }
    closedir PORTS;
}
closedir PROC;

print "type  port      inode     uid    pid   fd  name\n";
sub scheck {
	open(FILE,"/proc/net/".$_[0]) || die;
	while (<FILE>) {
	@F=split();
	next if ($F[9]=~/uid/);
	@A=split(":",$F[1]);
	$a=hex($A[1]);
	($pid,$fd)=($sock_proc{$F[9]}=~m.([0-9]*):([0-9]*).);
	$cmd = "";
	if ($pid && open (CMD,"/proc/$pid/status")) {
		$l = <CMD>;
		($cmd) = ( $l=~/Name:\s*(\S+)/ );
		close(CMD);
	}
	printf "%s %6d %10d  %6d %6d %4d  %s\n",
	$_[0], $a ,$F[9], $F[7], $pid, $fd, $cmd;
    }
    close(FILE);
}

scheck("tcp");
scheck("udp");
scheck("raw");
