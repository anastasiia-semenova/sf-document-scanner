public with sharing class WSDBController {

    public void deleteAttachedDocuments(List<SObject> docsToDelete) {
        if(!docsToDelete.isEmpty()) {
            SObject doc = docsToDelete.get(0);
            if(doc instanceof Attachment) {
                deleteAttachments((List<Attachment>) docsToDelete);
                return;
            }
            if(doc instanceof ContentDocument) {
                deleteDocuments((List<ContentDocument>) docsToDelete);
                return;
            }
            System.debug('Can not delete attached document. Wrong SObject type: ' + doc);
        }
        System.debug(System.LoggingLevel.INFO, 'No documents with disallowed urls');
    }

    public void deleteAttachments(List<Attachment> attachments) {
        if(!Schema.SObjectType.Attachment.isDeletable()) {
            throw createException('Object Attachment is not deletable');
        }
        Database.delete(attachments);
    }

    public void deleteDocuments(List<ContentDocument> documents) {
        System.debug(LoggingLevel.INFO, 'to delete ' + documents);
        if(!Schema.SObjectType.ContentDocument.isDeletable()) {
            throw createException('Object ContentVersion is not deletable');
        }
        Database.delete(documents);
    }


    private NoAccessException createException(String message) {
        NoAccessException ex = new NoAccessException();
        ex.setMessage(message);
        return ex;
    }
}