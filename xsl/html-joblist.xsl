<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <p>
        <xsl:variable name="disk_full" select="uws:joblist/disk_full"/>
        <xsl:if test="$disk_full='True'">
            <div class="errmsg">Disk Quota Exceeded.</div>
        </xsl:if>

        Using <xsl:value-of select="uws:joblist/disk_usage"/>
        (<xsl:value-of select="uws:joblist/disk_usage_pct"/>%)
        of your <xsl:value-of select="uws:joblist/disk_space"/>.
    </p>

    <table>
    <tr>
        <td><b>ID</b></td>
        <td><b>Project</b></td>
        <td><b>Starting Time</b></td>
        <td><b>Running Time</b></td>
        <td colspan="4"><b>Phase</b></td>
    </tr>
    
    <xsl:for-each select="uws:joblist/uws:job">
    <xsl:variable name="phase" select="uws:phase"/>
    <xsl:variable name="jobId" select="uws:jobId"/>
    <tr>
        <td><a href="{$service_url}/jobs/{$jobId}"><b><xsl:value-of select="uws:jobId"/></b></a></td>
        <td><xsl:value-of select="uws:jobInfo/project"/></td>
        <td><xsl:value-of select="uws:startTime"/></td>
        <td><xsl:value-of select="uws:jobInfo/runningTime"/></td>
        <td><xsl:value-of select="uws:phase"/></td>

        <xsl:if test="not($phase='PENDING')">
            <xsl:choose>
                <xsl:when test="$phase='EXECUTING'">
                    <td>
                        <form action="{$service_url}/jobs/{$jobId}/phase" method="POST">
                        <input type="hidden" name="PHASE" value="ABORT"/>
                        <input type="submit" value="Abort"/>
                        </form>
                    </td>
                </xsl:when>
                <xsl:otherwise>
                    <td>
                        <form action="{$service_url}/jobs/{$jobId}/results" method="get">
                        <input type="submit" value="Show result"/>
                        </form>
                    </td>
                    <td>
                        <form action="{$service_url}/jobs/{$jobId}" method="POST">
                        <input type="hidden" name="ACTION" value="DELETE"/>
                        <input type="submit" value="Delete"/>
                        </form>
                    </td>
                    <td>
                        <form action="{$service_url}/jobs/{$jobId}/again" method="get">
                        <input type="submit" value="Run again"/>
                        </form>
                    </td>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>

        <td>
        <xsl:if test="$phase='PENDING'">
            <form action="{$service_url}/jobs/{$jobId}/phase" method="POST">
            <input type="hidden" name="PHASE" value="RUN"/>
            <input type="submit" value="Run"/>
            </form>
        </xsl:if>
        </td>
    </tr>
    </xsl:for-each>
    
    </table>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="uws:joblist/uws:ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
