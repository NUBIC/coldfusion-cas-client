RLOGIN
======

The bcsec rlogin system permits single sign-on between applications which can
both access the same cc_pers instance (via `Pers::Rlogin`) or bcsec service 
(TODO).  The rlogin infrastructure supports passing arbitrarily nested lists  
and maps of basic value types (strings and numbers).

The bcsec plugin provides rlogin implementations as well as a default pair of  
rlogin/rlogout endpoints.  These are routed to /rlogin and /rlogout,  
respectively.  

Rlogout endpoint
----------------
The rlogout endpoint supports passing in a relative URL in the remote 
application:

  http://prod.example.com/thisapp/rlogout/remoteapp/special/report

The relative URL will be stored in the rlogin data.  (The exact place it is  
stored in the target application depends on the way the rlogin target is  
configured; see below.)  A compatible rlogin entry point in the target  
application can retrieve it and automatically redirect after the rlogin is  
verified.

Any additional query parameters provided to the rlogout endpoint will be  
stored in the rlogin data and will therefore be available to the target  
application.

Rlogin endpoint
---------------
The default rlogin entry point provided by the bcsec plugin accepts requests 
that look like this:

  http://prod.example.com/thisapp/rlogin/:123:45:67:89:12:3:etc

The long string of numbers is the usual textified list of bytes making up the 
encrypted rlogin key.  When it loads the rlogin data, it will first look for
a variable called `named_route`.  If such a variable exists, it will pass
a hash containing the remainder of the variables to "#{named_route}_url" --
i.e., the url builder for that named route -- and then redirect to the result.
If there is no `named_route`, it will pass all the variables to `redirect_to`.
In particular, note that if you include `controller` and/or `action` variables
(without a named route), the call to `redirect_to` will behave as you'd expect.

KNOWN ISSUE:  if both ends of your rlogin process are rails apps using this 
plugin, passing `controller` and `action` variables won't work.  This is 
because the rlogout endpoint accumulates variables from the params hash, but
rails' routing system overwrites `controller` and `action` with the values for
the actual controller & action being executed (i.e., `:access` and `:rlogout`).
A fix could be fashioned for this if necessary, or it can be worked around by
using named routes.

As is probably clear from the above, this default entry point is only 
suitable for use if the information you are passing can be represented as 
simple scalars.  This will suffice for basic transparent linking between 
apps, but if you need to pass more elaborate structures, you'll need to write 
your own endpoint.  (It's pretty easy -- the default one's only 7 lines long.) 

In case you need to process any rlogin options before the redirect, override 
AccessController#process_rlogin_options!. For example, if your app allows a 
user to act as someone else, this might be passed as an option to rlogin which
you want to intercept and remove from the options hash before redirecting to
the requested page.

Rlogin targets
--------------
The applications to which your application can rlogout are configured via 
`Bcsec::rlogin_targets`.  See the README for the syntax.  There are two kinds 
of targets: default (suitable for rails and java target applications) and cf
(suitable for ColdFusion applications).  The target types differ in the way 
the target URL provided to rlogout is stored.  For a default target, it is 
stored in a variable called `targetUrl`.  For a cf target, it is stored in 
`session.targetUrl`.  

This difference is necessary because the CF rlogin entry process involves code 
in two different CF scripts.