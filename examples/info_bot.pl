#!/usr/bin/perl -w

use strict;
use warnings;

use lib '../lib';

sub POE::Kernel::ASSERT_DEFAULT () { 1 }
use POE qw(Component::IRC Component::IRC::Plugin::CPAN::Info);

my @Channels = ( '#zofbot' );

my $irc = POE::Component::IRC->spawn( 
        nick    => 'CPAN2_',
        server  => 'irc.freenode.net',
        port    => 6667,
        ircname => 'CPAN module information bot',
) or die "Oh noes :( $!";

POE::Session->create(
    package_states => [
        main => [
            qw(
                _start
                irc_001
                _default
                cpaninfo_got_info
                cpaninfo_no_result
                cpaninfo_response
            )
        ],
    ],
);


$poe_kernel->run();

sub _start {
    $irc->yield( register => 'all' );
    
    # register our plugin
    $irc->plugin_add(
        'CPANInfo' => 
            POE::Component::IRC::Plugin::CPAN::Info->new( debug => 1,
            max_modules_limit => 1000)
    );
    
    $irc->yield( connect => { } );
    undef;
}

sub irc_001 {
    my ( $kernel, $sender ) = @_[ KERNEL, SENDER ];
    $kernel->post( $sender => join => $_ )
        for @Channels;
    $kernel->post( $sender => privmsg => 'NickServ' => 'identify se3P4nG0dn4ss!!!');
    undef;
}

sub cpaninfo_got_info {
    print "\nGot CPAN info at " . localtime $_[ARG0] . "\n";
}
use Data::Dumper;
sub cpaninfo_no_result {
    print Dumper($_[ARG0]);
}
sub cpaninfo_response {
    print Dumper($_[ARG0]);
}

sub _default {
    my ($event, $args) = @_[ARG0 .. $#_];
    return
        if $event =~ /^irc_(332|333|37[26]|25[124])/;
        
    my @output = ( "$event: " );

    foreach my $arg ( @$args ) {
        if ( ref($arg) eq 'ARRAY' ) {
                push( @output, "[" . join(" ,", @$arg ) . "]" );
        } else {
                push ( @output, "'$arg'" );
        }
    }
    print STDOUT join ' ', @output, "\n";
    return 0;
}