%%%
title           = "Authenticated transport encryption for authoritative DNS"
abbrev          = "ADoT"
workgroup       = "DNS Privacy"
area            = "Internet"
submissiontype  = "IETF"
ipr             = "trust200902"
date            = 2020-11-09T18:47:45Z
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
DNS-over-TLS connection to an authoritative DNS server. The
authoritative server is authenticated using TLSA records.


{mainmatter}


# Introduction

## Terminology

DNS-related terminology can be found in [@!RFC8499].

The key words **MUST**, **MUST NOT**, **REQUIRED**, **SHALL**,
**SHALL NOT**, **SHOULD**, **SHOULD NOT**, **RECOMMENDED**, **MAY**,
and **OPTIONAL** in this document are to be interpreted as described in
[@!RFC2119].


# Security considerations


{backmatter}


# Acknowledgments
