
#
# NethServer Mail package
#

use strict;
package NethServer::MailServer;

use esmith::AccountsDB;
use esmith::DomainsDB;

=pod

=cut
sub new 
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{AccountsDB} = esmith::AccountsDB->open_ro();
    $self->{DomainsDB} = esmith::DomainsDB->open_ro();

    return $self;
}

=pod

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

=pod

=cut
sub getAliases()
{
    my $self = shift;
    my %aliasMap = ();

    foreach my $record ($self->{AccountsDB}->pseudonyms()) {
	my $pseudonym = $record->key;
	my $account = $record->prop('Account');
	my $domain = $pseudonym;

	my $accountRecord = $self->{AccountsDB}->get($account);

	# Skip the pseudonym if the reffered account is not 
	# enabled.
	if(! defined($accountRecord) ) {
	    warn "Account `$account` not found";
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
	    warn "Found pseudonym key `$pseudonym` without \@domain suffix: skipped";
	    next;
	}

	$aliasMap{$pseudonym} = "$account\@$domain";

    }

    return %aliasMap;
}





1;
