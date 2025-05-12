class Service{
  Future<Map<String, String>> createHeaderAuthorization(
      {String? tokenAuthor}) async {
    var headersContentType = 'application/json';
    var typeAuthorization = 'Bearer ';
    var token = '55f15958e362452f82382944250905';
    return {
      'Content-type': '$headersContentType',
      'Authorization': '$typeAuthorization$token',
    };
  }
}