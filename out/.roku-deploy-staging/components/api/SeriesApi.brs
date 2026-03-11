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
    
    ' Build API URL
    url = "https://giatv.dineo.uk/api/content/" + typeId.ToStr() + "/" + seriesId.ToStr()
    print "SeriesApi.brs - [GetSeriesDetails] Trying endpoint: " + url
    
    ' Create message port for async request
    port = CreateObject("roMessagePort")
    
    request = CreateObject("roUrlTransfer")
    request.SetMessagePort(port)
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    
    ' Add auth header if available
    if accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + accessToken)
        print "SeriesApi.brs - [GetSeriesDetails] Using auth token"
    else
        print "SeriesApi.brs - [GetSeriesDetails] WARNING: No auth token available"
    end if
    
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    ' Make async request
    print "SeriesApi.brs - [GetSeriesDetails] Starting async request..."
    if request.AsyncGetToString()
        ' Wait for response with timeout
        msg = wait(10000, port) ' 10 second timeout
        
        if msg <> invalid and type(msg) = "roUrlEvent"
            responseCode = msg.GetResponseCode()
            print "SeriesApi.brs - [GetSeriesDetails] Response code: " + responseCode.ToStr()
            
            response = msg.GetString()
            
            if responseCode = 200 or responseCode = 206
                print "SeriesApi.brs - [GetSeriesDetails] Success response received"
                processResponse(response, responseCode)
            else
                print "SeriesApi.brs - [GetSeriesDetails] HTTP error: " + responseCode.ToStr()
                print "SeriesApi.brs - [GetSeriesDetails] Response length: " + response.Len().ToStr()
                print "SeriesApi.brs - [GetSeriesDetails] Response preview: " + Left(response, 200)
                m.top.errorMessage = "HTTP error: " + responseCode.ToStr()
            end if
        else
            print "SeriesApi.brs - [GetSeriesDetails] ERROR: Request timeout or no response"
            m.top.errorMessage = "Request timeout"
        end if
    else
        print "SeriesApi.brs - [GetSeriesDetails] ERROR: Failed to start async request"
        m.top.errorMessage = "Failed to start request"
    end if
end sub

sub processResponse(response as string, responseCode as integer)
    
    if response <> "" and response <> invalid
        print "SeriesApi.brs - [processResponse] Response received, length: " + response.Len().ToStr()
        print "SeriesApi.brs - [processResponse] Response preview: " + Left(response, 500)
        
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            print "SeriesApi.brs - [processResponse] JSON parsed, checking structure..."
            
            ' Check response structure
            if parsedResponse.data <> invalid
                print "SeriesApi.brs - [processResponse] Found data field"
                m.top.seriesData = parsedResponse.data
            else if parsedResponse.statusCode <> invalid and (parsedResponse.statusCode = 200 or parsedResponse.statusCode = 206)
                print "SeriesApi.brs - [processResponse] Using full response (statusCode: " + parsedResponse.statusCode.ToStr() + ")"
                m.top.seriesData = parsedResponse
            else if parsedResponse.seasons <> invalid
                print "SeriesApi.brs - [processResponse] Found seasons field directly"
                m.top.seriesData = parsedResponse
            else
                print "SeriesApi.brs - [processResponse] Unexpected structure, using full response"
                print "SeriesApi.brs - [processResponse] Response keys: " + FormatJson(parsedResponse.Keys())
                m.top.seriesData = parsedResponse
            end if
        else
            print "SeriesApi.brs - [processResponse] ERROR: Failed to parse JSON"
            print "SeriesApi.brs - [processResponse] Response length: " + response.Len().ToStr()
            print "SeriesApi.brs - [processResponse] Response preview: " + Left(response, 200)
            m.top.errorMessage = "Failed to parse response"
        end if
    else
        print "SeriesApi.brs - [processResponse] ERROR: Empty or invalid response (code: " + responseCode.ToStr() + ")"
        m.top.errorMessage = "No response from server (HTTP " + responseCode.ToStr() + ")"
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
