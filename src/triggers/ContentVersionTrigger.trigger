trigger ContentVersionTrigger on ContentVersion (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        List<WSObjects.DocumentWrapper> files = new List<WSObjects.DocumentWrapper>();
        Set<Id> ids = new Set<Id>();
        for(ContentVersion cv : Trigger.new) {
            ids.add(cv.Id);
        }
        for(ContentVersion cv : [
                SELECT Id, VersionData, PathOnClient, ContentDocumentId
                FROM ContentVersion
                WHERE Id IN :ids
        ]) {
            files.add(new WSObjects.DocumentWrapper(cv));
        }
        new WSVerificationDocumentService().startVerificationJob(files);
    }
}