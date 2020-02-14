<!doctype html>
<html>
<head>
	<meta charset="utf-8">
</head>
<body>


<cfscript>

i18n = new com.cfI18N.cfI18N();


setLocale("en_GB");

writeDump(i18n.getResource());

writeDump(i18n.findKey("label"));

t1 = getTickCount();
writeOutput(i18n.getText(
	key: "label", 
	args: [now(), "adda", 2],
	format: "java"
));

writeOutput("<br />");

writeOutput(i18n.getText(
	key: "label-icu2", 
	args: {
		"when": now(), 
		"name": "adda", 
		"n": 0
	}
));

writeOutput("<br />");

writeOutput(i18n.getText(
	key: "dog", 
	args: {
		"name": "rex", 
		"n": 3
	}
));

writeOutput("<br />");

writeOutput(i18n.getText(
	key: "jsonDog", 
	args: {
		"name": "rex", 
		"n": 1
	}
));

writeOutput("<br />");

writeOutput(i18n.getText("utf"));

writeOutput("<br />");

writeoutput("<br />#getTickCount()-t1#<br />");



</cfscript>

</body>
</html>