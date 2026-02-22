' =============================================================================
' SeasonScreen.brs - Displays seasons and episodes for a TV series
' =============================================================================

sub init()
    print "SeasonScreen.brs - [init] Called"
    
    ' Get references to new UI elements
    m.screenTitle = m.top.findNode("screenTitle")
    m.seasonLabelList = m.top.findNode("seasonLabelList")
    m.episodeGrid = m.top.findNode("episodeGrid")
    
    ' Legacy references (for compatibility)
    m.categoryRowList = m.top.findNode("tvShowSeasonList")
    m.rowList = m.top.findNode("episodeRowList")
    
    ' Initialize data cache
    m.DVRDataCache = {}
    m.selectedSeasonIndex = 0
    m.selectedDVRTime = ""
    m.lastFocusedItem = 0
    
    ' Set up observers
    m.top.observeField("visible", "onVisibleChange")
    
    ' Set up season list observer
    if m.seasonLabelList <> invalid
        m.seasonLabelList.observeField("itemFocused", "onSeasonFocused")
        m.seasonLabelList.observeField("itemSelected", "onSeasonSelected")
    end if
    
    ' Set up episode grid observer
    if m.episodeGrid <> invalid
        m.episodeGrid.observeField("itemFocused", "onEpisodeFocused")
        m.episodeGrid.observeField("itemSelected", "onEpisodeSelected")
    end if
    
    print "SeasonScreen.brs - [init] Initialization complete"
end sub

' =============================================================================
' onDVRsLoaded - Called when season/episode data is loaded
' =============================================================================
sub onDVRsLoaded()
    print "SeasonScreen.brs - [onDVRsLoaded] Called"
    
    if m.top.arrayDVRs <> invalid
        initializeSeasons(m.top.arrayDVRs)
    end if
    
    print "SeasonScreen.brs - [onDVRsLoaded] Complete"
end sub

' =============================================================================
' initializeSeasons - Set up the season list
' =============================================================================
sub initializeSeasons(seasons as object)
    print "SeasonScreen.brs - [initializeSeasons] Setting up " + seasons.Count().ToStr() + " seasons"
    
    if seasons = invalid or seasons.Count() = 0
        print "SeasonScreen.brs - [initializeSeasons] No seasons to display"
        return
    end if
    
    ' Set screen title with series name
    if m.top.DVRParent <> invalid and m.top.DVRParent.title <> invalid
        m.screenTitle.text = m.top.DVRParent.title
    else
        m.screenTitle.text = "Seasons"
    end if
    
    ' Create content for the season LabelList
    seasonContent = CreateObject("roSGNode", "ContentNode")
    
    for each seasonData in seasons
        seasonItem = CreateObject("roSGNode", "ContentNode")
        ' Add left padding with spaces for better alignment within focus highlight
        seasonItem.title = "  Season " + seasonData.dvrtitle
        
        ' Store season data in cache
        m.DVRDataCache[seasonData.dvrtitle] = seasonData.data
        
        seasonContent.appendChild(seasonItem)
        
        print "SeasonScreen.brs - [initializeSeasons] Added Season " + seasonData.dvrtitle
    end for
    
    ' Set content for the season list
    if m.seasonLabelList <> invalid
        m.seasonLabelList.content = seasonContent
        m.seasonLabelList.setFocus(true)
    end if
    
    ' Initialize with first season's episodes
    if seasons.Count() > 0
        m.selectedDVRTime = seasons[0].dvrtitle
        m.selectedSeasonIndex = 0
        loadEpisodesForSeason(m.selectedDVRTime)
    end if
    
    ' Also set up legacy components for compatibility
    initializeLegacyCategories(seasons)
end sub

' =============================================================================
' initializeLegacyCategories - Set up legacy RowList (for backward compatibility)
' =============================================================================
sub initializeLegacyCategories(categories as object)
    if m.categoryRowList = invalid then return
    
    m.contentContainer = m.top.findNode("tvShowContainer")
    
    hvc = CreateObject("roSGNode", "HomeVodContent")
    content = CreateObject("roSGNode", "ContentNode")
    
    if m.top.DVRParent <> invalid
        content.title = m.top.DVRParent.title
    end if
    
    if categories <> invalid
        m.firstCategoryInitialization = true
        m.selectedDVRTime = categories[0].dvrtitle
        
        for each categoryData in categories
            item = CreateObject("roSGNode", "ContentNode")
            item.title = categoryData
            m.DVRDataCache[categoryData.dvrtitle] = categoryData.data
            item.addFields({
                rowItemFocus: false,
                data: categoryData,
                categoryName: "Season " + categoryData.dvrtitle,
                catId: categoryData.dvrtitle,
                isDVR: true,
                isLiveChannel: false,
                focusable: true,
                isSelected: false
            })
            content.appendChild(item)
        end for
        
        hvc.appendChild(content)
        m.categoryRowList.content = hvc
    end if
end sub

' =============================================================================
' onSeasonFocused - Handle season focus change
' =============================================================================
sub onSeasonFocused()
    if m.seasonLabelList = invalid then return
    
    focusedIndex = m.seasonLabelList.itemFocused
    print "SeasonScreen.brs - [onSeasonFocused] Season " + focusedIndex.ToStr() + " focused"
    
    ' Get the season key from the data cache
    seasonKeys = []
    for each key in m.DVRDataCache
        seasonKeys.Push(key)
    end for
    seasonKeys.Sort()
    
    if focusedIndex >= 0 and focusedIndex < seasonKeys.Count()
        selectedSeasonKey = seasonKeys[focusedIndex]
        if selectedSeasonKey <> m.selectedDVRTime
            m.selectedDVRTime = selectedSeasonKey
            m.selectedSeasonIndex = focusedIndex
            loadEpisodesForSeason(m.selectedDVRTime)
        end if
    end if
end sub

' =============================================================================
' onSeasonSelected - Handle season selection (press OK on season)
' =============================================================================
sub onSeasonSelected()
    print "SeasonScreen.brs - [onSeasonSelected] Moving focus to episode grid"
    
    if m.episodeGrid <> invalid and m.episodeGrid.content <> invalid and m.episodeGrid.content.getChildCount() > 0
        m.episodeGrid.setFocus(true)
    end if
end sub

' =============================================================================
' loadEpisodesForSeason - Load episodes for the selected season
' =============================================================================
sub loadEpisodesForSeason(seasonKey as string)
    print "SeasonScreen.brs - [loadEpisodesForSeason] Loading episodes for Season " + seasonKey
    
    if m.episodeGrid = invalid then return
    
    ' Get episode data from cache
    episodesData = m.DVRDataCache[seasonKey]
    
    if episodesData = invalid
        print "SeasonScreen.brs - [loadEpisodesForSeason] No episodes found for season " + seasonKey
        return
    end if
    
    ' Create content node for episode grid
    content = CreateObject("roSGNode", "ContentNode")
    
    ' Sort episode keys numerically
    episodeKeys = []
    for each key in episodesData
        episodeNum = Val(key)
        if episodeNum > 0
            episodeKeys.Push(episodeNum)
        end if
    end for
    episodeKeys.Sort()
    
    print "SeasonScreen.brs - [loadEpisodesForSeason] Found " + episodeKeys.Count().ToStr() + " episodes"
    
    ' Create content nodes for each episode
    for each episodeNum in episodeKeys
        episodeKey = episodeNum.ToStr()
        episodeData = episodesData[episodeKey]
        
        if episodeData <> invalid
            episodeItem = CreateObject("roSGNode", "ContentNode")
            
            ' Set title
            if episodeData.title <> invalid
                episodeItem.title = episodeData.title
            else
                episodeItem.title = "Episode " + episodeKey
            end if
            
            ' Set poster URL
            if episodeData.images <> invalid
                if episodeData.images.thumbnail <> invalid
                    episodeItem.hdPosterUrl = encodeUrl(episodeData.images.thumbnail)
                else if episodeData.images.poster <> invalid
                    episodeItem.hdPosterUrl = encodeUrl(episodeData.images.poster)
                else
                    episodeItem.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            else
                episodeItem.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
            end if
            
            ' Add episode data
            episodeItem.addFields({
                data: episodeData,
                episodeNumber: episodeKey,
                seasonNumber: seasonKey
            })
            
            content.appendChild(episodeItem)
        end if
    end for
    
    ' Set content on episode grid
    m.episodeGrid.content = content
    
    ' Also update legacy episode row list
    updateLegacyEpisodeList(episodesData)
    
    print "SeasonScreen.brs - [loadEpisodesForSeason] Loaded " + content.getChildCount().ToStr() + " episodes"
end sub

' =============================================================================
' updateLegacyEpisodeList - Update legacy MarkupGrid (for compatibility)
' =============================================================================
sub updateLegacyEpisodeList(episodesData as object)
    if m.rowList = invalid then return
    
    content = CreateObject("roSGNode", "ContentNode")
    content.title = "Episodes"
    
    episodeKeys = []
    for each key in episodesData
        episodeNum = Val(key)
        if episodeNum > 0
            episodeKeys.Push(episodeNum)
        end if
    end for
    episodeKeys.Sort()
    
    for each episodeNum in episodeKeys
        episodeKey = episodeNum.ToStr()
        dvrData = episodesData[episodeKey]
        
        if dvrData <> invalid
            item = CreateObject("roSGNode", "ContentNode")
            item.title = ""
            
            if dvrData.images <> invalid and dvrData.images.thumbnail <> invalid
                item.hdPosterUrl = encodeUrl(dvrData.images.thumbnail)
            else
                item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
            end if
            
            item.addFields({
                rowItemFocus: false,
                data: dvrData,
                isDVRItem: false,
                isLiveChannel: false,
                focusable: true
            })
            
            content.appendChild(item)
        end if
    end for
    
    m.rowList.content = content
end sub

' =============================================================================
' onEpisodeFocused - Handle episode focus change
' =============================================================================
sub onEpisodeFocused()
    if m.episodeGrid = invalid then return
    
    focusedIndex = m.episodeGrid.itemFocused
    print "SeasonScreen.brs - [onEpisodeFocused] Episode " + focusedIndex.ToStr() + " focused"
    
    ' Update focused content for external use
    if m.episodeGrid.content <> invalid and focusedIndex < m.episodeGrid.content.getChildCount()
        m.top.focusedContent = m.episodeGrid.content.getChild(focusedIndex)
    end if
end sub

' =============================================================================
' onEpisodeSelected - Handle episode selection (play video)
' =============================================================================
sub onEpisodeSelected()
    print "SeasonScreen.brs - [onEpisodeSelected] Episode selected - playing video"
    navigateToPlayVideo()
end sub

' =============================================================================
' onVisibleChange - Handle visibility changes
' =============================================================================
sub onVisibleChange()
    print "SeasonScreen.brs - [onVisibleChange] visible = " + m.top.visible.ToStr()
    
    if m.top.visible
        ' Set focus to season list when screen becomes visible
        if m.seasonLabelList <> invalid
            m.seasonLabelList.setFocus(true)
        end if
    end if
end sub

' =============================================================================
' getActiveEntityDetails - Get currently selected episode
' =============================================================================
function getActiveEntityDetails()
    if m.episodeGrid <> invalid and m.episodeGrid.content <> invalid
        focusedIndex = m.episodeGrid.itemFocused
        if focusedIndex >= 0 and focusedIndex < m.episodeGrid.content.getChildCount()
            return m.episodeGrid.content.getChild(focusedIndex)
        end if
    end if
    
    ' Fallback to legacy rowList
    if m.rowList <> invalid and m.rowList.content <> invalid
        focusedIndex = m.rowList.itemFocused
        if focusedIndex >= 0 and focusedIndex < m.rowList.content.getChildCount()
            return m.rowList.content.getChild(focusedIndex)
        end if
    end if
    
    return invalid
end function

' =============================================================================
' navigateToPlayVideo - Play the selected episode
' =============================================================================
sub navigateToPlayVideo()
    m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
    selectionData = getActiveEntityDetails()
    
    if selectionData = invalid or selectionData.data = invalid
        print "SeasonScreen.brs - [navigateToPlayVideo] No episode data to play"
        return
    end if
    
    episodeData = selectionData.data
    
    ' Check for valid video source
    if episodeData.sources = invalid or episodeData.sources.primary = invalid
        print "SeasonScreen.brs - [navigateToPlayVideo] No video source available"
        return
    end if
    
    progNodeToPlay = CreateObject("roSGNode", "ContentNode")
    progNodeToPlay.url = encodeUrl(episodeData.sources.primary)
    
    ' Build title
    seriesTitle = ""
    if m.top.DVRParent <> invalid and m.top.DVRParent.title <> invalid
        seriesTitle = m.top.DVRParent.title
    end if
    
    episodeNum = ""
    if episodeData.episode <> invalid
        episodeNum = episodeData.episode.ToStr()
    end if
    
    progNodeToPlay.title = seriesTitle + " - Season " + m.selectedDVRTime + " Episode " + episodeNum
    
    ' Set description
    if episodeData.description <> invalid
        progNodeToPlay.description = episodeData.description
    else
        progNodeToPlay.description = ""
    end if
    
    ' Set poster
    if episodeData.images <> invalid and episodeData.images.thumbnail <> invalid
        progNodeToPlay.hdposterurl = encodeUrl(episodeData.images.thumbnail)
    end if
    
    progNodeToPlay.addFields({
        isCC: "false",
        isHD: "true",
        channelTitle: "JoyGo"
    })
    
    if m.DVRVideoPlayerScreen <> invalid
        m.DVRVideoPlayerScreen.navigatedFrom = "Seasons"
        m.DVRVideoPlayerScreen.content = progNodeToPlay
        m.DVRVideoPlayerScreen.setFocus(true)
        m.DVRVideoPlayerScreen.visible = true
        m.top.visible = false
    end if
end sub

' =============================================================================
' encodeUrl - URL encode a string
' =============================================================================
function encodeUrl(url as string) as string
    if url = invalid then return ""
    url = url.Replace(" ", "%20")
    return url
end function

' =============================================================================
' onKeyEvent - Handle remote control input
' =============================================================================
function onKeyEvent(key as string, press as boolean) as boolean
    print "SeasonScreen.brs - [onKeyEvent] key=" + key + " press=" + press.ToStr()
    
    if not press then return false
    
    ' Handle back button
    if key = "back"
        return handleBackNavigation()
    end if
    
    ' Handle navigation between season list and episode grid
    if key = "right"
        if m.seasonLabelList <> invalid and m.seasonLabelList.hasFocus()
            if m.episodeGrid <> invalid and m.episodeGrid.content <> invalid and m.episodeGrid.content.getChildCount() > 0
                m.episodeGrid.setFocus(true)
                return true
            end if
        end if
    end if
    
    if key = "left"
        if m.episodeGrid <> invalid and m.episodeGrid.hasFocus()
            if m.seasonLabelList <> invalid
                m.seasonLabelList.setFocus(true)
                return true
            end if
        end if
    end if
    
    ' Handle OK button on episode grid
    if key = "OK"
        if m.episodeGrid <> invalid and m.episodeGrid.hasFocus()
            navigateToPlayVideo()
            return true
        end if
    end if
    
    return false
end function

' =============================================================================
' handleBackNavigation - Handle back button press
' =============================================================================
function handleBackNavigation() as boolean
    print "SeasonScreen.brs - [handleBackNavigation] Navigating back"
    
    ' Show navigation bars
    navBar = m.global.findNode("navigation_bar")
    if navBar <> invalid
        navBar.visible = true
    end if
    
    dynamicNavBar = m.global.findNode("dynamic_navigation_bar")
    if dynamicNavBar <> invalid
        dynamicNavBar.visible = true
    end if
    
    ' Navigate based on source
    if m.top.navigatedFrom = "HOME"
        homeScreen = m.global.findNode("home_screen")
        if homeScreen <> invalid
            homeScreen.visible = true
            homeScreen.setFocus(true)
        end if
    else if m.top.navigatedFrom = "SEARCH"
        searchScreen = m.global.findNode("search_screen")
        if searchScreen <> invalid
            searchScreen.visible = true
            searchScreen.setFocus(true)
        end if
    else if m.top.navigatedFrom = "SERIES"
        print "SeasonScreen.brs - [handleBackNavigation] Returning to Series screen"
        dynamicScreensContainer = m.global.findNode("dynamicScreensContainer")
        if dynamicScreensContainer <> invalid
            for i = 0 to dynamicScreensContainer.getChildCount() - 1
                screen = dynamicScreensContainer.getChild(i)
                if screen <> invalid and screen.contentTypeId <> invalid and screen.contentTypeId = 2
                    screen.visible = true
                    screen.setFocus(true)
                    print "SeasonScreen.brs - [handleBackNavigation] Found and activated Series screen"
                    exit for
                end if
            end for
        end if
        if dynamicNavBar <> invalid
            dynamicNavBar.setFocus(true)
        end if
    else
        ' Default fallback to home
        homeScreen = m.global.findNode("home_screen")
        if homeScreen <> invalid
            homeScreen.visible = true
            homeScreen.setFocus(true)
        end if
    end if
    
    m.top.visible = false
    return true
end function