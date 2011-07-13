<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="html-common.xsl"/>

<!-- $Date$ -->
<!-- $Rev$ -->
<!-- $URL$ -->

<xsl:template name="html.dynamic">
    <h2>Home</h2>
    <p>
    This service  is the test-bed for embedding Fourier disentangling into the
    Virtual Observatory infrastructure. Currently the system allows uploading
    of user data, on-the-fly modification of parameters and management of
    various user files. The system uses the well-known
    interface of electronic shop. The user can see only her/his own files and it
    is guaranted that nobody (except the administrator) can access her/his private
    files. More information  about the service and its motivation is described in 
    <A href=" http://arxiv.org/abs/1003.4801">ArXiv:1003.4801</A>. The underlaying  
    code  KOREL is presented 
    on <A href="http://www.asu.cas.cz/~had/korel.html">KOREL</A> web page of its author P. Hadrava.
    </p>
    
    <p>
    To achive this the full encryption is used and the user is required to
    register (create unique account). After filling the form (and solving simple math question), the special credential is sent to user's mail.
    The web service may be used directly after the link embedded in mail is activated.
    Currently up to  five concurrent jobs may run in parallel - the others are queued.
    The service is adhering to the IVOA standards for Universal Worker Server (<A href="http://www.ivoa.net/Documents/UWS/20100210/">UWS</A>).
    </p>
    
   When using the results achieved by this system, please write the
   acknowledgment similar to the one stated below:  
  <hr> 
  </hr>
   <b> This research was
   accomplished  with the help of  the VO-KOREL web service, developed at the Astronomical Institute
   of the Academy of Sciences of the Czech Republic in the framework of the
   Czech Virtual Observatory (CZVO) by P. Skoda and  J. Fuchs using the Fourier
   disentangling code KOREL deviced by P. Hadrava
</b>
<hr>
</hr>
 Current version of KOREL installed on this server is <CODE>KOREL11a - release 21. 6. 2011</CODE>.
 <p>
 It can handle up to 2000 spectra with maximal size of 16384 bins, 50 spectral regions and 3 templates.
 </p>
    <p>
   <em> More details will be put in future on the server - so read it regularly.</em>
    </p>
</xsl:template>


<xsl:template match="/">
    <xsl:call-template name="html.static">
        <xsl:with-param name="ownerId" select="ownerId"/>
    </xsl:call-template>
</xsl:template>


</xsl:stylesheet>
