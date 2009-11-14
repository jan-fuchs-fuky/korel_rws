<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:strip-space elements="*"/>

<xsl:output
    method="html"
    indent="yes"
    encoding="UTF-8"
    doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
    doctype-system="http://www.w3.org/TR/html4/loose.dtd"/>

<xsl:variable name="service_url" select='"http://localhost:8000"'/>
<xsl:variable name="user" select='"fuky"'/>

<xsl:template name="html.static">
<html lang="en">
<head>
    <meta http-equiv="Content-language" content="en"/>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <title>Korel Universal Worker Service</title>
    <link href="{$service_url}/default.css" rel="stylesheet" type="text/css"/>
    <meta name="description" content="Korel Universal Worker Service"/>
    <meta name="keywords" content="gnu,gpl,open,source,linux,debian,python,uws,universal,worker,service,korel"/>
    <meta name="author" content="Jan Fuchs"/>
</head>
<body bgcolor="#CCCCCC">
    <hr/>
    <div class="menu">
        <a href="{$service_url}">Home</a> -
        <a href="{$service_url}/help">Help</a> -

        <xsl:choose>
            <xsl:when test="not(string($user))">
                <a href="{$service_url}/user/register">Create New Account</a> -
                <a href="{$service_url}/login">Login</a>
            </xsl:when>
            <xsl:otherwise>
                User <b><xsl:value-of select="$user"/></b> is logged on -
                <a href="{$service_url}/logout">Logout</a>
            </xsl:otherwise>
        </xsl:choose>

    </div>
    <hr/>

    <xsl:call-template name="html.dynamic"/>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
