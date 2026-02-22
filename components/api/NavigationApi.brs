sub init()
    m.top.functionName = "GetNavigationData"
    print "NavigationApi.brs - [init] Initialized"
end sub

sub GetNavigationData()
    print "NavigationApi.brs - [GetNavigationData] Called"

    ' Create HTTP request for navigation data
    url = "https://giatv.dineo.uk/api/content-type/list"
    print "NavigationApi.brs - [GetNavigationData] Making request to: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' Retrieve and add authentication token
    authData = RetrieveAuthData()
    if authData <> invalid and authData.accessToken <> invalid and authData.accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + authData.accessToken)
        print "NavigationApi.brs - [GetNavigationData] Making request with authentication token"
    else
        print "NavigationApi.brs - [GetNavigationData] WARNING: No valid auth token found, making request without authentication"
    end if
    
    ' Make the request
    print "NavigationApi.brs - [GetNavigationData] About to make HTTP request..."
    response = request.GetToString()
    
    print "NavigationApi.brs - [GetNavigationData] Response Length: " + response.Len().ToStr()
    
    if response <> "" and response <> invalid
        print "NavigationApi.brs - [GetNavigationData] Response received: " + response
        
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
                print "NavigationApi.brs - [GetNavigationData] Valid navigation data received with " + responseDataField.Count().ToStr() + " items"
                m.top.responseData = response
            else
                print "NavigationApi.brs - [GetNavigationData] WARNING: Unexpected response structure, but passing through: " + response
                ' Pass through the response anyway - let the navigation bar handle it
                m.top.responseData = response
            end if
        else
            print "NavigationApi.brs - [GetNavigationData] ERROR: Failed to parse JSON response"
            m.top.errorMessage = "Failed to parse navigation data"
        end if
    else
        print "NavigationApi.brs - [GetNavigationData] ERROR: Empty response from server"
        m.top.errorMessage = "No response from navigation API"
        ' Let the navigation bar handle the empty response with its own defaults
        m.top.responseData = ""
    end if
end sub

sub setDefaultNavigationData()
    print "NavigationApi.brs - [setDefaultNavigationData] Setting default navigation data"
    
    defaultNavData = [
        {
            "id": 1,
            "title": "Home",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/home_icon.png"]
            }
        },
        {
            "id": 2,
            "title": "Live",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/live_icon.png"]
            }
        },
        {
            "id": 3,
            "title": "Movies",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/movie_icon.png"]
            }
        },
        {
            "id": 4,
            "title": "TV Shows",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/archives_icon.png"]
            }
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
