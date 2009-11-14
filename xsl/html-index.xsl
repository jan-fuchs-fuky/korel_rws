<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>


<xsl:template name="html.dynamic">
    <h2>Home</h2>
    <p>
    This service  is the tested for embedding Fourier disentangling into the
    Virtual Observatory infrastructure. Currently the system allows uploading
    of user data, on-the-fly modification of parameters and management of
    various version of Korel and user files. The system uses the well-known
    interface of electronic shop. The user can see only his own files (and it
    is guaranted that nobody (except the administrator) can access his private
    files.
    </p>
    
    <p>
    To achive this the full encryption is used and the user is required to
    register (create unique account). Before he can use the service, the
    administrator has to allow him explicitly.
    </p>
    
    <p>
    Trusted users (again after permission of administrator) will be able to
    compile the customized version of Korel 2008 - different sizes or amount of
    spectra, spectral regions etc ...
    </p>
    
    <p>
    More details will be put in future on the server - so read it regularly.
    </p>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
