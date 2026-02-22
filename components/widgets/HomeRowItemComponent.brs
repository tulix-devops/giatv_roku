sub init()
    ' Portrait layout elements
    m.portraitLayout = m.top.findNode("portraitLayout")
    m.portraitPoster = m.top.findNode("portraitPoster")
    m.portraitTitle = m.top.findNode("portraitTitle")
    m.portraitLiveBadge = m.top.findNode("portraitLiveBadge")
    
    ' Landscape layout elements
    m.landscapeLayout = m.top.findNode("landscapeLayout")
    m.landscapePoster = m.top.findNode("landscapePoster")
    m.landscapeTitle = m.top.findNode("landscapeTitle")
    m.landscapeLiveBadge = m.top.findNode("landscapeLiveBadge")
    
    ' Track current layout
    m.currentLayout = "portrait"
end sub

sub OnContentSet()
    content = m.top.itemContent
    if content = invalid
        return
    end if
    
    ' Determine layout type from content
    layoutType = "portrait"  ' Default to portrait
    if content.hasField("layoutType") and content.layoutType <> invalid
        layoutType = content.layoutType
    end if
    
    ' Switch layout based on type
    if layoutType = "landscape"
        showLandscapeLayout(content)
    else
        showPortraitLayout(content)
    end if
end sub

sub showPortraitLayout(content as object)
    m.currentLayout = "portrait"
    m.portraitLayout.visible = true
    m.landscapeLayout.visible = false
    
    ' Set poster
    posterUrl = getPosterUrl(content)
    m.portraitPoster.uri = posterUrl
    
    ' Set title
    m.portraitTitle.text = getTitle(content)
    
    ' Show/hide Live badge
    isLive = checkIsLive(content)
    if m.portraitLiveBadge <> invalid
        m.portraitLiveBadge.visible = isLive
    end if
end sub

sub showLandscapeLayout(content as object)
    m.currentLayout = "landscape"
    m.portraitLayout.visible = false
    m.landscapeLayout.visible = true
    
    ' Set poster
    posterUrl = getPosterUrl(content)
    m.landscapePoster.uri = posterUrl
    
    ' Set title
    m.landscapeTitle.text = getTitle(content)
    
    ' Show/hide Live badge
    isLive = checkIsLive(content)
    if m.landscapeLiveBadge <> invalid
        m.landscapeLiveBadge.visible = isLive
    end if
end sub

function checkIsLive(content as object) as boolean
    if content.live <> invalid and content.live = true
        return true
    else if content.isLive <> invalid and content.isLive = true
        return true
    end if
    return false
end function

function getPosterUrl(content as object) as string
    posterUrl = ""
    
    if content.posterUrl <> invalid and content.posterUrl <> ""
        posterUrl = content.posterUrl
    else if content.HDPosterUrl <> invalid and content.HDPosterUrl <> ""
        posterUrl = content.HDPosterUrl
    else if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        posterUrl = content.hdPosterUrl
    else if content.thumbnail <> invalid and content.thumbnail <> ""
        posterUrl = content.thumbnail
    end if
    
    ' If no URL found, use appropriate placeholder based on layout
    if posterUrl = ""
        if m.currentLayout = "landscape"
            posterUrl = "pkg:/images/png/poster_not_found_350x245.png"
        else
            posterUrl = "pkg:/images/png/poster_not_found_220x375.png"
        end if
    end if
    
    return posterUrl
end function

function getTitle(content as object) as string
    titleText = ""
    
    if content.title <> invalid and content.title <> ""
        titleText = content.title
    else if content.name <> invalid and content.name <> ""
        titleText = content.name
    end if
    
    return titleText
end function

sub onFocusChanged()
    focusPercent = m.top.focusPercent
    
    ' Change title color based on focus
    if focusPercent > 0.5
        if m.currentLayout = "portrait"
            m.portraitTitle.color = "0xFFFFFFFF"
        else
            m.landscapeTitle.color = "0xFFFFFFFF"
        end if
    else
        if m.currentLayout = "portrait"
            m.portraitTitle.color = "0xCCCCCCFF"
        else
            m.landscapeTitle.color = "0xCCCCCCFF"
        end if
    end if
end sub