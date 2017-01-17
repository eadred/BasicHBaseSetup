Create virtual machine:	
	vagrant up

Run main processes(hbase, solr, hbase-idnexer):
	./run-tweets-indexer.sh


## Solr autocommit

According to provision script, documents are autocommitted to Solr after reaching 1000 limit(maxDocs set to 1000). 
If you add documents less than 1000, you can trigger commit manually by this query:
	curl http://localhost:8983/solr/<collection_name>/update?commit=true  
