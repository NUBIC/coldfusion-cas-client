<html>
<head>
  <script type="text/javascript" src="jquery-1.3.2.min.js"></script>

  <script type="text/javascript">
    $(document).ready(function(){      
      $("#service").click(function(event){
        $.getJSON("whoami_service.cfm?ticket=" + $("#proxy-ticket").text(),
          function(data, textStatus){
            alert(
              'Whoami URL: ' + 'whoami_service.cfm?ticket=' + $("#proxy-ticket").text() + '\n\n' +
              'Whoami Response: ' + data['username']
            );
          }
        );
      });
    });
    
  </script>
</head>
<body>
<cfoutput>#ucase("hello world")#</cfoutput>

<br/>
<cfset userName = ""/>
<cfinvoke component = "#Session.CFCAS#" method = "getUsername" returnVariable = "userName"/><br/>
<cfoutput>Username: #userName#</cfoutput><br/>

<cfset proxyTicket = ""/>
<cfinvoke component = "#Session.CFCAS#" method = "getProxyTicket" returnVariable = "proxyTicket">
  <cfinvokeargument name="targetService" value="http://0.0.0.0:3000/whoami.json"/>  
</cfinvoke>

<cfoutput>Proxy Ticket: <span id="proxy-ticket">#proxyTicket#</span></cfoutput>

<br/><br/>
<button id="service">Get Username from Test Service</button>
</body>
</html>