<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>


<xsl:template name="html.dynamic">
    <xsl:variable name="phase" select="uws:job/uws:phase"/>
    <xsl:variable name="jobId" select="uws:job/uws:jobId"/>

    <h2>Job</h2>

    <table>
    <tr>
        <td>Comment</td>
        <td><xsl:value-of select="uws:job/uws:jobInfo/comment"/></td>
    </tr>
    <tr>
        <td>Phase</td>
        <td>
            <xsl:value-of select="$phase"/><br/>
            <xsl:choose>
                <xsl:when test="$phase='PENDING'">
                    <form action="{$service_url}/jobs/{$jobId}/phase" method="POST">
                        <input type="hidden" name="PHASE" value="RUN"/>
                        <input type="submit" value="RUN"/>
                    </form>
                </xsl:when>
                <xsl:when test="$phase='COMPLETED'">
                    <form action="{$service_url}/jobs/{$jobId}" method="POST">
                        <input type="hidden" name="ACTION" value="DELETE"/>
                        <input type="submit" value="DELETE"/>
                    </form>
                </xsl:when>
                <xsl:when test="$phase='EXECUTING'">
                    <form action="{$service_url}/jobs/{$jobId}/phase" method="POST">
                        <input type="hidden" name="PHASE" value="ABORT"/>
                        <input type="submit" value="ABORT"/>
                    </form>
                </xsl:when>
            </xsl:choose>
        </td>
    </tr>
    <tr>
        <td>Start</td>
        <td><xsl:value-of select="uws:job/uws:startTime"/></td>
    </tr>
    <tr>
        <td>End</td>
        <td><xsl:value-of select="uws:job/uws:endTime"/></td>
    </tr>
    <tr>
        <td>ExecutionDuration</td>
        <td><xsl:value-of select="uws:job/uws:executionDuration"/></td>
    </tr>
    <tr>
        <td>Destruction</td>
        <td><xsl:value-of select="uws:job/uws:destruction"/></td>
    </tr>
    <tr>
        <td colspan="2"><b>PA details</b></td>
    </tr>
    <tr>
        <td colspan="2">
            <xsl:for-each select="uws:job/uws:parameters/uws:parameter">
                <xsl:choose>
                    <xsl:when test="@byReference='true'">
                        <a href="{.}">
                            <xsl:value-of select="@id"/>
                        </a><br/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- TODO -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </td>
    </tr>
    <tr>
        <td colspan="2"><a href="{$service_url}/jobs/{uws:job/uws:jobId}/results">Results</a></td>
    </tr>
    </table>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="uws:job/uws:ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
