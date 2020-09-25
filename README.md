# StreamSource

## API Reference
### Authentication
Certain routes are protected with a JWT that you must include in your Authorization header when making authenticated requests.

API tokens can be obtained by creating a user and POSTing to /users/login, which will generate and return a token.

Subsequent authenticated requests must include the following header:
```
Authorization: Bearer MYTOKEN
```

### POST /users/signup
Creates a new user

|Param|Description|
|-----|-----------|
|email|This will be your login|
|password|This will be your password|

#### Example:
```
curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/signup
```
```json
{
    "message": "Signed up successfully",
    "user": {
        "role": "default",
        "id": 7,
        "email": "youremail@yourdomain.com",
        "password": "REDACTED",
        "updatedAt": "2020-09-25T06:38:05.045Z",
        "createdAt": "2020-09-25T06:38:05.045Z"
    }
}
```
### POST /users/login
Authenticate in order to retrieve a long-lived JWT that can be used to make requests to other endpoints.

|Param|Description|
|-----|-----------|
|email|The email address of a valid user|
|password|The password of a valid user|

#### Example:
```
curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/login
```
```json
{
    "token": "YOURTOKEN"
}
```
### GET /streams
Retrieves a list of streams with the ability to filter results

Note: All string searches are case-insensitive and queried based on `ILIKE '%YOURSEARCHTERM%'`

|Param|Type|Description|
|-----|----|-----------|
|source|String|The name of a stream or streamer|
|notSource|String|The name of a stream or streamer to exclude|
|link|String|The URL of a stream|
|status|String|One of: `['Live', 'Offline', 'Unknown']`|
|notStatus|String|Exclude this status. One of: `['Live', 'Offline', 'Unknown']`|
|isExpired|Boolean|Streams are considered expired when they are no longer active. Default: false|
|title|String|Title of a stream|
|notTitle|String|Title of a stream|
|postedBy|String|Name of the person who submitted the link|
|notPostedBy|String|Name of a person to exclude|
|city|String|Name of a city|
|notCity|String|Name of a city to exclude|
|region|String|Name of a region (e.g., state, country, province)|
|notRegion|String|Name of a region (e.g., state, country, province) to exclude|

#### Example
Get all active streams in Seattle
```
curl http://localhost:3000/streams?city=seattle
```
```json
[
    {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T04:58:52.840Z"
    }
]
```
### POST /streams
Create a new stream.
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -d "link=http://someurl.com&city=Seattle&region=WA" -X POST http://localhost:3000/streams --header 'Authorization: Bearer MYTOKEN'
```
```json
    {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T04:58:52.840Z"
    }
```
### GET /streams/:id
Get details for a single stream
```
 curl http://localhost:3000/streams/1
```
```json
    {
        "id": 1,
        "source": "future_crystals",
        "platform": "Instagram",
        "link": "https://www.instagram.com/future_crystals/live",
        "status": "Live",
        "title": "",
        "isExpired": false,
        "checkedAt": "2020-09-25T04:58:52.840Z",
        "liveAt": "2020-09-25T04:58:52.840Z",
        "embedLink": "https://www.instagram.com/future_crystals/live",
        "postedBy": "someuser",
        "city": "Seattle",
        "region": "WA",
        "createdAt": "2020-09-25T04:58:52.840Z",
        "updatedAt": "2020-09-25T04:58:52.840Z"
    }
```
### PATCH /streams/:id
Update a new stream.
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -d "status=Offline" -X POST http://localhost:3000/streams/1 --header 'Authorization: Bearer MYTOKEN'
```
```json
    {
        ...
        "status": "Offline",
        ...
    }
```
### DELETE /streams/:id
Expire a stream
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X DELETE http://localhost:3000/streams/1 --header 'Authorization: Bearer MYTOKEN'
```
```json
    {
        ...
        "isExpired": true,
        ...
    }
```
