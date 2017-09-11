package MyAgent;

use base 'LWP::UserAgent';

package ZoneMinder::Control::IPROBOT3;

use 5.006;
use strict;
use warnings;

require ZoneMinder::Base;
require ZoneMinder::Control;

our @ISA = qw(ZoneMinder::Control);

our $VERSION = $ZoneMinder::Base::VERSION;

# ==========================================================================
#
# Tenvis IPROBOT3 IP Control Protocol
#
# ==========================================================================

use ZoneMinder::Logger qw(:all);
use ZoneMinder::Config qw(:all);

use Time::HiRes qw( usleep );

sub new {
    my $class        = shift;
    my $id           = shift;
    my $self         = ZoneMinder::Control->new($id);
    my $logindetails = "";
    bless( $self, $class );
    srand( time() );
    return $self;
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self  = shift;
    my $class = ref($self) || croak("$self not object");
    my $name  = $AUTOLOAD;
    $name =~ s/.*://;
    if ( exists( $self->{$name} ) ) {
        return ( $self->{$name} );
    }
    Fatal("Can't access $name member of object of class $class");
}
our $stop_command;

sub open {
    my $self = shift;

    $self->loadMonitor();

    $self->{ua} = MyAgent->new;
    $self->{ua}->agent("ZoneMinder Control Agent/");

    $self->{state} = 'open';
}

sub close {
    my $self = shift;
    $self->{state} = 'closed';
}

sub printMsg {
    my $self    = shift;
    my $msg     = shift;
    my $msg_len = length($msg);

    Debug( $msg . "[" . $msg_len . "]" );
}

sub sendCmd {
    my $self   = shift;
    my $cmd    = shift;
    my $result = undef;
    printMsg( $cmd, "Tx" );
    my $endpoint = "http://".$self->{Monitor}->{ControlAddress} . "/$cmd"."&".$self->{Monitor}->{ControlDevice};
    my $req = HTTP::Request->new( GET => $endpoint );
    my $res = $self->{ua}->request($req);

    if ( $res->is_success ) {
        $result = !undef;
    }
    else {
        Error(    "Error really, REALLY check failed:'"
                . $res->status_line()
                . "'" );
        Error( "Cmd:" . $cmd );
    }

    return ($result);
}

sub reset {
    my $self = shift;
    Debug("Camera Reset");
    my $cmd = "web/cgi-bin/hi3510/param.cgi?cmd=sysreboot";
    $self->sendCmd($cmd);
}

# PP - in all move operations, added auto stop after timeout

#Up Arrow
sub moveConUp {
    my $self = shift;
    Debug("Move Up");
    my $cmd = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=up&-speed=45";
    $self->sendCmd($cmd);
    $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
}

#Down Arrow
sub moveConDown {
    my $self = shift;
    Debug("Move Down");
    my $cmd = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=down&-speed=45";
    $self->sendCmd($cmd);
}

#Left Arrow
sub moveConLeft {
    my $self = shift;
    Debug("Move Left");
    my $cmd = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=left&-speed=45";
    $self->sendCmd($cmd);
    $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
}

#Right Arrow
sub moveConRight {
    my $self = shift;
    Debug("Move Right");
    my $cmd = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=right&-speed=45";
    $self->sendCmd($cmd);
    $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
}

#Diagonally Up Right Arrow
sub moveConUpRight {
    my $self = shift;
    Debug("Move Diagonally Up Right");
    foreach my $dir ( "up", "right" ) {
        my $cmd
            = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=$dir&-speed=45";
        $self->sendCmd($cmd);
        $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
    }
}

#Diagonally Down Right Arrow
sub moveConDownRight {
    my $self = shift;
    Debug("Move Diagonally Down Right");
    foreach my $dir ( "down", "right" ) {
        my $cmd
            = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=$dir&-speed=45";
        $self->sendCmd($cmd);
        $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
    }
}

#Diagonally Up Left Arrow
sub moveConUpLeft {
    my $self = shift;
    Debug("Move Diagonally Up Left");
    foreach my $dir ( "up", "left" ) {
        my $cmd
            = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=$dir&-speed=45";
        $self->sendCmd($cmd);
        $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
    }
}

#Diagonally Down Left Arrow
sub moveConDownLeft {
    my $self = shift;
    Debug("Move Diagonally Down Left");
    foreach my $dir ( "down", "left" ) {
        my $cmd
            = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=$dir&-speed=45";
        $self->sendCmd($cmd);
        $self->autoStop( $self->{Monitor}->{AutoStopTimeout} );
    }
}

#Stop
sub moveStop {
    my $self = shift;
    Debug("Move Stop");
    my $cmd = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=stop&-speed=45";
    $self->sendCmd($cmd);
}

# PP - imported from 9831 - autostop after usleep
sub autoStop {
    my $self     = shift;
    my $autostop = shift;
    if ($autostop) {
        Debug("Auto Stop");
        usleep($autostop);
        my $cmd
            = "web/cgi-bin/hi3510/ptzctrl.cgi?-step=0&-act=stop&-speed=45";
        $self->sendCmd($cmd);
    }
}

#Move Camera to Home Position
sub presetHome {
    my $self = shift;
    Debug("Home Preset");
    my $cmd = "web/cgi-bin/hi3510/preset.cgi?-act=goto&-number=0";
    $self->sendCmd($cmd);
}

#Set preset
sub presetSet {
    my $self   = shift;
    my $params = shift;
    my $preset = $self->getParam( $params, 'preset' );
    my $presetCmd
        = "web/cgi-bin/hi3510/preset.cgi?-act=set&-status=1&-number=$preset";
    Debug("Set Preset $preset with cmd $presetCmd");
    my $cmd = $presetCmd;
    $self->sendCmd($cmd);
}

#Goto preset
sub presetGoto {
    my $self      = shift;
    my $params    = shift;
    my $preset    = $self->getParam( $params, 'preset' );
    my $presetCmd = "web/cgi-bin/hi3510/preset.cgi?-act=goto&-number=$preset";

    Debug("Set Preset $preset with cmd $presetCmd");
    my $cmd = $presetCmd;
    $self->sendCmd($cmd);
}

#Turn IR on
sub wake {
    my $self = shift;
    Debug("Wake - IR on");
    my $cmd = "web/cgi-bin/hi3510/setinfrared.cgi?-infraredstat=auto";
    $self->sendCmd($cmd);
}

#Turn IR off
sub sleep {
    my $self = shift;
    Debug("Sleep - IR off");
    my $cmd = "web/cgi-bin/hi3510/setinfrared.cgi?-infraredstat=close";
    $self->sendCmd($cmd);
}

1;
__END__

=head1 SPP1802SWPTZ

ZoneMinder::Database - Perl extension for SunEyes SP-P1802SWPTZ

=head1 SYNOPSIS

Control script for SunEyes SP-P1802SWPTZ cameras.

=head1 DESCRIPTION

You can set "-speed=x" in the ControlDevice field of the control tab for
that monitor. x should be an integer between 0 and 64
Auto TimeOut should be 1. Don't set it to less - processes
start crashing :)

=head2 EXPORT

None by default.



=head1 SEE ALSO

=head1 AUTHOR

Bobby Billingsley, E<lt>bobby(at)bofh(dot)dkE<gt>
based on the work of:
Pliable Pixels, https://github.com/pliablepixels

git checkout -b SunEyes_sp-p1802swptz

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-  Bobby Billingsley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
