#!/usr/bin/perl -w
use strict;
use aliased 'IO::Socket::INET';
use YAML;

my ($list) = @ARGV;
unless ($list) {
	print "Usage: $0 node_list\n";
	exit;
}

my @nodes = read_nodes();

foreach my $name (@nodes) {
	my $node = node($name);
	if (not defined $node->{s}) {
		print "CONNECT: $name, $!\n";
		next;
	}
	if (not defined $node->{node}) {
		print "PREAMBLE: $name\n";
		next;
	}
	my $data = query($node, 'fetch df');
	foreach (keys %$data) {
		printf("DF: %s %s %.02f\n", $name, $_, $data->{$_}) if $data->{$_} > 95;
	}
}

sub read_nodes {
	open(my $fh, 'nodes');
	my @list;
	while(my $node = <$fh>) {
		chomp $node;
		push @list, $node;
	}
	close $fh;
	return @list;
}

sub _node ($$) { return { node => $_[0], s => $_[1] } }

sub query {
	my ($node, $cmd) = @_;
	$node->{s}->print( $cmd . "\r\n");
	my $ret = {};
	while (my $line = $node->{s}->getline) {
		chomp $line;
		last if $line =~ /^\.$/;
		my ($k,$v) = ($line =~ /^(.+)\.value\s+(.*)$/);
		$k =~ s/\_/\//g;
		$ret->{$k} = $v;
	}
	return $ret;
}

sub node {
	my ($host, $port, $timeout) = @_;
	my $s = INET->new( PeerAddr => $host, PeerPort => ($port || 4949), Proto => 'tcp', Timeout => ($timeout || 5) ) or return _node(undef, undef);
	my $intro = <$s>;
	my $node;
	if (defined $intro && $intro =~ /at\s+(.+)$/) {
		$node = $1;
	}
	return _node $node, $s;
}
