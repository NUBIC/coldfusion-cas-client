<!--- This file is a workaround for the problem caused by rubycas-server redirecting
      to a service url without a trailing '/'.  This is part of rubycas-server's 
      implementation to clean the url of trailing '/'.  The problem occurs
      when Coldfusion sees this url, it redirects to the same URL with a 
      trailing '/', but it doesn't include the url parameters in the redirect. 
      This file fixes the problem by using a page as the service_url,
      instead of the application root.  This will prevent redirects
      that lose the url parameters.
      
      Example:
          1. User successfully logs in through the CAS server: http://cas.server.com/cas/login?service_url=http://my.service.com/foo/
          2. The user is redirected to the service url: http://my.service.com/foo?ticket=ST-123456789
          3. Coldfusion redirects this request to (without the service ticket): http://my.service.com/foo/
          4. Coldfusion CAS client fails because there is no service ticket.
--->