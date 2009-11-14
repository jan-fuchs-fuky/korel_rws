<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:strip-space elements="*"/>

<xsl:output
    method="html"
    indent="yes"
    encoding="UTF-8"
    doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
    doctype-system="http://www.w3.org/TR/html4/loose.dtd"/>

<xsl:variable name="service_url" select='"https://127.0.0.1:8000"'/>


<xsl:template name="html.static">
    <xsl:param name="ownerId" select="''"/>

    <html lang="en">
    <head>
        <meta http-equiv="Content-language" content="en"/>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
        <title>Korel Universal Worker Service</title>
        <link href="{$service_url}/css/default.css" rel="stylesheet" type="text/css"/>
        <meta name="description" content="Korel Universal Worker Service"/>
        <meta name="keywords" content="gnu,gpl,open,source,linux,debian,python,uws,universal,worker,service,korel"/>
        <meta name="author" content="Jan Fuchs"/>
    </head>
    <body>
    <center>
    <table class="main">
        <tr><td>
            <h1>Korel Universal Worker Service</h1>
        </td></tr>

        <tr><td>
            <hr/>
            <div class="menu">
                <a href="{$service_url}">Home</a> -
                <a href="{$service_url}/help">Help</a> -
    
                <xsl:choose>
                    <xsl:when test="not(string($ownerId))">
                        <a href="{$service_url}/user/register">Create New Account</a> -
                        <a href="{$service_url}/login">Login</a>
                    </xsl:when>
                    <xsl:otherwise>
                        User <b><xsl:value-of select="$ownerId"/></b> is logged on -
                        <a href="{$service_url}/logout">Logout</a>
                    </xsl:otherwise>
                </xsl:choose>
    
            </div>
            <hr/>
        
            <xsl:if test="string($ownerId)">
                <table>
                <tr><td>
                    <form action="{$service_url}/jobs" method="POST">
                    <input type="submit" value="Create new job"/>
                    </form>
                </td>
                <td>
                    <form action="{$service_url}/jobs" method="GET">
                    <input type="submit" value="List jobs"/>
                    </form>
                </td></tr>
                </table>
            </xsl:if>

            <xsl:call-template name="html.dynamic"/>
        </td></tr>
    </table>
    </center>
    </body>
    </html>
</xsl:template>


</xsl:stylesheet>
