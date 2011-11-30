UCB Deployer
============

UCB Deployer is gem to automate Confluence and JIRA deployments to Tomcat.


Overview
--------

Deployments done with UCB Deployer will follow the following structure.

The user performing the deployment should manually stop tomcat 

   sudo service tomcat6-jira stop

and then excecute the ucb_deploy command:

    ucb_deploy APP=<jira|confluence> VERSION=<version>

The *ucb_deploy* command will then do the following:

1. Display a user friendly maintenance page that should be picked up by Apache.
2. Check out the application from SVN.
3. Configure the application in preparation for the build.
4. Build the application which results in a war file.
5. Deploy the war file to tomcat.

The user doing the deployment will then have to manually start tomcat 

    sudo service tomcat6-jira start

and confirm tomcat started.  Once they have confirmed things are ok, 
they can then remove the maintenance file via the command:

    ucb_deploy enable_web APP=<jira|confluence>

Woot!


Installation
------------

    gem install ucb_deployer


Assumptions
-----------

#### Tomcat Setup ####

It is assumed that JIRA and Confluence each have their own unique Tomcat instance.
For more information on this setup, see [Tomcat 6 Setup][1]
[1]: http://wikihub.berkeley.edu/x/gABpAg "Tomcat 6 Setup"

#### Application User Account Setup ####

It is also assumed that a corresponding unix user has been created for both JIRA and 
Confluence: this is referred to as the application user.  The Tomcat instance for
JIRA/Confluence will run as this application user.


#### Release Management User ####

You should have some sort of *release management user* setup that can start/stop
Tomcat for JIRA and Confluence (we use app_relmgt).  This user should have Read/Write 
access to the Tomcat directories for JIRA and Confluence. Again, for more information 
on this setup see: [Tomcat 6 Setup][1]


General Configuration
---------------------

#### Layout/Directories ####

The following directories and file need to be setup in the **app_relmgt** user's home 
directory:

    $HOME/.ucb_deployer/config/
                           +
                           |-- jira/
                                 +
                                 |-- deploy.yml
                           |-- confluence/
                                    +
                                    |-- deploy.yml

    $HOME/.ucb_deployer/build/
                         +
                         |-- jira/
                         |-- confluence/


#### Configuration Options ####

* **build_dir**            : *directory where build will be performed*
* **deploy_dir**           : *directory to deploy the war file to*
* **war_name**             : *name to use for the war file*
* **cas_server_url**       : *url of CAS Server*
* **cas_service_url**      : *url to redirect to after CAS auth succeeds*
* **data_dir**             : *directory to be used by confluecne or jira for storing local data*
* **svn_project_url**      : *location of confluence/jira release in svn*
* **maintenance_file_dir** : *location where maintenance file should be written to*

##### Sample Configuration For JIRA #####

Assuming we had the above directories setup in ($HOME=/home/app_relmgt), the
deploy.yml file for jira would look like so:

    build_dir: /home/app_relmgt/.ucb_deployer/build
    deploy_dir: /home/app_jira/tomcat6/webapps
    war_name: ROOT
    cas_server_url: http://cas-server.berkeley.edu
    cas_service_url: https://wikihub.berkeley.edu
    data_dir: /home/app_jira/app_data
    svn_project_url: svn+ssh://svn@code.berkeley.edu/istas/jira_archives/tags
    maintenance_file_dir: /var/www/html/jira/
    

Confluence Configuration
------------------------

#### Setup Container Jars ####
Before deploying confluence, you need to make sure the following jar files exist in
 **$CATALINA_BASE/lib** for Confluence's Tomcat instance:

* postgresql-8.4-701.jdbc3.jar
* javamail-1.3.2.jar
* activation-1.0.2.jar


JIRA Configuration
------------------

#### Setup Container Jars ####
Before deploying JIRA, you need to make sure the following jar files exist in 
**$CATALINA_BASE/lib** for JIRA's Tomcat instance:

* activation-1.0.2.jar
* xapool-1.3.1.jar
* ots-jts_1.0.jar
* mail-1.4.1.jar
* postgresql-8.4-701.jdbc3.jar
* jta-1.0.1.jar
* jotm-jrmp_stubs-1.4.3.jar
* jotm-iiop_stubs-1.4.3.jar
* log4j-1.2.7.jar
* objectweb-datasource-1.4.3.jar
* commons-logging-1.0.4.jar
* carol-properties.jar
* carol-1.5.2.jar
* jonas_timer-1.4.3.jar
* jotm-1.4.3.jar


Usage
-----
    # Either of these will deploy the appication
    ucb_deploy APP=<confluence|jira> VERSION=x.x.x
    ucb_deploy deploy APP=<confluence|jira> VERSION=x.x.x

For more options:

    ucb_deploy -T

