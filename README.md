# Release notes

## Version 0.2.2.1

- Fixed WebServiceProxy unauthenticated first call issue. Any API call now touches the API endpoint only once (previously the API was touched once unauthenticated and when that failed .Net automatically tried again with authentication and the call succeeded)
- Added caching of Fieldinfo pr entity. Significantly reduces the number of API calls in loops
- Added UDF expansion by default. Any UDF is added to an entity with a fieldname prefixed by # (hashtag). Udf names are freeform, and at least in our organization has a lot of spaces and punctuation. This way you will not forget to escape your UDF field names in your code. Speed gain: You can filter any collection of entities on UDF using standard Where-Object filters.

## Version 0.2.2.0

- Support TLS 1.2 in New-WebServiceProxy

## Version 0.2.1.9

- New parameter -AddPicklistLabel. Will add a text label to all fieldnames on an object that is a picklist field. Supports Where-Object filtering on textlabels for object collections.
- Parameter -passthru is supported for Set- and New- functions. Will pass any objects from the Autotask API to the PowerShell pipeline after modifying og creating the objects.

## Previous versions

We didn't pay enough attention to changes between releases before this.