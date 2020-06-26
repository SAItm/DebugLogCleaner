<a href="https://githubsfdeploy.herokuapp.com">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

# ApexLogCleaner
Batch for deleting 'Debug Logs' periodically.

### How to use
```
Integer runEachMinutes = 2;
new ApexLogCleaner(runEachMinutes).start();
```
or 
```
Integer runEachMinutes = 2;
String whereCondition = 'LogUserId == \'' + userId + '\'';
new ApexLogCleaner(runEachMinutes, whereCondition).start();
```
To stop:
```
ApexLogCleaner.stop();
```
