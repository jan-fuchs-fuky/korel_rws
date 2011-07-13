<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <h2>Again job <xsl:value-of select="/again/id"/> as job <xsl:value-of select="/again/new_id"/></h2>

    <form action="/jobs/{/again/new_id}/againstart" method="POST">
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
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="/again/ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>

