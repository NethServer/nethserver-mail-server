
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

=head2 ->getMailboxForwards()

Return an hash with account forward settings

=cut

sub getMailboxForwards()
{
    my $self = shift;
    my %forwards = ();

    foreach my $accountRecord ($self->{AccountsDb}->users(), $self->{AccountsDb}->groups()) {

        # Nothing to do, if MailStatus is disabled
        if (($accountRecord->prop('MailStatus') || '') ne 'enabled') {
            next;
        }

        my @destinations = ();
        my $account = $accountRecord->key;

        if($accountRecord->prop('type') eq 'user'
           && $accountRecord->prop('MailForwardStatus') eq 'enabled') {

            push @destinations, $accountRecord->prop('MailForwardAddress');

            if($accountRecord->prop('MailForwardKeepMessageCopy') eq 'yes') {
                push @destinations, $account;
            }

        } elsif($accountRecord->prop('type') eq 'group'
                && ( ! $accountRecord->prop('MailDeliveryType') # empty === copy
                     || $accountRecord->prop('MailDeliveryType') eq 'copy')) {

            @destinations = map {
                    my $userRecord = $self->{AccountsDb}->get($_);

                    # search group members having MailStatus enabled
                    if(defined $userRecord
                       && ($userRecord->prop('MailStatus') || '') eq 'enabled') {
                        ($_);
                    } else {
                        ();
                    }

            } split(',', $accountRecord->prop('Members'));

            # If the group has no members, forward message to
            # postmaster (1822).
            if( ! @destinations) {
                @destinations = 'postmaster';
            }

        }

        if(@destinations) {
            $forwards{$account} = \@destinations;
        }

    }

    return %forwards;
}

=head2 ->getMailboxAliases()

Return an hash describing the alias => mailboxes association

=cut
sub getMailboxAliases()
{
    my $self = shift;
    my %aliasMap = ();

    foreach my $record ($self->{AccountsDb}->pseudonyms()) {
        my $pseudonym = $record->key;
        my $account = $record->prop('Account') || '';
        my $accountRecord = $self->{AccountsDb}->get($account);

        my @destinations = ();

        if($account eq '') {
            # Handling of (null) empty string Account -- see #1726
            @destinations = ('postmaster');

        } elsif( ! defined $accountRecord) {
            # Skip the pseudonym if the referred account does not
            # exist.
            $self->{debug} && warn "Account `$account` not found";
            next;

        } elsif($accountRecord->prop('type') eq 'user'
            &&  $accountRecord->prop('MailStatus') eq 'enabled') {

            #
            # user account: check if MailStatus is enabled
            #

            if(($accountRecord->prop('MailStatus') || '') eq 'enabled') {
                @destinations = ($account);
            }

        } elsif($accountRecord->prop('type') eq 'group'
            &&  $accountRecord->prop('MailStatus') eq 'enabled') {

            #
            # group accounts
            #
            @destinations = ($account);

        }

        my ($localPart, $domainPart) = split('@', $pseudonym);
        my @dbKeys;

        if($domainPart) {
            @dbKeys = $domainPart;
        } else {
            @dbKeys = $self->getDeliveryDomains();
        }

        foreach (map { $localPart . '@' . $_ } @dbKeys) {
            if( ! defined $aliasMap{$_}) {
                $aliasMap{$_} = [];
            }
            if(@destinations) {
                push @{$aliasMap{$_}}, @destinations;
            }
        }

    }

    return %aliasMap;
}


=head2 ->createAccountDefaultPseudonyms($account)

Create account pseudonyms according to our rules

=cut
sub createAccountDefaultPseudonyms($)
{
    my $self = shift;
    my $account = shift;

    my $accountType = $self->{AccountsDb}->get_prop($account, 'type');

    if($accountType eq 'user') {
        return $self->createUserDefaultPseudonyms($account);
    } elsif($accountType eq 'group') {
        return $self->createGroupDefaultPseudonyms($account);
    } else {
        $self->{debug} && warn("Invalid account type for key `$account`\n");
        return 1;
    }
}

=head2 ->createUserDefaultPseudonyms($username)

Create user pseudonyms according to our rules

=cut
sub createUserDefaultPseudonyms($)
{
    my $self = shift;
    my $username = shift;

    my $userRecord = $self->{AccountsDb}->get($username);

    if( ! $userRecord || $userRecord->prop('type') ne 'user') {
        $self->{debug} && warn(qq(Given username "$username" is not a user record key));
        return 0; # failure
    }

    if($userRecord->prop('MailStatus') ne 'enabled') {
        $self->{debug} && warn("User mail account `$username` is not enabled, skipped.\n");
        return 1;
    }

    my $prefix = lc($username);
    $prefix =~ s/[^a-z0-9.-]/_/;
    $prefix =~ s/_+/_/;

    $self->_createPseudonymRecords($username, $prefix);

    return 1;
}

=head2 ->createGroupDefaultPseudonyms($groupname)

Create a group pseudonym groupname@domain

=cut
sub createGroupDefaultPseudonyms($)
{
    my $self = shift;
    my $groupname = shift;

    my $groupRecord = $self->{AccountsDb}->get($groupname);

    if ( ! $groupRecord || $groupRecord->prop('type') ne 'group') {
        $self->{debug} && warn(qq(Given group name "$groupname" is not a group record key));
        return 0; # failure
    }

    if($groupRecord->prop('MailStatus') ne 'enabled') {
        $self->{debug} && warn("Group mail account `$groupname` is not enabled, skipped.\n");
        return 1;
    }

    my $prefix = lc($groupname);
    $prefix =~ s/[^a-z0-9.-]/_/;
    $prefix =~ s/_+/_/;

    $self->_createPseudonymRecords($groupname, $prefix);

    return 1;

}


sub _createPseudonymRecords()
{
    my $self = shift;
    my $account = shift;
    my @prefixList = @_;

    my @domainList = $self->getDeliveryDomains();

    # Create a domain-less pseudonym for each prefix Refs #1665:
    foreach (@prefixList) {
        my $address = $_ . '@';
        my $props = {
            'type' => 'pseudonym',
            'Account' => $account,
            'ControlledBy' => 'system',
            'Access' => 'public',
            '_prevAccount' => $account,
        };

        my $newRecord = $self->{AccountsDb}->new_record($address, $props);

        if( ! $newRecord) {
            $self->{debug} && warn ("Pseudonym '${address}' already exists!");
        }
    }

}

=head2 ->getAccountMailAddresses($account)

Return a list of email address for the given $account argument

=cut
sub getAccountMailAddresses($)
{
    my $self = shift;
    my $account = shift;
    my @addresses = ();
    foreach ($self->_getAccountPseudonymRecords($account)) {
        push @addresses, $self->pseudonymToAddresses($_->key);
    }
    return @addresses;
}


=head2 ->pseudonymToAddresses($pseudonym)

Return the expanded email addresses from a pseudonym key

For instance,

  me@mail.gov => (me@mail.gov)
  you@ => (you@mail.gov, you@mail.net, ...)

=cut
sub pseudonymToAddresses($)
{
    my $self = shift;
    my $key = shift;
    if($key =~ /\@$/) {
        # Expand domainless pseudonyms, by appending domain names:
        return map { $key . $_ } $self->getDeliveryDomains();
    }
    return ($key);
}


=head2 ->getAccountPseudonyms($account)

Return a list of pseudonym keys pointing to the given $account argument

=cut
sub getAccountPseudonyms($)
{
    my $self = shift;
    my $account = shift;
    return map { $_->key } $self->_getAccountPseudonymRecords($account);
}

=head2 ->deleteAccountPseudonyms($)

Delete all pseudonyms referring to the given $username

=cut
sub deleteAccountPseudonyms($)
{
    my $self = shift;
    my $account = shift;
    $_->delete() foreach $self->_getAccountPseudonymRecords($account);
    return 1;
}

sub _getAccountPseudonymRecords($)
{
    my $self = shift;
    my $account = shift;
    return grep { $_->prop("Account") eq $account } $self->{AccountsDb}->pseudonyms();
}

=head2 ->getDeliveryDomains()

Get the list of domains configured for local or remote delivery

=cut
sub getDeliveryDomains()
{
    my $self = shift;
    # Fill the list of domains with Local or Remote Delivery type:
    my @domainList = ();
    foreach my $domainRecord ($self->{DomainsDb}->get_all_by_prop(type => 'domain')) {
        my $deliveryType = $domainRecord->prop('TransportType');
        if($deliveryType eq 'LocalDelivery'
            || $deliveryType eq 'RemoteDelivery') {
            push @domainList, $domainRecord->key;
        }
    }
    return @domainList;
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
