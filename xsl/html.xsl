<?xml version="1.0"?>

<xsl:stylesheet
    version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:strip-space elements="*"/>

<xsl:output
    method="html"
    indent="yes"
    encoding="UTF-8"
    doctype-public="-//W3C//DTD HTML 4.01 Transitional//EN"
    doctype-system="http://www.w3.org/TR/html4/loose.dtd"/>

<xsl:variable name="html" select="document('../xml/html.xml')/html"/>

<xsl:template match="/">
        <xsl:value-of select="$html/begin" disable-output-escaping="yes"/>
        <xsl:value-of select="$html/header" disable-output-escaping="yes"/>

        <!-- BEGIN result-id -->
        <xsl:if test="name(/*)='result'">
            <xsl:variable name="id" select="/result/id"/>

            <h2>Result of job <xsl:value-of select="$id"/> user <xsl:value-of select="/result/user"/></h2>

            <xsl:for-each select="result/link">
                <xsl:variable name="link" select="."/>
                <a href="/jobs/{$id}/result-id/{$link}">
                <xsl:value-of select="$link"/>
                </a><br/><xsl:text>&#xa;</xsl:text>
            </xsl:for-each>
        </xsl:if>
        <!-- END result-id -->

        <!-- BEGIN start -->
        <xsl:if test="name(/*)='start'">
            <xsl:variable name="id" select="/start/id"/>

            <h2>Start new job</h2>
            <xsl:choose>
                <xsl:when test="$id='-1'">
                    Failure. Must upload files korel.dat and korel.par.
                </xsl:when>
                <xsl:otherwise>
                    Start job <xsl:value-of select="$id"/> success.
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- END start -->

        <!-- BEGIN jobslist -->
        <xsl:if test="name(/*)='jobslist'">
            <h2>List of jobs user <xsl:value-of select="/jobslist/user"/></h2>
            <table>
            <tr><td><b>ID</b></td><td colspan="4"><b>State</b></td></tr>

            <xsl:for-each select="jobslist/job">
                <xsl:variable name="id" select="./id"/>
                <xsl:variable name="state" select="./state"/>

                <tr>
                <td><xsl:value-of select="$id"/></td>
                <td><xsl:value-of select="$state"/></td>

                <td>
                <xsl:choose>
                    <xsl:when test="$state='success'">
                        <form action="/jobs/{$id}/result-id" method="get">
                        <input type="submit" value="show result"/>
                        </form>
                    </xsl:when>
                    <xsl:otherwise>
                        <form action="/jobs/{$id}" method="post">
                        <input type="submit" value="kill job"/>
                        </form>
                    </xsl:otherwise>
                </xsl:choose>
                </td>

                <td>
                    <xsl:if test="$state='success'">
                        <form action="/jobs/{$id}" method="get">
                        <input type="submit" value="run again"/>
                        </form>
                    </xsl:if>
                </td>

                <td>
                    <xsl:if test="$state='success'">
                        <form action="/jobs/{$id}/remove" method="get">
                        <input type="submit" value="remove"/>
                        </form>
                    </xsl:if>
                </td>

                </tr><xsl:text>&#xa;</xsl:text>
            </xsl:for-each>

            </table>
        </xsl:if>
        <!-- END jobslist -->

        <!-- BEGIN body -->
        <xsl:if test="name(/*)='body'">
            <xsl:value-of select="/body" disable-output-escaping="yes"/>
        </xsl:if>
        <!-- END body -->

        <xsl:value-of select="$html/end" disable-output-escaping="yes"/>
</xsl:template>

</xsl:stylesheet>
