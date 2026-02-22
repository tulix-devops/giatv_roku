sub init()
    m.top.functionName = "GetSeriesDetails"
    print "SeriesApi.brs - [init] Initialized"
end sub

sub GetSeriesDetails()
    seriesId = m.top.seriesId
    typeId = m.top.typeId
    
    ' Default typeId to 2 (series) if not provided
    if typeId = invalid or typeId <= 0
        typeId = 2
    end if
    
    print "SeriesApi.brs - [GetSeriesDetails] Fetching details for series ID: " + seriesId.ToStr() + ", typeId: " + typeId.ToStr()
    
    if seriesId = invalid or seriesId <= 0
        print "SeriesApi.brs - [GetSeriesDetails] ERROR: Invalid series ID"
        m.top.errorMessage = "Invalid series ID"
        return
    end if
    
    ' Get access token from registry
    accessToken = getAccessToken()
    
    ' Build API URL - Format: /api/content/{typeId}/{seriesId}
    url = "https://giatv.dineo.uk/api/content/" + typeId.ToStr() + "/" + seriesId.ToStr()
    print "SeriesApi.brs - [GetSeriesDetails] Making request to: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    
    ' Add auth header if available
    if accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + accessToken)
        print "SeriesApi.brs - [GetSeriesDetails] Using auth token"
    end if
    
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' Make the request
    response = request.GetToString()
    
    if response <> "" and response <> invalid
        print "SeriesApi.brs - [GetSeriesDetails] Response received, length: " + response.Len().ToStr()
        print "SeriesApi.brs - [GetSeriesDetails] Response: " + response
        
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            if parsedResponse.data <> invalid
                m.top.seriesData = parsedResponse.data
                print "SeriesApi.brs - [GetSeriesDetails] Series data parsed successfully"
            else if parsedResponse.statusCode <> invalid and parsedResponse.statusCode = 200
                m.top.seriesData = parsedResponse
                print "SeriesApi.brs - [GetSeriesDetails] Using full response as series data"
            else
                print "SeriesApi.brs - [GetSeriesDetails] Unexpected response structure"
                m.top.seriesData = parsedResponse
            end if
        else
            print "SeriesApi.brs - [GetSeriesDetails] ERROR: Failed to parse JSON response"
            m.top.errorMessage = "Failed to parse response"
        end if
    else
        print "SeriesApi.brs - [GetSeriesDetails] ERROR: Empty response from server"
        m.top.errorMessage = "No response from server"
    end if
end sub

function getAccessToken() as string
    authDataJson = RegRead("authData", "AUTH")
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            if authData.accessToken <> invalid
                return authData.accessToken
            else if authData.accesstoken <> invalid
                return authData.accesstoken
            end if
        end if
    end if
    
    return ""
end function

function RegRead(key as string, section = "Default" as string) as dynamic
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key)
        return sec.Read(key)
    end if
    return invalid
end function
