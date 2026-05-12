sub init()
    print "RowListItemComponent.brs - [init] Initializing modern portrait item component"
    
    ' Get references to UI elements
    m.itemposter = m.top.findNode("poster")
    m.contentOverlay = m.top.findNode("contentOverlay")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.metaLabel = m.top.findNode("metaLabel")
    m.hdIndicator = m.top.findNode("hdIndicator")
    m.hdLabel = m.top.findNode("hdLabel")
    m.newIndicator = m.top.findNode("newIndicator")
    m.newLabel = m.top.findNode("newLabel")
    m.playButtonGroup = m.top.findNode("playButtonGroup")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.focusBorder = m.top.findNode("focusBorder")
    m.cardBackground = m.top.findNode("cardBackground")
    
    ' Set up poster loading observer
    m.itemposter.observeField("loadStatus", "onPosterLoadStatusChanged")
    
    ' Set up focus observer
    m.top.observeField("focusedChild", "onFocusChanged")
    
    ' Initialize as focusable
    m.top.focusable = true
    
    ' Set initial state
    showLoadingState()
end sub

' Modern portrait item component - no variants needed



sub OnContentSet()
    content = m.top.itemContent
    if content = invalid
        print "RowListItemComponent.brs - [OnContentSet] Content is invalid"
        return
    end if
    
    ' Determine layout type based on content
    isLandscape = false
    if content.isLiveChannel <> invalid and content.isLiveChannel = true
        isLandscape = true
        print "RowListItemComponent.brs - [OnContentSet] Setting up landscape content (Live/TV Shows)"
    else
        print "RowListItemComponent.brs - [OnContentSet] Setting up portrait content (Movies)"
    end if
    
    ' Apply appropriate layout
    setupLayout(isLandscape)
    
    print "RowListItemComponent.brs - [OnContentSet] Content: " + FormatJson(content)
    
    ' Set title
    if content.title <> invalid and content.title <> ""
        m.titleLabel.text = content.title
        print "RowListItemComponent.brs - [OnContentSet] Title: " + content.title
    else if content.shortDescriptionLine1 <> invalid and content.shortDescriptionLine1 <> ""
        m.titleLabel.text = content.shortDescriptionLine1
    else
        m.titleLabel.text = "Untitled"
    end if
    
    ' Set description/year
    if content.releaseDate <> invalid and content.releaseDate <> ""
        m.descriptionLabel.text = content.releaseDate
    else if content.shortDescriptionLine2 <> invalid and content.shortDescriptionLine2 <> ""
        m.descriptionLabel.text = content.shortDescriptionLine2
    else if content.description <> invalid and content.description <> ""
        desc = content.description
        if Len(desc) > 40
            desc = Left(desc, 37) + "..."
        end if
        m.descriptionLabel.text = desc
    else
        m.descriptionLabel.text = ""
    end if
    
    ' Set metadata (duration, rating, etc.)
    metaText = ""
    if content.length <> invalid and content.length > 0
        minutes = content.length / 60
        metaText = minutes.ToStr() + "m"
    end if
    m.metaLabel.text = metaText
    
    ' Set poster image
    posterUrl = ""
    if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
        posterUrl = content.hdPosterUrl
        print "RowListItemComponent.brs - [OnContentSet] Using hdPosterUrl: " + posterUrl
    else if content.hdGridPosterUrl <> invalid and content.hdGridPosterUrl <> ""
        posterUrl = content.hdGridPosterUrl
        print "RowListItemComponent.brs - [OnContentSet] Using hdGridPosterUrl: " + posterUrl
    else if content.hdBackgroundImageUrl <> invalid and content.hdBackgroundImageUrl <> ""
        posterUrl = content.hdBackgroundImageUrl
        print "RowListItemComponent.brs - [OnContentSet] Using hdBackgroundImageUrl: " + posterUrl
    else if content.thumbnail <> invalid and content.thumbnail <> ""
        posterUrl = content.thumbnail
        print "RowListItemComponent.brs - [OnContentSet] Using thumbnail: " + posterUrl
    else
        print "RowListItemComponent.brs - [OnContentSet] No poster URL found, using default"
        posterUrl = "pkg:/images/png/poster_not_found_220x375.png"
    end if
    
    print "RowListItemComponent.brs - [OnContentSet] Setting poster URI to: " + posterUrl
    m.itemposter.uri = posterUrl
    
    ' Setup content indicators
    setupContentIndicators(content)
    
    ' Show content overlay
    m.contentOverlay.visible = true
    
    print "RowListItemComponent.brs - [OnContentSet] Layout setup complete"
end sub

sub setupLayout(isLandscape as boolean)
    
    if isLandscape
        ' Landscape layout for Live channels and TV Shows (280x196)
        m.cardBackground.width = 280
        m.cardBackground.height = 196
        
        ' Poster takes most of the space
        m.itemposter.width = 276
        m.itemposter.height = 155
        m.itemposter.translation = [2, 2]
        
        ' Compact overlay at bottom
        m.contentOverlay.translation = [2, 157]
        m.contentOverlay.findNode("overlayBackground").width = 276
        m.contentOverlay.findNode("overlayBackground").height = 37
        
        ' Adjust title positioning and size
        m.titleLabel.translation = [8, 4]
        m.titleLabel.width = 250
        m.titleLabel.height = 18
        m.titleLabel.getChild(0).size = 14 ' Font size
        
        ' Hide description and meta labels for compact layout
        m.descriptionLabel.visible = false
        m.metaLabel.visible = false
        
        ' Adjust status container
        m.contentOverlay.findNode("statusContainer").translation = [230, 4]
        
        ' Center play button for landscape
        m.playButtonGroup.translation = [118, 65]
        m.loadingGroup.translation = [128, 75]
        
    else
        ' Portrait layout for Movies (280x420) - default layout
        m.cardBackground.width = 280
        m.cardBackground.height = 420
        
        m.itemposter.width = 276
        m.itemposter.height = 350
        m.itemposter.translation = [2, 2]
        
        m.contentOverlay.translation = [2, 352]
        m.contentOverlay.findNode("overlayBackground").width = 276
        m.contentOverlay.findNode("overlayBackground").height = 66
        
        ' Reset title positioning and size
        m.titleLabel.translation = [12, 8]
        m.titleLabel.width = 250
        m.titleLabel.height = 28
        m.titleLabel.getChild(0).size = 20 ' Font size
        
        ' Show description and meta labels
        m.descriptionLabel.visible = true
        m.metaLabel.visible = true
        
        ' Reset status container
        m.contentOverlay.findNode("statusContainer").translation = [230, 8]
        
        ' Center play button for portrait
        m.playButtonGroup.translation = [118, 155]
        m.loadingGroup.translation = [128, 165]
    end if
    
    print "RowListItemComponent.brs - [setupLayout] Layout applied successfully"
end sub

sub setupContentIndicators(content)
    ' Reset all indicators
    m.hdIndicator.visible = false
    m.hdLabel.visible = false
    m.newIndicator.visible = false
    m.newLabel.visible = false
    
    ' Check for HD content
    isHD = false
    if content.quality <> invalid and LCase(content.quality) = "hd"
        isHD = true
    else if content.title <> invalid
        ' Demo: Mark certain content as HD
        if Instr(1, LCase(content.title), "4k") > 0 or Instr(1, LCase(content.title), "hd") > 0
            isHD = true
        end if
    end if
    
    if isHD
        m.hdIndicator.visible = true
        m.hdLabel.visible = true
        print "RowListItemComponent.brs - [setupContentIndicators] HD content detected"
    end if
    
    ' Check for new content (simulate for demo)
    isNew = false
    if content.title <> invalid
        ' Demo: Mark certain content as new
        if Instr(1, LCase(content.title), "new") > 0 or Instr(1, LCase(content.title), "2024") > 0
            isNew = true
        end if
    end if
    
    if isNew
        m.newIndicator.visible = true
        m.newLabel.visible = true
        print "RowListItemComponent.brs - [setupContentIndicators] New content detected"
    end if
end sub

sub onPosterLoadStatusChanged()
    loadStatus = m.itemposter.loadStatus
    print "RowListItemComponent.brs - [onPosterLoadStatusChanged] Load status: " + loadStatus
    
    if loadStatus = "ready"
        hideLoadingState()
    else if loadStatus = "loading"
        showLoadingState()
    else if loadStatus = "failed"
        hideLoadingState()
        ' Set fallback image
        m.itemposter.uri = "pkg:/images/png/poster_not_found_220x375.png"
    end if
end sub

sub showLoadingState()
    print "RowListItemComponent.brs - [showLoadingState] Showing loading state"
    m.loadingGroup.visible = true
end sub

sub hideLoadingState()
    print "RowListItemComponent.brs - [hideLoadingState] Hiding loading state"
    m.loadingGroup.visible = false
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        print "RowListItemComponent.brs - [onFocusChanged] Portrait item gained focus - showing modern focus state"
        
        ' Show modern purple focus border
        m.focusBorder.visible = true
        
        ' Show play button overlay
        m.playButtonGroup.visible = true
        
        ' Enhance card background for focus
        m.cardBackground.color = "#252b3a"  ' Slightly lighter on focus
        
        print "RowListItemComponent.brs - [onFocusChanged] Modern focus effects applied"
    else
        print "RowListItemComponent.brs - [onFocusChanged] Portrait item lost focus - hiding focus state"
        
        ' Hide focus border
        m.focusBorder.visible = false
        
        ' Hide play button
        m.playButtonGroup.visible = false
        
        ' Reset card background
        m.cardBackground.color = "#1a1f2e"  ' Original dark color
        
        print "RowListItemComponent.brs - [onFocusChanged] Focus effects removed"
    end if
end sub

' Modern portrait item component complete



