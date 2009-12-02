<html>
<body>
<cfoutput>#ucase("hello world")#</cfoutput>

<br/>
<cfset userName = ""/>
<cfinvoke component = "#Session.CFCAS#" method = "getUsername" returnVariable = "userName"/><br/>
<cfoutput>Username: #userName#</cfoutput><br/>

<cfset proxyTicket = ""/>
<cfinvoke component = "#Session.CFCAS#" method = "getProxyTicket" returnVariable = "proxyTicket">
  <cfinvokeargument name="targetService" value="http://localhost:3000/whoami.xml"/>  
</cfinvoke>

<cfoutput>Proxy Ticket: #proxyTicket#</cfoutput>
</body>
</html>