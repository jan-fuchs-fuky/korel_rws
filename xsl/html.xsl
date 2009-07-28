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
        <xsl:choose>
            <xsl:when test="name(/*)='phase'">
                <xsl:value-of select="$html/begin_refresh" disable-output-escaping="yes"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$html/begin" disable-output-escaping="yes"/>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="$html/header" disable-output-escaping="yes"/>

        <!-- BEGIN results -->
        <xsl:if test="name(/*)='result'">
            <xsl:variable name="id" select="/result/id"/>
            <xsl:variable name="phase" select="/result/phase"/>

            <h2>Result of job</h2>

            <p>
            Job <xsl:value-of select="$id"/>
            user <xsl:value-of select="/result/user"/>
            <xsl:text> </xsl:text><xsl:value-of select="$phase"/>.
            </p>

            <p><form action="/jobs/{$id}/again" method="get">
            <input type="submit" value="run again"/>
            </form></p>

            <xsl:if test="not($phase='EXECUTING')">
                <xsl:for-each select="result/link">
                    <xsl:variable name="link" select="."/>
                    <a href="/jobs/{$id}/results/{$link}">
                    <xsl:value-of select="$link"/>
                    </a><br/><xsl:text>&#xa;</xsl:text>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>
        <!-- END results -->

        <!-- BEGIN phase -->
        <xsl:if test="name(/*)='phase'">
            <xsl:variable name="user" select="/phase/user"/>
            <xsl:variable name="id" select="/phase/id"/>
            <xsl:variable name="phase" select="/phase/phase"/>

            <h2>Phase of job <xsl:value-of select="$id"/> user <xsl:value-of select="$user"/></h2>
            <xsl:choose>
                <xsl:when test="$phase='EXECUTING'">
                    The job is running.
                </xsl:when>
                <xsl:when test="$phase='COMPLETED'">
                    The job has completed successfully.
                </xsl:when>
                <xsl:when test="$phase='ERROR'">
                    Some form of error has occurred.
                </xsl:when>
                <xsl:otherwise>
                    The job is in an unknown state.
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <!-- END phase -->

        <!-- BEGIN again -->
        <xsl:if test="name(/*)='again'">
            <xsl:variable name="new_id" select="/again/new_id"/>

            <h2>Again job <xsl:value-of select="/again/id"/> as job <xsl:value-of select="$new_id"/></h2>

            <form action="/jobs/{$new_id}/againstart" method="post">
            <p><textarea name="korel_par" cols="80" rows="15"><xsl:value-of select="/again/korel_par"/></textarea></p>
            <p><input type="submit" value="Start"/></p>
            </form>
        </xsl:if>
        <!-- END again -->

        <!-- BEGIN jobslist -->
        <xsl:if test="name(/*)='jobslist'">
            <h2>List of jobs user <xsl:value-of select="/jobslist/user"/></h2>
            <table>
            <tr><td><b>ID</b></td><td colspan="4"><b>Phase</b></td></tr>

            <xsl:for-each select="jobslist/job">
                <xsl:variable name="id" select="./id"/>
                <xsl:variable name="phase" select="./phase"/>

                <tr>
                <td><xsl:value-of select="$id"/></td>
                <td><xsl:value-of select="$phase"/></td>

                <td>
                <xsl:choose>
                    <xsl:when test="not($phase='EXECUTING')">
                        <form action="/jobs/{$id}/results" method="get">
                        <input type="submit" value="show result"/>
                        </form>
                    </xsl:when>
                    <xsl:otherwise>
                        <form action="/jobs/{$id}" method="post">
                        <input type="submit" value="cancel job"/>
                        </form>
                    </xsl:otherwise>
                </xsl:choose>
                </td>

                <td>
                    <form action="/jobs/{$id}/again" method="get">
                    <input type="submit" value="run again"/>
                    </form>
                </td>

                <td>
                    <form action="/jobs/{$id}/remove" method="get">
                    <input type="submit" value="remove"/>
                    </form>
                </td>

                </tr><xsl:text>&#xa;</xsl:text>
            </xsl:for-each>

            </table>
        </xsl:if>
        <!-- END jobslist -->

        <!-- BEGIN register_user -->
        <xsl:if test="name(/*)='register_user'">
            <h2>Register user</h2>

            <xsl:if test="not(/register_user/errmsg='')">
                <div class="errmsg"><xsl:value-of select="/register_user/errmsg"/></div>
            </xsl:if>

            <form action="/user/register" method="post" enctype="multipart/form-data">
                <table>
                <tr>
                    <td>First Name:</td>
                    <td><input type="text" name="first_name" value="{/register_user/first_name}"/></td>
                </tr>
                <tr>
                    <td>Surname:</td>
                    <td><input type="text" name="surname" value="{/register_user/surname}"/></td>
                </tr>
                <tr>
                    <td>Organization:</td>
                    <td><input type="text" name="organization" value="{/register_user/organization}"/></td>
                </tr>
                <tr>
                    <td>Login:</td>
                    <td><input type="text" name="login" value="{/register_user/login}"/></td>
                </tr>
                <tr>
                    <td>Password:</td>
                    <td><input type="password" name="password"/></td>
                </tr>
                <tr>
                    <td><nobr>Re-type Password:</nobr></td>
                    <td><input type="password" name="retype_password"/></td>
                </tr>
                <tr>
                    <td>E-mail:</td>
                    <td><input type="text" name="email" value="{/register_user/email}"/></td>
                </tr>
                <tr>
                    <td><img src="/mathproblem/{/register_user/mathproblem_png}"/>
                        <input type="hidden" name="mathproblem_png" value="{/register_user/mathproblem_png}"/></td>
                    <td><input type="text" name="mathproblem_solution"/></td>
                    <td>This question is for testing whether you are a human visitor and to
                        prevent automated spam submissions. Solve this simple math problem
                        and enter the result. E.g. for 1+3, enter 4.</td>
                </tr>
                <tr>
                    <td colspan="2"><input type="submit" value="Register"/></td>
                </tr>
                </table>
            </form>
        </xsl:if>
        <!-- END register_user -->

        <!-- BEGIN body -->
        <xsl:if test="name(/*)='body'">
            <xsl:value-of select="/body" disable-output-escaping="yes"/>
        </xsl:if>
        <!-- END body -->

        <xsl:value-of select="$html/end" disable-output-escaping="yes"/>
</xsl:template>

</xsl:stylesheet>
