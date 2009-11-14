<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<xsl:template name="html.dynamic">
<table>
<tr>
    <td><b>ID</b></td>
    <td><b>Project</b></td>
    <td><b>Starting Time</b></td>
    <td><b>Running Time</b></td>
    <td colspan="4"><b>Phase</b></td>
</tr>

<xsl:for-each select="uws:joblist/uws:job" xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3">
<tr>
    <td><b><xsl:value-of select="uws:jobId"/></b></td>
    <td><b><xsl:value-of select="uws:jobInfo/project"/></b></td>
    <td><b><xsl:value-of select="uws:startTime"/></b></td>
    <td><b><xsl:value-of select="uws:jobInfo/runningTime"/></b></td>
    <td colspan="4"><b><xsl:value-of select="uws:phase"/></b></td>
</tr>
</xsl:for-each>

</table>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static"/>
</xsl:template>

</xsl:stylesheet>
