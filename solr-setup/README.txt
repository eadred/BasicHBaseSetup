solr-core-6.3.0.jar is a modified version of Solr Core to handle Azure blob storage (ie where the file system uses the wasb:// protocol).

The code for this is on the azure_support_6_3 branch of git@github.com:eadred/lucene-solr.git.

To build this run the following Ant tasks:
ant common.clean
ant.common.common.jar-core -Dversion="6.3.0"