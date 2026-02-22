' Content Item Helper - Roku equivalent of Flutter content models
' Based on ContentItemModel, ContentItemDetailsModel, ContentItemImagesModel, ContentItemSourceModel

' Default image URL for missing posters
function getDefaultImageUrl() as string
    return "https://wchupload.tulix.net/storage/etc/no-poster-found.png"
end function

' Parse content item from JSON response
function parseContentItem(jsonItem as object) as object
    if jsonItem = invalid
        return invalid
    end if
    
    contentItem = {
        id: parseIntSafely(jsonItem.id, 0),
        parentId: parseIntSafely(jsonItem.parentId, invalid),
        typeId: parseIntSafely(jsonItem.typeId, invalid),
        type: getStringValue(jsonItem.type, ""),
        statusId: parseIntSafely(jsonItem.statusId, invalid),
        productId: parseIntSafely(jsonItem.productId, invalid),
        countryId: parseIntSafely(jsonItem.countryId, invalid),
        season: parseIntSafely(jsonItem.season, invalid),
        episode: parseIntSafely(jsonItem.episode, invalid),
        title: getStringValue(jsonItem.title, ""),
        description: getStringValue(jsonItem.description, ""),
        live: getBooleanValue(jsonItem.live, false),
        details: parseContentItemDetails(jsonItem.details),
        seo: parseContentItemSeo(jsonItem.seo),
        images: parseContentItemImages(jsonItem.images),
        sources: parseContentItemSources(jsonItem.sources),
        seasons: parseContentSeasons(jsonItem.seasons)
    }
    
    return contentItem
end function

' Parse content item details
function parseContentItemDetails(detailsJson as object) as object
    if detailsJson = invalid
        detailsJson = {}
    end if
    
    details = {
        id: parseIntSafely(detailsJson.id, invalid),
        tagline: getStringValue(detailsJson.tagline, invalid),
        copyright: getStringValue(detailsJson.copyright, invalid),
        studio: getStringValue(detailsJson.studio, invalid),
        sku: getStringValue(detailsJson.sku, invalid),
        imdbId: getStringValue(detailsJson.imdbId, invalid),
        productionYear: getStringValue(detailsJson.productionYear, invalid),
        language: getStringValue(detailsJson.language, invalid)
    }
    
    return details
end function

' Parse content item SEO
function parseContentItemSeo(seoJson as object) as object
    if seoJson = invalid
        seoJson = {}
    end if
    
    seo = {
        id: parseIntSafely(seoJson.id, invalid),
        title: getStringValue(seoJson.title, invalid),
        description: getStringValue(seoJson.description, invalid),
        keywords: getStringValue(seoJson.keywords, invalid)
    }
    
    return seo
end function

' Parse content item images
function parseContentItemImages(imagesJson as object) as object
    if imagesJson = invalid
        imagesJson = {}
    end if
    
    images = {
        id: parseIntSafely(imagesJson.id, invalid),
        poster: getStringValue(imagesJson.poster, invalid),
        thumbnail: getStringValue(imagesJson.thumbnail, invalid),
        banner: getStringValue(imagesJson.banner, invalid)
    }
    
    return images
end function

' Parse content item sources
function parseContentItemSources(sourcesJson as object) as object
    if sourcesJson = invalid
        sourcesJson = {}
    end if
    
    sources = {
        id: parseIntSafely(sourcesJson.id, invalid),
        primary: getStringValue(sourcesJson.primary, invalid),
        secondary: getStringValue(sourcesJson.secondary, invalid),
        hls: getStringValue(sourcesJson.hls, invalid),
        trailer: getStringValue(sourcesJson.trailer, invalid),
        dash: getStringValue(sourcesJson.dash, invalid),
        file: getStringValue(sourcesJson.file, invalid)
    }
    
    return sources
end function

' Parse content seasons
function parseContentSeasons(seasonsJson as object) as object
    if seasonsJson = invalid
        return invalid
    end if
    
    seasons = {
        id: parseIntSafely(seasonsJson.id, invalid),
        seasons: []
    }
    
    if seasonsJson.seasons <> invalid and GetInterface(seasonsJson.seasons, "ifArray") <> invalid
        seasons.seasons = seasonsJson.seasons
    end if
    
    return seasons
end function

' Get poster image with fallback priority
function getContentItemPoster(images as object) as string
    if images = invalid
        return getDefaultImageUrl()
    end if
    
    imagePriority = [images.poster, images.thumbnail, images.banner]
    return getImageByPriority(imagePriority)
end function

' Get banner image with fallback priority
function getContentItemBanner(images as object) as string
    if images = invalid
        return getDefaultImageUrl()
    end if
    
    imagePriority = [images.banner, images.poster, images.thumbnail]
    return getImageByPriority(imagePriority)
end function

' Get thumbnail image with fallback priority
function getContentItemThumbnail(images as object) as string
    if images = invalid
        return getDefaultImageUrl()
    end if
    
    imagePriority = [images.thumbnail, images.poster, images.banner]
    return getImageByPriority(imagePriority)
end function

' Get image by priority order
function getImageByPriority(imagePriority as object) as string
    for each imageUrl in imagePriority
        if isValidImageUrl(imageUrl)
            return imageUrl
        end if
    end for
    
    return getDefaultImageUrl()
end function

' Check if image URL is valid
function isValidImageUrl(url as dynamic) as boolean
    if url = invalid or GetInterface(url, "ifString") = invalid
        return false
    end if
    
    urlString = url.ToStr()
    if urlString = "" or urlString = invalid
        return false
    end if
    
    return urlString.Instr("https") = 0 or urlString.Instr("http") = 0
end function

' Get preferred video source
function getPreferredVideoSource(sources as object) as string
    if sources = invalid
        return ""
    end if
    
    sourcePriority = [sources.primary, sources.secondary, sources.file, sources.hls, sources.dash]
    
    for each sourceUrl in sourcePriority
        if isValidVideoUrl(sourceUrl)
            return sourceUrl
        end if
    end for
    
    return ""
end function

' Check if video URL is valid
function isValidVideoUrl(url as dynamic) as boolean
    if url = invalid or GetInterface(url, "ifString") = invalid
        return false
    end if
    
    urlString = url.ToStr()
    if urlString = "" or urlString = invalid
        return false
    end if
    
    return urlString.Instr("http") = 0
end function

' Parse content item list from API response
function parseContentItemList(responseData as string) as object
    if responseData = invalid or responseData = ""
        return {items: []}
    end if
    
    parsedResponse = ParseJson(responseData)
    if parsedResponse = invalid or parsedResponse.data = invalid
        return {items: []}
    end if
    
    contentItems = []
    
    if GetInterface(parsedResponse.data, "ifArray") <> invalid
        for each itemJson in parsedResponse.data
            contentItem = parseContentItem(itemJson)
            if contentItem <> invalid
                contentItems.Push(contentItem)
            end if
        end for
    end if
    
    return {items: contentItems}
end function

' Helper function to safely parse integers
function parseIntSafely(value as dynamic, defaultValue as dynamic) as dynamic
    if value = invalid
        return defaultValue
    end if
    
    if GetInterface(value, "ifInt") <> invalid
        return value
    end if
    
    if GetInterface(value, "ifString") <> invalid
        ' BrightScript doesn't have try/catch, so we'll use a simple conversion
        intValue = value.ToInt()
        if intValue <> invalid
            return intValue
        else
            print "ContentItemHelper.brs - [parseIntSafely] Warning: Could not parse '" + value + "' as int"
            return defaultValue
        end if
    end if
    
    return defaultValue
end function

' Helper function to safely get string values
function getStringValue(value as dynamic, defaultValue as dynamic) as dynamic
    if value = invalid
        return defaultValue
    end if
    
    if GetInterface(value, "ifString") <> invalid
        return value
    end if
    
    return defaultValue
end function

' Helper function to safely get boolean values
function getBooleanValue(value as dynamic, defaultValue as boolean) as boolean
    if value = invalid
        return defaultValue
    end if
    
    if GetInterface(value, "ifBoolean") <> invalid
        return value
    end if
    
    if GetInterface(value, "ifString") <> invalid
        valueStr = value.ToStr().ToLower()
        if valueStr = "true" or valueStr = "1"
            return true
        else if valueStr = "false" or valueStr = "0"
            return false
        end if
    end if
    
    if GetInterface(value, "ifInt") <> invalid
        return value <> 0
    end if
    
    return defaultValue
end function

' Create content node for Roku components
function createContentNode(contentItem as object) as object
    if contentItem = invalid
        return invalid
    end if
    
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Set basic properties
    contentNode.title = contentItem.title
    contentNode.description = contentItem.description
    contentNode.id = contentItem.id.ToStr()
    
    ' Set images
    if contentItem.images <> invalid
        contentNode.hdPosterUrl = getContentItemPoster(contentItem.images)
        contentNode.sdPosterUrl = getContentItemThumbnail(contentItem.images)
        contentNode.hdBackgroundImageUrl = getContentItemBanner(contentItem.images)
    end if
    
    ' Set video source
    if contentItem.sources <> invalid
        videoUrl = getPreferredVideoSource(contentItem.sources)
        if videoUrl <> ""
            contentNode.url = videoUrl
        end if
        
        ' Set trailer if available
        if contentItem.sources.trailer <> invalid and isValidVideoUrl(contentItem.sources.trailer)
            contentNode.trailerUrl = contentItem.sources.trailer
        end if
    end if
    
    ' Set additional metadata
    if contentItem.details <> invalid
        if contentItem.details.productionYear <> invalid
            contentNode.releaseDate = contentItem.details.productionYear
        end if
        if contentItem.details.studio <> invalid
            contentNode.studio = contentItem.details.studio
        end if
    end if
    
    ' Set content type
    contentNode.contentType = contentItem.type
    
    ' Set live flag
    contentNode.live = contentItem.live
    
    ' Store original content item data
    contentNode.addField("contentItemData", "assocarray", false)
    contentNode.contentItemData = contentItem
    
    return contentNode
end function
