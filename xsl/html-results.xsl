<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <xsl:variable name="id" select="/result/id"/>
    <xsl:variable name="phase" select="/result/phase"/>

    <h2>Result of job</h2>

    <p>
    Job <xsl:value-of select="$id"/>
    <xsl:text> </xsl:text><xsl:value-of select="$phase"/>.
    </p>

    <p><form action="/jobs/{$id}/again" method="get">
    <input type="submit" value="run again"/>
    </form></p>

    <xsl:if test="not($phase='EXECUTING')">
        <p>
        <xsl:for-each select="result/link">
            <xsl:variable name="link" select="."/>

            <xsl:choose>
                <xsl:when test="not(@type='normal')">
                    <a href="/jobs/{$id}/results/{$link}" class="{@type}">
                        <xsl:value-of select="$link"/>
                    </a>
                </xsl:when>
                <xsl:otherwise>
                    <a href="/jobs/{$id}/results/{$link}">
                        <xsl:value-of select="$link"/>
                    </a>
                </xsl:otherwise>
            </xsl:choose>

            &#160;<xsl:value-of select="@size"/><br/>
        </xsl:for-each>
        </p>

        <xsl:for-each select="result/plot">
            <h2>
                Picture <code><xsl:value-of select="."/></code>
                from file <code><xsl:value-of select="@source"/></code>
            </h2>

            <p><img src="/jobs/{$id}/results/{.}" alt="{.}"/></p>
            <hr/>
        </xsl:for-each>

        <xsl:for-each select="result/component">
            <h2>
                Picture <code><xsl:value-of select="."/></code>
                from file <code>korel.spe</code>
            </h2>

            <p><img src="/jobs/{$id}/results/{.}" alt="{.}"/></p>
        </xsl:for-each>
    </xsl:if>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="result/ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
