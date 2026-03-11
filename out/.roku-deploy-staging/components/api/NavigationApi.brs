sub init()
    m.top.functionName = "GetNavigationData"
    print "NavigationApi.brs - [init] Initialized"
end sub

sub GetNavigationData()
    ' Create HTTP request for navigation data
    url = "https://giatv.dineo.uk/api/content-type/list"
    print "NavigationApi.brs - [GetNavigationData] Requesting: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' Set connection timeout (3 seconds)
    request.SetConnectionTimeout(3000)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    ' Retrieve and add authentication token
    authData = RetrieveAuthData()
    if authData <> invalid and authData.accessToken <> invalid and authData.accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + authData.accessToken)
    end if
    port = CreateObject("roMessagePort")
    request.SetPort(port)
    
    if request.AsyncGetToString()
        ' Wait for response with timeout (3 seconds)
        startTime = CreateObject("roDateTime").AsSeconds()
        maxWaitTime = 3
        response = invalid
        responseCode = -1
        
        while true
            msg = wait(500, port)
            currentTime = CreateObject("roDateTime").AsSeconds()
            elapsed = currentTime - startTime
            
            if msg <> invalid
                if type(msg) = "roUrlEvent"
                    responseCode = msg.GetResponseCode()
                    response = msg.GetString()
                    exit while
                end if
            else if elapsed >= maxWaitTime
                print "NavigationApi.brs - [GetNavigationData] Timeout after " + elapsed.ToStr() + "s"
                exit while
            end if
        end while
    else
        responseCode = -1
        response = invalid
    end if
    
    ' Check if we got a valid response
    if response <> invalid and response <> "" and responseCode >= 200 and responseCode < 300
        ' Parse and validate the response
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            ' Check if response has expected structure
            hasValidData = false
            responseDataField = parsedResponse["data"]
            if responseDataField <> invalid
                dataInterface = GetInterface(responseDataField, "ifArray")
                if dataInterface <> invalid
                    hasValidData = true
                end if
            end if
            
            if hasValidData
                print "NavigationApi.brs - [GetNavigationData] Success: " + responseDataField.Count().ToStr() + " items"
                m.top.responseData = response
            else
                print "NavigationApi.brs - [GetNavigationData] WARNING: Unexpected response structure, but passing through"
                ' Pass through the response anyway - let the navigation bar handle it
                m.top.responseData = response
            end if
        else
            print "NavigationApi.brs - [GetNavigationData] ERROR: Failed to parse JSON response"
            print "NavigationApi.brs - [GetNavigationData] Using default navigation data instead"
            m.top.errorMessage = "Failed to parse navigation data"
            setDefaultNavigationData()
        end if
    else
        ' Request failed, timed out, or returned error code
        print "NavigationApi.brs - [GetNavigationData] ERROR: Request failed"
        print "NavigationApi.brs - [GetNavigationData] Response code: " + responseCode.ToStr()
        print "NavigationApi.brs - [GetNavigationData] Response is invalid: " + (response = invalid).ToStr()
        print "NavigationApi.brs - [GetNavigationData] Response is empty: " + (response = "").ToStr()
        print "NavigationApi.brs - [GetNavigationData] Using default navigation data instead"
        m.top.errorMessage = "API request failed (code: " + responseCode.ToStr() + ")"
        ' Use default navigation data instead of empty response
        setDefaultNavigationData()
    end if
end sub

sub setDefaultNavigationData()
    print "NavigationApi.brs - [setDefaultNavigationData] Setting default navigation data"
    
    defaultNavData = [
        {
            "id": 13,
            "title": "Home",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/home_icon.png"]
            }
        },
        {
            "id": 3,
            "title": "Live",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/live_icon.png"]
            }
        },
        {
            "id": 1,
            "title": "Movies",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/movie_icon.png"]
            }
        },
        {
            "id": 2,
            "title": "TV Shows",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/archives_icon.png"]
            }
        },
        {
            "id": 14,
            "title": "User Channels",
            "images": invalid
        }
    ]
    
    defaultResponse = {
        "data": defaultNavData
    }
    
    m.top.responseData = FormatJson(defaultResponse)
end sub

function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    if jsonData <> invalid and jsonData <> ""
        data = ParseJson(jsonData)
        if data <> invalid
            currentTime = CreateObject("roDateTime").asSeconds()
            if data.expiry <> invalid and currentTime <= data.expiry
                return data
            else
                print "NavigationApi.brs - [RetrieveAuthData] Auth token expired"
                return invalid
            end if
        end if
    end if
    return invalid
end function

function RegRead(key, section = invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
end function
