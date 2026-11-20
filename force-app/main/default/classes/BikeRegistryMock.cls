@IsTest
public class BikeRegistryMock implements HttpCalloutMock {
    public HttpResponse respond(HttpRequest req) {
        // Volitelně můžeme assertnout, jestli Queueable volá správné URL a metodu
        // System.assertEquals('POST', req.getMethod());

        // Fake odpověď z API
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status": "success", "message": "Kolo uspesne registrovano"}');
        res.setStatusCode(200);

        return res;
    }
}