trigger AttachmentTrigger on Attachment (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        List<WSObjects.DocumentWrapper> files = new List<WSObjects.DocumentWrapper>();
        for(Attachment attachment : Trigger.new) {
            files.add(new WSObjects.DocumentWrapper(attachment));
        }
        new WSVerificationDocumentService().startVerificationJob(files);
    }
}