#
# NethServer Mail package
#

use strict;
package NethServer::MailServer::AclManager;

use IO::Socket::UNIX;
use NethServer::Directory;

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
	password => NethServer::Directory::getUserPassword('vmail'),
	commandId => 0,
	debug => 0,
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
	$self->{debug} && print STDERR "DEBUG " . $line . "\n";
    } while ($line =~ /^\* /);


    if($line =~ m/^${cid} ${expect}/i) {
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


1;