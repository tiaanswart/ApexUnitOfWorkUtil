# Apex Unit Of Work Util

Unit Of Work Utility for Salesforce Apex

I am a big fan of FFlib for Apex, however I needed something a little bit more lightweight and dynamic.

This utility allows the following:

1. Register SObject Types in the order you want it to be processed and additionally include an External Id field you want to be used when performing the upserts.
2. Register SObject Records to be Upserted (Insert and Update)
3. Register SObject Records to be Deleted
4. Register Relationships that should be resolved before DML

For examples check the test class.

<br/>
<a href="https://githubsfdeploy.herokuapp.com?owner=tiaanswart&repo=ApexUnitOfWorkUtil&ref=master">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>