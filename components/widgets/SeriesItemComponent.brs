sub init()
    m.posterImage = m.top.findNode("posterImage")
    m.titleLabel = m.top.findNode("titleLabel")
    m.liveBadge = m.top.findNode("liveBadge")
    m.itemContainer = m.top.findNode("itemContainer")
end sub

sub OnContentSet()
    itemContent = m.top.itemContent
    
    if itemContent = invalid
        return
    end if
    
    ' Set poster image
    posterUrl = ""
    
    ' Try different image fields
    if itemContent.hdPosterUrl <> invalid and itemContent.hdPosterUrl <> ""
        posterUrl = itemContent.hdPosterUrl
    else if itemContent.sdPosterUrl <> invalid and itemContent.sdPosterUrl <> ""
        posterUrl = itemContent.sdPosterUrl
    else if itemContent.posterUrl <> invalid and itemContent.posterUrl <> ""
        posterUrl = itemContent.posterUrl
    end if
    
    ' Check nested images object
    if posterUrl = "" and itemContent.images <> invalid
        if itemContent.images.thumbnail <> invalid and itemContent.images.thumbnail <> ""
            posterUrl = itemContent.images.thumbnail
        else if itemContent.images.poster <> invalid and itemContent.images.poster <> ""
            posterUrl = itemContent.images.poster
        else if itemContent.images.backdrop <> invalid and itemContent.images.backdrop <> ""
            posterUrl = itemContent.images.backdrop
        end if
    end if
    
    ' Fallback to thumbnail field
    if posterUrl = "" and itemContent.thumbnail <> invalid and itemContent.thumbnail <> ""
        posterUrl = itemContent.thumbnail
    end if
    
    if posterUrl <> ""
        m.posterImage.uri = posterUrl
    else
        ' Use landscape placeholder for Series/Live content
        m.posterImage.uri = "pkg:/images/png/poster_not_found_350x245.png"
    end if
    
    ' Set title
    title = ""
    if itemContent.title <> invalid and itemContent.title <> ""
        title = itemContent.title
    else if itemContent.name <> invalid and itemContent.name <> ""
        title = itemContent.name
    end if
    
    m.titleLabel.text = title
    
    ' Show/hide Live badge
    isLive = false
    if itemContent.live <> invalid and itemContent.live = true
        isLive = true
    else if itemContent.isLive <> invalid and itemContent.isLive = true
        isLive = true
    end if
    
    if m.liveBadge <> invalid
        m.liveBadge.visible = isLive
    end if
end sub

sub showFocus()
    focusPercent = m.top.focusPercent
    
    ' Change title color based on focus
    if focusPercent > 0.5
        m.titleLabel.color = "0xFFFFFFFF"  ' White when focused
    else
        m.titleLabel.color = "0xCCCCCCFF"  ' Light gray when not focused
    end if
end sub

' Update component size dynamically if needed
sub updateSize()
    width = m.top.width
    height = m.top.height
    
    ' Calculate poster height for 16:9 aspect ratio
    posterHeight = Int(width * 9 / 16)
    
    m.posterImage.width = width
    m.posterImage.height = posterHeight
    
    m.titleLabel.width = width
    m.titleLabel.translation = [0, posterHeight + 6]
end sub