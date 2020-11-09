%%%
title           = "Authenticated transport encryption for authoritative DNS"
abbrev          = "ADoT"
workgroup       = "DNS Privacy"
area            = "Internet"
submissiontype  = "IETF"
ipr             = "trust200902"
date            = 2020-11-09T18:50:43Z
keyword         = [
    "DNS",
    "TLS",
]

[seriesInfo]
name            = "Internet-Draft"
value           = "draft-fanf-dprive-adot-00"
status          = "standard"

[[author]]
initials        = "T."
surname         = "Finch"
fullname        = "Tony Finch"
organization    = "University of Cambridge"
 [author.address]
 email          = "dot@dotat.at"
  [author.address.postal]
  streets       = [
    "University Information Services",
    "Roger Needham Building",
    "7 JJ Thomson Avenue",
  ]
  city          = "Cambridge"
  country       = "England"
  code          = "CB3 0RB"

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
    responses are visible to on-path passive attackers;

  * DNS messages are vulnerable to alteration by on-path active
    attackers.

DNSSEC protects the integrity and authenticity of most DNS data, but
it does not protect delegation NS records or glue, nor does it protect
other parts of a DNS message such as its header and OPT record.


## Overview

A zone's apex NS RRset lists the hostnames of the zone's authoritative
nameservers, for example,

        myzone.example.    NS    ns1.hoster.example.
        myzone.example.    NS    nsa.2ndary.example.

TLSA records [@!RFC6698] can indicate that a host supports TLS for a
particular service. DNS-over-TLS uses TCP port 853, so an
authoritative server can advertise support for encryption like

        ns1.hoster.example.    TLSA    0 1 1 ( ... )

The profile of TLSA for authoritative DNS servers is in (#tlsa).

Sometimes a resolver cannot get a nameserver's TLSA records before
querying the nameserver, for instance when the nameserver is
in-bailiwick and its zone's delegation requires glue. For example,

        hoster.example.    NS    ns1.hoster.example.
        hoster.example.    NS    ns2.hoster.example.

To allow a resolver to use an encrypted transport before it can get a
nameserver's TLSA records, we change the nameserver's hostname to
include a tag that indicates which transports it supports, as
described in (#hints), for example,

        hoster.example.    NS    dot--ns1.hoster.example.
        hoster.example.    NS    dot--ns2.hoster.example.

The reason for this ugly hack is discussed in (#rationale).


## Terminology

DNS-related terminology can be found in [@!RFC8499].

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**,
**SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**,
and **OPTIONAL** in this document are to be interpreted as described in
[@!RFC2119].


# TLSA records for name servers {#tlsa}


# Encrypted transport hints {#hints}


# Resolver algorithm {#algorithm}


# IANA considerations {#iana}


# Security considerations

Many security considerations are discussed in (#rationale).


# Rationale {#rationale}




{backmatter}


# Acknowledgments
