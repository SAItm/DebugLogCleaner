public with sharing class DebugLogCleaner implements Database.Batchable<sObject>, Database.AllowsCallouts {
    // Tooling api after api v.7 allows to delete max 200 ids.
    Integer SCOPE_SIZE = 200;
    
    Integer eachMinutes;
    Datetime executionTime;
    String whereCondition;

    public DebugLogCleaner(Integer eachMinutes) {
        this.eachMinutes = eachMinutes;
    }

    public DebugLogCleaner(Integer eachMinutes, String whereCondition) {
        this.eachMinutes = eachMinutes;
        this.whereCondition = whereCondition;
    }

    DebugLogCleaner(Integer eachMinutes, Datetime executionTime, String whereCondition) {
        this.eachMinutes = eachMinutes;
        this.executionTime = executionTime;
        this.whereCondition = whereCondition;
    }

    public void start() {
        stop();
        try {
            this.executionTime = Datetime.now();
            Database.executeBatch(this, this.SCOPE_SIZE);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }

    public static void stop() {
        for (CronTrigger cronTrigger : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name = 'DebugLogCleaner']) {
            System.abortJob(cronTrigger.Id);
        }
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
                'SELECT Id FROM ApexLog ' + (String.isBlank(whereCondition) ? '' : whereCondition)
        );
    }
    public void execute(Database.BatchableContext context, List<SObject> logs) {
        List<Id> logsIds = new List<Id>(new Map<Id, SObject>(logs).keySet());
        deleteLogs(logsIds);
    }

    public static HttpResponse deleteLogs(List<Id> ids) {
        HttpRequest request = prepareRequest(ids);
        Http http = new Http();
        if (Test.isRunningTest()) return null;
        return http.send(request);
    }

    public static HttpRequest prepareRequest(List<Id> ids) {
        HttpRequest request = new HttpRequest();
        request.setEndpoint(Url.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/T/49.0');
        request.setBody(prepareRequestBody(ids));
        request.setMethod('POST');
        request.setHeader('SOAPAction', '""');
        request.setHeader('Content-Type', 'text/xml');
        return request;
    }

    public static String prepareRequestBody(List<Id> ids) {
        String body =
                '<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:urn=\"urn:tooling.soap.sforce.com\">'
                   + '<soapenv:Header>'
                        + '<urn:AllOrNoneHeader>'
                            + '<urn:allOrNone>false</urn:allOrNone>'
                        + '</urn:AllOrNoneHeader>'
                        + '<urn:MetadataWarningsHeader>'
                            + '<urn:ignoreSaveWarnings>true</urn:ignoreSaveWarnings>'
                        + '</urn:MetadataWarningsHeader>'
                        + '<urn:SessionHeader>'
                            + '<urn:sessionId>' + UserInfo.getOrganizationId() + '' + UserInfo.getSessionId().Substring(15) + '</urn:sessionId>'
                        + '</urn:SessionHeader>'
                    + '</soapenv:Header>'
                    + '<soapenv:Body>'
                        + '<urn:delete>'
                            + '<urn:ids>' + String.join(ids, '</urn:ids><urn:ids>') + '</urn:ids>'
                        + '</urn:delete>'
                    + '</soapenv:Body>'
                + '</soapenv:Envelope>';
        return body;
    }

    public void finish(Database.BatchableContext context) {
        Datetime nextExecution = this.executionTime.addMinutes(eachMinutes);
        Integer inMinutes = (Integer) ((nextExecution.getTime() - Datetime.now().getTime()) / 1000 / 60);
        inMinutes = inMinutes >= 0 ? inMinutes : 0;
        DebugLogCleaner batch = new DebugLogCleaner(
            this.eachMinutes,
            nextExecution,
            this.whereCondition
        );
        System.scheduleBatch(batch, 'DebugLogCleaner', inMinutes, this.SCOPE_SIZE);
    }
}