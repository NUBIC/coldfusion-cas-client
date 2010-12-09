<cfif not StructKeyExists(Application,"PgtTicketStore") OR not IsInstanceOf(Application.PgtTicketStore,"PgtTicketStore")>
  <cfreturn />
</cfif>

<cfset pgt = Application.PgtTicketStore.retrieve(urlParameters = URL) />
<cfparam name="pgt" default="">
PGT: <cfoutput>#pgt#</cfoutput>
<br/>
<cfinvoke component="#Application.PgtTicketStore#" method="dump" />
