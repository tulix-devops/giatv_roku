sub init()
    print "VerticalNavigationBar.brs - [init] *** VERTICAL NAVIGATION BAR INITIALIZING ***"
    
    ' Ensure navigation bar is focusable
    m.top.focusable = true
    m.top.setFocus(true)
    m.top.navHasFocus = true
    m.navBarBackground = m.top.findNode("navBarBackground")
    m.navigationRowList = m.top.findNode("navigationRowList")
    
    ' Debug: Check if RowList was found
    if m.navigationRowList = invalid
        print "VerticalNavigationBar.brs - [init] ERROR: navigationRowList not found! Retrying..."
        ' Try to find it again after a brief delay
        m.retryTimer = CreateObject("roSGNode", "Timer")
        m.retryTimer.duration = 0.1
        m.retryTimer.observeField("fire", "retryFindRowList")
        m.retryTimer.control = "start"
    else
        print "VerticalNavigationBar.brs - [init] navigationRowList found successfully: " + Type(m.navigationRowList)
    end if
    
    print "VerticalNavigationBar.brs - [init] Navigation bar focusable: " + m.top.focusable.ToStr()
    print "VerticalNavigationBar.brs - [init] Navigation bar hasFocus: " + m.top.hasFocus().ToStr()
    
    ' Initialize static navigation items
    m.accountGroup = m.top.findNode("accountGroup")
    
    ' Navigation items array
    m.navItems = []
    m.currentIndex = 0
    print "VerticalNavigationBar.brs - [init] Initial currentIndex set to: " + m.currentIndex.ToStr()
    
    ' For testing: Use default navigation immediately
    print "VerticalNavigationBar.brs - [init] Using default navigation for testing"
    useDefaultNavigation()
    
    ' Also initialize API for real data (will override default when received)
    initializeNavigationApi()
    
    ' Set up RowList observers
    setupRowListObservers()
end sub

sub retryFindRowList()
    print "VerticalNavigationBar.brs - [retryFindRowList] Retrying to find navigationRowList"
    m.navigationRowList = m.top.findNode("navigationRowList")
    
    if m.navigationRowList <> invalid
        print "VerticalNavigationBar.brs - [retryFindRowList] Successfully found navigationRowList on retry"
        setupRowListObservers()
    else
        print "VerticalNavigationBar.brs - [retryFindRowList] Still cannot find navigationRowList"
    end if
end sub

sub setupRowListObservers()
    if m.navigationRowList <> invalid
        print "VerticalNavigationBar.brs - [setupRowListObservers] Setting up RowList observers"
        m.navigationRowList.observeField("itemFocused", "onNavigationItemFocused")
        m.navigationRowList.observeField("itemSelected", "onNavigationItemSelected")
    else
        print "VerticalNavigationBar.brs - [setupRowListObservers] Cannot setup observers - RowList is invalid"
    end if
end sub

sub initializeNavigationApi()
    print "VerticalNavigationBar.brs - [initializeNavigationApi] Fetching navigation data"
    
    m.navigationApi = createObject("roSGNode", "NavigationApi")
    m.navigationApi.observeField("responseData", "handleNavigationResponse")
    m.navigationApi.observeField("errorMessage", "handleNavigationError")
    m.navigationApi.control = "RUN"
end sub

sub handleNavigationResponse()
    print "VerticalNavigationBar.brs - [handleNavigationResponse] *** VERTICAL NAVIGATION DATA RECEIVED ***"
    
    responseData = m.navigationApi.responseData
    if responseData <> invalid and responseData <> ""
        print "VerticalNavigationBar.brs - [handleNavigationResponse] Raw response: " + responseData
        parsedData = ParseJson(responseData)
        if parsedData <> invalid and parsedData.data <> invalid
            print "VerticalNavigationBar.brs - [handleNavigationResponse] Successfully parsed " + parsedData.data.Count().ToStr() + " navigation items"
            m.top.navigationData = parsedData.data
            print "VerticalNavigationBar.brs - [handleNavigationResponse] Set navigationData field, should trigger buildNavigationItems"
        else
            print "VerticalNavigationBar.brs - [handleNavigationResponse] ERROR: Invalid navigation data structure"
            useDefaultNavigation()
        end if
    else
        print "VerticalNavigationBar.brs - [handleNavigationResponse] ERROR: Empty navigation response"
        useDefaultNavigation()
    end if
end sub

sub handleNavigationError()
    print "VerticalNavigationBar.brs - [handleNavigationError] Navigation API error: " + m.navigationApi.errorMessage
    useDefaultNavigation()
end sub

sub useDefaultNavigation()
    print "VerticalNavigationBar.brs - [useDefaultNavigation] Using default navigation items"
    
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
            "title": "Live TV",
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
            "title": "Series",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/archives_icon.png"]
            }
        },
        {
            "id": 5,
            "title": "User Channels",
            "images": {
                "full_hd_images": ["pkg:/images/png/navigation_icons/podcast_icon.png"]
            }
        }
    ]
    
    m.top.navigationData = defaultNavData
end sub

sub buildNavigationItems()
    print "VerticalNavigationBar.brs - [buildNavigationItems] *** BUILDING VERTICAL NAVIGATION ITEMS ***"
    
    navigationData = m.top.navigationData
    if navigationData = invalid or navigationData.Count() = 0
        print "VerticalNavigationBar.brs - [buildNavigationItems] No navigation data available"
        return
    end if
    
    ' Hide global loader
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("hideGlobalLoader")
    end if
    
    ' Create ContentNode for RowList
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Create a single row with all navigation items
    rowNode = CreateObject("roSGNode", "ContentNode")
    rowNode.title = "Navigation"
    
    ' Add each navigation item to the row
    for i = 0 to navigationData.Count() - 1
        navItem = navigationData[i]
        if navItem <> invalid
            itemNode = CreateObject("roSGNode", "ContentNode")
            itemNode.title = navItem.title
            itemNode.id = navItem.id.ToStr()
            
            ' Store navigation data for later use
            itemNode.addField("navData", "assocarray", false)
            itemNode.navData = navItem
            itemNode.addField("navIndex", "int", false)
            itemNode.navIndex = i
            
            rowNode.appendChild(itemNode)
            print "VerticalNavigationBar.brs - [buildNavigationItems] Added nav item: " + navItem.title
        end if
    end for
    
    contentNode.appendChild(rowNode)
    
    if m.navigationRowList <> invalid
        print "VerticalNavigationBar.brs - [buildNavigationItems] Setting content on RowList"
        m.navigationRowList.content = contentNode
        
        print "VerticalNavigationBar.brs - [buildNavigationItems] RowList content set, child count: " + contentNode.getChildCount().ToStr()
        if contentNode.getChildCount() > 0
            firstRow = contentNode.getChild(0)
            print "VerticalNavigationBar.brs - [buildNavigationItems] First row child count: " + firstRow.getChildCount().ToStr()
        end if
        
        ' Set initial focus on RowList
        print "VerticalNavigationBar.brs - [buildNavigationItems] Setting focus on RowList"
        m.navigationRowList.setFocus(true)
        m.navigationRowList.jumpToRowItem = [0, 0]  ' Focus first item
        print "VerticalNavigationBar.brs - [buildNavigationItems] RowList focus set, hasFocus: " + m.navigationRowList.hasFocus().ToStr()
    else
        print "VerticalNavigationBar.brs - [buildNavigationItems] ERROR: navigationRowList is invalid!"
    end if
    
    print "VerticalNavigationBar.brs - [buildNavigationItems] Built " + navigationData.Count().ToStr() + " navigation items"
end sub

sub onNavigationItemFocused()
    if m.navigationRowList <> invalid
        print "VerticalNavigationBar.brs - [onNavigationItemFocused] Item focused: " + m.navigationRowList.itemFocused.ToStr()
        
        focusedIndex = m.navigationRowList.itemFocused
        if focusedIndex >= 0 and m.top.navigationData <> invalid and focusedIndex < m.top.navigationData.Count()
            m.currentIndex = focusedIndex
            print "VerticalNavigationBar.brs - [onNavigationItemFocused] Updated currentIndex to: " + m.currentIndex.ToStr()
            
            ' Trigger navigation change
            determineAndExecuteNavigation(m.currentIndex)
        end if
    end if
end sub

sub onNavigationItemSelected()
    if m.navigationRowList <> invalid
        print "VerticalNavigationBar.brs - [onNavigationItemSelected] Item selected: " + m.navigationRowList.itemSelected.ToStr()
        
        selectedIndex = m.navigationRowList.itemSelected
        if selectedIndex >= 0 and m.top.navigationData <> invalid and selectedIndex < m.top.navigationData.Count()
            ' Move focus to content screen
            m.top.navHasFocus = false
            selectAndScreenSpecificFocus(selectedIndex)
        end if
    end if
end sub

sub focusUpdated()
    print "VerticalNavigationBar.brs - [focusUpdated] navHasFocus: " + m.top.navHasFocus.ToStr() + ", hasFocus: " + m.top.hasFocus().ToStr()
    
    if m.top.navHasFocus = false
        m.top.opacity = 0.4
    else
        m.top.opacity = 1
        
        ' Try to ensure the navigation bar itself has focus as fallback
        if not m.top.hasFocus()
            print "VerticalNavigationBar.brs - [focusUpdated] Setting focus on navigation bar itself"
            m.top.setFocus(true)
        end if
        
        ' Try to set focus on RowList if it's available and ready
        if m.navigationRowList <> invalid and Type(m.navigationRowList) = "roSGNode"
            print "VerticalNavigationBar.brs - [focusUpdated] RowList is valid roSGNode, checking if it has content"
            if m.navigationRowList.content <> invalid
                print "VerticalNavigationBar.brs - [focusUpdated] RowList has content, setting focus"
                m.navigationRowList.setFocus(true)
            else
                print "VerticalNavigationBar.brs - [focusUpdated] RowList has no content yet, keeping focus on navigation bar"
            end if
        else
            print "VerticalNavigationBar.brs - [focusUpdated] RowList is invalid or wrong type, using navigation bar focus"
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "VerticalNavigationBar.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr() + ", navHasFocus: " + m.top.navHasFocus.ToStr()
    
    ' Only handle key press events, not release
    if not press then
        return false
    end if
    
    ' Only handle keys if navigation has conceptual focus
    if m.top.navHasFocus = false
        print "VerticalNavigationBar.brs - [onKeyEvent] Navigation doesn't have conceptual focus, ignoring key"
        return false
    end if
    
    ' Let RowList handle up/down navigation
    if key = "up" or key = "down"
        print "VerticalNavigationBar.brs - [onKeyEvent] Letting RowList handle: " + key
        return false  ' Let RowList handle it
    else if key = "right" then
        print "VerticalNavigationBar.brs - [onKeyEvent] RIGHT: Moving focus to content screen"
        m.top.navHasFocus = false
        selectAndScreenSpecificFocus(m.currentIndex)
        return true
    else if key = "OK" then
        print "VerticalNavigationBar.brs - [onKeyEvent] OK: Activating current navigation item"
        selectAndScreenSpecificFocus(m.currentIndex)
        return true
    end if
    
    return false
end function

sub determineAndExecuteNavigation(index as integer)
    print "VerticalNavigationBar.brs - [determineAndExecuteNavigation] Navigating to index: " + index.ToStr()
    
    ' Get the parent scene to handle navigation
    parentScene = m.top.getParent()
    if parentScene <> invalid
        ' Set the selected index on the parent scene
        if parentScene.hasField("selectedNavIndex")
            parentScene.selectedNavIndex = index
        end if
        
        ' Call navigation handler on parent scene
        if parentScene.hasField("handleDynamicNavigation")
            parentScene.callFunc("handleDynamicNavigation", index)
        end if
        
        ' Trigger screen switch
        screenIndex = convertNavIndexToScreenIndex(index)
        print "VerticalNavigationBar.brs - [determineAndExecuteNavigation] Navigation index " + index.ToStr() + " -> Screen index " + screenIndex.ToStr()
        parentScene.callFunc("setScreenFocus", screenIndex)
    end if
end sub

sub selectAndScreenSpecificFocus(index as integer)
    print "VerticalNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus for screen at index: " + index.ToStr()
    
    ' Get the parent scene to handle focus
    parentScene = m.top.getParent()
    if parentScene <> invalid
        ' Convert navigation index to screen index
        screenIndex = convertNavIndexToScreenIndex(index)
        print "VerticalNavigationBar.brs - [selectAndScreenSpecificFocus] Navigation index " + index.ToStr() + " -> Screen index " + screenIndex.ToStr()
        
        ' Call setScreenFocus function
        result = parentScene.callFunc("setScreenFocus", screenIndex)
        if result <> invalid
            print "VerticalNavigationBar.brs - [selectAndScreenSpecificFocus] Successfully called setScreenFocus"
        end if
        
        ' Set focus on content screen
        dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
        if dynamicScreensContainer <> invalid
            contentScreen = dynamicScreensContainer.getChild(screenIndex)
            if contentScreen <> invalid
                print "VerticalNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus on content screen"
                contentScreen.setFocus(true)
            end if
        end if
    end if
end sub

sub onSelectedIndexChanged()
    print "VerticalNavigationBar.brs - [onSelectedIndexChanged] Selected index changed to: " + m.top.selectedIndex.ToStr()
    
    ' Update RowList focus to match selected index
    if m.top.selectedIndex >= 0 and m.top.navigationData <> invalid and m.top.selectedIndex < m.top.navigationData.Count()
        m.currentIndex = m.top.selectedIndex
        if m.navigationRowList <> invalid
            m.navigationRowList.jumpToRowItem = [0, m.top.selectedIndex]
            print "VerticalNavigationBar.brs - [onSelectedIndexChanged] Updated RowList focus to item: " + m.top.selectedIndex.ToStr()
        end if
    end if
end sub

function convertNavIndexToScreenIndex(navIndex as integer) as integer
    ' Direct 1:1 mapping since search is removed
    print "VerticalNavigationBar.brs - [convertNavIndexToScreenIndex] Converting nav index " + navIndex.ToStr() + " to screen index " + navIndex.ToStr()
    return navIndex
end function