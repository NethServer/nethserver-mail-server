#
# NethServer Mail package
#

#
# Copyright (C) 2012 Nethesis S.r.l.
# http://www.nethesis.it - support@nethesis.it
# 
# This script is part of NethServer.
# 
# NethServer is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License,
# or any later version.
# 
# NethServer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
package NethServer::MailServer::AclManager;

use IO::Socket::UNIX;
use NethServer::Password;

=head1

A simple IMAP client to manage ACLs on the server

=head2 new

Create a new client connected to the IMAP server. Return undef if connection fails.

=cut
sub new
{     
    my $class = shift;
    my $self = {
	login => 'vmail',
	server => '/var/run/dovecot/imap-ipc',
	password => NethServer::Password->new('vmail')->getAscii(),
	commandId => 0,
	debug => 0,
	error => '',
    };

    while(@_) {
	my $key = shift;
	my $value = shift;

	$self->{$key} = $value;
    }


    $self->{socket} = IO::Socket::UNIX->new(Peer => $self->{server}) or return undef;

    bless $self, $class;

    $self->_login() || return undef;

    return $self;
}

sub create($$)
{
    my $self = shift;
    my $mailbox = shift;
    return $self->_do('OK CREATE', 'CREATE', $mailbox);
}

sub setAcl($$$$)
{
    my $self = shift;
    my $mailbox = shift;
    return $self->_do('OK SETACL', 'SETACL', $mailbox, @_);
}


sub deleteAcl($$$)
{
    my $self = shift;
    my $mailbox = shift;
    return $self->_do('OK DELETEACL', 'DELETEACL', $mailbox, @_);
}

sub _login
{
    my $self = shift;
    return $self->_do('OK', 'LOGIN', $self->{login}, $self->{password});    
}

sub logout
{
    my $self = shift;
    if($self->_do('OK LOGOUT', 'LOGOUT')) {
	return close $self->{socket};
    }
    return 0;
}

sub _do
{
    my $self = shift;
    my $expect = shift;
    my @command = (shift);

    while(@_) {
	my $arg = shift;
	push @command, '"' . $arg . '"';
    }

    $self->_send(join(' ', @command)) || return 0;
    return $self->_expect($expect);
}

sub _expect
{
    my $self = shift;
    my $expect = shift;
    my $cid = sprintf('%04x', $self->{commandId});

    # increment the comman counter for the next action
    $self->{commandId}++;

    $self->{debug} && print STDERR 'DEBUG expecting ' . "${cid} ${expect}\n";

    my $response;
    my $line = '';

    # skip untagged lines
    do {
	$line = readline $self->{socket};
	$self->{error} .= $line;
	$self->{debug} && print STDERR "DEBUG " . $line . "\n";
    } while ($line =~ /^\* /);

    if($line =~ m/^${cid} ${expect}/i) {
	$self->{error} = '';
	return 1;
    }

    return 0;
}


sub _send
{
    my $self = shift;
    my $fh = $self->{socket};
    print $fh (sprintf('%04x ', $self->{commandId}), @_, "\r\n");
    return 1;
}


sub getErrorMessage()
{
    my $self = shift;
    return $self->{error};
}

1;
