<?xml version="1.0"?>
<!DOCTYPE xsl:stylesheet [ <!ENTITY nbsp "&#160;"> ]>
<!--
  Converts the htmlsrc documentation snippets into Asciidoc.
  Counterpart of htmlsrc2html.xsl.
  Placeholders like @OPCODES1@ are kept on their own line, so that
  scripts/inserts.sh can replace them with the generated tables.
-->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method="text" encoding="UTF-8"/>
<xsl:strip-space elements="docpage section subsection table tr ul ol"/>

<xsl:variable name="nl"><xsl:text>
</xsl:text></xsl:variable>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->

<xsl:template match="docpage">
  <xsl:text>= </xsl:text><xsl:value-of select="@name"/><xsl:value-of select="$nl"/>
  <xsl:for-each select="author">
    <xsl:text>(C) </xsl:text>
    <xsl:value-of select="yearstart"/><xsl:text>-</xsl:text><xsl:value-of select="yearend"/>
    <xsl:text> </xsl:text><xsl:value-of select="name"/>
    <xsl:value-of select="$nl"/>
  </xsl:for-each>
  <xsl:if test="toc">
    <xsl:text>:toc:</xsl:text><xsl:value-of select="$nl"/>
  </xsl:if>
  <xsl:value-of select="$nl"/>
  <xsl:apply-templates select="overview" mode="block"/>
  <xsl:apply-templates select="news"/>
  <xsl:for-each select="verbatim">
    <xsl:apply-templates mode="block"/>
  </xsl:for-each>
  <xsl:apply-templates select="section"/>
  <xsl:apply-templates select="disclaimer"/>
  <xsl:apply-templates select="closing"/>
</xsl:template>

<xsl:template match="section">
  <xsl:if test="@toc">
    <xsl:text>[[</xsl:text><xsl:value-of select="@toc"/><xsl:text>]]</xsl:text>
    <xsl:value-of select="$nl"/>
  </xsl:if>
  <xsl:text>== </xsl:text><xsl:value-of select="@name"/>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  <xsl:apply-templates select="desc" mode="block"/>
  <xsl:apply-templates select="subsection"/>
  <xsl:apply-templates select="subitem|extlink|file"/>
  <xsl:apply-templates select="disclaimer"/>
</xsl:template>

<xsl:template match="subsection">
  <xsl:if test="@toc">
    <xsl:text>[[</xsl:text><xsl:value-of select="@toc"/><xsl:text>]]</xsl:text>
    <xsl:value-of select="$nl"/>
  </xsl:if>
  <xsl:text>=== </xsl:text><xsl:value-of select="@name"/>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  <xsl:apply-templates select="desc" mode="block"/>
  <xsl:apply-templates select="extlink|file"/>
</xsl:template>

<xsl:template match="disclaimer">
  <xsl:text>== </xsl:text><xsl:value-of select="@name"/>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  <xsl:apply-templates mode="block"/>
</xsl:template>

<xsl:template match="closing">
  <xsl:text>'''</xsl:text><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  <xsl:apply-templates mode="block"/>
</xsl:template>

<xsl:template match="news">
  <xsl:text>== News</xsl:text><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  <xsl:for-each select="item">
    <xsl:text>* </xsl:text>
    <xsl:if test="@date"><xsl:value-of select="@date"/><xsl:text>: </xsl:text></xsl:if>
    <xsl:apply-templates mode="inline"/>
    <xsl:value-of select="$nl"/>
  </xsl:for-each>
  <xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="extlink">
  <xsl:text>* </xsl:text>
  <xsl:value-of select="@link"/><xsl:text>[</xsl:text><xsl:value-of select="@name"/><xsl:text>] </xsl:text>
  <xsl:apply-templates mode="inline"/>
  <xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="text()"/>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->
<!-- block level content -->

<xsl:template match="p" mode="block">
  <xsl:apply-templates mode="inline"/>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="ul|ol" mode="block">
  <xsl:for-each select="li">
    <xsl:choose>
      <xsl:when test="parent::ol"><xsl:text>. </xsl:text></xsl:when>
      <xsl:otherwise><xsl:text>* </xsl:text></xsl:otherwise>
    </xsl:choose>
    <xsl:apply-templates mode="inline"/>
    <xsl:value-of select="$nl"/>
  </xsl:for-each>
  <xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="pre" mode="block">
  <xsl:text>----</xsl:text><xsl:value-of select="$nl"/>
  <xsl:value-of select="."/>
  <xsl:if test="substring(., string-length(.)) != $nl"><xsl:value-of select="$nl"/></xsl:if>
  <xsl:text>----</xsl:text><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="table" mode="block">
  <xsl:variable name="cols">
    <xsl:for-each select="tr">
      <xsl:sort select="count(td|th)" data-type="number" order="descending"/>
      <xsl:if test="position() = 1"><xsl:value-of select="count(td|th)"/></xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:text>[cols="</xsl:text>
  <xsl:choose>
    <xsl:when test="$cols != '' and $cols != '0'"><xsl:value-of select="$cols"/></xsl:when>
    <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
  <xsl:text>*"]</xsl:text><xsl:value-of select="$nl"/>
  <xsl:text>|===</xsl:text><xsl:value-of select="$nl"/>
  <xsl:for-each select="tr">
    <xsl:for-each select="td|th">
      <xsl:if test="@colspan"><xsl:value-of select="@colspan"/><xsl:text>+</xsl:text></xsl:if>
      <xsl:if test="self::th"><xsl:text>h</xsl:text></xsl:if>
      <xsl:text>| </xsl:text>
      <xsl:apply-templates mode="inline"/>
      <xsl:value-of select="$nl"/>
    </xsl:for-each>
    <xsl:value-of select="$nl"/>
  </xsl:for-each>
  <xsl:text>|===</xsl:text><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="div" mode="block">
  <xsl:apply-templates mode="block"/>
</xsl:template>

<xsl:template match="img" mode="block">
  <xsl:text>image::</xsl:text><xsl:value-of select="@src"/><xsl:text>[]</xsl:text>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="br" mode="block"/>
<xsl:template match="toc" mode="block"/>

<!-- container elements pass through, text directly in a block is either a
     placeholder (own line) or a paragraph -->
<xsl:template match="desc|overview" mode="block">
  <xsl:apply-templates mode="block"/>
</xsl:template>

<xsl:template match="text()" mode="block">
  <xsl:variable name="t" select="normalize-space(.)"/>
  <xsl:if test="$t != ''">
    <xsl:value-of select="$t"/><xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
  </xsl:if>
</xsl:template>

<!-- inline-only elements appearing at block level start a paragraph -->
<xsl:template match="a|b|i|code|em|strong" mode="block">
  <xsl:apply-templates select="." mode="inline"/>
  <xsl:value-of select="$nl"/><xsl:value-of select="$nl"/>
</xsl:template>

<xsl:template match="*" mode="block">
  <xsl:apply-templates mode="block"/>
</xsl:template>

<!-- xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx -->
<!-- inline content -->

<xsl:template match="text()" mode="inline">
  <xsl:variable name="s" select="translate(., '&#9;&#10;&#13;&#160;', '    ')"/>
  <xsl:if test="starts-with($s, ' ') and not(position() = 1)"><xsl:text> </xsl:text></xsl:if>
  <xsl:value-of select="normalize-space($s)"/>
  <xsl:if test="normalize-space($s) != '' and substring($s, string-length($s)) = ' ' and not(position() = last())"><xsl:text> </xsl:text></xsl:if>
</xsl:template>

<xsl:template match="a" mode="inline">
  <xsl:variable name="h" select="@href"/>
  <xsl:choose>
    <xsl:when test="starts-with($h, '#')">
      <xsl:text>&lt;&lt;</xsl:text><xsl:value-of select="substring($h, 2)"/><xsl:text>,</xsl:text>
      <xsl:apply-templates mode="inline"/><xsl:text>&gt;&gt;</xsl:text>
    </xsl:when>
    <xsl:when test="@name and not(@href)"><xsl:apply-templates mode="inline"/></xsl:when>
    <xsl:otherwise>
      <!-- links to other documentation pages point to the adoc version -->
      <xsl:text>link:</xsl:text>
      <xsl:choose>
        <xsl:when test="not(contains($h, '://')) and contains($h, '.html')">
          <xsl:value-of select="substring-before($h, '.html')"/><xsl:text>.adoc</xsl:text>
          <xsl:value-of select="substring-after($h, '.html')"/>
        </xsl:when>
        <xsl:otherwise><xsl:value-of select="$h"/></xsl:otherwise>
      </xsl:choose>
      <xsl:text>[</xsl:text><xsl:apply-templates mode="inline"/><xsl:text>]</xsl:text>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="b|strong" mode="inline">
  <xsl:text>*</xsl:text><xsl:apply-templates mode="inline"/><xsl:text>*</xsl:text>
</xsl:template>

<xsl:template match="i|em" mode="inline">
  <xsl:text>_</xsl:text><xsl:apply-templates mode="inline"/><xsl:text>_</xsl:text>
</xsl:template>

<xsl:template match="code|tt" mode="inline">
  <xsl:text>`</xsl:text><xsl:apply-templates mode="inline"/><xsl:text>`</xsl:text>
</xsl:template>

<xsl:template match="br" mode="inline"><xsl:text> +&#10;</xsl:text></xsl:template>

<xsl:template match="img" mode="inline">
  <xsl:text>image:</xsl:text><xsl:value-of select="@src"/><xsl:text>[]</xsl:text>
</xsl:template>

<xsl:template match="ul|ol|p|pre|table" mode="inline">
  <!-- nested blocks inside list items/cells -->
  <xsl:value-of select="$nl"/>
  <xsl:apply-templates select="." mode="block"/>
</xsl:template>

<xsl:template match="*" mode="inline">
  <xsl:apply-templates mode="inline"/>
</xsl:template>

</xsl:stylesheet>
