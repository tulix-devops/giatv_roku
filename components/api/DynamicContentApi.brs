sub init()
    m.top.functionName = "GetDynamicContentData"
end sub

sub GetDynamicContentData()
    contentTypeId = m.top.contentTypeId
    
    ' OPTIMIZATION: Check cache first (valid for 10 minutes)
    ' Use contentTypeId + page number for cache key
    pageNum = 1
    if contentTypeId = 14 and m.top.pageNumber <> invalid
        pageNum = m.top.pageNumber
        if pageNum < 1 then pageNum = 1
    end if
    cacheKey = "content_" + contentTypeId.ToStr() + "_page_" + pageNum.ToStr()
    cachedContent = readCache(cacheKey, 600) ' 10 minutes = 600 seconds
    
    if cachedContent <> invalid
        print "DynamicContentApi.brs - [GetDynamicContentData] *** USING CACHED CONTENT (type " + contentTypeId.ToStr() + ", page " + pageNum.ToStr() + ") ***"
        parsedCache = ParseJson(cachedContent)
        if parsedCache <> invalid
            m.top.responseData = cachedContent
            if contentTypeId = 14
                processResponseWithPagination(cachedContent, contentTypeId)
            else
                processResponse(cachedContent, contentTypeId)
            end if
            ' Still fetch fresh data in background to update cache
            print "DynamicContentApi.brs - [GetDynamicContentData] Fetching fresh data in background to update cache"
        end if
    else
        print "DynamicContentApi.brs - [GetDynamicContentData] No valid cache for type " + contentTypeId.ToStr() + ", fetching from API"
    end if
    
    ' Get access token from registry
    authDataJson = RegRead("authData", "AUTH")
    accessToken = ""
    
    if authDataJson <> invalid and authDataJson <> ""
        authData = ParseJson(authDataJson)
        if authData <> invalid
            if authData.accessToken <> invalid
                accessToken = authData.accessToken
            else if authData.accesstoken <> invalid
                accessToken = authData.accesstoken
            end if
        end if
    end if
    
    ' Determine API endpoint based on content type
    apiEndpoint = getApiEndpointForContentType(contentTypeId)
    
    if apiEndpoint = ""
        defaultResponse = getDefaultContentForType(contentTypeId)
        m.top.responseData = FormatJson(defaultResponse)
        m.top.contentItems = defaultResponse.data
        return
    end if

    url = "https://giatv.dineo.uk/api/" + apiEndpoint
    
    ' Add pagination for User Channels (contentTypeId = 14)
    ' OPTIMIZATION: Only load page 1 at startup, load more on demand
    if contentTypeId = 14
        pageNum = m.top.pageNumber
        if pageNum < 1 then pageNum = 1
        url = url + "?page=" + pageNum.ToStr()
        print "DynamicContentApi.brs - [GetDynamicContentData] User Channels URL with pagination: " + url
        print "DynamicContentApi.brs - [GetDynamicContentData] OPTIMIZATION: Loading page " + pageNum.ToStr() + " only"
    end if
    
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.EnablePeerVerification(false)
    request.EnableHostVerification(false)
    
    if accessToken <> ""
        request.AddHeader("Authorization", "Bearer " + accessToken)
    end if
    
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    
    ' OPTIMIZATION: Changed User Channels to ASYNC for better performance
    ' All content types now use async for non-blocking parallel loading
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    
    if request.AsyncGetToString()
        msg = wait(10000, port)
        if msg <> invalid and type(msg) = "roUrlEvent"
            responseCode = msg.GetResponseCode()
            response = msg.GetString()
            
            if responseCode >= 200 and responseCode < 300 and response <> ""
                ' User Channels uses special pagination handler
                if contentTypeId = 14
                    processResponseWithPagination(response, contentTypeId)
                else
                    processResponse(response, contentTypeId)
                end if
            else
                useDefaultContent(contentTypeId)
            end if
        else
            useDefaultContent(contentTypeId)
        end if
    else
        useDefaultContent(contentTypeId)
    end if
end sub

sub processResponseWithPagination(response as string, contentTypeId as integer)
    ' Special handler for paginated responses (User Channels)
    print "DynamicContentApi.brs - [processResponseWithPagination] Processing paginated response"
    
    parsedResponse = ParseJson(response)
    if parsedResponse = invalid
        print "DynamicContentApi.brs - [processResponseWithPagination] Failed to parse response"
        useDefaultContent(contentTypeId)
        return
    end if
    
    ' Extract pagination metadata from "meta" field
    ' API format: { "data": [...], "meta": { "currentPage": 1, "lastPage": 16, "total": 787 } }
    if parsedResponse.meta <> invalid
        if parsedResponse.meta.lastPage <> invalid
            m.top.totalPages = parsedResponse.meta.lastPage
            print "DynamicContentApi.brs - [processResponseWithPagination] Total pages: " + m.top.totalPages.ToStr()
        end if
        if parsedResponse.meta.total <> invalid
            m.top.totalItems = parsedResponse.meta.total
            print "DynamicContentApi.brs - [processResponseWithPagination] Total items: " + m.top.totalItems.ToStr()
        end if
        if parsedResponse.meta.currentPage <> invalid
            print "DynamicContentApi.brs - [processResponseWithPagination] Current page: " + parsedResponse.meta.currentPage.ToStr()
        end if
    end if
    
    ' Extract data
    responseDataField = parsedResponse["data"]
    if responseDataField <> invalid
        dataInterface = GetInterface(responseDataField, "ifArray")
        if dataInterface <> invalid
            print "DynamicContentApi.brs - [processResponseWithPagination] Found " + responseDataField.Count().ToStr() + " items on this page"
            m.top.responseData = response
            
            ' OPTIMIZATION: Cache the response
            pageNum = m.top.pageNumber
            if pageNum < 1 then pageNum = 1
            cacheKey = "content_" + contentTypeId.ToStr() + "_page_" + pageNum.ToStr()
            writeCache(cacheKey, response)
            print "DynamicContentApi.brs - [processResponseWithPagination] *** CACHED CONTENT (type " + contentTypeId.ToStr() + ", page " + pageNum.ToStr() + ") ***"
            
            userChannelsContentItems = convertUserChannelsToContentItems(responseDataField)
            m.top.contentItems = userChannelsContentItems
            return
        end if
    end if
    
    print "DynamicContentApi.brs - [processResponseWithPagination] No valid data found"
    m.top.responseData = response
    m.top.contentItems = []
end sub

sub processResponse(response as string, contentTypeId as integer)
    parsedResponse = ParseJson(response)
    if parsedResponse = invalid
        useDefaultContent(contentTypeId)
        return
    end if

    hasValidData = false
    responseDataField = invalid

    ' Check if response is a direct array (TV Guide format)
    directArrayInterface = GetInterface(parsedResponse, "ifArray")
    if directArrayInterface <> invalid
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
        m.top.responseData = response
        
        ' OPTIMIZATION: Cache the response
        cacheKey = "content_" + contentTypeId.ToStr() + "_page_1"
        writeCache(cacheKey, response)
        print "DynamicContentApi.brs - [processResponse] *** CACHED CONTENT (type " + contentTypeId.ToStr() + ") ***"

        if contentTypeId = 17
            tvGuideContentItems = convertTVGuideToContentItems(responseDataField)
            m.top.contentItems = tvGuideContentItems
        else if contentTypeId = 14
            userChannelsContentItems = convertUserChannelsToContentItems(responseDataField)
            m.top.contentItems = userChannelsContentItems
        else
            m.top.contentItems = responseDataField
        end if
    else
        m.top.responseData = response
        m.top.contentItems = []
    end if
end sub

sub useDefaultContent(contentTypeId as integer)
    defaultResponse = getDefaultContentForType(contentTypeId)
    m.top.responseData = FormatJson(defaultResponse)
    
    if contentTypeId = 14
        userChannelsContentItems = convertUserChannelsToContentItems(defaultResponse.data)
        m.top.contentItems = userChannelsContentItems
    else
        m.top.contentItems = defaultResponse.data
    end if
end sub

function getApiEndpointForContentType(contentTypeId as integer) as string
    endpoint = ""
    if contentTypeId = 13
        endpoint = "content/13/home"
    else if contentTypeId = 3
        endpoint = "content/3/home"
    else if contentTypeId = 1
        endpoint = "content/1/home"
    else if contentTypeId = 2
        endpoint = "content/2/home"
    else if contentTypeId = 14
        endpoint = "content/14/list"
    else if contentTypeId = 15
        endpoint = "content/15/home"
    else if contentTypeId = 16
        endpoint = "content/16/home"
    else if contentTypeId = 17
        endpoint = "tvguide"
    else
        endpoint = "content/" + contentTypeId.ToStr() + "/home"
    end if
    
    return endpoint
end function

function getDefaultContentForType(contentTypeId as integer) as object
    if contentTypeId = 13
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
                    "sources": { "primary": "", "hls": "", "trailer": "" },
                    "details": { "productionYear": "2024", "studio": "GiaTV" }
                }
            ]
        }
    else if contentTypeId = 3
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
                    "sources": { "primary": "", "hls": "" },
                    "details": { "studio": "GiaTV Live" }
                }
            ]
        }
    else if contentTypeId = 1
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
                    "sources": { "primary": "", "hls": "", "trailer": "" },
                    "details": { "productionYear": "2024", "studio": "GiaTV Movies" }
                }
            ]
        }
    else if contentTypeId = 2
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
                    "sources": { "primary": "", "hls": "", "trailer": "" },
                    "details": { "productionYear": "2024", "studio": "GiaTV Series" }
                }
            ]
        }
    else if contentTypeId = 14
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
                    "details": { "studio": "User Generated" }
                }
            ]
        }
    else if contentTypeId = 15
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
                    "sources": { "primary": "", "hls": "" },
                    "details": { "studio": "GiaTV Age Restricted" }
                }
            ]
        }
    else if contentTypeId = 16
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
                    "sources": { "primary": "", "hls": "" },
                    "details": { "studio": "Personal" }
                }
            ]
        }
    else if contentTypeId = 17
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
                    "sources": { "primary": "", "hls": "" },
                    "details": { "studio": "GiaTV" }
                }
            ]
        }
    else
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
                    "sources": { "primary": "" },
                    "details": { "studio": "GiaTV" }
                }
            ]
        }
    end if
end function

function convertTVGuideToContentItems(tvGuideChannels as object) as object
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
            currentShowName = ""
            currentShowDescription = ""
            if channel.shows <> invalid
                showsInterface = GetInterface(channel.shows, "ifArray")
                if showsInterface <> invalid and channel.shows.Count() > 0
                    currentDateTime = CreateObject("roDateTime")
                    currentDateTime.ToLocalTime()
                    currentHour = currentDateTime.GetHours()
                    currentMinute = currentDateTime.GetMinutes()
                    currentTotalMinutes = currentHour * 60 + currentMinute
                    
                    currentShow = invalid
                    for each show in channel.shows
                        if show <> invalid and show.start <> invalid and show.end <> invalid
                            startParts = show.start.Split(":")
                            if startParts.Count() >= 2
                                showStartHour = Val(startParts[0])
                                showStartMinute = Val(startParts[1])
                                showStartTotal = showStartHour * 60 + showStartMinute
                                
                                endParts = show.end.Split(":")
                                if endParts.Count() >= 2
                                    showEndHour = Val(endParts[0])
                                    showEndMinute = Val(endParts[1])
                                    showEndTotal = showEndHour * 60 + showEndMinute
                                    
                                    if showEndTotal < showStartTotal
                                        showEndTotal = showEndTotal + 1440
                                    end if
                                    
                                    if currentTotalMinutes >= showStartTotal and currentTotalMinutes < showEndTotal
                                        currentShow = show
                                        exit for
                                    end if
                                end if
                            end if
                        end if
                    end for
                    
                    if currentShow <> invalid
                        if currentShow.name <> invalid then currentShowName = currentShow.name
                        if currentShow.longdescription <> invalid then currentShowDescription = currentShow.longdescription
                    else if channel.shows.Count() > 0
                        firstShow = channel.shows[0]
                        if firstShow <> invalid
                            if firstShow.name <> invalid then currentShowName = firstShow.name
                            if firstShow.longdescription <> invalid then currentShowDescription = firstShow.longdescription
                        end if
                    end if
                end if
            end if
            
            channelIcon = ""
            if channel.icon <> invalid and channel.icon <> ""
                if Left(channel.icon, 4) = "http"
                    channelIcon = channel.icon
                else
                    channelIcon = "https://giatv.dineo.uk" + channel.icon
                end if
            end if
            
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
    return contentItems
end function

function convertUserChannelsToContentItems(userChannelItems as object) as object
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
            
            if channel.typeId <> invalid then channelItem.typeId = channel.typeId
            if channel.subtitle <> invalid then channelItem.subtitle = channel.subtitle
            if channel.episode <> invalid then channelItem.episode = channel.episode
            if channel.season <> invalid then channelItem.season = channel.season
            if channel.dvr_url <> invalid then channelItem.dvr_url = channel.dvr_url
            if channel.seo <> invalid then channelItem.seo = channel.seo
            
            channelContents.Push(channelItem)
        end if
    end for
    
    contentItems[0].contents = channelContents
    return contentItems
end function

function RegRead(key, section = invalid)
    if section = invalid then section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) then return sec.Read(key)
    return invalid
end function

' ==================== CACHE UTILITIES ====================

function readCache(cacheKey as string, maxAge as integer) as dynamic
    ' Read cached data if it exists and is not expired
    ' maxAge is in seconds (e.g., 600 = 10 minutes)
    
    section = "CACHE"
    sec = CreateObject("roRegistrySection", section)
    
    ' Check if cache exists
    if not sec.Exists(cacheKey) then return invalid
    if not sec.Exists(cacheKey + "_timestamp") then return invalid
    
    ' Read cache data and timestamp
    cacheData = sec.Read(cacheKey)
    timestampStr = sec.Read(cacheKey + "_timestamp")
    
    if cacheData = invalid or timestampStr = invalid then return invalid
    
    ' Check if cache is still valid
    currentTime = CreateObject("roDateTime").AsSeconds()
    cacheTime = timestampStr.ToInt()
    age = currentTime - cacheTime
    
    if age > maxAge
        print "Cache expired for '" + cacheKey + "' (age: " + age.ToStr() + "s, max: " + maxAge.ToStr() + "s)"
        return invalid
    end if
    
    print "Cache hit for '" + cacheKey + "' (age: " + age.ToStr() + "s)"
    return cacheData
end function

sub writeCache(cacheKey as string, data as string)
    ' Write data to cache with current timestamp
    section = "CACHE"
    sec = CreateObject("roRegistrySection", section)
    
    ' Store data
    sec.Write(cacheKey, data)
    
    ' Store timestamp
    currentTime = CreateObject("roDateTime").AsSeconds()
    sec.Write(cacheKey + "_timestamp", currentTime.ToStr())
    
    ' Flush to disk
    sec.Flush()
    
    print "Cached '" + cacheKey + "' at " + currentTime.ToStr()
end sub

sub clearCache(cacheKey = invalid as dynamic)
    ' Clear specific cache key or all cache if cacheKey is invalid
    section = "CACHE"
    sec = CreateObject("roRegistrySection", section)
    
    if cacheKey <> invalid
        ' Clear specific cache
        sec.Delete(cacheKey)
        sec.Delete(cacheKey + "_timestamp")
        print "Cleared cache for: " + cacheKey
    else
        ' Clear all cache
        sec.Delete()
        print "Cleared all cache"
    end if
    
    sec.Flush()
end sub
