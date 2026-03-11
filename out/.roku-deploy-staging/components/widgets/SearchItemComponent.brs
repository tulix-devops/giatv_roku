sub init()
    ' Main elements
    m.itemposter = m.top.findNode("poster")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.infoPanel = m.top.findNode("infoPanel")
    m.glassBackground = m.top.findNode("glassBackground")
    m.glassReflection = m.top.findNode("glassReflection")
    
    ' Visual effects
    m.actionButton = m.top.findNode("actionButton")
    m.cornerBadge = m.top.findNode("cornerBadge")
    m.badgeText = m.top.findNode("badgeText")
    
    ' Animations
    m.focusInAnimation = m.top.findNode("focusInAnimation")
    m.focusOutAnimation = m.top.findNode("focusOutAnimation")
end sub

sub OnContentSet() ' invoked when item metadata retrieved
    content = m.top.itemContent
    content.observeField("keyPressed", "onKeyPressed")
    
    if content <> invalid
        ' Set poster image directly
        if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
            m.itemposter.uri = content.hdPosterUrl
            print "SearchItemComponent: Setting image URI to: " + content.hdPosterUrl
        else
            print "SearchItemComponent: No image URL provided for: " + content.title
        end if
        
        ' Always ensure poster is visible
        m.itemposter.visible = true
        print "SearchItemComponent: Poster visible set to: " + m.itemposter.visible.ToStr()
        
        ' Set up layout based on content type
        setupLayout(content)
        
        ' Set content information
        setContentInfo(content)
        
        ' Set up focus handling with animations
        content.observeField("rowItemFocus", "onFocusChanged")
    end if
end sub

sub setupLayout(content)
    ' Get content type from typeId
    ' typeId 3 = Live, typeId 1 = VOD (Movie), typeId 2 = TV Show (Series)
    if content.typeId = 3
        ' Live channel layout
        setupLiveChannelLayout()
    else if content.typeId = 2
        ' TV Show layout
        setupTvShowLayout()
    else
        ' VOD Movie layout (default)
        setupVodContentLayout()
    end if
    
    ' Update the component's overall size to match the content
    updateComponentSize(content)
end sub

sub updateComponentSize(content)
    ' The RowList allocates 320x420 space for each item
    ' We need to center our content within that space based on type
    if content.typeId = 3 or content.typeId = 2
        ' Live channels and TV Shows - center the 320x180 item in the 320x420 space
        m.top.width = 320
        m.top.height = 420  ' Use full height to center properly
        ' Center the poster vertically
        m.itemposter.translation = [0, 120] ' (420-180)/2 = 120
        ' Adjust info panel position
        m.infoPanel.translation = [0, 260] ' 120 + 180 - 40
        ' Position corner badge at top-left of poster
        m.cornerBadge.translation = [10, 130] ' 10, 120 + 10
    else
        ' VOD Movies - center the 300x420 item in the 320x420 space
        m.top.width = 320
        m.top.height = 420
        ' Center the poster horizontally
        m.itemposter.translation = [10, 0] ' (320-300)/2 = 10
        ' Info panel stays at bottom
        m.infoPanel.translation = [10, 300] ' 10 + 300
        ' Position corner badge at top-left of poster
        m.cornerBadge.translation = [20, 20] ' 10 + 10, 10 + 10
    end if
end sub

sub setupLiveChannelLayout()
    ' Live channel dimensions - 16:9 aspect ratio
    m.itemposter.width = 320
    m.itemposter.height = 180
    m.glassBackground.width = 320
    m.glassBackground.height = 40
    
    ' Hide the glass background and reflection for live channels
    m.glassBackground.visible = false
    m.glassReflection.visible = false
    
    ' Center the play icon for live items (320x180) - positioned relative to poster
    m.actionButton.translation = [118, 168]  ' (320-84)/2, 120 + (180-84)/2
    
    ' Live channel badge - Blue
    m.badgeText.text = "LIVE"
    m.cornerBadge.findNode("badgeBackground").color = "0x4A90E2"  ' Blue
    
    ' Hide description for live channels
    m.descriptionLabel.visible = false
    m.titleLabel.translation = [15, 130] ' 120 + 10
end sub

sub setupTvShowLayout()
    ' TV Show dimensions - 16:9 aspect ratio (same as Live)
    m.itemposter.width = 320
    m.itemposter.height = 180
    m.glassBackground.width = 320
    m.glassBackground.height = 40
    
    ' Hide the glass background and reflection for TV shows
    m.glassBackground.visible = false
    m.glassReflection.visible = false
    
    ' Center the play icon for TV shows (320x180) - positioned relative to poster
    m.actionButton.translation = [118, 168]  ' (320-84)/2, 120 + (180-84)/2
    
    ' TV Show badge - Blue
    m.badgeText.text = "SERIES"
    m.cornerBadge.findNode("badgeBackground").color = "0x4A90E2"  ' Blue
    
    ' Hide description for TV shows
    m.descriptionLabel.visible = false
    m.titleLabel.translation = [15, 130] ' 120 + 10
end sub

sub setupVodContentLayout()
    ' VOD content dimensions
    m.itemposter.width = 300
    m.itemposter.height = 420
    m.glassBackground.width = 300
    m.glassBackground.height = 120
    
    ' Show the glass background and reflection for VOD content
    m.glassBackground.visible = true
    m.glassReflection.visible = true
    
    ' Center the play icon for VOD items (300x420) - positioned relative to poster
    m.actionButton.translation = [118, 168]  ' 10 + (300-84)/2, (420-84)/2
    
    ' VOD content badge - Red
    m.badgeText.text = "MOVIE"
    m.cornerBadge.findNode("badgeBackground").color = "0xFF6B6B"  ' Red
    
    ' Show description for VOD content
    m.descriptionLabel.visible = true
    m.titleLabel.translation = [25, 15] ' 10 + 15
end sub

sub setContentInfo(content)
    ' Set title with enhanced styling
    if content.data <> invalid and content.data.title <> invalid
        title = content.data.title
        if len(title) > 30
            title = left(title, 27) + "..."
        end if
        m.titleLabel.text = title
    else if content.title <> invalid
        title = content.title
        if len(title) > 30
            title = left(title, 27) + "..."
        end if
        m.titleLabel.text = title
    else
        m.titleLabel.text = ""
    end if
    
    ' Set description with enhanced styling (only for VOD content)
    if content.typeId = 1 ' VOD Movies only
        if content.data <> invalid and content.data.description <> invalid
            description = content.data.description
            description = cleanText(description)
            if len(description) > 80
                description = left(description, 77) + "..."
            end if
            m.descriptionLabel.text = description
        else
            m.descriptionLabel.text = ""
        end if
    end if
end sub

sub onFocusChanged()
    content = m.top.itemContent
    if content <> invalid
        if content.rowItemFocus = true
            ' Start focus in animation
            m.focusInAnimation.control = "start"
        else
            ' Start focus out animation
            m.focusOutAnimation.control = "start"
        end if
    end if
end sub

sub onKeyPressed()
    ' Handle key press events if needed
end sub

function cleanText(text as string) as string
    ' Remove HTML tags and clean up text
    text = text.replace("<br>", " ")
    text = text.replace("<br/>", " ")
    text = text.replace("<p>", "")
    text = text.replace("</p>", " ")
    text = text.replace("<b>", "")
    text = text.replace("</b>", "")
    text = text.replace("<i>", "")
    text = text.replace("</i>", "")
    ' Remove extra whitespace
    while text.instr("  ") > -1
        text = text.replace("  ", " ")
    end while
    return text.trim()
end function
