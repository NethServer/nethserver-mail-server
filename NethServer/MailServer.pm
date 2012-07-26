
#
# NethServer Mail package
#

use strict;
package NethServer::MailServer;

use esmith::AccountsDB;
use esmith::DomainsDB;
use Encode;
use Text::Unidecode;
use NethServer::MailServer::AclManager;

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

=head2 ->getMailboxes()

Return the list of currently active mailboxes

=cut
sub getMailboxes()
{
    my $self = shift;

    my %mailboxes = ();

    my %aliases = $self->getMailboxAliases();

    while ( my ($alias, $mbxList) = each %aliases ) {
	$mailboxes{$_} = 1 foreach (@{$mbxList});
    }

    return keys %mailboxes;
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

	if($pseudonym !~ m/^[^@]+@.+$/) {
	    warn ("Missing domain part in pseudonym `$pseudonym`: skipped\n");
	    next;
	}

	my $account = $record->prop('Account');
	my $domain = $pseudonym;

	# Trim the address part:
	$domain =~ s/([^@]+@)//;

	if(! $domain ) {
	    $self->{debug} && warn "Found pseudonym key `$pseudonym` without \@domain suffix: skipped";
	    next;
	}

	my $accountRecord = $self->{AccountsDb}->get($account);
	my $domainRecord = $self->{DomainsDb}->get($domain);

	# Skip the pseudonym if the refered account is not 
	# enabled.
	if(! defined($accountRecord) ) {
	    $self->{debug} && warn "Account `$account` not found";
	    next;
	} elsif($accountRecord->prop('type') eq 'user'
	    &&  $accountRecord->prop('MailStatus') eq 'enabled') {

	    if($accountRecord->prop('MailForwardStatus') eq 'enabled') {
		if($accountRecord->prop('MailForwardKeepMessageCopy') eq 'yes') {
		    $aliasMap{$pseudonym} = ["$account\@$domain", $accountRecord->prop('MailForwardAddress')];
		} else {
		    $aliasMap{$pseudonym} = [$accountRecord->prop('MailForwardAddress')];
		}	       
	    } else {
		$aliasMap{$pseudonym} = ["$account\@$domain"];
	    }

	} elsif($accountRecord->prop('type') eq 'group'
	    &&  $accountRecord->prop('MailStatus') eq 'enabled') {

	    if($accountRecord->prop('MailDeliveryType') eq 'copy') {
		my @MailEnabledMemberList = grep { 
		    $self->{AccountsDb}->get_prop($_, 'MailStatus') eq 'enabled' 
		} split(',', $accountRecord->prop('Members'));
		
		$aliasMap{$pseudonym} = [map { $_ . '@' . $domain } @MailEnabledMemberList];
	    } elsif($accountRecord->prop('MailDeliveryType')eq 'shared') {
		$aliasMap{$pseudonym} = ["$account\@$domain"];
	    }
	} 

    }

    return %aliasMap;
}


=head2 ->createAccountDefaultPseudonyms($)

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

=head2 ->createUserDefaultPseudonyms($)

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

    my $firstName = lc(unidecode(decode("UTF-8", $userRecord->prop('FirstName'))));
    my $lastName = lc(unidecode(decode("UTF-8", $userRecord->prop('LastName'))));

    # Trim any whitespace character
    $firstName =~ s/\s+//;
    $lastName =~ s/\s+//;

    my $prefix1 = $firstName . '.' . $lastName;

    $self->_createPseudonymRecords($username, $prefix1);

    return 1;
}

=head2 ->createGroupDefaultPseudonyms($)

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
    my $username = shift;
    my @prefixList = @_;

    my @domainList = $self->getDeliveryDomains();
    
    foreach (@prefixList) {
	foreach my $domain (@domainList) {
	    my $address = $_ . '@' . $domain;
	    my $props = {
		'type' => 'pseudonym',
		'Account' => $username,
		'ControlledBy' => 'system',
		'Access' => 'public'
	    };
	    
	    my $newRecord = $self->{AccountsDb}->new_record($address, $props);
	    
	    if( ! $newRecord) {
		$self->{debug} && warn ("Pseudonym ${address} already exists");
	    }
	}
    }

}



=head2 ->getAccountPseudonyms($)

Return a list of pseudonym keys pointing to the given $username argument

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

=head2 connectAclManager

Create a connection to the IMAP server, to configure ACLs

=cut
sub connectAclManager
{
    my $class = shift;
    my $account = shift;

    return NethServer::MailServer::AclManager->new(login => $account);
}

=head2 getDovecotSharedPath

Return the path of the shared mailfolder for the given group name

=cut
sub getDovecotSharedPath($)
{
    my $group = shift;
    return '/var/lib/vmail/user/' . $group . '/Maildir/dovecot-shared';
}


=head2 getInteralAddresses()

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

1;
