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

<!-- http://geekswithblogs.net/Erik/archive/2008/04/01/120915.aspx -->
<xsl:template name="string-replace-all">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="by"/>
    <xsl:choose>
        <xsl:when test="contains($text, $replace)">
            <xsl:value-of select="substring-before($text,$replace)" disable-output-escaping="yes"/>
            <xsl:value-of select="$by" disable-output-escaping="yes"/>
            <xsl:call-template name="string-replace-all">
                <xsl:with-param name="text" select="substring-after($text,$replace)"/>
                <xsl:with-param name="replace" select="$replace"/>
                <xsl:with-param name="by" select="$by"/>
            </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
            <xsl:value-of select="$text" disable-output-escaping="yes"/>
        </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="html-begin">
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$html/begin"/>
        <xsl:with-param name="replace" select="'{$service_url}'"/>
        <xsl:with-param name="by" select="$service_url"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="html-begin-refresh">
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$html/begin_refresh"/>
        <xsl:with-param name="replace" select="'{$service_url}'"/>
        <xsl:with-param name="by" select="$service_url"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="html-header">
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$html/header"/>
        <xsl:with-param name="replace" select="'{$service_url}'"/>
        <xsl:with-param name="by" select="$service_url"/>
    </xsl:call-template>
</xsl:template>

<xsl:template name="html-end">
    <xsl:call-template name="string-replace-all">
        <xsl:with-param name="text" select="$html/end"/>
        <xsl:with-param name="replace" select="'{$service_url}'"/>
        <xsl:with-param name="by" select="$service_url"/>
    </xsl:call-template>
</xsl:template>

<xsl:template match="/">
        <xsl:choose>
            <xsl:when test="name(/*)='phase'">
                <xsl:call-template name="html-begin-refresh"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="html-begin"/>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:call-template name="html-header"/>

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

            <p><form action="{$service_url}/jobs/{$id}/again" method="get">
            <input type="submit" value="run again"/>
            </form></p>

            <xsl:if test="not($phase='EXECUTING')">
                <p>
                <xsl:for-each select="result/link">
                    <xsl:variable name="link" select="."/>

                    <xsl:choose>
                        <xsl:when test="not(@type='normal')">
                            <a href="{$service_url}/jobs/{$id}/results/{$link}" class="{@type}">
                                <xsl:value-of select="$link"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <a href="{$service_url}/jobs/{$id}/results/{$link}">
                                <xsl:value-of select="$link"/>
                            </a>
                        </xsl:otherwise>
                    </xsl:choose>

                    &#160;<xsl:value-of select="@size"/><br/>
                </xsl:for-each>
                </p>

                <p><img src="{$service_url}/jobs/{$id}/results/phg.png"/></p>

                <xsl:for-each select="result/component">
                    <p><img src="{$service_url}/jobs/{$id}/results/{.}"/></p>
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
                <xsl:when test="$phase='PREPARING'">
                    Preparing run job.
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

            <form action="{$service_url}/jobs/{$new_id}/againstart" method="post">
                <table>
                <tr>
                    <td>Project name:</td>
                    <td><input type="text" name="project" value="{/again/project}"/></td>
                </tr>
                <tr>
                    <td>Comment:</td>
                    <td><textarea name="comment" cols="60" rows="3"></textarea></td>
                </tr>
                <tr>
                    <td>korel.par:</td>
                    <td><textarea name="korel_par" cols="80" rows="15">
                        <xsl:value-of select="/again/korel_par"/>
                    </textarea></td>
                </tr>
                <tr>
                    <td>Send result on e-mail:</td>
                    <td>
                        <input type="text" name="email" value="{/again/email}"/>
                        <input type="checkbox" name="mailing" value="true"/>
                    </td>
                </tr>
                <tr>
                    <td colspan="2"><input type="submit" value="Start"/></td>
                </tr>
                </table>
            </form>
        </xsl:if>
        <!-- END again -->

        <!-- BEGIN jobslist -->
        <xsl:if test="name(/*)='jobslist'">
            <h2>List of jobs user <xsl:value-of select="/jobslist/user"/></h2>
            <table>
                <tr>
                    <td><b>ID</b></td>
                    <td><b>Project</b></td>
                    <td><b>Starting Time</b></td>
                    <td><b>Running Time</b></td>
                    <td colspan="4"><b>Phase</b></td>
                </tr>

            <xsl:for-each select="jobslist/job">
                <xsl:variable name="id" select="./id"/>
                <xsl:variable name="phase" select="./phase"/>

                <tr>
                <td><xsl:value-of select="$id"/></td>
                <td><xsl:value-of select="./project"/></td>
                <td><xsl:value-of select="./time_begin"/></td>
                <td><xsl:value-of select="./time_run"/></td>
                <td><xsl:value-of select="$phase"/></td>

                <td>
                <xsl:if test="not($phase='PREPARING')">
                    <xsl:choose>
                        <xsl:when test="not($phase='EXECUTING')">
                            <form action="{$service_url}/jobs/{$id}/results" method="get">
                            <input type="submit" value="show result"/>
                            </form>
                        </xsl:when>
                        <xsl:otherwise>
                            <form action="{$service_url}/jobs/{$id}" method="post">
                            <input type="submit" value="cancel job"/>
                            </form>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
                </td>

                <td>
                <xsl:if test="not($phase='PREPARING')">
                    <form action="{$service_url}/jobs/{$id}/again" method="get">
                    <input type="submit" value="run again"/>
                    </form>
                </xsl:if>
                </td>

                <td>
                    <form action="{$service_url}/jobs/{$id}/remove" method="get">
                    <input type="submit" value="remove"/>
                    </form>
                </td>

                </tr>

                <tr>
                    <td colspan="8"><i><b>Comment: </b><xsl:value-of select="./comment"/></i><br/><br/></td>
                </tr>

                <xsl:text>&#xa;</xsl:text>
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

            <form action="{$service_url}/user/register" method="post" enctype="multipart/form-data">
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
                    <td>Min. 3 characters. One character must be alpha.
                        Valid characters are alpha and dot and underscore.</td>
                </tr>
                <tr>
                    <td>Password:</td>
                    <td><input type="password" name="password"/></td>
                    <td>Min. 6 characters.</td>
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
                    <td><img src="{$service_url}/mathproblem/{/register_user/mathproblem_png}"/>
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

        <!-- BEGIN start_new_job -->
        <xsl:if test="name(/*)='start_new_job'">
            <body>
            <h2>Start new job</h2>
            <form action="{$service_url}/jobs" method="post" enctype="multipart/form-data">
                <table>
                <tr>
                    <td>Project name:</td>
                    <td><input type="text" name="project"/></td>
                </tr>
                <tr>
                    <td>Comment:</td>
                    <td><textarea name="comment" cols="60" rows="3"></textarea></td>
                </tr>
                <tr>
                    <td>korel.dat:</td>
                    <td><input type="file" name="korel_dat"/></td>
                </tr>
                <tr>
                    <td>korel.par:</td>
                    <td><input type="file" name="korel_par"/></td>
                </tr>
                <tr>
                    <td>Send result on e-mail:</td>
                    <td>
                        <input type="text" name="email" value="{/start_new_job/email}"/>
                        <input type="checkbox" name="mailing" value="true"/>
                    </td>
                </tr>
                <tr>
                    <td colspan="2"><input type="submit" value="Start"/></td>
                </tr>
                </table>
            </form>
            </body>
        </xsl:if>
        <!-- END start_new_job -->

        <!-- BEGIN body -->
        <xsl:if test="name(/*)='body'">
            <xsl:value-of select="/body" disable-output-escaping="yes"/>
        </xsl:if>
        <!-- END body -->

        <xsl:call-template name="html-end"/>
</xsl:template>

</xsl:stylesheet>
