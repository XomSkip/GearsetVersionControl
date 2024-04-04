public class JWT_Box {
    public String entityId;
    public String clientId;
    public String clientSecret;

    private String createJti() {
        String validChars = '1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
        Integer len = validChars.length();
        String randomString = '';

        for (Integer i = 0; i < 32; i++) {
            Integer rInt = Integer.valueOf(Math.rint(Math.random() * (len - 1)));
            randomString += validChars.substring(rInt, rInt + 1);
        }
        return randomString;
    }

    public string getAccessToken() {
        String strEndPoint = 'callout:Box_Rest_API/oauth2/token';
        //sub is the hardcoded box dev user //Custom Setting for the future
        String encodingHeader = JWT.base64URLencode(Blob.valueOf('{"alg":"RS256","typ":"JWT"}'));
        String encodingPayload = JWT.base64URLencode(
            Blob.valueOf(
                '{"sub":"26147573989",' +
                '"aud":"' +
                strEndPoint.replace('callout:Box_Rest_API', 'https://api.box.com') +
                '",' +
                '"iss":"' +
                clientId +
                '","jti":"' +
                createJti() +
                '",' +
                '"exp":' +
                String.valueOf((DateTime.now().getTime() / 1000) + 10) +
                ',' +
                '"box_sub_type":"user"}'
            )
        );
        String jwtHeader = encodingHeader + '.' + encodingPayload;
        Blob signature = Crypto.signWithCertificate('rsa-sha256', Blob.valueOf(jwtHeader), 'salesforcebox');
        jwtHeader += '.' + JWT.base64URLencode(signature);

        String urlParameters = String.format(
            'grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer' + '&client_id={0}&client_secret={1}&assertion={2}',
            new List<String>{ clientId, clientSecret, jwtHeader }
        );

        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setMethod('POST');
        req.setEndpoint(strEndPoint);
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setTimeout(120000);
        req.setBody(urlParameters);

        res = h.send(req);
        System.debug('res.getBody() ' + res.getBody());
        if (res.getStatusCode() == 200) {
            return ((Map<String, Object>) JSON.deserializeUntyped(res.getBody())).get('access_token') + '';
        } else {
            System.debug(((Map<String, Object>) JSON.deserializeUntyped(res.getBody())).get('error_description') + '');
            return null;
        }
    }
}