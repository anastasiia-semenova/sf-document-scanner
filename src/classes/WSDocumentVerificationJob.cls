public with sharing class WSDocumentVerificationJob implements Database.Batchable<WSObjects.DocumentWrapper>, Database.Stateful, Database.AllowsCallouts {
    
    private List<WSObjects.DocumentWrapper> files;
    private Map<WSObjects.DocumentWrapper, List<String>> urlsByDocumentWrapper = new Map<WSObjects.DocumentWrapper, List<String>>();
    @TestVisible
    private WSVerificationDocumentService service;

    public WSDocumentVerificationJob(List<WSObjects.DocumentWrapper> files, WSVerificationDocumentService service) {
        this.files = files;
        this.service = service;
    }
    public WSDocumentVerificationJob(List<WSObjects.DocumentWrapper> files) {
        this.files = files;
        this.service = new WSVerificationDocumentService();
    }
    

    public List<WSObjects.DocumentWrapper> start(Database.BatchableContext param1) {
        if(files == null  || service == null){
            return new List<WSObjects.DocumentWrapper>();
        }
        return files;
    }

    public void execute(Database.BatchableContext param1, List<WSObjects.DocumentWrapper> docs) {
        for(Integer i = 0; i < docs.size(); i++) {
            WSObjects.DocumentWrapper doc = docs.get(i);
            List<String> parsedUrls = service.scanUrls(doc);
            if(parsedUrls != null){
                urlsByDocumentWrapper.put(doc, parsedUrls);
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        service.processScanResult(urlsByDocumentWrapper);
    }

}