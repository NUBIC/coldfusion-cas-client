<!--- 
  This is a workaround for issues with:
    1. Cross site scripting protection issues in jQuery
    2. Redirects not being followed in jQuery.
 --->
<cfheader name = "content-type" value = "application/json; charset=utf-8"/>
<cfsetting showDebugOutput="No">
  
<cfhttp url="http://0.0.0.0:3000/whoami.json" method="get">
  <cfhttpparam name="ticket" value="#URL.ticket#" type="url" />
</cfhttp>

   
<cfoutput>#cfhttp.FileContent#</cfoutput>