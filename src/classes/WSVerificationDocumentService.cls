public with sharing class WSVerificationDocumentService {

    private WSVerificationClient client = new WSVerificationClient();
    private WSDBController db = new WSDBController();
    @TestVisible
    private List<String> disallowedUrls = new List<String>();

    public WSVerificationDocumentService() {
        try {
            if(Test.isRunningTest()){
                this.disallowedUrls = new List<String>();
                return;
            }
            List<Disallowed_Url__mdt> disallowedUrls = Disallowed_Url__mdt.getAll().values();
            for(Disallowed_Url__mdt disallowedUrl : disallowedUrls) {
                this.disallowedUrls.add(disallowedUrl.Url__c);
            }
        } catch(Exception e) {
            System.debug('Getting disallowedUrls failed');
        }
    }
    
    public void startVerificationJob(List<WSObjects.DocumentWrapper> files){
        System.debug('disallowedUrls : ' + disallowedUrls);
        if(files == null || files.isEmpty() || isListOfDisallowedUrlsEmpty()){
            System.debug(LoggingLevel.INFO, 'Docs or disallowedUrls list is empty. Job was not started');
            return;
        }
        System.debug('start job : ');
        WSDocumentVerificationJob job = new WSDocumentVerificationJob(files, this);
        Database.executeBatch(job, 1);
    }
    
    private Boolean isListOfDisallowedUrlsEmpty(){
        return disallowedUrls.isEmpty();
    }

    public List<String> scanUrls(WSObjects.DocumentWrapper doc) {
        try {
            WSObjects.Response result = client.scanUrls(doc);
            if(result.error == null) {
                return result.links;
            }
            System.debug(System.LoggingLevel.ERROR, 'Can not scan document' + doc + '; ' + result.error);
        } catch(Exception e) {
            System.debug(System.LoggingLevel.ERROR, e);
        }
        return null;
    }

    public Boolean isAnyDisallowedUrlContainedInList(List<String> urls) {
        for(String url : urls) {
            for(String disallowedUrl : disallowedUrls) {
                if(url.startsWithIgnoreCase(disallowedUrl)) {
                    return true;
                }
            }
        }
        return false;
    }
    
    public void processScanResult(Map<WSObjects.DocumentWrapper, List<String>> parsingResult){
        List<SObject> docsToDelete = verifyDocumentUrlsAndRemove(parsingResult);
        db.deleteAttachedDocuments(docsToDelete);
    }

    private List<SObject> verifyDocumentUrlsAndRemove(Map<WSObjects.DocumentWrapper, List<String>> parsingResult) {
        List<SObject> docsToDelete = new List<SObject>();
        for(WSObjects.DocumentWrapper doc : parsingResult.keySet()) {
            if(isAnyDisallowedUrlContainedInList(parsingResult.get(doc))) {
                docsToDelete.add(doc.getDocument());
            }
        }
        return docsToDelete;
    }
}