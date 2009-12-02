AUTHENTICATION
==============

Bcsec authentication has two parts: 

* verifying credentials (currently username/password)
* verifying portal access

Both of these parts are implemented by _`Authenticator`_ instances. Each 
application should configure a list of authenticators; for each half of the 
process, each authenticator will be given an opportunity to authenticate a 
request.  If one fails, the next will be tried, until one succeeds or all of 
them fail.

Available authenticators are:

[TODO: make this more detailed, with example configurations.]

BcsecServiceAuthenticator
-------------------------
(TODO) `BcsecServiceAuthenticator` communicates with the bcsec RESTful web service.
It provides abstracted access to the authentication information in the main
cc_pers instances, along with netid authentication against the NU LDAP
directories.

PersAuthenticator
-----------------
`PersAuthenticator` uses an ActiveRecord-modeled view of the cc_pers  
tablespace to verify credentials (`t_personnel` username/password) and check 
portal access (`t_security_logins`).

It should be used for authenticating against local dev databases only -- 
access to any of the main cc_pers instances should be via 
`BcsecServiceAuthenticator`.

NetidAuthenticator
------------------
`NetidAuthenticator` connects directly to the NU LDAP directory to do netid
and password verification.  It does not implemented any portal access checks 
on its own.  (Thus, if used by itself, no one will be able to log in to 
anything.)

It is used by the implementation of the bcsec web service; regular 
applications shouldn't ever need to use it.  (And unless they're running behind 
one of the firewalls, won't be able to.)

MockAuthenticator
-----------------
`MockAuthenticator` allows for runtime-configured users and portal access,
suitable for use when testing.