<cfscript>
i18n = new com.cfI18N.cfI18N();
setLocale("en_GB");
//writeDump(getPageContext().getResponse());
writeOutput(i18n.getDefaultLocale());
writeDump(i18n.getResource());

writeDump(i18n.splitLocale(i18n.getDefaultLocale()));

writeDump(i18n.getText("dog", {name:"rex"}, 1));
writeDump(i18n.getText("cars.vw.skoda"));

</cfscript>