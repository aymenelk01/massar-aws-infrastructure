// This CloudFront Function rewrites requests to the root domain to the S3 static path
function handler(event) {
    var request = event.request;
    // If the request is for the root domain, rewrite it to the S3 static path
    if (request.uri === '/' || request.uri === '/index.html') {
        request.uri = '/static/index.html';
    }
    return request;
}

//if the user tap the root domain, it will rewrite the request to the S3 static path exactly the index.html 