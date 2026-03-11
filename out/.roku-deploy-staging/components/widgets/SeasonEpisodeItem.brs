sub init()
    m.episodePoster = m.top.findNode("episodePoster")
    m.episodeTitle = m.top.findNode("episodeTitle")
    m.playIcon = m.top.findNode("playIcon")
    m.focusBorder = m.top.findNode("focusBorder")
end sub

sub OnContentSet()
    content = m.top.itemContent
    
    if content <> invalid
        print "SeasonEpisodeItem.brs - [OnContentSet] Setting content"
        
        ' Set episode poster
        posterUrl = ""
        if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
            posterUrl = content.hdPosterUrl
        else if content.images <> invalid
            if content.images.thumbnail <> invalid and content.images.thumbnail <> ""
                posterUrl = encodeUrl(content.images.thumbnail)
            else if content.images.poster <> invalid and content.images.poster <> ""
                posterUrl = encodeUrl(content.images.poster)
            end if
        else if content.thumbnail <> invalid and content.thumbnail <> ""
            posterUrl = encodeUrl(content.thumbnail)
        end if
        
        if posterUrl <> ""
            m.episodePoster.uri = posterUrl
        else
            m.episodePoster.uri = "pkg:/images/png/poster_not_found_350x245.png"
        end if
        
        ' Set episode title
        episodeText = ""
        
        ' Try to get title from various sources
        if content.title <> invalid and content.title <> ""
            episodeText = content.title
        else if content.data <> invalid and content.data.title <> invalid
            episodeText = content.data.title
        end if
        
        ' Add episode number if available
        if content.data <> invalid and content.data.episode <> invalid
            episodeNum = content.data.episode.ToStr()
            if episodeText = "" or episodeText = content.data.title
                episodeText = "Episode " + episodeNum
            end if
        end if
        
        ' Truncate long titles
        if Len(episodeText) > 40
            episodeText = Left(episodeText, 37) + "..."
        end if
        
        m.episodeTitle.text = episodeText
    end if
end sub

sub showFocus()
    focusPercent = m.top.focusPercent
    
    if focusPercent > 0.5
        ' Show play icon when focused
        m.playIcon.opacity = 1.0
    else
        ' Hide play icon when not focused
        m.playIcon.opacity = 0.0
    end if
end sub

function encodeUrl(url as string) as string
    if url = invalid then return ""
    url = url.Replace(" ", "%20")
    return url
end function