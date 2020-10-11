# StreamSource
Streamsource is a publicly readable API to store and retrieve information about livestreams across many streaming platforms.

## Getting Started
**If you just want to use the API to read stream data found at [streams.streamwall.io](http://streams.streamwall.io), see [API Reference](#api-reference)**

### Current state
Streamsource is in active development at a very early stage. Do not consider the API stable. We don't even have versioning yet! (we accept PRs!)

Many assumptions are built in, and this application is tightly coupled to a few different services. This will improve over time.

### Installation

1. Clone this repository
1. `npm install`
1. Install Postgres and create a database, a user, etc.
1. Copy example.env to just .env and update your configuration settings
1. `npx sequelize-cli db:migrate`

### Running

1. Make sure Postgres is running
1. Start server: `node bin/www`
1. Preview streams json: http://localhost:3000/streams

### Upgrading

1. Get new code: `git pull`
1. Apply migrations: `npx sequelize-cli db:migrate`
1. Restart server: `node bin/www` 

### Development and contributing

This project is in its infancy. We're open to pull requests and will work with you to get improvements merged.

## API Reference

### Authentication
Most routes are protected with a JWT that you must include in your Authorization header when making authenticated requests.

API tokens can be obtained by creating a user and POSTing to /users/login, which will generate and return a token.

Subsequent authenticated requests must include the following header:
```
Authorization: Bearer MYTOKEN
```

#### Getting Started with Authentication
1. Create your user
    ```
    curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/signup
    ```
2. Log in
    ```
    curl -d "email=youremail@yourdomain.com&password=abc123" -X POST http://localhost:3000/users/login
    ```
3. Save the token in your app/script/bot's configuration file (keep it secret!)

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
|platform|String|The name of a streaming platform (e.g., "Facebook", "Twitch")|
|notPlatform|String|The name of a platform to exclude|
|link|String|The URL of a stream|
|status|String|One of: `['Live', 'Offline', 'Unknown']`|
|notStatus|String|Exclude this status. One of: `['Live', 'Offline', 'Unknown']`|
|isPinned|Boolean|Defaults to null. When true, prevents state changes, e.g. updates to `isExpired` or `status`|
|isExpired|Boolean|Streams are considered expired when they are no longer active. Default: false|
|title|String|Title of a stream|
|notTitle|String|Title of a stream|
|postedBy|String|Name of the person who submitted the link|
|notPostedBy|String|Name of a person to exclude|
|city|String|Name of a city|
|notCity|String|Name of a city to exclude|
|region|String|Name of a region (e.g., state, country, province)|
|notRegion|String|Name of a region (e.g., state, country, province) to exclude|
|orderFields|String, CSV|CSV of fields to order by. Must be accompanied by an orderDirection for each field|
|orderDirections|String, CSV|CSV of directions to order by. One per orderField, respectively|
|format|String|Currently only accepts "`array`" or null; returns a raw array of streams for Streamwall if set to `array`, otherwise it's formatted like `{ data: [ {...}, {...} ] }`|

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
        "isPinned": false,
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
        "isPinned": false,
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
        "isPinned": false,
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
### PUT /streams/:id/pin
Pin a stream; prevents state changes while pinned
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X PUT http://localhost:3000/streams/1/pin --header 'Authorization: Bearer MYTOKEN'
```
```json
    {
        ...
        "isPinned": true,
        ...
    }
```
### DELETE /streams/:id/pin
Unpin a stream
- **Requires authentication**
- **Requires privileged role: Editor or Admin**
```
 curl -X PUT http://localhost:3000/streams/1/pin --header 'Authorization: Bearer MYTOKEN'
```
```json
    {
        ...
        "isPinned": false,
        ...
    }
```
