# APEX-Utilites
SFDC solutions and utilities 

## ApexLogCleaner
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