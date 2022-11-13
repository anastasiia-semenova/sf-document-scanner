@IsTest(SeeAllData=false)
private class WSDocumentVerificationTest {

    private static final String SOME_FILE1_TXT_FILE_NAME = 'someFile1.txt';
    private static final String DISALLOWED_LINK = 'http://www.flickr.com';
    private static final String STATUS_503_MARK = 'Status_503';
    private static final String BAD_RESPONSE_FORMAT_MARK = 'Bad_response';

    private static WSVerificationClient client = new WSVerificationClient();

    @TestSetup
    static void setupData() {
        Blob content = Blob.valueOf('content');

        ContentVersion version = new ContentVersion();
        version.PathOnClient = SOME_FILE1_TXT_FILE_NAME;
        version.VersionData = content;
        insert version;

        Case testCase = new Case();
        insert testCase;

        Attachment attachment = new Attachment();
        attachment.Name = SOME_FILE1_TXT_FILE_NAME;
        attachment.Body = content;
        attachment.ParentId = testCase.Id;
        insert attachment;
    }

//    WSVerificationClient tests
    @IsTest
    static void shouldScanUrlsEndReturnResponseWithError() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        ContentVersion version = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME).get(0);
        version.VersionData = Blob.valueOf(STATUS_503_MARK);
        update version;

        WSObjects.DocumentWrapper docWrapper = new WSObjects.DocumentWrapper(version);

        Test.startTest();
        WSObjects.Response response = client.scanUrls(docWrapper);
        Test.stopTest();

        System.assertEquals(true, response != null, 'response should not be null');
        System.assertEquals(true, response.links == null, 'List links should be null');
        System.assertEquals(true, response.error != null, 'Error should not be null');
        System.assertEquals('{"errorMessage":"\\"Internal Server Error\\"","status":"Error","statusCode":"503"}', response.error, 'Wrong error value');
    }

    @IsTest
    static void shouldScanUrlsEndReturnResponseWithParsingError() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        ContentVersion version = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME).get(0);
        version.VersionData = Blob.valueOf(BAD_RESPONSE_FORMAT_MARK);
        update version;

        WSObjects.DocumentWrapper docWrapper = new WSObjects.DocumentWrapper(version);

        Test.startTest();
        WSObjects.Response response = client.scanUrls(docWrapper);
        Test.stopTest();

        System.assertEquals(true, response != null, 'response should not be null');
        System.assertEquals(true, response.links == null, 'List links should be null');
        System.assertEquals(true, response.error != null, 'Error should not be null');
        System.assertEquals(true, response.error.containsIgnoreCase('Can not parse response'), 'Wrong error value');
    }


//    WSDocumentVerificationJob tests
    @IsTest
    static void shouldVerifyAndDeleteDocumentWhenRunWSDocumentVerificationJob() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        ContentVersion version = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME).get(0);
        version.VersionData = Blob.valueOf('some data');
        update version;

        WSObjects.DocumentWrapper doc = new WSObjects.DocumentWrapper(version);
        List<WSObjects.DocumentWrapper> docs = new List<WSObjects.DocumentWrapper>{doc};

        Test.startTest();
        WSDocumentVerificationJob job = new WSDocumentVerificationJob(docs);
        job.service.disallowedUrls = new List<String>{DISALLOWED_LINK};
        Database.executeBatch(job, 1);
        Test.stopTest();

        List<ContentVersion> contentVersions = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME);

        System.assertEquals(true, contentVersions.isEmpty(), 'Document version should be deleted after verification');
    }

    @IsTest
    static void shouldVerifyAndDKeepDocumentWhenRunWSDocumentVerificationJob() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        ContentVersion version = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME).get(0);
        version.VersionData = Blob.valueOf('some data');
        update version;

        WSObjects.DocumentWrapper doc = new WSObjects.DocumentWrapper(version);
        List<WSObjects.DocumentWrapper> docs = new List<WSObjects.DocumentWrapper>{doc};

        Test.startTest();
        WSDocumentVerificationJob job = new WSDocumentVerificationJob(docs);
        job.service.disallowedUrls = new List<String>{'https://www.test.org/'};
        Database.executeBatch(job, 1);
        Test.stopTest();

        List<ContentVersion> contentVersions = getContentVersionsByPathOnClient(SOME_FILE1_TXT_FILE_NAME);

        System.assertEquals(false, contentVersions.isEmpty(), 'Document should be kept after verification');
        System.assertEquals(1, contentVersions.size(), ' One Document should be kept after verification');
    }

    @IsTest
    static void shouldVerifyAndDeleteAttachmentWhenRunWSDocumentVerificationJob() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        Attachment attachment = getAttachmentsByName(SOME_FILE1_TXT_FILE_NAME).get(0);
        attachment.Body = Blob.valueOf('some data');
        update attachment;

        WSObjects.DocumentWrapper doc = new WSObjects.DocumentWrapper(attachment);
        List<WSObjects.DocumentWrapper> docs = new List<WSObjects.DocumentWrapper>{doc};

        Test.startTest();
        WSDocumentVerificationJob job = new WSDocumentVerificationJob(docs);
        job.service.disallowedUrls = new List<String>{DISALLOWED_LINK};
        Database.executeBatch(job, 1);
        Test.stopTest();

        List<Attachment> attachments = getAttachmentsByName(SOME_FILE1_TXT_FILE_NAME);
        
        System.assertEquals(true, attachments.isEmpty(), 'Attachment  should be deleted after verification');
    }


    @IsTest
    static void shouldVerifyAndDKeepAttachmentWhenRunWSDocumentVerificationJob() {
        Test.setMock(HttpCalloutMock.class, new MockDocumentScannerAPI());
        Attachment attachment = getAttachmentsByName(SOME_FILE1_TXT_FILE_NAME).get(0);
        attachment.Body = Blob.valueOf('some data');
        update attachment;

        WSObjects.DocumentWrapper doc = new WSObjects.DocumentWrapper(attachment);
        List<WSObjects.DocumentWrapper> docs = new List<WSObjects.DocumentWrapper>{doc};

        Test.startTest();
        WSDocumentVerificationJob job = new WSDocumentVerificationJob(docs);
        job.service.disallowedUrls = new List<String>{'https://www.test.org/'};
        Database.executeBatch(job, 1);
        Test.stopTest();

        List<Attachment> attachments = getAttachmentsByName(SOME_FILE1_TXT_FILE_NAME);
        System.assertEquals(false, attachments.isEmpty(), 'Attachment should be kept after verification');
        System.assertEquals(1, attachments.size(), ' One Attachment should be kept after verification');
    }

    private static List<Attachment> getAttachmentsByName(String fileName) {
        return [
                SELECT Id, Body, ParentId, Name
                FROM Attachment
                WHERE Name = :fileName
        ];
    }

    private static List<ContentVersion> getContentVersionsByPathOnClient(String pathOnClient) {
        List<ContentVersion> contentVersions = [
                SELECT Id, VersionData, PathOnClient, ContentDocumentId
                FROM ContentVersion
                WHERE PathOnClient = :pathOnClient
        ];
        return contentVersions;
    }


    private class MockDocumentScannerAPI implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {

            String expectedEndpoint = WSVerificationClient.DOMAIN + WSVerificationClient.PARSE_DOCUMENT_CONTENT_PATH;
            System.assertEquals(expectedEndpoint, req.getEndpoint(), 'Endpoint is wrong');
            System.assertEquals('POST', req.getMethod(), 'Method is wrong');

            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if(req.getBody().contains(STATUS_503_MARK)) {
                String response = 'Internal Server Error';
                res.setBody(JSON.serialize(response));
                res.setStatus('Error');
                res.setStatusCode(503);
                return res;
            }

            if(req.getBody().contains(BAD_RESPONSE_FORMAT_MARK)) {
                res.setStatus('OK');
                res.setStatusCode(200);
                res.setBody('some response');
                return res;
            }

            List<String> urls = new List<String>{
                    DISALLOWED_LINK,
                    'http://500px.com',
                    'http://www.freeimagehosting.net',
                    'https://postimage.io',
                    'https://www.facebook.com/'
            };
            res.setBody(JSON.serialize(urls));
            res.setStatus('OK');
            res.setStatusCode(200);
            return res;
        }
    }
}