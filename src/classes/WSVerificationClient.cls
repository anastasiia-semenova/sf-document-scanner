public with sharing class WSVerificationClient {
    public static final String DOMAIN = 'http://ec2-18-212-67-184.compute-1.amazonaws.com';
    public static final String PARSE_DOCUMENT_CONTENT_PATH = '/content/parse-urls';

    public WSObjects.Response scanUrls(WSObjects.DocumentWrapper document) {
        HttpResponse httpResponse = sendRequest(document);
        System.debug('status: ' + httpResponse.getStatus() + ' ; status code: ' + httpResponse.getStatusCode());
        System.debug('body ' + httpResponse.getBody());
        WSObjects.Response resp = parseResponse(httpResponse);
        return resp;
    }

    private WSObjects.Response parseResponse(HttpResponse httpResponse) {
        try {
            if(httpResponse != null
                    && httpResponse.getStatus() != null
                    && httpResponse.getStatusCode() == 200) {
                List<String> urls = (List<String>) JSON.deserialize(httpResponse.getBody(), List<String>.class);
                return new WSObjects.Response(urls);
            } else {
                Map<String, String> responseParams = new Map<String, String>{
                        'statusCode' => String.valueOf(httpResponse.getStatusCode()),
                        'status' => httpResponse.getStatus(),
                        'errorMessage' => httpResponse.getBody()
                };
                return new WSObjects.Response(JSON.serialize(responseParams));
            } 
        } catch(Exception e){
            String exceptionMessage = 'Can not parse response: ' + httpResponse.getBody();
            System.debug(LoggingLevel.ERROR, exceptionMessage);
            return new WSObjects.Response(exceptionMessage);
        }
    }


    private HttpResponse sendRequest(WSObjects.DocumentWrapper doc) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint(DOMAIN + PARSE_DOCUMENT_CONTENT_PATH);
        request.setMethod('POST');
        request.setTimeout(120000);
        String jsonBody = JSON.serialize(
                new Map<String, String>{
                        'content' => doc.getFileBlob().toString()
                });
        request.setBody(jsonBody);
        return http.send(request);
    }

}