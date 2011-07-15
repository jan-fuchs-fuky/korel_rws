<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <h2>Register user</h2>

    <xsl:if test="string(/register/errmsg)">
        <div class="errmsg"><xsl:value-of select="/register/errmsg"/></div>
    </xsl:if>

    <form action="{$service_url}/user/register" method="POST" enctype="multipart/form-data">
        <table>
        <tr>
            <td>First Name:</td>
            <td><input type="text" name="first_name" value="{/register/first_name}"/></td>
        </tr>
        <tr>
            <td>Surname:</td>
            <td><input type="text" name="surname" value="{/register/surname}"/></td>
        </tr>
        <tr>
            <td>Organization:</td>
            <td><input type="text" name="organization" value="{/register/organization}"/></td>
        </tr>
        <tr>
            <td>Login:</td>
            <td><input type="text" name="login" value="{/register/login}"/></td>
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
            <td><input type="text" name="email" value="{/register/email}"/></td>
        </tr>
        <tr>
            <td><img src="{$service_url}/mathproblem/{/register/mathproblem_png}"/>
                <input type="hidden" name="mathproblem_png" value="{/register/mathproblem_png}"/></td>
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
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static"/>
</xsl:template>


</xsl:stylesheet>
