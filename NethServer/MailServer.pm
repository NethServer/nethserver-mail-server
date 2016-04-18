
#
# NethServer MailServer package
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


package NethServer::MailServer;

use strict;
use esmith::AccountsDB;
use esmith::DomainsDB;
use Encode;
use Text::Unidecode;
use NethServer::MailServer::AclManager;
use User::grent;

=head1 NethServer::MailServer package

Encapsulate the MailServer domain logic.

Copyright (C) 2012 Nethesis srl

=head2 new()

Create a new MailServer object

=cut
sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{AccountsDb} = esmith::AccountsDB->open();
    $self->{DomainsDb} = esmith::DomainsDB->open();

    return $self;
}

=head2 ->connectAclManager($account)

Create a connection to the IMAP server, to configure ACLs

=cut
sub connectAclManager
{
    my $class = shift;
    my $account = shift;

    return NethServer::MailServer::AclManager->new(login => $account);
}

=head2 ::getDovecotSharedPath($group)

Return the path of the shared mailfolder for the given group name

=cut
sub getDovecotSharedPath($)
{
    my $group = shift;
    return '/var/lib/nethserver/vmail/' . $group . '/Maildir/dovecot-shared';
}


=head2 ->getInteralAddresses()

Return the list of internal (aka private) email addresses. Recipients
in this list are visible only to local clients (mynetworks).

=cut
sub getInternalAddresses()
{
    my $self = shift;
    my @internalAddresses = ();

    foreach my $addressRecord ($self->{AccountsDb}->pseudonyms()) {
        if(defined $addressRecord->prop('Access')
           && $addressRecord->prop('Access') eq 'private') {
            push @internalAddresses, $addressRecord->key;
        }
    }

    return @internalAddresses;
}

=head2 ->changeGroupSubscriptions($group, $reverse)

The function reads the new members of $group from Members prop and the
old members of $group from getent(). It calculates the differences
between the two sets, then invokes doveadm to SUBSCRIBE $group INBOX
for added members, and UNSUBSCRIBE for removed members.

If $reverse is a TRUE value, new members are read from getent() and
old members from group Members prop.

Return 1 on success, 0 otherwise.

=cut

sub changeGroupSubscriptions($$)
{
    my $self = shift;
    my $groupName = shift;
    my $reverse = shift;

    my @validUsers = map { $_->key } $self->{AccountsDb}->users();
    my $groupRecord = $self->{AccountsDb}->get($groupName);
    my $groupEntry = getgrnam($groupName);

    my @setR = ();
    my @setE = ();

    if($groupRecord
       && $groupRecord->prop('type') eq 'group'
       && ($groupRecord->prop('MailDeliveryType') || '') eq 'shared') {
        @setR = split(',', ($groupRecord->prop('Members') || ''));
    }

    if($groupEntry) {
        @setE = @{$groupEntry->members()};
    }

    #
    # Calculate the differences between @setR and @setE, considering
    # only validUsers
    #

    my %H = ();
    $H{$_} |= 0x1 foreach @validUsers;
    $H{$_} |= 0x2 foreach ($reverse ? @setR : @setE); # old members
    $H{$_} |= 0x4 foreach ($reverse ? @setE : @setR); # new members

    my $errors = 0;

    foreach my $u (keys %H) {
        my $action;
        my @folders = ();

        if($H{$u} == 0x3) {
            $action = 'unsubscribe';
            @folders = ("Shared/$groupName/INBOX", "Shared/$groupName", "Shared/$groupName/");
        } elsif($H{$u} == 0x5) {
            $action = 'subscribe';
            @folders = ("Shared/$groupName/INBOX");
        } else {
            next;
        }

        system('/usr/bin/doveadm', 'mailbox', $action , '-u', $u, @folders);
        if($? != 0) {
            $errors ++;
        }
    }

    return ($errors > 0 ? 0 : 1);
}

1;
