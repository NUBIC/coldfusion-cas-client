<html>
<body>
<cfoutput>#ucase("hello world")#</cfoutput>

<br/>
<!---<cfoutput>#MM_Username#</cfoutput>--->
<!--- <cfinvoke component = "Session.CFCAS" method = "validate('index.cfm')" returnVariable = "userName"/> --->

<!--- <cfoutput>#StructKeyExists(URL,"ticket")#</cfoutput> --->
<cfinvoke component = "#Session.CFCAS#" method = "getUsername" returnVariable = "userName"/><br/>
<cfoutput>Username: #userName#</cfoutput><br/>
<!--- <cfdump var = "#Session.CFCAS#"/> --->
<!--- <cfinvoke component = "#Session.CFCAS#" method = "getAllVariables" returnVariable = "allVariables"/>
<cfdump var = "#allVariables#"/> --->
<cfinvoke component = "#Session.CFCAS#" method = "getProxyTicket" returnVariable = "pt"/>
<cfoutput>#pt#</cfoutput>
<!--- <cfoutput>StructKeyExists(URL,"ticket"): #StructKeyExists(URL,"ticket")#</cfoutput><br/> --->
<!--- <cfoutput>Session.ticket: #Session.ticket#</cfoutput><br/> --->
<!--- <cfoutput>Session.xml: #Session.xml#</cfoutput> --->
</body>
</html>