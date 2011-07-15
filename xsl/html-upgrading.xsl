<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <h2>Please wait...</h2>
    <p>
        Upgrading VO-KOREL Web Service in progress.
    </p>
    <p>
        <center><img src="/images/icon_inprogress.gif"/></center>
    </p>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
