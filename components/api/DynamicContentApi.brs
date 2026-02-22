sub init()
    m.top.functionName = "GetDynamicContentData"
    print "DynamicContentApi.brs - [init] Initialized"
end sub

sub GetDynamicContentData()
    print "DynamicContentApi.brs - [GetDynamicContentData] Called for contentTypeId: " + m.top.contentTypeId.ToStr()

    ' Get access token from registry
    authDataJson = RegRead("authData", "AUTH")
    print "DynamicContentApi.brs - [GetDynamicContentData] Raw authData from registry: " + authDataJson
    
    accessToken = ""
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            print "DynamicContentApi.brs - [GetDynamicContentData] Parsed authData: " + FormatJson(authData)
            
            ' Check for both possible field names
            if authData.accessToken <> invalid
                accessToken = authData.accessToken
                print "DynamicContentApi.brs - [GetDynamicContentData] Found accessToken (camelCase): " + accessToken.Len().ToStr() + " characters"
            else if authData.accesstoken <> invalid
                accessToken = authData.accesstoken
                print "DynamicContentApi.brs - [GetDynamicContentData] Found accesstoken (lowercase): " + accessToken.Len().ToStr() + " characters"
            else
                print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: No accessToken or accesstoken field found"
                print "DynamicContentApi.brs - [GetDynamicContentData] Available fields: " + FormatJson(authData)
            end if
        else
            print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: Failed to parse authData JSON"
        end if
    else
        print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: No authData found in registry"
    end if
    
    ' Determine API endpoint based on content type
    apiEndpoint = getApiEndpointForContentType(m.top.contentTypeId)
    print "DynamicContentApi.brs - [GetDynamicContentData] API endpoint for contentTypeId " + m.top.contentTypeId.ToStr() + ": " + apiEndpoint
    
    if apiEndpoint = ""
        print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: No API endpoint for contentTypeId: " + m.top.contentTypeId.ToStr()
        ' Use default content only if no endpoint is available
        defaultResponse = getDefaultContentForType(m.top.contentTypeId)
        m.top.responseData = FormatJson(defaultResponse)
        ' Parse default content items - convert to category structure
        m.top.contentItems = defaultResponse.data
        return
    end if

    ' Create HTTP request for content data (try API call even without auth)
    url = "https://giatv.dineo.uk/api/" + apiEndpoint
    print "DynamicContentApi.brs - [GetDynamicContentData] Making request to: " + url
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    
    ' Add auth header only if we have a token
    if accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + accessToken)
        print "DynamicContentApi.brs - [GetDynamicContentData] *** USING AUTHENTICATION TOKEN ***"
        print "DynamicContentApi.brs - [GetDynamicContentData] Token length: " + accessToken.Len().ToStr() + " characters"
        print "DynamicContentApi.brs - [GetDynamicContentData] Token preview: " + Left(accessToken, 20) + "..."
    else
        print "DynamicContentApi.brs - [GetDynamicContentData] *** WARNING: NO AUTH TOKEN - MAKING UNAUTHENTICATED REQUEST ***"
        print "DynamicContentApi.brs - [GetDynamicContentData] This may cause the API to return empty or default data"
    end if
    
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' Make the request
    print "DynamicContentApi.brs - [GetDynamicContentData] Making HTTP request..."
    response = request.GetToString()
    
    print "DynamicContentApi.brs - [GetDynamicContentData] HTTP request completed"
    print "DynamicContentApi.brs - [GetDynamicContentData] Response is empty: " + (response = "").ToStr()
    print "DynamicContentApi.brs - [GetDynamicContentData] Response is invalid: " + (response = invalid).ToStr()
    if response <> invalid and response <> ""
        print "DynamicContentApi.brs - [GetDynamicContentData] Response length: " + response.Len().ToStr()
    end if
    
    if response <> ""
        print "DynamicContentApi.brs - [GetDynamicContentData] Response received: " + response
        
        ' Extra logging for User Channels (contentTypeId = 14)
        if m.top.contentTypeId = 14
            print "=============================================="
            print "*** USER CHANNELS - RAW API RESPONSE ***"
            print "=============================================="
            print "Response length: " + response.Len().ToStr() + " characters"
            print ""
            print "---------- FULL RAW JSON FROM API ----------"
            print response
            print "=============================================="
        end if
        
        ' Parse and validate the response
        print "DynamicContentApi.brs - [GetDynamicContentData] Raw response: " + response
        parsedResponse = ParseJson(response)
        if parsedResponse <> invalid
            ' Extra logging for User Channels (contentTypeId = 14)
            if m.top.contentTypeId = 14
                print "DynamicContentApi.brs - [GetDynamicContentData] *** USER CHANNELS PARSED RESPONSE ***"
                print "DynamicContentApi.brs - [GetDynamicContentData] Parsed response type: " + Type(parsedResponse)
                
                ' Check if it's an associative array with keys
                keysInterface = GetInterface(parsedResponse, "ifAssociativeArray")
                if keysInterface <> invalid
                    print "DynamicContentApi.brs - [GetDynamicContentData] Parsed response keys:"
                    for each key in parsedResponse.Keys()
                        print "DynamicContentApi.brs - [GetDynamicContentData]   - " + key + ": " + Type(parsedResponse[key])
                    end for
                end if
                
                userChannelsData = parsedResponse["data"]
                if userChannelsData <> invalid
                    print "DynamicContentApi.brs - [GetDynamicContentData] User Channels data found!"
                    dataArrayInterface = GetInterface(userChannelsData, "ifArray")
                    if dataArrayInterface <> invalid
                        print "DynamicContentApi.brs - [GetDynamicContentData] User Channels data is array with " + userChannelsData.Count().ToStr() + " items"
                    else
                        print "DynamicContentApi.brs - [GetDynamicContentData] User Channels data is NOT an array, type: " + Type(userChannelsData)
                    end if
                else
                    print "DynamicContentApi.brs - [GetDynamicContentData] User Channels response has no 'data' field"
                end if
            end if
            
            ' Check if response has expected structure
            ' TV Guide (contentTypeId = 17) returns a direct array, not wrapped in "data"
            hasValidData = false
            responseDataField = invalid
            
            ' First check if response is a direct array (TV Guide format)
            directArrayInterface = GetInterface(parsedResponse, "ifArray")
            if directArrayInterface <> invalid
                print "DynamicContentApi.brs - [GetDynamicContentData] Response is a direct array (TV Guide format)"
                responseDataField = parsedResponse
                hasValidData = true
            else
                ' Standard format: { "data": [...] }
                responseDataField = parsedResponse["data"]
                if responseDataField <> invalid
                    dataInterface = GetInterface(responseDataField, "ifArray")
                    if dataInterface <> invalid
                        hasValidData = true
                    end if
                end if
            end if
            
            if hasValidData
                print "DynamicContentApi.brs - [GetDynamicContentData] Valid content data received with " + responseDataField.Count().ToStr() + " items"
                m.top.responseData = response
                
                ' For TV Guide and User Channels, wrap the array in a data structure for consistent handling
                if m.top.contentTypeId = 17
                    print "DynamicContentApi.brs - [GetDynamicContentData] TV Guide: Converting direct array to content items"
                    ' Convert TV Guide channels to content items format
                    tvGuideContentItems = convertTVGuideToContentItems(responseDataField)
                    m.top.contentItems = tvGuideContentItems
                else if m.top.contentTypeId = 14
                    print "DynamicContentApi.brs - [GetDynamicContentData] User Channels: Converting direct array to content items"
                    ' Convert User Channels to content items format (wrap in category)
                    userChannelsContentItems = convertUserChannelsToContentItems(responseDataField)
                    m.top.contentItems = userChannelsContentItems
                else
                    ' Parse content items using ContentItemHelper
                    ' The API returns categories with contents, not a flat list
                    m.top.contentItems = responseDataField
                end if
                
            else
                print "DynamicContentApi.brs - [GetDynamicContentData] WARNING: Unexpected response structure, but passing through: " + response
                ' Pass through the response anyway - let the UI handle it
                m.top.responseData = response
                
                ' Try to parse content items anyway
                ' Pass through the response for the UI to handle
                m.top.contentItems = []
            end if
        else
            print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: Failed to parse JSON response: " + response
            m.top.errorMessage = "Failed to parse content data"
            
            ' Check if API returned "disabled" for User Channels
            if m.top.contentTypeId = 14 and response = "disabled"
                print "DynamicContentApi.brs - [GetDynamicContentData] *** USER CHANNELS ENDPOINT IS DISABLED ***"
                print "DynamicContentApi.brs - [GetDynamicContentData] This means the user doesn't have access to User Channels"
            end if
            
            ' Only use defaults if we truly can't parse anything
            defaultResponse = getDefaultContentForType(m.top.contentTypeId)
            m.top.responseData = FormatJson(defaultResponse)
            
            ' Convert default data to category structure for User Channels
            if m.top.contentTypeId = 14
                print "DynamicContentApi.brs - [GetDynamicContentData] Converting User Channels default data to category structure"
                userChannelsContentItems = convertUserChannelsToContentItems(defaultResponse.data)
                m.top.contentItems = userChannelsContentItems
            else
                ' For other types, try to parse or use data directly
                m.top.contentItems = defaultResponse.data
            end if
        end if
    else
        print "DynamicContentApi.brs - [GetDynamicContentData] ERROR: Empty response from server"
        print "DynamicContentApi.brs - [GetDynamicContentData] URL that failed: " + url
        print "DynamicContentApi.brs - [GetDynamicContentData] ContentTypeId: " + m.top.contentTypeId.ToStr()
        
        if m.top.contentTypeId = 14
            print "DynamicContentApi.brs - [GetDynamicContentData] *** USER CHANNELS API RETURNED EMPTY - USING DEFAULT DATA ***"
        end if
        
        m.top.errorMessage = "No response from content API"
        
        ' Only use defaults if there's truly no response
        defaultResponse = getDefaultContentForType(m.top.contentTypeId)
        m.top.responseData = FormatJson(defaultResponse)
        
        ' Convert default data to category structure for User Channels
        if m.top.contentTypeId = 14
            print "DynamicContentApi.brs - [GetDynamicContentData] Converting User Channels default data to category structure"
            userChannelsContentItems = convertUserChannelsToContentItems(defaultResponse.data)
            m.top.contentItems = userChannelsContentItems
        else
            ' Parse default content items - convert to category structure
            m.top.contentItems = defaultResponse.data
        end if
        
        print "DynamicContentApi.brs - [GetDynamicContentData] Using default data with " + defaultResponse.data.Count().ToStr() + " items"
    end if
end sub

function getApiEndpointForContentType(contentTypeId as integer) as string
    ' Map content type IDs to API endpoints
    ' ACTUAL API IDs from navigation response:
    ' - Home: 13 → content/13/home
    ' - Live TV: 3 → content/3/home
    ' - Movies: 1 → content/1/home
    ' - Series: 2 → content/2/home
    ' - User Channels: 14 → content/14/home
    ' - Age Restricted: 15 → content/15/home (displays like Live TV)
    ' - Personal: 16 → content/16/home
    ' - TV Guide: 17 → tvguide (special endpoint for TV Guide data)
    
    endpoint = ""
    if contentTypeId = 13
        endpoint = "content/13/home" ' Home content (id=13)
    else if contentTypeId = 3
        endpoint = "content/3/home"  ' Live TV content (id=3)
    else if contentTypeId = 1
        endpoint = "content/1/home"  ' Movies content (id=1)
    else if contentTypeId = 2
        endpoint = "content/2/home"  ' Series/TV Shows content (id=2)
    else if contentTypeId = 14
        endpoint = "content/14/home"   ' User Channels (id=14)
    else if contentTypeId = 15
        endpoint = "content/15/home" ' Age Restricted Channels (id=15, displays like Live TV)
    else if contentTypeId = 16
        endpoint = "content/16/home" ' Personal content (id=16)
    else if contentTypeId = 17
        endpoint = "tvguide" ' TV Guide (id=17) - uses special tvguide endpoint
    else
        ' Fallback: try to use the contentTypeId directly
        endpoint = "content/" + contentTypeId.ToStr() + "/home"
    end if
    
    print "DynamicContentApi.brs - [getApiEndpointForContentType] *** API MAPPING ***"
    print "DynamicContentApi.brs - [getApiEndpointForContentType] ContentTypeId: " + contentTypeId.ToStr()
    print "DynamicContentApi.brs - [getApiEndpointForContentType] Endpoint: " + endpoint
    print "DynamicContentApi.brs - [getApiEndpointForContentType] Full URL: https://giatv.dineo.uk/api/" + endpoint
    return endpoint
end function

function getDefaultContentForType(contentTypeId as integer) as object
    ' Return default/sample content based on content type
    ' ACTUAL API IDs: 13=Home, 3=Live TV, 1=Movies, 2=Series, 14=User Channels, 15=Age Restricted, 16=Personal, 17=TV Guide
    
    if contentTypeId = 13 ' Home (id=13)
        return {
            "data": [
                {
                    "id": 13,
                    "title": "Welcome to GiaTV",
                    "description": "Discover amazing content on GiaTV",
                    "type": "featured",
                    "live": false,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": "",
                        "trailer": ""
                    },
                    "details": {
                        "productionYear": "2024",
                        "studio": "GiaTV"
                    }
                }
            ]
        }
    else if contentTypeId = 3 ' Live TV (id=3)
        return {
            "data": [
                {
                    "id": 3,
                    "title": "Live Channel 1",
                    "description": "Live streaming content",
                    "type": "live",
                    "live": true,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": ""
                    },
                    "details": {
                        "studio": "GiaTV Live"
                    }
                }
            ]
        }
    else if contentTypeId = 1 ' Movies (id=1)
        return {
            "data": [
                {
                    "id": 1,
                    "title": "Sample Movie",
                    "description": "A great movie to watch",
                    "type": "movie",
                    "live": false,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": "",
                        "trailer": ""
                    },
                    "details": {
                        "productionYear": "2024",
                        "studio": "GiaTV Movies"
                    }
                }
            ]
        }
    else if contentTypeId = 2 ' Series/TV Shows (id=2)
        return {
            "data": [
                {
                    "id": 2,
                    "title": "Sample TV Show",
                    "description": "An exciting TV series",
                    "type": "series",
                    "live": false,
                    "season": 1,
                    "episode": 1,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": "",
                        "trailer": ""
                    },
                    "details": {
                        "productionYear": "2024",
                        "studio": "GiaTV Series"
                    }
                }
            ]
        }
    else if contentTypeId = 14 ' User Channels (id=14)
        return {
            "data": [
                {
                    "id": 14,
                    "title": "Sample User Channel",
                    "description": "User Channels endpoint returned 'disabled'. This is sample fallback data.",
                    "type": "user_channel",
                    "live": true,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8",
                        "hls": "https://cph-p2p-msl.akamaized.net/hls/live/2000341/test/master.m3u8"
                    },
                    "details": {
                        "studio": "User Generated"
                    }
                }
            ]
        }
    else if contentTypeId = 15 ' Age Restricted Channels (id=15)
        return {
            "data": [
                {
                    "id": 15,
                    "title": "Age Restricted Channel",
                    "description": "Age restricted content",
                    "type": "live",
                    "live": true,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": ""
                    },
                    "details": {
                        "studio": "GiaTV Age Restricted"
                    }
                }
            ]
        }
    else if contentTypeId = 16 ' Personal (id=16)
        return {
            "data": [
                {
                    "id": 16,
                    "title": "Personal Content",
                    "description": "Your personal content",
                    "type": "personal",
                    "live": false,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": ""
                    },
                    "details": {
                        "studio": "Personal"
                    }
                }
            ]
        }
    else if contentTypeId = 17 ' TV Guide (id=17)
        return {
            "data": [
                {
                    "id": 17,
                    "title": "TV Guide",
                    "description": "Live TV channel guide",
                    "type": "tvguide",
                    "live": true,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": "",
                        "hls": ""
                    },
                    "details": {
                        "studio": "GiaTV"
                    }
                }
            ]
        }
    else
        ' Default content
        return {
            "data": [
                {
                    "id": 0,
                    "title": "GiaTV Content",
                    "description": "Default content placeholder",
                    "type": "default",
                    "live": false,
                    "images": {
                        "poster": "pkg:/images/png/default-logo.png",
                        "thumbnail": "pkg:/images/png/default-logo.png",
                        "banner": "pkg:/images/png/default-logo.png"
                    },
                    "sources": {
                        "primary": ""
                    },
                    "details": {
                        "studio": "GiaTV"
                    }
                }
            ]
        }
    end if
end function

function convertTVGuideToContentItems(tvGuideChannels as object) as object
    ' Convert TV Guide channels array to content items format
    ' TV Guide format: [{ id, name, icon, shows: [...], http, ... }, ...]
    ' Content format: [{ id, category, contents: [...] }]
    
    print "DynamicContentApi.brs - [convertTVGuideToContentItems] Converting " + tvGuideChannels.Count().ToStr() + " TV Guide channels"
    
    ' Create a single category with all channels as contents
    ' Note: Must use "category" field as that's what buildContentDisplay expects
    contentItems = [
        {
            "id": 17,
            "category": "Live Channels",
            "contents": []
        }
    ]
    
    channelContents = []
    for each channel in tvGuideChannels
        if channel <> invalid
            ' Get current show if available
            currentShowName = ""
            currentShowDescription = ""
            if channel.shows <> invalid
                showsInterface = GetInterface(channel.shows, "ifArray")
                if showsInterface <> invalid and channel.shows.Count() > 0
                    firstShow = channel.shows[0]
                    if firstShow <> invalid
                        if firstShow.name <> invalid then currentShowName = firstShow.name
                        if firstShow.longdescription <> invalid then currentShowDescription = firstShow.longdescription
                    end if
                end if
            end if
            
            ' Build channel icon URL
            channelIcon = ""
            if channel.icon <> invalid and channel.icon <> ""
                if Left(channel.icon, 4) = "http"
                    channelIcon = channel.icon
                else
                    channelIcon = "https://giatv.dineo.uk" + channel.icon
                end if
            end if
            
            ' Get stream URL
            streamUrl = ""
            if channel.http <> invalid and channel.http <> ""
                streamUrl = channel.http
            end if
            
            channelItem = {
                "id": channel.id,
                "title": channel.name,
                "description": currentShowDescription,
                "subtitle": currentShowName,
                "type": "live",
                "live": true,
                "images": {
                    "poster": channelIcon,
                    "thumbnail": channelIcon,
                    "banner": channelIcon
                },
                "sources": {
                    "primary": streamUrl,
                    "hls": streamUrl
                },
                "details": {
                    "studio": channel.name,
                    "language": channel.language
                },
                "shows": channel.shows
            }
            channelContents.Push(channelItem)
        end if
    end for
    
    contentItems[0].contents = channelContents
    print "DynamicContentApi.brs - [convertTVGuideToContentItems] Created " + channelContents.Count().ToStr() + " channel items"
    
    return contentItems
end function

function convertUserChannelsToContentItems(userChannelItems as object) as object
    ' Convert User Channels array to content items format
    ' User Channels format: [{ id, title, description, images, sources, ... }, ...]
    ' Content format: [{ id, category, contents: [...] }]
    
    print "DynamicContentApi.brs - [convertUserChannelsToContentItems] Converting " + userChannelItems.Count().ToStr() + " User Channel items"
    
    ' Create a single category with all channels as contents
    ' Note: Must use "category" field as that's what buildContentDisplay expects
    contentItems = [
        {
            "id": 14,
            "category": "User Channels",
            "contents": []
        }
    ]
    
    channelContents = []
    for each channel in userChannelItems
        if channel <> invalid
            ' User Channels items already have the correct structure from the API
            ' Just ensure they have all required fields
            channelItem = {
                "id": channel.id,
                "title": channel.title,
                "description": channel.description,
                "type": channel.type,
                "live": channel.live,
                "images": channel.images,
                "sources": channel.sources,
                "details": channel.details
            }
            
            ' Add optional fields if they exist
            if channel.subtitle <> invalid then channelItem.subtitle = channel.subtitle
            if channel.episode <> invalid then channelItem.episode = channel.episode
            if channel.season <> invalid then channelItem.season = channel.season
            
            channelContents.Push(channelItem)
        end if
    end for
    
    contentItems[0].contents = channelContents
    print "DynamicContentApi.brs - [convertUserChannelsToContentItems] Created " + channelContents.Count().ToStr() + " channel items in category structure"
    
    return contentItems
end function

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function
