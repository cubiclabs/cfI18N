component{

	variables._settings = {
		"resourcePath": getDefaultResourcePath(),
		"defaultLocale": "en"
	};
	
	variables._resources = {};
	
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
		return getLocalPath() & "resources\";
	}

	/** 
	* @hint Returns the absolute path to a given cfc
	*/
	public string function getLocalPath(any o=this){
		local.path = listToArray(getMetaData(arguments.o).path, "\");
		arrayDeleteAt(local.path, arrayLen(local.path)); // remove file name
		return arrayToList(local.path, "\") & "\";
	}

	/** 
	* @hint returns the default locale as a language and country code
	*/
	public string function getDefaultLocale(){
		local.locale = getPageContext().getResponse().getLocale();
		local.ret = local.locale.getLanguage();
		if(len(local.locale.getCountry())) local.ret &= "_" & local.locale.getCountry();
		return local.ret;
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
	* @hint reads our resource files
	*/
	public void function readResources(){
		local.files = directoryList(getSetting("resourcePath"), false, "path");
		for(local.file in local.files){
			local.resource = deserializeJSON(fileRead(local.file, "utf-8"));
			variables._resources[local.resource.locale] = flattenResourceKeys(local.resource);
		}
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
	* @hint searches our locale resources for a given key
	*/
	public string function getText(
		string key, 
		struct args={}, 
		numeric n=0, 
		string locale=getDefaultLocale()){

		// get our locale search order
		local.localesToSearch = localePreference(arguments.locale);

		for(local.loc in local.localesToSearch){
			if(structKeyExists(variables._resources, local.loc)){
				local.resource = getResource(local.loc);

				if(structKeyExists(local.resource.lookup, arguments.key)){
					// we have a match
					local.match = local.resource.lookup[arguments.key];

					// check for a pluralised translation
					if(isArray(local.match)){
						// find our plural position using the number of plurals that we have
						local.plural = local.resource.plurals[arrayLen(local.match)];
						local.matchedI = evaluate(local.plural) + 1;
						local.match = local.match[local.matchedI];
					}

					// relace arg strings
					for(local.argKey in structKeyArray(arguments.args)){
						local.match = replaceNoCase(local.match, "{" & local.argKey & "}", arguments.args[local.argKey], "ALL");
					}
					// replace 'n'
					local.match = replaceNoCase(local.match, "{n}", arguments.n, "ALL");

					return local.match;
				}
			}
		}

		return "NOT FOUND";
	}


}