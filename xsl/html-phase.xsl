<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>


<xsl:template name="html.dynamic">
    <h2>Phase</h2>
    <xsl:value-of select="/phase/value"/>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="phase/ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
