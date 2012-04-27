<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [ <!ENTITY eac "&#38;eacute; "> <!ENTITY nbsp "&#160;"> ] >
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="xml" 
	doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
	doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" />

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template name="h2toc">
	<xsl:param name="hdr"/>
	<xsl:param name="a"/>
  <div class="h2h">
    <div class="h2t">&nbsp;</div>
    <xsl:choose>
      <xsl:when test="$a != ''">
      	<h2>
          <a name="{$a}"><xsl:value-of select="$hdr"/></a>
        </h2>
      </xsl:when>
      <xsl:otherwise>
        <h2>
          <xsl:value-of select="$hdr"/>
        </h2>
      </xsl:otherwise>
    </xsl:choose>
    <div class="toplink"><a href="#top">Top</a></div>
  </div>
</xsl:template>

<!--xsl:template name="h2">
	<xsl:param name="hdr"/>
<h2><xsl:value-of select="$hdr"/></h2>
<div class="toplink"><a href="#topanchor">Top</a></div>
</xsl:template-->

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template name="commoncol">
	<div id="leftcol">
		<div id="menu" class="top">
			<div class="tophead">navigate</div>
		@MENU@
		</div><!-- menu -->
		<!--div class="top" id="browser">
			Site has been tested with Firefox 3.6, IE6, IE8, Opera 10 and Google Chrome 5 on Windows XP, as well as Firefox 3.5, Google Chrome 5 and konqueror 4.3.5 on (SuSE) Linux 11.2
		</div-->
	</div> <!-- leftcol -->
	<div id="rightcol">
		<div class="top" id="twitter"><div class="tophead">follow</div><div>
		            Follow the 65k tweets on<br/>
		            <a class="extlink" target="_blank" href="https://twitter.com/#!/search/realtime/afachat%20%2365k">Twitter</a><br/> (In new window)
		</div></div>
		<div class="top" id="forum"><div class="tophead">discuss</div><div>
			<p>Discuss my site on <a class="extlink" target="_blank" href="http://forum.6502.org/viewtopic.php?t=956">this 6502.org forum thread</a></p>
			<xsl:for-each select="//forum[@type='6502.org']">
				<p>Discuss this page's content on <a class="extlink" target="_blank"><xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute> this 6502.org forum thread</a></p>
			</xsl:for-each>
			<p>(Forum registration required to post)</p>
		</div></div>
		<xsl:if test="oldnews">
			<div class="top" id="oldnews"><div class="tophead">History</div>
			<div id="oldnewscontent">
				<xsl:apply-templates select="oldnews"/>
			</div></div>
		</xsl:if>
		<!--div class="top" id="browser">
			<div class="tophead">browser</div>
			<div><p>
			Site has been tested with a number of browsers and systems. Javascript required for advanced menu, but degrades gracefully without Javascript. IE6 not supported anymore!
			</p></div>
		</div-->
	</div>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template match="desc">
<xsl:copy-of select="*|text()"/>
</xsl:template>

<xsl:template match="section">
  <div class="h2">
    <xsl:call-template name="h2toc">
      <xsl:with-param name="hdr"><xsl:value-of select="@name"/></xsl:with-param>
      <xsl:with-param name="a"><xsl:value-of select="@toc"/></xsl:with-param>
    </xsl:call-template>
    <div class="h2c">
      <xsl:apply-templates select="desc"/>
      <xsl:apply-templates select="subsection"/>
      <xsl:if test="subitem|extlink|file">
        <ul>
          <xsl:apply-templates select="subitem"/>
          <xsl:apply-templates select="extlink"/>
	  <xsl:apply-templates select="file"/>
        </ul>
      </xsl:if>
    </div><!-- h2c -->
  </div><!-- h2 -->
</xsl:template>

<xsl:template match="subsection">
<h3><a name="{@toc}"><xsl:value-of select="@name"/></a></h3>
<xsl:apply-templates select="desc"/>
<xsl:if test="extlink">
<ul>
<xsl:apply-templates select="extlink"/>
</ul>
</xsl:if>
<xsl:if test="file">
<table>
<xsl:apply-templates select="file"/>
</table>
</xsl:if>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template name="aname">
    <xsl:choose>
	<xsl:when test="@toc">
		<a name="{@toc}"><xsl:value-of select="@name"/></a>
	</xsl:when>
	<xsl:otherwise>
		<xsl:value-of select="@name"/>
	</xsl:otherwise>
    </xsl:choose>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template match="copyright">
<h3>(C) <xsl:value-of select="start"/><xsl:text> - </xsl:text><xsl:value-of select="end"/><xsl:text> </xsl:text><xsl:value-of select="author"/></h3>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template match="docpage">
<html><head> 
	<xsl:call-template name="head"/>
	<title><xsl:value-of select="@name"/></title>
</head><xsl:text>
</xsl:text><body>
<div id="headerbox">
  <div id="lefthdr">The 65k Project</div>
  <div id="righthdr">
	<div class="large">65002</div>
	<div class="small">The 65k processor - a modern 6502 with 64 bit</div>
  </div>
</div>
<div id="mainbox">
<a name="top"/>
<xsl:call-template name="commoncol"/>
<div id="midcol">
<xsl:call-template name="ie6warn"/>
<div class="top" id="content">
<div id="minmax"/>
<h1><xsl:value-of select="@name"/></h1>

<xsl:for-each select="author">
<p class="copyright">(C)
<xsl:value-of select="yearstart"/>-<xsl:value-of select="yearend"/>
<xsl:text> </xsl:text>
<xsl:value-of select="name"/> 
</p>
<xsl:text> 
</xsl:text>
</xsl:for-each>
<div class="overview">
<xsl:copy-of select="overview/*|overview/text()"/>
</div> <!-- overview -->
<xsl:apply-templates select="news"/>
<xsl:if test="toc"><xsl:call-template name="toc"/></xsl:if>
<xsl:for-each select="verbatim">
        <xsl:copy-of select="*|text()"/>
</xsl:for-each>
<xsl:for-each select="section">
  <div class="h2">
    <xsl:call-template name="h2toc">
      <xsl:with-param name="hdr"><xsl:value-of select="@name"/></xsl:with-param>
      <xsl:with-param name="a"><xsl:value-of select="@toc"/></xsl:with-param>
    </xsl:call-template>
    <div class="h2c">
      <xsl:apply-templates select="desc"/>
      <xsl:apply-templates select="subsection"/>
      <xsl:if test="extlink">
        <ul>
          <xsl:apply-templates select="extlink"/>
        </ul>
      </xsl:if>
      <xsl:apply-templates select="disclaimer"/>
    </div><!-- h2c -->
  </div><!-- h2 -->
</xsl:for-each>
<!--xsl:apply-templates select="oldnews"/-->
<xsl:apply-templates select="disclaimer"/>
<xsl:apply-templates select="closing"/>
</div> <!-- content -->
</div> <!-- midcol -->
<div id="footer">&nbsp;</div>
</div> <!-- mainbox -->
<xsl:call-template name="bottom"/>
</body></html>
<xsl:text> 
</xsl:text>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template name="toc">
<div id="toc" class="h2">
<xsl:call-template name="h2toc">
        <xsl:with-param name="hdr">Table of content</xsl:with-param>
        </xsl:call-template>
        <div class="h2c">
        <ul>
        <xsl:for-each select="section|itemlist">
        <li><a href="#{@toc}"><xsl:value-of select="@name"/></a></li>
        <xsl:if test="subsection|items/item">
        <li style="list-style-type:none;"><ul>
        <xsl:for-each select="subsection|items/item">
        <li><a href="#{@toc}"><xsl:value-of select="@name"/></a></li>
        </xsl:for-each>
        </ul></li>
        </xsl:if>
        </xsl:for-each>
        <xsl:if test="driver">
        <li><a href="#driver">Driver</a></li>
        <li style="list-style-type:none;"><ul>
        <xsl:for-each select="driver">
        <li><a href="#driver{position()}"><xsl:value-of select="name"/></a></li>
        </xsl:for-each>
        </ul></li>
        </xsl:if>
        <xsl:if test="rev">
        <li><a href="#boards">Board Revisions</a></li>
        <li style="list-style-type:none;"><ul>
        <xsl:for-each select="rev">
        <li><a href="#board{position()}"><xsl:value-of select="version"/></a> (<xsl:value-of select="status"/>)</li>
        </xsl:for-each>
        </ul></li>
        </xsl:if>
        <xsl:if test="diagram">
        <li><a href="#blkdiag">Block diagram</a></li>
        </xsl:if>
        <!--xsl:if test="oldnews">
             <li><a href="#oldnews">Old News</a></li>
             </xsl:if -->
</ul>
</div><!-- h2c -->
</div><!-- toc h2 -->
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template match="news">
 <div class="h2">
   <xsl:call-template name="h2toc">
     <xsl:with-param name="hdr">News:</xsl:with-param>
     <xsl:with-param name="a">news</xsl:with-param>
   </xsl:call-template>
   <div class="h2c">
     <ul class="news">
     <xsl:for-each select="item[@state='hot']">
      <li><div class="i_hotnews">&nbsp;</div>
        <small><xsl:value-of select="@date"/></small>
        <xsl:copy-of select="*|text()"/>
      </li>
    </xsl:for-each>
    <xsl:for-each select="item[@state='old' or not(@state)]">
      <li><div>
        <xsl:if test="@state='old'"><xsl:attribute name="class">i_oldnews</xsl:attribute></xsl:if>&nbsp;</div>
        <small><xsl:value-of select="@date"/></small>
        <xsl:copy-of select="*|text()"/>
      </li>
    </xsl:for-each>
    </ul>
  </div><!-- h2c -->
 </div><!-- h2 -->
</xsl:template>

<xsl:template match="oldnews">
 <!--xsl:call-template name="h2toc">
   <xsl:with-param name="hdr">Old News:</xsl:with-param>
   <xsl:with-param name="a">oldnews</xsl:with-param>
 </xsl:call-template-->
 <ul class="news">
 <xsl:for-each select="item[@state!='off' or not(@state)]">
  <li><div>
  <xsl:attribute name="class">i_oldnews</xsl:attribute>&nbsp;</div>
  <small><xsl:value-of select="@date"/></small>
  <xsl:copy-of select="*|text()"/>
  </li>
 </xsl:for-each>
 </ul>
</xsl:template>

<xsl:template match="disclaimer">
  <div class="h2">
    <xsl:call-template name="h2toc">
      <xsl:with-param name="hdr"><xsl:value-of select="@name"/></xsl:with-param>
    </xsl:call-template>
    <div class="h2c">
      <xsl:copy-of select="*|text()"/>
    </div><!-- h2c -->
  </div><!-- h2 -->
</xsl:template>

<xsl:template match="closing">
    <hr/>
    <xsl:copy-of select="*|text()"/>
</xsl:template>

<xsl:template match="extlink">
	<li>
	      <a href="{@link}" target="_blank" class="extlink">
	      <xsl:value-of select="@name"/>
	      </a><xsl:text> </xsl:text>
  	      <xsl:copy-of select="*|text()"/>
	</li>
</xsl:template>

<xsl:template match="*|@*|text()|comment()">
   <xsl:copy></xsl:copy>
</xsl:template>

<xsl:template name="head">
<xsl:text>
</xsl:text>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/><xsl:text>
</xsl:text>
<meta name="author" content="{author/name}"/><xsl:text>

</xsl:text>
<meta name="description" content="{metadesc}"/><xsl:text>
</xsl:text>
<meta name="keywords" content="{keywords}"/><xsl:text>
</xsl:text>
<link rev="made" href="mailto:{author/email}"/><xsl:text>
</xsl:text>
<link rel="stylesheet" title="Default" type="text/css" href="doc.css"/>
<xsl:if test="style">
  <link rel="stylesheet" type="text/css" href="{style}"/>
  </xsl:if>
  <xsl:text>
</xsl:text>
</xsl:template>

<xsl:template name="ie6warn">
<div class="top" id="ie6warn">
You are using an old MS Internet Explorer as browser. This version is not supported anymore. Please use a 
more modern browser, like Internet Explorer 8 or later, 
<a target="_blank" class="extlink" href="http://www.firefox.com">Firefox</a>,
<a target="_blank" class="extlink" href="http://www.google.com/chrome">Google Chrome</a>, or
<a target="_blank" class="extlink" href="http://www.opera.com">Opera</a>.
</div>
</xsl:template>

<xsl:template name="bottom">
<!--
  <script type="text/javascript">myUp="%up%";</script>
  <script type="text/javascript" src="%up%scripts-all.js"></script>
  <script type="text/javascript" src="%up%jquery.socialshareprivacy.js"></script>
  <script type="text/javascript">
          jQuery(document).ready(function($){
                  if($('#socialshareprivacy').length != 0){
                            $('#socialshareprivacy').socialSharePrivacy();
                  }
          });
  </script>
  -->
</xsl:template>

</xsl:stylesheet>

