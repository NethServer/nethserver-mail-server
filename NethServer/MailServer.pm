
#
# NethServer Mail package
#

use strict;
package NethServer::MailServer;

use esmith::AccountsDB;
use esmith::DomainsDB;
use Text::Unidecode;

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

    my %aliases = $self->getAliases();

    while ( my ($alias, $mailbox) = each %aliases ) {
	$mailboxes{$mailbox} = 1;
    }

    return keys %mailboxes;
}

=head2 ->getAliases()

Return an hash describing the alias => mailbox association

=cut
sub getAliases()
{
    my $self = shift;
    my %aliasMap = ();

    foreach my $record ($self->{AccountsDb}->pseudonyms()) {
	my $pseudonym = $record->key;
	my $account = $record->prop('Account');
	my $domain = $pseudonym;

	my $accountRecord = $self->{AccountsDb}->get($account);

	# Skip the pseudonym if the reffered account is not 
	# enabled.
	if(! defined($accountRecord) ) {
	    $self->{debug} && warn "Account `$account` not found";
	    next;
	} elsif($accountRecord->prop('type') eq 'user'
	    &&  $accountRecord->prop('MailStatus') ne 'enabled') {
	    next;
	} elsif($accountRecord->prop('type') eq 'group') {
	    next;
	}

	# Trim the address part:
	$domain =~ s/([^@]+@)//;

	if(! $domain ) {
	    $self->{debug} && warn "Found pseudonym key `$pseudonym` without \@domain suffix: skipped";
	    next;
	}

	$aliasMap{$pseudonym} = "$account\@$domain";

    }

    return %aliasMap;
}


=head2 ->createUserPseudonyms($$)

Create user pseudonyms according to our rules

=cut
sub createUserDefaultPseudonyms($) 
{
    my $self = shift;
    my $username = shift;

    my @domainList = $self->getDeliveryDomains();

    my $userRecord = $self->{AccountsDb}->get($username);

    if ( ! $userRecord ) {
	return 0; # failure
    }

    my $firstName = lc(unidecode($userRecord->prop('FirstName')));
    my $lastName = lc(unidecode($userRecord->prop('LastName')));

    # Trim any whitespace character
    $firstName =~ s/\s+//;
    $lastName =~ s/\s+//;

    foreach my $domain (@domainList) {
	my $address1 = $firstName . '.' . $lastName . '@' . $domain;
	my $props = {
	    'type' => 'pseudonym',
	    'Account' => $username,
	    'ControlledBy' => 'system'
	};

	my $newRecord = $self->{AccountsDb}->new_record($address1, $props);

	if( ! $newRecord) {
	    $self->{debug} && warn ("Pseudonym ${address1} already exists");
	}
    }

    return 1;
}

=head2 ->getUserPseudonyms($)

Return a list of pseudonym keys pointing to the given $username argument

=cut
sub getUserPseudonyms($) 
{
    my $self = shift;
    my $username = shift;
    my @pseudonymList = ();
    push @pseudonymList, $_->key foreach $self->_getUserPseudonymRecords($username);
    return @pseudonymList;
}

=head2 ->deleteUserPseudonyms($)

Delete all pseudonyms referring to the given $username

=cut
sub deleteUserPseudonyms($)
{
    my $self = shift;
    my $username = shift;
    $_->delete() foreach $self->_getUserPseudonymRecords($username);
    return 1;
}

sub _getUserPseudonymRecords($) 
{
    my $self = shift;
    my $username = shift;
    return grep { $_->prop("Account") eq $username } $self->{AccountsDb}->pseudonyms();
}


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

1;
