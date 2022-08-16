%%%
title           = "Authenticated transport encryption for authoritative DNS"
abbrev          = "aaDoT"
workgroup       = "DNS Privacy"
area            = "Internet"
submissiontype  = "IETF"
ipr             = "trust200902"
date            = 2022-08-16T20:24:14Z
keyword         = [ "DNS", "TLS" ]

[seriesInfo]
name            = "Internet-Draft"
value           = "draft-fanf-dprive-adot-00"
status          = "standard"
stream          = "IETF"

[[author]]
initials        = "T."
surname         = "Finch"
fullname        = "Tony Finch"
organization    = "Internet Systems Consortium"
 [author.address]
 email          = "dot@dotat.at"
  [author.address.postal]
  streets       = [ "PO Box 360" ]
  city          = "Newmarket"
  code          = "NH 03857"
  country       = "USA"

%%%

.# Abstract

This note describes how a DNS resolver can establish an encrypted
DNS-over-TLS connection to an authoritative DNS server, authenticated
using TLSA records.


{mainmatter}


# Introduction

The DNS has two weaknesses that can be fixed by encrypting connections
from DNS resolvers to authoritative servers:

  * Cleartext DNS has a privacy leak: the contents of queries and
    responses are visible to on-path passive attackers ("snoopers");

  * DNS messages are vulnerable to alteration by on-path active
    attackers.

DNSSEC protects the integrity and authenticity of most DNS data, but
it does not protect delegation NS records or glue, nor does it protect
other parts of a DNS message such as its header and EDNS options.

This memo specifies a way to use DNS-over-TLS for connections from
resolvers to authoritative servers. TLSA records indicate that
encrypted connections are possible and how they can be authenticated.


## Overview

A zone's delegation NS RRset lists the hostnames of the zone's
authoritative nameservers, for example,

        zone.example.    NS    ns1.hoster.example.
        zone.example.    NS    nsa.2ndary.example.

TLSA records [@!RFC6698] can indicate that a host supports TLS for a
particular service. DNS-over-TLS uses TCP port 853, so an
authoritative DNS server can advertise support for encryption like

        _853._tcp.ns1.hoster.example.    TLSA    0 1 1 ( ... )

The profile of TLSA for authoritative DNS servers is in (#tlsa).

Sometimes a resolver cannot get a nameserver's TLSA records before
querying the nameserver, in particular when the nameserver's name is
below its zone cut and therefore its zone's delegation requires glue
([@!RFC1034] section 4.2.1). For example,

        hoster.example.    NS    ns1.hoster.example.
        hoster.example.    NS    ns2.hoster.example.

In this situation, the resolver can send cleartext queries to the
nameserver for the nameserver's TLSA RRset, and its zone's DNSKEY
RRset for authenticating the TLSA RRset. Although the contents of
these queries are visible to on-path passive attackers, they only
contain information about the authoritative nameserver. As discussed
in (#glueful), if the nameserver is referred to by its canonical name,
a snooper does not learn anything interesting from these queries.

These extra DNS queries do not necessarily slow down a resolver, as
explained in (#performance), and in some cases they can be faster than
unauthenticated unilateral DoT probing.


## Terminology

DNS-related terminology can be found in [@!RFC8499].

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**,
**SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**,
and **OPTIONAL** in this document are to be interpreted as described in
BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all
capitals, as shown here.


# TLSA records for name servers {#tlsa}

(Detailed TLSA profile TBD)


# Resolver algorithm {#algorithm}

## Choice of name server

## Performance {#performance}

Make TLSA, DNSKEY queries concurrently with establishing TLS
connection; the queries should complete before the TLS server hello
arrives, so the resolver should be able to authenticate the
certificate without delay.

Use a short TLS timeout if the TLSA response is negative

## Nameservers that require glue {#glueful}

# Security considerations

Many security considerations are discussed in (#rationale).


# Rationale {#rationale}

This section discusses the constraints on how the DNS can be updated
to include transport encryption.


## Explicit encryption support signal

How can a resolver know an authoritative server supports encryption?
There are three basic alternatives:

 1. No explicit signal: the resolver tries to make an encrypted
    connection, and falls back to cleartext if it gets an ICMP
    unreachable error or connection timeout.

    This is problematic because connection timeouts can be very slow,
    especially if the resolver tries multiple encrypted transports.
    This is also is vulnerable to downgrade attacks.

    This alternative is described in unilateral probing (ref tbd)

 2. Signal in an EDNS [@?RFC6891] or DSO [@?RFC8490] option: the
    resolver starts by connecting in the clear, and upgrades to an
    encrypted connection if the authoritative server supports it.

    This is vulnerable to downgrade attacks. The initial cleartext
    connection adds latency, and would need to be specified carefully
    to avoid privacy leaks.

 3. Signal in DNS records: the resolver makes extra queries during
    iterative resolution to find out whether an authoritative server
    supports encryption, before the resolver connects to it.

    The extra queries can add latency. That might be mitigated by
    placing the new records on the existing resolution path, or by
    doing more concurrently.

    DNSSEC can provide authentication and downgrade protection.

This specification takes the last option, since it is best for
security, and it uses concurrency to get acceptable performance.


## TLS certificate authentication

The DNS does not currently depend on the name that appears in an NS
target, provided it resolves to the IP address(es) of the intended server.
In particular the NS name does not have to be the server operator's
preferred name. Zone operators sometimes use different nameserver names
because they prefer to avoid glueless delegations, for example.

The widespread use of unofficial nameserver names means it is impossible
for a nameserver to present a certificate that always matches the
`subjectAltName` `dNSName` [@!RFC6125] expected by the client. There are a
number of ways to avoid this problem:

  * Authenticate the server by `subjectAltName` `iPAddress`. Unfortunately
    IP address certificates are hard to obtain (though this is likely to
    become easier after [@?RFC8738] is deployed). This is only an advantage
    when there is no signal associated with the nameserver's name (such as
    TLSA records) to indicate support for encrypted transports, because if
    there is such a signal the client knows what name to expect in the
    certificate.

  * Use the syntax of the name, such as a `dot--` prefix, to indicate
    that the name will match the certificate. This has the
    disadvantage of requiring all delegations to be updated. (See the
    discussion of "scalability" below.)

  * Ignore certificate name mismatches, and authenticate just the public
    key. This raises the question of how the client can find out the right
    public key: if it can find out the right key why can't it also
    find out the right name? It has the disadvantage that public key
    pinning has a poor operational track record.

  * Use the presence of a DNS record associated with the nameserver
    name to indicate that the server's certificate will match the
    name. This specification uses TLSA records alongside the
    nameserver's address records; other possible kinds of records for
    doing this job are discussed in the following subsections.


## Where can nameserver encryption records go?

Where can we put the new DNS records to signal that a nameserver
supports encryption? There are a number of issues to consider:

  1. Performance: we don't want the extra queries to slow down
     resolution too much;

  2. Scalability: is encryption configured per nameserver? per zone?

  3. Authentication: DNSSEC does not protect delegation NS records or
     glue address records;

  4. DNS data model: we ought to re-use existing RRtypes according to
     their intended purpose;

  5. DNS extensibility: make use of well-oiled upgrade points and
     avoid changes that have a track record of very slow deployment;

  6. Compatibility: a zone's delegation is usually managed by
     non-nameserver software discussed in the next subsection; any
     changes to the DNS need to work with the wide ecosystem of
     delegation and registry management systems.

The following subsections discuss the possible locations for DNS
records that indicate a nameserver supports encrypted transports, and
explain why most of the possibilities have been rejected.


## Delegation management systems

Alongside the DNS itself there are many systems that manage the
contents of the DNS (which records appear at which names) and the
structure of the DNS (zones and delegations). These include:

  * The TLD registry / registrar system, and the Extensible
    Provisioning Protocol [@?RFC5730] [@?RFC5731] [@?RFC5732] by which
    registrars manage registrations and domain delegations.

  * The various proprietary registrar user interfaces and APIs by
    which registrants can manage their domain delegations.

  * The regional internet registries have proprietary user interfaces
    and APIs for managing delegations in the reverse DNS.

  * Enterprise IPAM (IP address management) software that handles DNS
    and DHCP in large organizations.

Any significant change to how DNS delegations work cannot be deployed
without upgrades these DNS management systems. "Significant" means any
change to the types of records that need to be published in the parent
zone for the new kind of delegation to work. For instance, DS records
and IPv6 were significant changes.

New DS or DNSKEY algorithms are less significant, since they fit
within the existing syntax but may need new checking code. Changes to
nameserver names or addresses are insignificant.


## In the reverse DNS?

Given a nameserver's IP address, a resolver might make a query like

        _853._tcp.1.2.0.192.in-addr.arpa.    TLSA?

This possibility was rejected because:

  * It would be very slow: after receiving a referral, a resolver
    would have to iterate down the reverse DNS, instead of immediately
    following the referral.

  * At the moment the reverse DNS refers to the forward DNS for NS
    records; this would also make the forward DNS refer to the reverse
    DNS for TLSA records. Dependency loops are best avoided.

  * It's often difficult to put arbitrary records in the reverse DNS.

  * Encryption would apply to the server as a whole, whereas many
    operators would like to be able to set up different zones on the
    same server with encrypted and unencrypted transports. This can
    make testing and staged rollout easier.


## A new kind of delegation?

In theory, DNSSEC provides a way to update the DNS data model, along
the lines of the way NSEC3 was introduced [@?RFC5155]. The rough idea
is to introduce new DNSSEC algorithm types which indicate that a zone can
include new types of records that need special validation logic.
Existing validators will be able to resolve names in the zone, but
will treat it as insecure.

We might use this upgrade strategy to introduce new delegation records
that indicate support for transport encryption. However, it would
require a very long deployment timeline. It would also require a
corresponding upgrade to delegation management systems.

This is much too difficult.


## Non-delegation records in the parent zone?

Although it's extremely difficult to change which DNS records can
appear at a delegation, in principle the parent zone could contain
information about a delegation in a separate subdomain, like

        zone.example.    NS    ns1.zone.example.
        zone.example.    NS    ns2.zone.example.
        _853._tcp.ns1.zone._dot.example.    TLSA (...)
        _853._tcp.ns2.zone._dot.example.    TLSA (...)

The `_dot` tag makes the TLSA records into authoritative data in the
parent zone, rather than non-authoritative glue-like records. To
improve performance, the parent zone's nameservers could include these
records in referrals as additional data. The resolver could
authenticate them with DNSSEC and immediately use an encrypted
connection to the child zone's nameservers.

Although this idea would be secure and fast and compatible with the
DNS, it is not scalable, nor is it compatible with existing delegation
and registry management systems, so it is not realistically
deployable.


## New DS record algorithm?

The basic idea is to introduce a special DNSSEC algorithm number that
can be used in DS records to indicate support for encryption. This
runs into a number of problems, ultimately because it's trying to
abuse DS records for an unintended purpose.

  * DS records are per-zone, whereas encryption support is per-server.
    Support for incremental deployment would need a hack like having a
    DS record per nameserver, with further hacks to make it possible
    for humans to understand encryption DS records.

  * DS records can be updated by the child zone's DNSSEC key manager
    using CDS and/or CDNSKEY records [@?RFC8078]; CDS implementations
    would need to be changed to avoid interfering with encryption DS
    records.

  * There is a similar problem with ensuring that these DS records can
    be updated through delegation management systems. There are TLD
    registries that generate DS records from DNSKEY records
    themselves, rather than using DS records submitted by the zone
    owner, so these encryption DS records would have to be specified
    as the hash of a special DNSKEY record.

  * Poor scalability: there are orders of magnitude more zones than
    there are nameservers. If the encryption signal is per-zone like
    this idea, then it requires orders of magnitude more work to
    deploy.


## Special-use nameserver addresses?

Could we abuse special IP addresses (such as a new special-use IPv6
address block) to signal support for encryption? This terrible idea is
listed for completeness; it's bad because:

  * It will cause problems for resolvers and other software that
    doesn't understand the special IP addresses and tries to use them
    as normal IP addresses;

  * Glue addresses are not authenticated by DNSSEC so it's vulnerable
    to downgrade attacks if the connection to the parent zone's
    nameserver is insecure.


## Authenticator in nameserver hostname?

We might signal support for encryption is in the nameserver hostname
itself, like [@?DNScurve]. There is room for more than 300 bits in a
domain name label, which is enough space to pack an authenticator
(such as a cryptographic hash of a certificate) into the hostname.

This trick would be compatible with the existing DNS and delegation
management systems, and it avoids adding delays. But there are
problems.

This idea would involve specifying a label format with roughly the
same functionality as a TLSA record.

Nameserver hostnames appear both in the zone's apex NS RRset, which
can be authenticated by DNSSEC, and in the delegation NS RRset, which
is not authenticated. So referrals are vulnerable to
encryption-stripping downgrade attacks if the connection to the parent
zone's nameserver is insecure. A resolver can avoid downgrades by
re-fetching and validating the zone's nameservers from signed
authoritative data below the zone cut, at the cost of exposing the zone
name to snoopw, and a round-trip query delay.

But the showstopper is its horrible scalability, even worse than the
DS record idea described above: every zone's delegation and apex NS
RRsets need to be updated to support encryption, and changed whenever
a nameserver's key changes. Nameserver operators and zone owners are
often different people, so key changes would require communication
across multiple organization boundaries. Normal DNSSEC DS record
updates involve the zone owner, primary server operator, and
registrar; this idea involves all of them plus the secondary server
operators.


## TLSA records alongside nameserver addresses

This idea is to use TLSA records in a straightforward way:

        ns1.zone.example.    A     192.0.2.1
        ns1.zone.example.    AAAA  2001:db8::1
        _853._tcp.ns1.zone.example.    TLSA    ( ... )

The TLSA records only appear in the zone's authoritative data, so
there are no delegation-related complications. They are signed with
DNSSEC, which protects against downgrade attacks.

As discussed in (#performance), it does not necessarily add any
significant delay, and can perform better than unilateral probing.

There is a clear framework for supporting other transports such as
QUIC, by adding more TLSA records. (With the caveat that each new
transport requires another query because the TLSA owner name varies
per transport.)

This setup has good scalability: the extra records depend on the
number of namesevrers, independent of the number of zones. Existing
delegations do not need to be updated to support encryption if they
use a nameserver's canonical name.

The main problem with this setup is that it appears to need something
like glue: in many cases a resolver will need to know a nameserver's
TLSA records in order to securely fetch the nameserver's TLSA records.


## Glue and nameserver TLSA records

The DNS needs glue addresses when a resolver follows a referral to a
zone whose nameservers are under the zone cut ([@!RFC1034] section
4.2.1). When the resolver wants to make an encrypted connection to
these nameservers, it also needs the TLSA records, which are also
under the zone cut.

The resolver can make an unencrypted query for the TLSA records, then
upgrade to an encrypted connection. This leaks the zone name to
on-path passive attackers.

This might be acceptable in limited circumstances. A snooper can
obtain a map from IP addresses to nameserver names from public sources
such as passive DNS feeds and TLD zone files. If the delegation refers
to the nameserver by its canonical name, then the extra queries do not
leak any information that cannot be inferred from the nameserver's IP
address.

Queries for other domains hosted on the same nameserver can remain
private.


{backmatter}

<reference anchor='DNScurve' target='https://dnscurve.org/'>
    <front>
        <title>DNSCurve: Usable security for DNS</title>
        <author initials='D.J.' surname='Bernstein'/>
        <date year='2009'/>
    </front>
</reference>


# Acknowledgments

Thanks to Manu Bretelle, Brian Dickson, Peter van Dijk, and Scott
Hollenbeck for helpful feedback.
