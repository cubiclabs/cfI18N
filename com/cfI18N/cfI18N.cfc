component{
	
	/*
	ICU
	https://github.com/unicode-org/icu/
	http://site.icu-project.org/

	ICU message formatting
	http://userguide.icu-project.org/formatparse/messages
	https://medium.com/i18n-and-l10n-resources-for-developers/the-missing-guide-to-the-icu-message-format-d7f8efc50bab
	http://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
	
	*/


	variables._localResourcePath = "resources";
	variables._icuJarPath = "java/icu4j-65_1.jar";
	variables._resources = {}; // holds all our locale keys
	variables._plurals = {}; // holds JSON plural configuration for locales

	variables._settings = {
		"resourcePath": getDefaultResourcePath(),
		"defaultLocale": "en",
		"format": "icu"
	};
	
	/**
	* @hint constructor
	*/
	public function init(struct settings={}){
		structAppend(variables._settings, arguments.settings);
		readResources();
		return this;
	}

	/**
	* @hint returns all our settings
	*/
	public struct function getSettings(){
		return variables._settings;
	}

	/**
	* @hint returns a setting value
	*/
	public any function getSetting(string settingName){
		return variables._settings[arguments.settingName];
	}

	/** 
	* @hint Returns path to the default schema storage location
	*/
	public string function getDefaultResourcePath(){
		return getLocalPath() & variables._localResourcePath & "\";
	}

	/** 
	* @hint Returns the absolute path to a given cfc
	*/
	public string function getLocalPath(boolean absolute=true){
		if(arguments.absolute){
			// absolute path
			local.path = listToArray(getMetaData(this).path, "\");
			arrayDeleteAt(local.path, arrayLen(local.path)); // remove file name
			return arrayToList(local.path, "\") & "\";
		}else{
			// relative path
			local.path = listToArray(getMetaData(this).name, ".");
			arrayDeleteAt(local.path, arrayLen(local.path)); // remove file name
			return arrayToList(local.path, "/") & "/";
		}
	}

	/** 
	* @hint returns the default locale as a language, country and variant code
	*/
	public string function getDefaultLocale(){
		local.locale = getPageContext().getResponse().getLocale();
		local.ret = local.locale.getLanguage();
		if(len(local.locale.getCountry())) local.ret &= "_" & local.locale.getCountry();
		if(len(local.locale.getVariant())) local.ret &= "_" & local.locale.getVariant();
		return local.ret;
	}

	/** 
	* @hint returns a jAva lacal object
	*/
	public any function jLocale(string locale){
		local.split = splitLocale(arguments.locale);
		return createObject("java","java.util.Locale").init(local.split.language, local.split.country, local.split.variant);
	}

	/** 
	* @hint splits a locale string into its three parts - language, country, variant
	*/
	public struct function splitLocale(string locale){
		local.delims = ["_","-"];
		for(local.delim in local.delims){
			if(findNoCase(local.delim, arguments.locale)) break;
		}
		local.split = listToArray(arguments.locale, local.delim);
		local.ret = {
			"language": local.split[1],
			"country": "",
			"variant": ""
		}
		if(arrayLen(local.split) >= 2) local.ret.country = local.split[2];
		if(arrayLen(local.split) >= 3) local.ret.variant = local.split[3];
		return local.ret;
	}

	/** 
	* @hint returns an array of locales to search
	*/
	public array function localePreference(string locale=getDefaultLocale()){
		local.parsedLocale = splitLocale(arguments.locale);
		local.ret = [];
		if(len(local.parsedLocale.variant)) arrayAppend(local.ret, local.parsedLocale.language & "_" & local.parsedLocale.country & "_" & local.parsedLocale.variant);
		if(len(local.parsedLocale.country)) arrayAppend(local.ret, local.parsedLocale.language & "_" & local.parsedLocale.country);
		arrayAppend(local.ret, local.parsedLocale.language);
		if(!arrayFindNoCase(local.ret, getSetting("defaultLocale"))){
			arrayAppend(local.ret, getSetting("defaultLocale"));
		}
		return local.ret;
	}

	/** 
	* @hint returns our locale resources
	*/
	public struct function getResource(string locale=""){
		if(len(arguments.locale)){
			return variables._resources[arguments.locale];
		}
		return variables._resources;
	}

	/** 
	* @hint returns our locale plurals defined from JSON translation files
	*/
	public struct function getPlurals(string locale=""){
		if(len(arguments.locale)){
			return variables._plurals[arguments.locale];
		}
		return variables._plurals;
	}

	/** 
	* @hint reads a Java resource bundle and returns the keys that it contains
	*/
	public struct function readResourceBundle(string path){

		// define our return struct
		local.name = listFirst(listLast(arguments.path, "\"), ".");
		local.ret = {
			"name": local.name,
			"baseName": listFirst(local.name, "_"),
			"locale": getSetting("defaultLocale"),
			"keys": {}
		};

		// get a locale from the bundle file name
		if(listLen(local.name, "_") GT 1){
			local.ret.locale = right(local.name, len(local.name)-len(local.ret.baseName)-1);
		}
		
		// open our file stream
		local.fileStream = createObject("java","java.io.FileInputStream").init(arguments.path);
		// open an input stream using UTF-8
		local.inputStream = createObject("java", "java.io.InputStreamReader").init(local.fileStream, "UTF8");
		// open a buffereed reader
		local.reader = createObject("java", "java.io.BufferedReader").init(local.inputStream);

		try{
			// read our resource bundle
			local.resourceBundle = createObject("java","java.util.PropertyResourceBundle").init(local.reader);
			
			// get the keys from the bundle
			local.keys = local.resourceBundle.getKeys();
			
			// extract our keys
			while(local.keys.hasMoreElements()){
				local.key = local.keys.nextElement();
				local.value = local.resourceBundle.handleGetObject(local.key);
				local.ret.keys[local.key] = local.value;
			}
		}
		catch(any e){
			// if we have an error, we need to ensure that the file stream gets closed
			local.reader.close();
			rethrow;
		}
		
		// close the input stream
		local.reader.close();

		// return our data
		return local.ret;
	}


	/** 
	* @hint reads a JSON file and returns the keys that it contains
	*/
	public struct function readJSONBundle(string path){

		// define our return struct
		local.name = listFirst(listLast(arguments.path, "\"), ".");
		local.ret = {
			"name": local.name,
			"baseName": listFirst(local.name, "_"),
			"locale": getSetting("defaultLocale"),
			"plurals": "",
			"keys": {}
		};

		// read our JSON file
		local.resource = fileRead(arguments.path, "utf-8");
		if(isJSON(local.resource)){
			local.resource = deserializeJSON(local.resource);
			// flatten any nested keys
			flattenResourceKeys(local.resource);
			local.ret.keys = local.resource.lookup;

			if(structKeyExists(local.resource, "plurals")){
				local.ret.plurals = local.resource.plurals;
			}
		}

		return local.ret;
	}


	/** 
	* @hint creates a lookup table for key values by flattening nested keys
	*/
	public struct function flattenResourceKeys(struct resource, any node="", string keyPath=""){
		if(!isStruct(arguments.node)) arguments.node = arguments.resource.keys;

		if(!structKeyExists(arguments.resource, "lookup")) arguments.resouce["lookup"] = {};

		for(local.key in structKeyArray(arguments.node)){
			local.keyNode = arguments.node[local.key];
			local.keyNodePath = listAppend(arguments.keyPath, local.key, ".");
			if(isStruct(local.keyNode)){
				// recursive
				flattenResourceKeys(arguments.resource, local.keyNode, local.keyNodePath);
			}else{
				arguments.resource.lookup[local.keyNodePath] = local.keyNode;
			}
		}

		return arguments.resource;
	}

	/** 
	* @hint reads our resource files
	*/
	public void function readResources(){
		local.files = directoryList(getSetting("resourcePath"), false, "path");
		for(local.file in local.files){

			if(listLast(local.file, ".") IS "properties"){
				// java resource bundle
				local.bundle = readResourceBundle(local.file);
			}else{
				// assume a JSON format
				local.bundle = readJSONBundle(local.file);
				if(isStruct(local.bundle.plurals)){
					variables._plurals[local.bundle.locale] = local.bundle.plurals;
				}
			}

			if(!structKeyExists(variables._resources, local.bundle.locale)){
				variables._resources[local.bundle.locale] = {};
			}

			structAppend(variables._resources[local.bundle.locale], local.bundle.keys);
		}
	}

	/** 
	* @hint searches our locale resources for a given key
	*/
	public struct function findKey(
		string key, 
		string locale=getDefaultLocale(),
		string default="NOT FOUND"){

		local.ret = {
			"found": false,
			"value": arguments.default,
			"locale": arguments.locale,
			"localesToSearch": localePreference(arguments.locale)
		};

		// scan our locales for a matching key
		for(local.loc in local.ret.localesToSearch){
			if(structKeyExists(variables._resources, local.loc)){
				local.resource = getResource(local.loc);

				if(structKeyExists(local.resource, arguments.key)){
					// we have a match
					local.ret.found = true;
					local.ret.locale = local.loc;
					local.ret.value = local.resource[arguments.key];
					return local.ret;
				}
			}
		}

		return local.ret;
	}



	/** 
	* @hint searches our locale resources for a given key and formats the message
	*/
	public string function getText(
		string key, 
		any args={}, 
		string locale=getDefaultLocale(),
		string messageFormat=getSetting("format"),
		string default="NOT FOUND"){

		local.match = findKey(arguments.key, arguments.locale, arguments.default);

		if(local.match.found){

			// po formatted string??
			if(isArray(local.match.value)){
				// make sure that we have 'n' defined
				local.n = 0;
				if(isStruct(arguments.args) AND structKeyExists(arguments.args, "n")){
					local.n = val(arguments.args.n);
				}
				// find our plural position using the number of plurals that we have
				local.plural = getPlurals(local.match.locale)[arrayLen(local.match.value)];
				local.matchedI = evaluate(local.plural) + 1;
				local.match.value = local.match.value[local.matchedI];
			}

			// replace arg strings
			if(isStruct(arguments.args)){
				for(local.argKey in structKeyArray(arguments.args)){
					local.match.value = replaceNoCase(local.match.value, "{" & local.argKey & "}", arguments.args[local.argKey], "ALL");
				}
				// replace 'n'
				//local.match = replaceNoCase(local.match, "{n}", local.n, "ALL");
			}

			return this.format(local.match.value, arguments.args, arguments.locale, arguments.messageFormat);
	
		}

		return arguments.default;
	}

	/** 
	* @hint formats a message using a java MessageFormat
	*/
	public string function format(
		string msg, 
		any args={}, 
		string locale=getDefaultLocale(),
		string messageFormat=getSetting("format")){

		// get a java locale object
		local.formatLocale = jLocale(arguments.locale);
		
		// what formatter are we using
		switch(arguments.messageFormat){
			case "java":
				// Java message formater
				local.msgFormat = createObject("java","java.text.MessageFormat").init(arguments.msg, local.formatLocale);
				break;
			default:
				// enhanced icu4j message formatter
				if(server.coldfusion.productname IS "Lucee"){
					// Lucee can create Java objects using a path to the jar
					local.msgFormat = createObject("java","com.ibm.icu.text.MessageFormat", getLocalPath(false) & variables._icuJarPath).init(arguments.msg, local.formatLocale);
				}else{
					// ACF - jar needs to be added to class path
					local.msgFormat = createObject("java","com.ibm.icu.text.MessageFormat").init(arguments.msg, local.formatLocale);
				}
		}

		// get our args into a Java format
		if(isArray(arguments.args)){
			arguments.args = arguments.args.toArray();
		}

		// format our message
		return local.msgFormat.format(arguments.args);
	}

	
}