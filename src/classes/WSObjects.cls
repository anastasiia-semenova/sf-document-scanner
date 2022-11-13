public with sharing class WSObjects {

    public class DocumentWrapper {
        private Attachment attachment;
        private ContentVersion contentVersion;

        private Id fileId;
        private String sfType;
        private String fileName;
        private Blob fileBlob;

        public DocumentWrapper(SObject file) {
            if(file instanceof Attachment) {
                this.attachment = (Attachment) file;
                this.sfType = 'Attachment';
                this.fileId = attachment.Id;
                this.fileName = attachment.Name;
                this.fileBlob = attachment.Body;
            }
            if(file instanceof ContentVersion) {
                this.contentVersion = (ContentVersion) file;
                this.sfType = 'ContentVersion';
                this.fileId = contentVersion.Id;
                this.fileName = contentVersion.PathOnClient;
                this.fileBlob = contentVersion.VersionData;
            }
        }

        public Id getId() {
            if(attachment != null) {
                return attachment.Id;
            }
            return contentVersion.Id;
        }

        public String getFileName() {
            return fileName;
        }

        public Blob getFileBlob() {
            return fileBlob;
        }

        public String getType() {
            return sfType;
        }

        public SObject getDocument() {
            if(attachment != null) {
                return attachment;
            }
            return new ContentDocument(
                    id = contentVersion.ContentDocumentId
            );
        }
    }

    public class Response {
        public List<String> links { private set; public get; }
        public String error { private set; public get; }

        public Response(List<String> links) {
            this.links = links;
        }

        public Response(String error) {
            this.error = error;
        }
    }
}