Summary: Mail server implementation based on postfix and dovecot packages
Name: nethserver-mail-server
Version: 1.8.3
Release: 1%{?dist}
License: GPL
URL: %{url_prefix}/%{name} 
Source0: %{name}-%{version}.tar.gz
BuildArch: noarch

Requires: dovecot >= 2.1.16, dovecot-pigeonhole >= 2.1.16, dovecot-antispam >= 0.0.49-1
Requires: nethserver-mail-common > 1.4.1-1
Requires: nethserver-directory
Requires: perl(Text::Unidecode)
Requires: cyrus-sasl-plain, cyrus-sasl-ldap, cyrus-sasl-ntlm, cyrus-sasl-md5

# The GSSAPI ldap client works only if postfix has been compiled with
# -DUSE_LDAP_SASL flag (refs #1747):
Requires: postfix >= 2:2.9.6-2.ns6

BuildRequires: perl
BuildRequires: nethserver-devtools >= 1.0.0

%description
Mail server implementation based on postfix and dovecot packages.

%prep
%setup

%build
%{makedocs}
mkdir -p root%{perl_vendorlib}
mv -v NethServer root%{perl_vendorlib}
perl createlinks

%install
rm -rf $RPM_BUILD_ROOT
(cd root; find . -depth -print | cpio -dump $RPM_BUILD_ROOT)
%{genfilelist} $RPM_BUILD_ROOT \
    --dir /var/lib/nethserver/vmail 'attr(0700,vmail,vmail)' \
    --dir /var/lib/nethserver/sieve-scripts 'attr(0770,root,vmail)' \
    > %{name}-%{version}-filelist
echo "%doc COPYING" >> %{name}-%{version}-filelist
echo "%doc migration/sync_maildirs.sh"  >> %{name}-%{version}-filelist

%clean
rm -rf $RPM_BUILD_ROOT

%pre
# ensure vmail user exists:
if ! id vmail >/dev/null 2>&1 ; then
   useradd -c 'Virtual mailboxes owner' -r -M -d /var/lib/nethserver/vmail -s /sbin/nologin vmail
fi

# add vmail group to postfix user
usermod -G vmail -a postfix >/dev/null 2>&1

# Add amavis to vmail group to talk to dovecot LMTP socket:
usermod -G vmail -a amavis >/dev/null 2>&1

exit 0


%files -f %{name}-%{version}-filelist
%defattr(-,root,root)
%attr(0644, root, root) %config(noreplace) %{_sysconfdir}/logrotate.d/imap

%changelog
* Tue Dec 09 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.8.3-1.ns6
- Avoid fetchmail bounces - Enhancement #2954 [NethServer]
- sync_maildirs.sh delete - Bug #2884 [NethServer]

* Mon Nov 03 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.8.2-1.ns6
- nethserver-mail-group-acl-cleanup FAILED: group not deleted - Bug #2933 [NethServer]
- Action nethserver-mail-group-change-subscriptions fails - Bug #2888 [NethServer]

* Wed Oct 15 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.8.1-1.ns6
- Backup config: remove /etc/aliases - Feature #2739

* Tue Oct 07 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.8.0-1.ns6
- Avoid excessive postfix reload  - Enhancement #2843
- Dovecot: separate log files for IMAP and LMTP/delivery - Enhancement #2841
- Relay denied to SMTP clients both in local networks and submission_whitelist - Bug #2814
- Edit workgroup name when role is Workstation - Enhancement
- Relax Postix restrictions for whitelisted senders - Enhancement #2768
- Mail spying / always Bcc - Feature #2750
- Customizable mail quota increments - Enhancement #2723
- Dashboard mail quota panel: order by size is wrong - Bug #2698

* Thu Jun 12 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.7.0-1.ns6
- AD group mail delivery type switch - Feature #2751
- Use DNS A record to locate AD controllers - Enhancement #2729
- Configurable AD accounts LDAP subtree - Enhancement #2727
- SOGo does not display user mail quota - Bug #2722
- Backup config: minimize creation of new backup - Enhancement #2699

* Thu Apr 17 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.6.4-1.ns6
- Open POP3s port (995) - Bug #2703

* Mon Mar 10 2014 Davide Principi <davide.principi@nethesis.it> - 1.6.3-1.ns6
- Backup Notification to System administrator fails by default - Bug #2675 [NethServer]

* Fri Feb 28 2014 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.6.2-1.ns6
- Fix error on pseudonym creation - Bug #2679

* Wed Feb 26 2014 Davide Principi <davide.principi@nethesis.it> - 1.6.1-1.ns6
- Skip migration of builtin mail aliases - Enhancement #2646 [NethServer]

* Wed Feb 05 2014 Davide Principi <davide.principi@nethesis.it> - 1.6.0-1.ns6
- NethCamp 2014 - Task #2618 [NethServer]
- Override mail system /etc/aliases - Enhancement #2499 [NethServer]
- Move admin user in LDAP DB - Feature #2492 [NethServer]
- everyone@ mail alias - Feature #2464 [NethServer]
- Dashboard mail quota usage report - Feature #2433 [NethServer]
- Apply submission whitelist to smtpd port 25 - Enhancement #2422 [NethServer]
- Update all inline help documentation - Task #1780 [NethServer]
- Dashboard: new widgets - Enhancement #1671 [NethServer]

* Wed Dec 18 2013 Davide Principi <davide.principi@nethesis.it> - 1.5.0-1.ns6
- Kerberos keytab file is missing for new services - Bug #2407 [NethServer]
- Non-spam messages in SpamFolder are retained indefinitely - Enhancement #2290 [NethServer]
- Group Shared Folder always shown - Bug #2214 [NethServer]
- Mail-server: avoid warning if Samba is not installed - Enhancement #2153 [NethServer]
- group-create event fails on nethserver-mail-group-acl-adjust action - Bug #2151 [NethServer]
- Allow dot in user and group names - Enhancement #2087 [NethServer]
- Directory: backup service accounts passwords  - Enhancement #2063 [NethServer]
- Mail-server: automatic subscription of group shared folders - Feature #1879 [NethServer]

* Mon Sep 02 2013 Davide Principi <davide.principi@nethesis.it> - 1.4.6-1.ns6
- Group (User) UI module: opening a group for update fails - Bug #2082 [NethServer]

* Fri Aug 02 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.4.5-1.ns6
- nethserver-mail-backup: handle files and directories with spaces

* Mon Jul 22 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.4.4-1.ns6
- Make Dovecot accessibile from red interface when server is in gateway mode #2071
- make Postfix accessibile from red interface when server is in gateway mode #2069

* Fri Jul 12 2013 Giacomo Sanchietti <giacomo.sanchietti@nethesis.it> - 1.4.3-1.ns6
- Backup: implement and document full restore #2043

* Thu Jul 04 2013 Davide Principi <davide.principi@nethesis.it> - 1.4.2-1.ns6
- Fixed automatic subscription of group shared folders - Feature #1879 [NethServer]

* Mon Jun 10 2013 Davide Principi <davide.principi@nethesis.it> - 1.4.1-1.ns6
- Enable dovecot Listescape plugin #2003
- Automatic subscription of group shared folders #1879

* Wed May 29 2013 Davide Principi <davide.principi@nethesis.it> - 1.4.0-1.ns6
- IMAP access for Active Directory users #1747

* Tue May  7 2013 Davide Principi <davide.principi@nethesis.it> - 1.3.1-1.ns6
- Require nethserver-directory explicitly #1870

* Tue Apr 30 2013 Davide Principi <davide.principi@nethesis.it> - 1.3.0-1.ns6
- Full automatic package install/upgrade/uninstall support #1870 #1872 #1874
- Group Mail UI plugin: show default group pseudonym in create action #1795
- Use sieve global script auto-compilation #1877
- Enabled imapflags obsolete sieve extnsion #1816
- Allow SMTP/AUTH on port 25 through "legacy" SubmissionPolicyType #1818
- Forced delivery of messages to an empty group to postmaster account #1822
- Honoured delivery type "copy" when recipient is group@hostname #1857
- Migrate user sieve filters #1815
- Switch submission policy to "authenticated" when mail-server is installed #1856
- Cleanup empty Maildir/ directory in user's home; reset POSIX acls on destination Maildir/ #1669
- Fixed removal of duplicated postmaster entry during migration #1841
- Migrate spam settings #1820
- Fixed expansion of all pseudonym when a domain is modified #1823
- Experimental support to Active Directory GSSAPI AUTH #1747
- Fixed address extension +spam propagated during message forwarding: removed vmail.nh internal domain suffix, using local(8) daemon with /etc/postfix/aliases template #1844
- Fixed ACL storage path of shared mailboxes #1739
- Fixed master-users file is world-readable: /etc/dovecot/master-users, set permissions 0640  #1825
- Fixed user mail forwarding not honoured in group delivery #1840
- Added migration/sync_maildirs.sh utility: synchronization script for maildirs #1808
- Migrate pseudonym pointing to another pseudonym #1806
- Name pseudonym after migrated account name #1805 

* Tue Mar 19 2013 Davide Principi <davide.principi@nethesis.it> - 1.2.0-1.ns6
- vmail storage moved from /var/lib/vmail into /var/lib/nethserver/vmail, removing user/ subdir. Refs #1739
- Optionally, create default user's mail addresses during user creation. #1623
- IMAP access to admin's mailbox. #1622
- Migration support. #1669 #1726
- Support domainless pseudonyms. #1665
- Create default primary mail domain record. #1530 
- /etc/sysconfig/dovecot template: fixed wrong bash syntax to close stderr descriptor. Fixes #1656 
- *.spec: use %{url_prefix} macro in URL tag; set minimum version requirements. #1654 #1653


* Thu Jan 31 2013 Davide Principi <davide.principi@nethesis.it> - 1.1.0-1.ns6
- Added postfix/SystemUserRecipientStatus prop. Refs #1635
- Removed localhost.localdomain from transport delivery table. Refs #1635
- Migrate admin's standard mailbox to vmail storage. Refs #1622
- Grant IMAP access to system users in /etc/dovecot/system-users passwd database. Refs #1622
- Dovecot certificates under nethserver-base certificate management. Refs #1634

