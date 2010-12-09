<cfcomponent output="false">
  <cffunction name="init" access="public" output="no" returntype="PgtTicketStore" hint="Initialize the pgt ticket store cache">
    <cfargument name="defaultTimeout" type="numeric" required="no" default="60000" hint="The default timeout time for a proxy granting ticket in milliseconds" />

    <cfset Variables.cache = {} />
    
    <cfreturn this />
  </cffunction>
  
  <cffunction name="receive" access="public" output="yes" hint="Receives the proxy granting ticket from the CAS Server">
    <cfargument name="urlParameters" required="yes" hint="The URL parameters from the request" />
    
    <cfparam name="urlParameters.pgt" default=""/>
    <cfparam name="urlParameters.pgtId" default=""/>
    <cfparam name="urlParameters.pgtIOU" default=""/>

    <!--- CAS Protocol spec says that the argument should be called 'pgt', but the JA-SIG CAS server seems to use pgtId.  --->
    <!--- To accomodate this, we check for both parameters, although 'pgt' takes precedence over 'pgtId'.                 --->

    <cfset pgt = ""/>
    <cfif len(trim(urlParameters.pgt)) GT 0>
      <cfset pgt = trim(urlParameters.pgt)>
    <cfelse>
      <cfset pgt = trim(urlParameters.pgtId)>
    </cfif>
    
    <cfset pgtIOU = trim(urlParameters.pgtIOU)>
    
    <cflog 
        text="Received pgt [#pgt#] for pgtIOU [#pgtIOU#], "
        file="cas_client" 
        application="no"/>       
          
    <cfif len(pgt) LE 0 OR len(pgtIOU) LE 0 >
      <cfreturn />
    </cfif>
    
    <cflock timeout="10">
        <cfscript>
          proxyTicketHolder = {
            pgt = pgt, 
            timeInserted = #Now()#
          };
          
          Variables.cache[pgtIOU] = proxyTicketHolder;
        </cfscript>
    </cflock>
  </cffunction>
  
  <cffunction name="retrieve" access="public" output="no" hint="Allows the user to retrieve the proxy granting ticket using the pgtIOU">
    <cfargument name="urlParameters" required="yes" hint="The URL parameters from the request" />

    <cfparam name="urlParameters.pgtIOU" default=""/>
    <cfset pgtIOU = trim(#urlParameters.pgtIOU#) />

    <cfif len(trim(pgtIOU)) LE 0 OR NOT StructKeyExists(Variables.cache, "#trim(pgtIOU)#")>
      <cfreturn />
    </cfif>

    <cfset pgt = Variables.cache[pgtIOU].pgt />
    <cfscript>StructDelete(Variables.cache, "#pgtIOU#");</cfscript>
    
    <cflog 
        text="Retrieved pgt [#pgt#] for pgtIOU [#pgtIOU#], "
        file="cas_client" 
        application="no"/>

        
    <cfreturn pgt />
  </cffunction>
  
  <cffunction name="dump" access="public" output="yes">
    <cfloop collection="#Variables.cache#" item="pgtIOU">
      <cfoutput>
        <b>#pgtIOU#:</b> #Variables.cache[pgtIOU].pgt#, #Variables.cache[pgtIOU].timeInserted#<br />
      </cfoutput>
    </cfloop>
  </cffunction>
</cfcomponent>  
  
    