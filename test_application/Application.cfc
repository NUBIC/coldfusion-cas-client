<!--- Application.cfc implementing the ColdFusion CAS Client Component v1.0
      By: John Watson
          jwatson2@ucmerced.edu
          University of California, Merced
--->
<cfcomponent output="false">
  <cfset THIS.name = "CFCASEx" />
  <cfset THIS.sessionManagement = true />
  
  <!--- Require the use of CAS --->
  <cfset Variables.require_CAS = true />
   <!--- Required information for CAS
          cas_server - URL for the cas server
          service - URL for this application
        Optional arguments [default]
          final_page [''] - Final redirection page after CAS logout, '' means no redirection
          direct_forwarding [false] - After successful authentication, redirect user to their originally intended page
          default_page ['/'] - If "direct_forwarding" is disabled, redirect user to this page
          gateway [false] - Enable gatewaying
          gateway_page ['/index.cfm'] - Page to send user to after being gatewayed and not being authenticated
          renew [false] - Require primary authentication on CAS (disable single sign on) --->
  <cfset Variables.CAS_arguments = { cas_server = "https://cas2.nubic.northwestern.edu/cas-staging/", 
                                     service = "http://localhost:8500/cfcas_test_app/cas_workaround.cfm", 
                                     cas_proxy_callback_receive = "https://cas2.nubic.northwestern.edu/cas-proxy-callback-staging/receive_pgt", 
                                     cas_proxy_callback_retrieve = "https://cas2.nubic.northwestern.edu/cas-proxy-callback-staging/retrieve_pgt", 
                                     direct_forwarding = true } />
                                     
   <!--- <cfset Variables.CAS_arguments = { cas_server = "http://localhost/cas", 
                                     service = "http://localhost:8500/cfcas_test_app/cas_workaround.cfm", 
                                     cas_proxy_callback_receive = "http://localhost/cas-proxy-callback/receive_pgt", 
                                     cas_proxy_callback_retrieve = "http://localhost/cas-proxy-callback/retrieve_pgt", 
                                     direct_forwarding = true } /> --->
  
  <!--- Following is not for CAS, but an improvement of security --->
  <!--- Is this a secure site (HTTPS) - 
        In CF Administrator -> Memory Variables
          "Use J2EE Session Variables" needs to be enabled --->
  <cfset Variables.secureSite = false />
  <!--- This prevents CFID and CFTOKEN being sent as cookies --->
  <cfset THIS.setClientCookies = false />

  <cffunction name="onApplicationStart" returnType="boolean" output="false">
    <!--- Initialize ST to SessionID struct in Application scope for Single-Sign-Out --->
    <cfif Variables.require_CAS>
      <cfset Application.CASSessions = StructNew() />
    </cfif>
    <cfreturn true />
  </cffunction>
  
  <cffunction name="onMissingTemplate" returnType="boolean">
    <cfargument name="targetpage" required="true" type="string" />
    
    <cfswitch expression="#ListLast(targetpage,'/')#">
      <!--- No actual logout.cfm page, instead perform CAS logout --->
      <cfcase value="logout.cfm">
        <cfif StructKeyExists(Session,"CFCAS") AND IsInstanceOf(Session.CFCAS,"cas")>
          <!--- Copy the object so we can run the logout method after ending the session --->
          <cfset CAS = Session.CFCAS />
          <cfinvoke method="onSessionEnd">
            <cfinvokeargument name="sessionScope" value="#Session#" />
            <cfinvokeargument name="appScope" value="#Application#" />
          </cfinvoke>
          <cfinvoke component="#CAS#" method="logout" />
        <cfelse>
          <!--- If there was not a CAS object, just display page not found error --->
          <cfinclude template="resources/pages/page_not_found.cfm" />
        </cfif>
      </cfcase>
      <cfdefaultcase>
        <cfinclude template="resources/pages/page_not_found.cfm" />
      </cfdefaultcase>
    </cfswitch>
    
    <cfreturn true />
  </cffunction>
  
  <cffunction name="onRequestStart" returnType="boolean">
    <cfargument name="thePage" type="string" required="true" />

    <cflog file="cas_client" application="no" text="onRequestStart invoked: http://#cgi.server_name##cgi.script_name#?#cgi.query_string#">    
    <cfif Variables.require_CAS>
      <cflock timeout="30" throwontimeout="no" type="exclusive" scope="session">
        <!--- Make sure the CAS object is initialized --->
        <cfif not StructKeyExists(Session,"CFCAS") OR not IsInstanceOf(Session.CFCAS,"cas")>
          <cfinvoke method="onSessionStart" />
        </cfif>
        <!--- Check if it is a Single-Sign-Out request --->
        <cfif Session.CFCAS.isLogoutRequest()>
          <cfabort />
        </cfif>
        <!--- Validate the CAS session --->
        <cfinvoke component="#Session.CFCAS#" method="validate">
          <cfinvokeargument name="requestedPage" value="#Arguments.thePage#" />
        </cfinvoke>
        
        <!--- Authorization code here
              Session.CFCAS.getUsername() will return the value of cas:user --->
      </cflock>
    </cfif>
    
    <cfreturn true />
  </cffunction>
  
  <cffunction name="onSessionStart" returnType="void" output="false">
    <!--- Make the cookie secure since CF doesn't do it (applies only to HTTPS sites)
          Firefox will keep the session cookie if "Show my  windows and tabs from last time" is enabled
            So even if the user closes the browser, they are techinically still logged into the application
            This makes the cookie secure, thus Firefox will destroy it appropriately --->
    <cfif Variables.secureSite>
      <cfcookie name="JSESSIONID" expires="NOW" />
      <cfcookie name="JSESSIONID" value="#Session.sessionid#" secure="yes" />
    </cfif>
    
    <!--- Initialize the CAS object --->
    <cfif Variables.require_CAS>
      <cfset Session.CFCAS = CreateObject("component","cas").init(argumentcollection = Variables.CAS_arguments) />
    </cfif>
  </cffunction>
  
  <cffunction name="onSessionEnd" returnType="void" output="false">
    <cfargument name="sessionScope" type="struct" required="true" />
    <cfargument name="appScope" type="struct" required="false" />
    
    <!--- Expire the cookie and clear the session scope --->
    <cfcookie name="JSESSIONID" expires="NOW" />
    <cfset StructClear(Arguments.sessionScope) />
  </cffunction>
</cfcomponent>