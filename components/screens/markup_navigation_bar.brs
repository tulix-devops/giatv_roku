sub init()
    print "MarkupNavigationBar.brs - [init] *** MARKUP NAVIGATION BAR INITIALIZING ***"
    
    m.navList = m.top.findNode("navList")
    print "MarkupNavigationBar.brs - [init] NavList found: " + (m.navList <> invalid).ToStr()
    
    ' Ensure navigation bar is focusable
    m.top.focusable = true
    m.top.setFocus(true)
    m.top.navHasFocus = true
    
    ' Initialize navigation items array
    m.navItems = []
    m.currentIndex = 0
    
    ' Set up observers
    m.top.observeField("navHasFocus", "onFocusUpdated")
    
    ' Show global loading state while waiting for API
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("showGlobalLoader", "Loading Navigation...")
    end if
    
    ' For testing: Use default navigation immediately
    print "MarkupNavigationBar.brs - [init] Using default navigation for testing"
    useDefaultNavigation()
    
    ' Also initialize API for real data
    initializeNavigationApi()
end sub

sub initializeNavigationApi()
    print "MarkupNavigationBar.brs - [initializeNavigationApi] Fetching navigation data"
    
    m.navigationApi = createObject("roSGNode", "NavigationApi")
    m.navigationApi.observeField("responseData", "handleNavigationResponse")
    m.navigationApi.observeField("errorMessage", "handleNavigationError")
    m.navigationApi.control = "RUN"
end sub

sub handleNavigationResponse()
    print "MarkupNavigationBar.brs - [handleNavigationResponse] *** MARKUP NAVIGATION DATA RECEIVED ***"
    
    responseData = m.navigationApi.responseData
    if responseData <> invalid and responseData <> ""
        print "MarkupNavigationBar.brs - [handleNavigationResponse] Raw response: " + responseData
        parsedData = ParseJson(responseData)
        if parsedData <> invalid and parsedData.data <> invalid
            print "MarkupNavigationBar.brs - [handleNavigationResponse] Successfully parsed " + parsedData.data.Count().ToStr() + " navigation items"
            m.top.navigationData = parsedData.data
        else
            print "MarkupNavigationBar.brs - [handleNavigationResponse] ERROR: Invalid navigation data structure"
            useDefaultNavigation()
        end if
    else
        print "MarkupNavigationBar.brs - [handleNavigationResponse] ERROR: Empty navigation response"
        useDefaultNavigation()
    end if
end sub

sub handleNavigationError()
    print "MarkupNavigationBar.brs - [handleNavigationError] Navigation API error: " + m.navigationApi.errorMessage
    useDefaultNavigation()
end sub

sub useDefaultNavigation()
    print "MarkupNavigationBar.brs - [useDefaultNavigation] Using default navigation items"
    
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
    print "MarkupNavigationBar.brs - [buildNavigationItems] *** BUILDING MARKUP NAVIGATION ITEMS ***"
    
    navigationData = m.top.navigationData
    if navigationData = invalid or navigationData.Count() = 0
        print "MarkupNavigationBar.brs - [buildNavigationItems] No navigation data available"
        return
    end if
    
    ' Hide global loader
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("hideGlobalLoader")
    end if
    
    ' Initialize content for MarkupList
    initializeContent()
    
    print "MarkupNavigationBar.brs - [buildNavigationItems] Built " + navigationData.Count().ToStr() + " navigation items"
end sub

sub initializeContent()
    print "MarkupNavigationBar.brs - [initializeContent] Creating content for MarkupList"
    
    content = CreateObject("roSGNode", "ContentNode")
    
    navigationData = m.top.navigationData
    if navigationData = invalid
        print "MarkupNavigationBar.brs - [initializeContent] No navigation data available"
        return
    end if
    
    ' Create navigation items array for screen mapping
    m.navItems = []
    
    for i = 0 to navigationData.Count() - 1
        navItem = navigationData[i]
        if navItem <> invalid
            ' Create content item for MarkupList
            item = content.CreateChild("ContentNode")
            item.title = navItem.title
            
            ' Add custom fields using addFields()
            item.addFields({
                focused: false,
                selected: false
            })
            
            print "MarkupNavigationBar.brs - [initializeContent] Created content item with title: '" + item.title + "'"
            
            ' Store navigation mapping
            m.navItems.Push({ 
                id: navItem.id.ToStr(), 
                screen: "screen_" + i.ToStr(),
                title: navItem.title,
                navData: navItem
            })
            
            print "MarkupNavigationBar.brs - [initializeContent] Created item: " + navItem.title
        end if
    end for
    
    print "MarkupNavigationBar.brs - [initializeContent] Setting content to navList"
    if m.navList <> invalid
        print "MarkupNavigationBar.brs - [initializeContent] MarkupList exists, setting content"
        m.navList.content = content
        
        ' Debug: Check if content was set
        if m.navList.content <> invalid
            print "MarkupNavigationBar.brs - [initializeContent] Content successfully set to MarkupList"
            print "MarkupNavigationBar.brs - [initializeContent] MarkupList content child count: " + m.navList.content.getChildCount().ToStr()
        else
            print "MarkupNavigationBar.brs - [initializeContent] ERROR: Content not set on MarkupList"
        end if
        
        m.navList.itemSelected = 0
        m.navList.jumpToItem = 0
        
        ' Set up observers for item selection and focus
        m.navList.observeField("itemSelected", "onItemSelected")
        m.navList.observeField("itemFocused", "onItemFocused")
        
        ' Make sure MarkupList is added to navGroup (like in your original example)
        navGroup = m.top.findNode("navGroup")
        if navGroup <> invalid
            print "MarkupNavigationBar.brs - [initializeContent] Adding MarkupList to navGroup"
            navGroup.appendChild(m.navList)
        end if
        
        print "MarkupNavigationBar.brs - [initializeContent] Content set, item count: " + content.getChildCount().ToStr()
        print "MarkupNavigationBar.brs - [initializeContent] Setting focus on MarkupList"
        m.navList.setFocus(true)
        
        ' Set MarkupList to focus on first item and initialize states
        if content.getChildCount() > 0
            m.navList.jumpToItem = 0
            m.currentIndex = 0
            
            ' Explicitly set the first item as both focused and selected
            updateNavItemFocus(0)
            updateNavItemSelected(0)
            
            print "MarkupNavigationBar.brs - [initializeContent] Set first item as focused and selected"
        end if
        
        ' Debug: Check MarkupList properties
        print "MarkupNavigationBar.brs - [initializeContent] MarkupList visible: " + m.navList.visible.ToStr()
        print "MarkupNavigationBar.brs - [initializeContent] MarkupList focusable: " + m.navList.focusable.ToStr()
        print "MarkupNavigationBar.brs - [initializeContent] MarkupList hasFocus: " + m.navList.hasFocus().ToStr()
    else
        print "MarkupNavigationBar.brs - [initializeContent] ERROR: navList is invalid"
    end if
end sub

sub onItemSelected()
    print "MarkupNavigationBar.brs - [onItemSelected] Navigation item selected (OK/Enter pressed)"
    
    if m.navList <> invalid
        selectedIndex = m.navList.itemSelected
        print "MarkupNavigationBar.brs - [onItemSelected] Selected index: " + selectedIndex.ToStr()
        
        if selectedIndex >= 0 and selectedIndex < m.navItems.count()
            selectedItem = m.navItems[selectedIndex]
            print "MarkupNavigationBar.brs - [onItemSelected] Selected screen: " + selectedItem.title
            m.currentIndex = selectedIndex
            
            ' Switch screen content and update selected state (active tab)
            parentScene = m.top.getParent()
            if parentScene <> invalid
                screenIndex = convertNavIndexToScreenIndex(selectedIndex)
                parentScene.callFunc("switchScreenContent", screenIndex)
                
                ' Update SELECTED state (active tab) - this shows which screen is currently visible
                updateNavItemSelected(selectedIndex)
                print "MarkupNavigationBar.brs - [onItemSelected] Screen switched and selected state updated"
            end if
        end if
    end if
end sub

sub onItemFocused()
    print "MarkupNavigationBar.brs - [onItemFocused] Navigation item focused"
    
    if m.navList <> invalid
        focusedIndex = m.navList.itemFocused
        print "MarkupNavigationBar.brs - [onItemFocused] Focused index: " + focusedIndex.ToStr()
        
        if focusedIndex >= 0 and focusedIndex < m.navItems.count()
            focusedItem = m.navItems[focusedIndex]
            print "MarkupNavigationBar.brs - [onItemFocused] Focused item: " + focusedItem.title
            m.currentIndex = focusedIndex
            
            ' Update FOCUS state (navigation cursor) - this changes as user navigates up/down
            updateNavItemFocus(focusedIndex)
            
            ' Switch screen content and update selected state
            parentScene = m.top.getParent()
            if parentScene <> invalid
                screenIndex = convertNavIndexToScreenIndex(m.currentIndex)
                parentScene.callFunc("switchScreenContent", screenIndex)
                
                ' Update SELECTED state (active tab) - this shows which screen is currently visible
                updateNavItemSelected(focusedIndex)
            end if
        end if
    end if
end sub

sub updateNavItemFocus(focusedIndex as integer)
    print "MarkupNavigationBar.brs - [updateNavItemFocus] Updating focus visual state for index: " + focusedIndex.ToStr()
    
    ' This is a workaround since MarkupList might not automatically trigger focus events on NavItem components
    ' We need to manually set the focused field on content items
    if m.navList <> invalid and m.navList.content <> invalid
        for i = 0 to m.navList.content.getChildCount() - 1
            item = m.navList.content.getChild(i)
            if item <> invalid
                if i = focusedIndex
                    item.focused = true
                    print "MarkupNavigationBar.brs - [updateNavItemFocus] Set item " + i.ToStr() + " focused = true"
                else
                    item.focused = false
                    print "MarkupNavigationBar.brs - [updateNavItemFocus] Set item " + i.ToStr() + " focused = false"
                end if
            end if
        end for
    end if
end sub

sub updateNavItemSelected(selectedIndex as integer)
    print "MarkupNavigationBar.brs - [updateNavItemSelected] Updating selected visual state for index: " + selectedIndex.ToStr()
    
    ' Set selected state on content items to show which tab is currently active
    if m.navList <> invalid and m.navList.content <> invalid
        for i = 0 to m.navList.content.getChildCount() - 1
            item = m.navList.content.getChild(i)
            if item <> invalid
                if i = selectedIndex
                    item.selected = true
                    print "MarkupNavigationBar.brs - [updateNavItemSelected] Set item " + i.ToStr() + " selected = true"
                else
                    item.selected = false
                    print "MarkupNavigationBar.brs - [updateNavItemSelected] Set item " + i.ToStr() + " selected = false"
                end if
            end if
        end for
    end if
end sub


sub onFocusUpdated()
    print "MarkupNavigationBar.brs - [onFocusUpdated] navHasFocus: " + m.top.navHasFocus.ToStr()
    
    if m.top.navHasFocus = false
        m.top.opacity = 0.4
    else
        if m.navList <> invalid
            m.navList.setFocus(true)
        end if
        m.top.opacity = 1
    end if
end sub

sub determineAndExecuteNavigation(index as integer)
    print "MarkupNavigationBar.brs - [determineAndExecuteNavigation] Navigating to index: " + index.ToStr()
    
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
        print "MarkupNavigationBar.brs - [determineAndExecuteNavigation] Navigation index " + index.ToStr() + " -> Screen index " + screenIndex.ToStr()
        parentScene.callFunc("setScreenFocus", screenIndex)
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "MarkupNavigationBar.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr()
    
    if m.navList <> invalid
        m.navList.setFocus(true)
    end if
    
    if press then
        if key = "right" then
            print "MarkupNavigationBar.brs - [onKeyEvent] RIGHT: Moving focus to content screen"
            m.top.navHasFocus = false
            if m.navList <> invalid
                selectedIndex = m.navList.itemSelected
                selectAndScreenSpecificFocus(selectedIndex)
            end if
            return true
        else if key = "OK" then
            print "MarkupNavigationBar.brs - [onKeyEvent] OK: Activating current navigation item"
            if m.navList <> invalid
                selectedIndex = m.navList.itemSelected
                selectAndScreenSpecificFocus(selectedIndex)
            end if
            return true
        end if
    end if
    return false
end function

sub selectAndScreenSpecificFocus(index as integer)
    print "MarkupNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus for screen at index: " + index.ToStr()
    
    ' Get the parent scene to handle focus
    parentScene = m.top.getParent()
    if parentScene <> invalid
        ' Convert navigation index to screen index
        screenIndex = convertNavIndexToScreenIndex(index)
        print "MarkupNavigationBar.brs - [selectAndScreenSpecificFocus] Navigation index " + index.ToStr() + " -> Screen index " + screenIndex.ToStr()
        
        ' Call setScreenFocus function
        result = parentScene.callFunc("setScreenFocus", screenIndex)
        if result <> invalid
            print "MarkupNavigationBar.brs - [selectAndScreenSpecificFocus] Successfully called setScreenFocus"
        end if
        
        ' Set focus on content screen
        dynamicScreensContainer = parentScene.findNode("dynamicScreensContainer")
        if dynamicScreensContainer <> invalid
            contentScreen = dynamicScreensContainer.getChild(screenIndex)
            if contentScreen <> invalid
                print "MarkupNavigationBar.brs - [selectAndScreenSpecificFocus] Setting focus on content screen"
                contentScreen.setFocus(true)
            end if
        end if
    end if
end sub

sub onSelectedIndexChanged()
    print "MarkupNavigationBar.brs - [onSelectedIndexChanged] Selected index changed to: " + m.top.selectedIndex.ToStr()
    
    ' Update MarkupList focus to match selected index
    if m.top.selectedIndex >= 0 and m.top.navigationData <> invalid and m.top.selectedIndex < m.top.navigationData.Count()
        m.currentIndex = m.top.selectedIndex
        if m.navList <> invalid
            m.navList.jumpToItem = m.top.selectedIndex
            print "MarkupNavigationBar.brs - [onSelectedIndexChanged] Updated MarkupList focus to item: " + m.top.selectedIndex.ToStr()
        end if
        
        ' Update selected visual state
        updateNavItemSelected(m.top.selectedIndex)
    end if
end sub

function convertNavIndexToScreenIndex(navIndex as integer) as integer
    ' Direct 1:1 mapping since search is removed
    print "MarkupNavigationBar.brs - [convertNavIndexToScreenIndex] Converting nav index " + navIndex.ToStr() + " to screen index " + navIndex.ToStr()
    return navIndex
end function
