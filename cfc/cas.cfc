<!--- ColdFusion CAS Client Component
      By: John Watson
          jwatson2@ucmerced.edu
          Univeristy of California, Merced
          
      This client is compliant with the CAS 2.0 Protocol specification written/tested with ColdFusion 8
      
      Additional features:
        Single Sign Out
        Attributes (per JA-SIG CAS Client for Java 3.1)
      
      Does not support:
        Proxying
        
      v1.0 [2009-05-01] - Initial Release
--->      
      
<cfcomponent displayname="CF CAS Component" output="no" author="John Watson">
  <cffunction name="init" access="public" output="no" returntype="cas" hint="Initialize the CAS object">
    <cfargument name="cas_server" type="string" required="yes" hint="URL for the CAS server (Ex. https://cas.school.edu/cas)" />
    <cfargument name="service" type="string" required="yes" hint="URL for the service (Ex. http://someapp.school.edu/app)" />
    <cfargument name="cas_proxy_callback_receive" type="string" required="no" hint="URL for the CAS server to issue callback requsts that include proxy granting tickets and proxy granting ticket IOUs (Ex. http://cas.school.edu/receive_pgt)" />
    <cfargument name="cas_proxy_callback_retrieve" type="string" required="no" hint="URL for the CAS server to issue callback requsts that include proxy granting tickets and proxy granting ticket IOUs (Ex. http://cas.school.edu/receive_pgt)" />
    <cfargument name="final_page" type="string" required="no" default="" hint="If 'direct_forwarding' is disabled, redirect user to this page" />
    <cfargument name="default_page" type="string" required="no" default="/" hint="After successful authentication, redirect user to their originally intended page" />
    <cfargument name="direct_forwarding" type="boolean" required="no" default="no" hint="After successful authentication, redirect user to their originally intended page" />
    <cfargument name="gateway" type="boolean" required="no" default="false" hint="Enable gatewaying" />
    <cfargument name="gateway_page" type="string" required="no" default="/index.cfm" hint="Page to send user to after being gatewayed and not being authenticated" />
    <cfargument name="renew" type="boolean" required="no" default="false" hint="Require primary authentication on CAS (disable single sign on)" />
    <cfargument name="isCAS3" type="boolean" required="no" default="true" hint="Is this a CAS3 server" />
    
    <cfset Variables.cas_server = Arguments.cas_server & IIF(Right(Arguments.cas_server,1) is not "/",DE('/'),DE('')) />
    <cfset Variables.service = Arguments.service />
    
    <cfset Variables.cas_proxy_callback_receive = Arguments.cas_proxy_callback_receive />
    <cfset Variables.cas_proxy_callback_retrieve = Arguments.cas_proxy_callback_retrieve />
    
    <cfset Variables.final_page = Arguments.final_page />
    <cfset Variables.default_page = Arguments.default_page />
    <cfset Variables.direct_forwarding = Arguments.direct_forwarding />
    <cfset Variables.gateway = Arguments.gateway />
    <cfset Variables.gateway_page = Arguments.gateway_page />
    <cfset Variables.renew = Arguments.renew />
    <cfset Variables.isCAS3 = Arguments.isCAS3 />
    
    <cfset Variables.username = "" />
    <cfset Variables.proxy_granting_ticket = "">
    <cfset Variables.requestedPage = "" />
    <cfset Variables.attributes = {} />
    
    <cfset Variables.gatewayed = false />
    
    <cfreturn this />
  </cffunction>
  
  <!--- Some of the logic in this function is derived from the CFML script by Christian Stuck --->
  <cffunction name="validate" access="public" output="no" returntype="void" hint="Validate user with CAS, if fail, send them to login page">
    <cfargument name="requestedPage" type="string" required="no" default="" hint="Requested page that is asking for CAS validation" />
    
    <cfset var service_ticket = "" />
    
    <cfif StructKeyExists(URL,"ticket")>
      <cfset service_ticket = URL.ticket />
    </cfif>
    
    <!--- User is not logged in --->
    <cfif Variables.username is "">
      <!--- Don't have a ST to validate --->
      <cfif service_ticket is "">
        <cfif Variables.gateway>
          <cfif Variables.gatewayed>
            <!--- If the user is on the gateway page and has been gatewayed, let them through --->
            <cfif Arguments.requestedPage is Variables.gateway_page>
              <cfset Variables.gatewayed = false />
              <cfreturn />
            <!--- If not on the right page but have been to CAS send them to the gateway page --->
            <cfelse>
              <cflocation url="#Variables.gateway_page#" addtoken="no" />
            </cfif>
          <cfelse>
            <cfset Variables.gatewayed = true />
           </cfif>
        </cfif>
        <!--- Store the page the user requested for when they come back --->
        <cfset Variables.requestedPage = IIf(Variables.direct_forwarding,'Arguments.requestedPage','Variables.default_page') />
        <cfinvoke method="login" />
      <cfelse>
        <cfinvoke method="serviceTicketValidate">
          <cfinvokeargument name="service_ticket" value="#service_ticket#" />
        </cfinvoke>
        
        <!--- ST Validation failed, get a new one --->
        <cfif Variables.username is "">
          <cfinvoke method="login" />
        </cfif>
        
        <!--- Map the ST to SessionID for Single-Sign-Out --->
        <cflock timeout="0" scope="Application" throwOnTimeout="no" type="exclusive">
          <cfset Application.CASSessions["#service_ticket#"] = Session.sessionId />
        </cflock>
        
        <!--- Clean up if user was gatewayed but were already authenticated --->
        <cfif Variables.gateway>
          <cfset Variables.gatewayed = false />
        </cfif>
        
        <cflocation url="#Variables.requestedPage#" addtoken="no" />
      </cfif>        
    </cfif>
  </cffunction>
   
  <cffunction name="serviceTicketValidate" access="public" output="no" returntype="void" hint="Validate the service ticket">
    <cfargument name="service_ticket" type="string" required="yes" hint="The ST to validate" />
  
    <!--- Contact the CAS server to validate the ticket --->
    <cfhttp url="#Variables.cas_server#serviceValidate" method="get">
      <cfhttpparam name="ticket" value="#Arguments.service_ticket#" type="url" />
      <cfhttpparam name="service" value="#Variables.requestedPage#" type="url" />
      <cfhttpparam name="pgtUrl" value="#Variables.cas_proxy_callback_receive#" type="url" />
    </cfhttp>
    
    <cflog file="cas_client" application="no" text="/servicevalidate response: #cfhttp.FileContent#.">
    <!--- Received a valid XML response --->
    <cfif IsXML(cfhttp.FileContent)>
      <cfset XMLobj = XmlParse(cfhttp.fileContent)>
      <!--- Check for the cas:user tag --->
      <cfset CASuser = XmlSearch(XMLobj, "cas:serviceResponse/cas:authenticationSuccess/cas:user")>
      
      <!--- Set the username to the value --->
      <cfif ArrayLen(CASuser)>
        <cfset Variables.username = CASuser[1].XmlText />
      </cfif>
      
      
      <cfif cas_proxy_callback_receive IS NOT '' OR cas_proxy_callback_retrieve IS NOT ''>
        <!--- Check for the cas:proxy tag --->
        <cfset CasPgtIouXml = XmlSearch(XMLobj, "cas:serviceResponse/cas:authenticationSuccess/cas:proxyGrantingTicket")>
        
        <!--- Get the proxy granting ticket IOU if available --->
        <cfif ArrayLen(CasPgtIouXml)>
          <cfset CasPgtIou = CasPgtIouXml[1].XmlText />
        
          <!--- Get the proxy granting ticket from the cas proxy callback service --->
          <cfhttp url="#Variables.cas_proxy_callback_retrieve#" method="get">
            <cfhttpparam name="pgtIou" value="#CasPgtIou#" type="url" />
          </cfhttp>
          <cflog file="cas_client" application="no" text="#Variables.cas_proxy_callback_retrieve# response: #cfhttp.FileContent#.">
            
          <!--- Verify the response contains a proxy granting ticket --->
          <cfif REFindNoCase("^[TP]GT-.*$", cfhttp.FileContent) IS NOT 0>
            <cfset proxy_granting_ticket = trim(cfhttp.FileContent)>
          <cfelse>
            <cflog file="cas_client" application="no" text="Problem retrieving proxy granting ticket; entity does not appear to contain a PGT">
          </cfif>
        <cfelse>
          <cflog file="cas_client" application="no" text="Problem retrieving proxy granting ticket IOU">
        </cfif>
      </cfif>
      
      <!--- Search for cas:attributes --->
      <cfset CASattributes = XmlSearch(XMLobj, "cas:serviceResponse/cas:authenticationSuccess/cas:attributes")>
      <!--- Go through all the attributes and add them to the attributes struct --->
      <cfif ArrayLen(CASattributes)>
        <cfloop array=#CASattributes[1].XmlChildren# index="attribute">
          <cfset StructInsert(Variables.attributes,RemoveChars(attribute.XmlName,1,Find(":",attribute.XmlName)),attribute.XmlText)/>
        </cfloop>
      </cfif>
    </cfif>
  </cffunction>
  
  <cffunction name="login" access="public" output="no" returntype="void" hint="Call CAS login page">
    <cfargument name="forceRenew" required="no" type="boolean" default="false" hint="Force them to provide primary authentication" />
    
    <!--- Encode service url before redirecting to the CAS server.
          This is done for us by cfhttpparam when validating the service ticket. --->
    <cfset encoded_service_url = URLEncodedFormat(Variables.requestedPage) />
    <cflocation url="#Variables.cas_server#login?service=#encoded_service_url##Iif(Variables.renew OR Arguments.forceRenew,DE('&renew=true'),DE(''))##Iif(Variables.gateway,DE('&gateway=true'),DE(''))#" addtoken="no" />
  </cffunction>
  
  <cffunction name="logout" access="public" output="no" returntype="void" hint="Call CAS logout page">
    <cfif Variables.isCAS3>
      <cflocation url="#Variables.cas_server#logout#IIf(Len(Variables.final_page),DE('?url=#Variables.final_page#'),DE(''))#" addtoken="no" />
    <cfelse>
      <cflocation url="#Variables.cas_server#logout#IIf(Len(Variables.final_page),DE('?destination=#Variables.final_page#'),DE(''))#" addtoken="no" />
    </cfif>
  </cffunction>
  
  <cffunction name="isLogoutRequest" access="public" output="no" returntype="boolean" hint="Check if it's a single sign out request">
    <cfset var endRequest = StructKeyExists(Form,"logoutrequest") AND IsXML(Form.logoutrequest) />
    <cfset var sessionTracker = CreateObject("java","coldfusion.runtime.SessionTracker") />
    
    <cfif endRequest>
      <cftry>
        <cfset xmlDoc = XmlParse(Form.logoutrequest) />
        <cfset xmlRes = XmlSearch(xmlDoc,"samlp:LogoutRequest/samlp:SessionIndex") />
        <cfcatch type="any">
          <cflog text="#cfcatch#" file="saml" />
          <cfreturn false />
        </cfcatch>
      </cftry>
      
      <cftry>
        <cflock timeout="0" scope="Application" throwOnTimeout="no" type="exclusive">
          <!--- Check to see if we know this ST --->
          <cfif StructKeyExists(Application.CASSessions,xmlRes[1].xmlText)>
            <!--- Attempt to retrieve the Session  --->
            <cfset sessionToKill = sessionTracker.getSession("#Application.applicationName#_#Application.CASSessions['#xmlRes[1].xmlText#']#") />
            <!--- If it does, clear it out --->
            <cfif IsDefined("sessionToKill")>
              <cfset StructClear(sessionToKill) />
            </cfif>
            <!--- Forget the ST --->
            <cfset StructDelete(Application.CASSessions,xmlRes[1].xmlText) />
          </cfif>
        </cflock>
        <!--- Problem with destroying the session, doesn't exist? --->
        <cfcatch type="any">
          <cfreturn true />
        </cfcatch>
      </cftry>
    </cfif>
    
    <cfreturn endRequest />
  </cffunction>

  <cffunction name="getProxyTicket" access="public" output="yes" returntype="string" hint="Get proxy ticket">
    <cfargument name="targetService" required="yes" type="string" hint="The service identifier of the back-end service cas is proxying authentication to" />

    <cfset proxy_ticket = ""/>

    <cfinvoke method="requestProxyTicket" returnVariable="proxyTicketingResponse">
      <cfinvokeargument 
          name="proxyGrantingTicket" 
          value="#Variables.proxy_granting_ticket#"/>
                        
      <cfinvokeargument 
          name="targetService" 
          value="#Arguments.targetService#"/>
    </cfinvoke>

    <cfinvoke method="parseProxyTicketingResponse" returnVariable="proxyTicket">
      <cfinvokeargument
          name="proxyTicketingResponse"
          value="#proxyTicketingResponse#"/>
    </cfinvoke>
    
    
    <cfreturn proxyTicket/>
  </cffunction>
  
  <cffunction name="requestProxyTicket" access="private" output="no" returntype="string" hint="Request proxy ticket from cas server">
    <cfargument 
        name="proxyGrantingTicket" 
        required="yes" 
        type="string" 
        hint="The Proxy Granting Ticket" />
                
    <cfargument 
        name="targetService"
        required="yes" 
        type="string" 
        hint="The service identifier of the back-end service cas is proxying authentication to" />
    
    
    <cfhttp url="#Variables.cas_server#proxy" method="get">
      <cfhttpparam 
          name="pgt" 
          value="#Arguments.proxyGrantingTicket#" 
          type="url" />
                   
      <cfhttpparam 
          name="targetService" 
          value="#Arguments.targetService#" 
          type="url" />
    </cfhttp>
    
    <cflog 
        text="#Variables.cas_server#proxy?pgt=#Variables.proxy_granting_ticket#&targetService=#Arguments.targetService# response: #cfhttp.FileContent#."
        file="cas_client" 
        application="no"/>       
          
    <cfif NOT IsXML(cfhttp.FileContent)>
      <cfthrow 
          type="CFCas.RequestException.ProxyTicket"
          message="There was a problem requesting a proxy ticket from the CAS server."/>
    </cfif>
    
    <cfreturn cfhttp.fileContent>
  </cffunction>
  
  
  <cffunction name="parseProxyTicketingResponse" access="private" output="no" returntype="string" hint="Parse proxy ticketing response from cas server">
    <cfargument 
        name="proxyTicketingResponse" 
        required="yes" 
        type="string" 
        hint="The Proxy Ticketing Response" />

    <cfset XMLobj = XmlParse(#Arguments.proxyTicketingResponse#)>      
    <cfset CasPtXml = XmlSearch(XMLobj, "cas:serviceResponse/cas:proxySuccess/cas:proxyTicket")>

    <!--- Get the cas proxy ticket --->
    <cfif NOT ArrayLen(CasPtXml)>
      <cflog 
          text="Problem parsing proxy ticket"
          file="cas_client" 
          application="no" />
          
      <cfthrow 
          type="CFCas.ParsingException.ProxyTicket"
          message="There was a problem parsing the proxy ticketing response."/>    
    </cfif>
    
    <cfreturn trim(CasPtXml[1].XmlText) />
  </cffunction>
  
  <!--- <cffunction name="proxyValidate" access="public" output="no" returntype="string" hint="Validates a proxy ticket for a given service">
    <cfargument name="ticket" required="yes" type="string" default="false" hint="The proxy ticket issued through getProxyTicket" />
    <cfargument name="service" required="yes" type="string" default="false" hint="The service identifier of the back-end service cas is proxying authentication to" />

  </cffunction> --->
  
  <cffunction name="invalidate" access="public" output="no" returntype="void" hint="Invalidate the CAS Session">
      <cfset Variables.username = "" />
  </cffunction>
  
  <cffunction name="getUsername" access="public" output="no" returntype="string" hint="Get the authenticated CAS username">
    <cfreturn Variables.username />
  </cffunction>
  
  <cffunction name="getAttribute" access="public" output="no" returntype="any" hint="Get an attribute that was returned by CAS (if it doesn't exist returns "")">
    <cfargument name="key" type="string" required="yes" hint="The attribute to retrieve" />
    
    <cfreturn IIf(StructKeyExists(Variables.attributes,Arguments.key),'Variables.attributes.#Arguments.key#',DE('')) />
  </cffunction>
  
  <cffunction name="getAllAttributes" access="public" output="no" returntype="struct" hint="Get the whole attributes struct">
    <cfreturn Variables.attributes />
  </cffunction>
  
  <cffunction name="getAllVariables" access="public" output="no" returntype="struct" hint="Get the whole attributes struct">
    <cfreturn Variables />
  </cffunction>
  
</cfcomponent>