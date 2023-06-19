<?xml version="1.0" encoding="UTF-8"?>
<!--

    Extract the name of the latest .tar.gz snapshot from a Maven metadata file.

-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns="urn:oasis:names:tc:SAML:2.0:metadata">

	<xsl:output method="text"/>

    <xsl:template match="//snapshotVersion[extension='tar.gz']">
        <xsl:value-of select="./value"/>
    </xsl:template>

	<xsl:template match="text()"/>
</xsl:stylesheet>
