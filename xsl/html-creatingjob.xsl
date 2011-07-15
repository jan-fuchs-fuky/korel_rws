<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:uws="http://www.ivoa.net/xml/UWS/v1.0rc3"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
<h2>Create new job</h2>
<form action="{$service_url}/jobs" method="POST" enctype="multipart/form-data">
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
        <td colspan="2">
        Please attach korel.dat and korel.par (plus korel.tmp if a template is required).
        You may use alternatively an archive korel.(zip|tar.gz|tar.bz2).
        Archive must contain a <em>korel</em> directory. The korel
        directory can contain korel.dat, korel.par and korel.tmp. 
        <p>
        After clicking the <code>Start</code> button the files are uploaded to the server, the job is created
        and prepared to run (after clicking the <code>Run</code> button). You may upload and create several jobs,
        and run them afterwards from the list of jobs. If more than five jobs are running, the further are queued
        and run once other is finished.
        </p> 

        </td>
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
        <td>korel.tmp:</td>
        <td><input type="file" name="korel_tmp"/></td>
    </tr>
    <tr>
        <td><nobr>korel.(zip|tgz|tbz2):</nobr></td>
        <td><input type="file" name="korel_archive"/></td>
    </tr>
    <tr>
        <td>Send result on e-mail:</td>
        <td>
            <input type="text" name="email" value="{/creatingjob/email}"/>
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
        <xsl:with-param name="ownerId" select="creatingjob/ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
