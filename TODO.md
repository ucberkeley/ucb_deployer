* Add "clean" task to remove previous build dirs, files, etc
* Add "init" task to automatically create build/ and config/ directories
* Don't needlessly download source from svn everytime.  If source for requested 
  version has already been pulled down to the filesystem, reuse it.
* For commands like display_maintenance_file and remove_maintenance_file, you should 
  not need to pass int the VERSION option
* Currently we're bundling our own copy of xwork.xml for Confluence, modifiying it and
then deploying.  A better long term strategy would be to unjar WEB-INF/lib/confluence-3.4.2.jar
during the deployment process and modify its xwork.xml, then rejar it.

