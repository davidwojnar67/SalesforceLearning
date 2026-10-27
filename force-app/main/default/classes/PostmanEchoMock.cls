@isTest
public class PostmanEchoMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"json": {"bikeName": "Test Bike"}}');
        res.setStatusCode(200);
        return res;
    }
}