sub init()
    print "DynamicContentScreen.brs - [init] Initializing dynamic content screen"
    
    ' Ensure content screen can receive focus
    m.top.focusable = true
    
    ' Initialize flag to control when content should actually get focus
    m.top.explicitContentFocusRequested = false
    
    m.contentRowList = m.top.findNode("contentRowList")
    m.loadingGroup = m.top.findNode("loadingGroup")
    m.noContentGroup = m.top.findNode("noContentGroup")
    
    ' Screen header elements (Tab Name • Icon • Time format)
    m.screenHeaderGroup = m.top.findNode("screenHeaderGroup")
    m.screenTabName = m.top.findNode("screenTabName")
    m.screenDotSeparator = m.top.findNode("screenDotSeparator")
    m.screenBrandIcon = m.top.findNode("screenBrandIcon")
    m.screenTimeLabel = m.top.findNode("screenTimeLabel")
    m.headerDivider = m.top.findNode("headerDivider")
    
    ' Expand/Collapse animation nodes
    m.expandRowListAnimation = m.top.findNode("expandRowListAnimation")
    m.collapseRowListAnimation = m.top.findNode("collapseRowListAnimation")
    m.expandHeaderAnimation = m.top.findNode("expandHeaderAnimation")
    m.collapseHeaderAnimation = m.top.findNode("collapseHeaderAnimation")
    
    ' Timer for updating the clock
    m.clockTimer = CreateObject("roSGNode", "Timer")
    m.clockTimer.repeat = true
    m.clockTimer.duration = 30  ' Update every 30 seconds
    m.clockTimer.observeField("fire", "updateClockDisplay")
    
    ' Initial time update
    updateClockDisplay()
    
    ' Content API reference
    m.contentApi = invalid
    
    ' Initialize auth required state
    m.showingAuthRequired = false
    m.authRequiredGroup = invalid
    
    ' Initialize login variables
    m.loginUsername = ""
    m.loginPassword = ""
    
    ' Initialize User Channels login variables
    m.userChannelsLoginUsername = ""
    m.userChannelsLoginPassword = ""
    m.userChannelsSignupUsername = ""
    m.userChannelsSignupPassword = ""
    
    ' Set up RowList event handlers
    m.contentRowList.observeField("itemSelected", "onItemSelected")
    m.contentRowList.observeField("itemFocused", "onItemFocused")
    
    ' Focus handling
    m.top.observeField("focusedChild", "onFocusChanged")
    
    ' Set initial state
    showLoadingState()
end sub

sub onFocusChanged()
    print "DynamicContentScreen.brs - [onFocusChanged] Focus changed, hasFocus: " + m.top.hasFocus().ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] Screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    print "DynamicContentScreen.brs - [onFocusChanged] ContentTypeId: " + m.top.contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] ShowingAuthRequired: " + m.showingAuthRequired.ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] RowList visible: " + m.contentRowList.visible.ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] NoContent visible: " + m.noContentGroup.visible.ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] Loading visible: " + m.loadingGroup.visible.ToStr()
    print "DynamicContentScreen.brs - [onFocusChanged] Screen focusable: " + m.top.focusable.ToStr()
    
    if m.top.hasFocus()
        ' When content screen gains focus, check if we should set focus on content or return to navigation
        print "DynamicContentScreen.brs - [onFocusChanged] Screen gained focus, calling setInitialFocus"
        setInitialFocus()
    else
        print "DynamicContentScreen.brs - [onFocusChanged] Screen lost focus"
    end if
end sub

sub updateClockDisplay()
    ' Get current local time and format as HH:MM
    dateTime = CreateObject("roDateTime")
    dateTime.ToLocalTime()
    
    hours = dateTime.GetHours()
    minutes = dateTime.GetMinutes()
    
    ' Format with leading zeros
    hoursStr = hours.ToStr()
    if hours < 10 then hoursStr = "0" + hoursStr
    
    minutesStr = minutes.ToStr()
    if minutes < 10 then minutesStr = "0" + minutesStr
    
    timeStr = hoursStr + ":" + minutesStr
    
    if m.screenTimeLabel <> invalid
        m.screenTimeLabel.text = timeStr
    end if
end sub

' Handle expand/collapse state change for full-width content
sub onExpandedChanged()
    print "DynamicContentScreen.brs - [onExpandedChanged] isExpanded: " + m.top.isExpanded.ToStr()
    
    ' The container (dynamicScreensContainer) already moves from [140, 0] to [0, 0] 
    ' when expanding, which shifts all content 140px left automatically.
    ' We don't need to move internal content additionally - that would be double movement.
    ' Just log the state change for debugging.
    
    if m.contentRowList <> invalid
        currentTranslation = m.contentRowList.translation
        print "DynamicContentScreen.brs - [onExpandedChanged] RowList translation: [" + currentTranslation[0].ToStr() + ", " + currentTranslation[1].ToStr() + "]"
    end if
    
    if m.screenHeaderGroup <> invalid
        headerTranslation = m.screenHeaderGroup.translation
        print "DynamicContentScreen.brs - [onExpandedChanged] Header translation: [" + headerTranslation[0].ToStr() + ", " + headerTranslation[1].ToStr() + "]"
    end if
end sub

sub loadContentForType()
    print "DynamicContentScreen.brs - [loadContentForType] *** FUNCTION CALLED ***"
    contentTypeId = m.top.contentTypeId
    print "DynamicContentScreen.brs - [loadContentForType] Current contentTypeId: " + contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [loadContentForType] Screen ID: " + m.top.id
    print "DynamicContentScreen.brs - [loadContentForType] Screen visible state - translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    print "DynamicContentScreen.brs - [loadContentForType] Current showingAuthRequired: " + m.showingAuthRequired.ToStr()
    
    ' Special debug for Account screen
    if contentTypeId = 6
        print "DynamicContentScreen.brs - [loadContentForType] *** THIS IS THE ACCOUNT SCREEN ***"
        print "DynamicContentScreen.brs - [loadContentForType] About to check authentication for Account"
    end if
    
    if m.authRequiredGroup <> invalid
        print "DynamicContentScreen.brs - [loadContentForType] AuthRequiredGroup visible: " + m.authRequiredGroup.visible.ToStr()
    else
        print "DynamicContentScreen.brs - [loadContentForType] AuthRequiredGroup is invalid (not created yet)"
    end if
    if contentTypeId <= 0
        print "DynamicContentScreen.brs - [loadContentForType] Invalid content type ID: " + contentTypeId.ToStr()
        return
    end if
    
    ' Adjust content position and background based on content type (Home screen has banner)
    backgroundRect = m.top.findNode("backgroundRect")
    print "DynamicContentScreen.brs - [loadContentForType] Background rect found: " + (backgroundRect <> invalid).ToStr()
    if contentTypeId = 13  ' Home screen (id=13)
        print "DynamicContentScreen.brs - [loadContentForType] Home screen - adjusting for banner"
        
        ' Hide header for Home screen (it has the banner instead)
        if m.screenHeaderGroup <> invalid
            m.screenHeaderGroup.visible = false
        end if
        ' Stop the clock timer when header is hidden
        if m.clockTimer <> invalid
            m.clockTimer.control = "stop"
        end if
        
        if m.contentRowList <> invalid
            m.contentRowList.translation = [20, 500]  ' Position content over full-height banner with top spacing
            print "DynamicContentScreen.brs - [loadContentForType] Content moved to position: [20, 500]"
        end if
        ' Make background transparent for Home screen so banner shows through
        if backgroundRect <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] Setting background opacity to 0 for Home screen"
            backgroundRect.opacity = 0
            print "DynamicContentScreen.brs - [loadContentForType] Background opacity set to: " + backgroundRect.opacity.ToStr()
            
            ' Ensure banner stays fully visible by setting its opacity explicitly
            parentScene = m.top.getParent()
            if parentScene <> invalid
                homeBannerGroup = parentScene.findNode("homeBannerGroup")
                if homeBannerGroup <> invalid
                    homeBannerGroup.opacity = 1.0
                    print "DynamicContentScreen.brs - [loadContentForType] Ensured banner opacity is 1.0"
                end if
            end if
        else
            print "DynamicContentScreen.brs - [loadContentForType] ERROR: Background rect not found for Home screen!"
        end if
    else
        print "DynamicContentScreen.brs - [loadContentForType] Other screen - normal content position"
        
        ' Check if this is a screen that should show the header (Live TV, Age Restricted, Personal, Series, Movies, User Channels)
        showHeader = false
        headerTabName = ""
        
        if contentTypeId = 3
            showHeader = true
            headerTabName = "Live TV"
        else if contentTypeId = 15
            showHeader = true
            headerTabName = "Age Restricted"
        else if contentTypeId = 16
            showHeader = true
            headerTabName = "Personal"
        else if contentTypeId = 17
            showHeader = true
            headerTabName = "TV Guide"
        else if contentTypeId = 2
            showHeader = true
            headerTabName = "Series"
        else if contentTypeId = 1
            showHeader = true
            headerTabName = "Movies"
        else if contentTypeId = 14
            showHeader = true
            headerTabName = "User Channels"
        end if
        
        ' Configure screen header
        if showHeader and m.screenHeaderGroup <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] Showing screen header for: " + headerTabName
            m.screenHeaderGroup.visible = true
            m.screenTabName.text = headerTabName
            
            ' Adjust positions based on tab name length (font size 32 ~ 18px per char for bold font)
            tabNameWidth = Len(headerTabName) * 18
            
            ' Dot with small space after title: Title [8px] Dot
            m.screenDotSeparator.translation = [tabNameWidth + 8, 42]
            
            ' Time label with small space after dot: Dot [8px] Time
            timeX = tabNameWidth + 28
            m.screenTimeLabel.translation = [timeX, 44]
            
            ' Logo stays at fixed position on the right (set in XML)
            ' Divider stays at fixed position below (set in XML)
            
            ' Update the clock and start timer
            updateClockDisplay()
            if m.clockTimer <> invalid
                m.clockTimer.control = "start"
            end if
            
            ' Move content down to make room for header (15) + logo (120) + divider (2) + gap (30)
            if m.contentRowList <> invalid
                m.contentRowList.translation = [20, 175]
                print "DynamicContentScreen.brs - [loadContentForType] Content moved down for header: [20, 175]"
            end if
        else
            ' Hide header for other screens
            if m.screenHeaderGroup <> invalid
                m.screenHeaderGroup.visible = false
            end if
            ' Stop the clock timer when header is hidden
            if m.clockTimer <> invalid
                m.clockTimer.control = "stop"
            end if
            if m.contentRowList <> invalid
                m.contentRowList.translation = [20, 20]  ' Normal position with left padding
            end if
        end if
        
        ' Restore background for other screens
        if backgroundRect <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] Setting background opacity to 1 for other screen"
            backgroundRect.opacity = 1
            print "DynamicContentScreen.brs - [loadContentForType] Background opacity set to: " + backgroundRect.opacity.ToStr()
        else
            print "DynamicContentScreen.brs - [loadContentForType] ERROR: Background rect not found for other screen!"
        end if
    end if
    
    ' Don't clear User Channels auth state during navigation
    ' The auth state should persist until user actually authenticates or explicitly cancels
    ' Commenting out this logic to prevent premature clearing
    ' if contentTypeId <> 5 and m.showingAuthRequired = true
    '     print "DynamicContentScreen.brs - [loadContentForType] *** SWITCHING AWAY FROM USER CHANNELS ***"
    '     print "DynamicContentScreen.brs - [loadContentForType] New contentTypeId: " + contentTypeId.ToStr() + ", was showing auth: " + m.showingAuthRequired.ToStr()
    '     m.showingAuthRequired = false
    '     if m.authRequiredGroup <> invalid
    '         print "DynamicContentSwcreen.brs - [loadContentForType] Hiding auth required group"
    '         m.authRequiredGroup.visible = false
    '     end if
    '     print "DynamicContentScreen.brs - [loadContentForType] Auth state cleared"
    ' end if
    
    ' Hide Account page when switching away from Account
    if contentTypeId <> 6
        if m.accountPageGroup <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] Hiding Account page"
            m.accountPageGroup.visible = false
        end if
        if m.prettierAuthGroup <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] Hiding prettier auth dialog"
            m.prettierAuthGroup.visible = false
        end if
        
        ' Restore main background when leaving Account page
        if m.top.backgroundRect <> invalid
            m.top.backgroundRect.visible = true
            print "DynamicContentScreen.brs - [loadContentForType] Restored main background rectangle"
        end if
    end if
    
    ' Check authentication for User Channels (contentTypeId = 14)
    if contentTypeId = 14
        print "DynamicContentScreen.brs - [loadContentForType] *** USER CHANNELS DETECTED ***"
        print "DynamicContentScreen.brs - [loadContentForType] Current screen focus state: " + m.top.hasFocus().ToStr()
        print "DynamicContentScreen.brs - [loadContentForType] Current showingAuthRequired state: " + m.showingAuthRequired.ToStr()
        print "DynamicContentScreen.brs - [loadContentForType] AuthRequiredGroup exists: " + (m.authRequiredGroup <> invalid).ToStr()
        if m.authRequiredGroup <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] AuthRequiredGroup visible: " + m.authRequiredGroup.visible.ToStr()
        end if
        
        ' Check authentication result
        authResult = checkAuthenticationForUserChannels()
        print "DynamicContentScreen.brs - [loadContentForType] Authentication check result: " + authResult.ToStr()
        
        ' Ensure screen is in clean state for User Channels
        print "DynamicContentScreen.brs - [loadContentForType] Ensuring clean state for User Channels"
        m.contentRowList.visible = false
        m.noContentGroup.visible = false
        if m.authRequiredGroup <> invalid
            m.authRequiredGroup.visible = false
        end if
        
        if not authResult
            print "DynamicContentScreen.brs - [loadContentForType] *** USER NOT AUTHENTICATED - SHOWING AUTH DIALOG ***"
            print "DynamicContentScreen.brs - [loadContentForType] Current showingAuthRequired before showing dialog: " + m.showingAuthRequired.ToStr()
            print "DynamicContentScreen.brs - [loadContentForType] Screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
            print "DynamicContentScreen.brs - [loadContentForType] Screen visible: " + m.top.visible.ToStr()
            ' Always show auth dialog when returning to User Channels if not authenticated
            ' This handles the case where user navigated away and came back
            showAuthorizationRequiredMessage()
            print "DynamicContentScreen.brs - [loadContentForType] *** AUTH DIALOG CREATION COMPLETED ***"
            print "DynamicContentScreen.brs - [loadContentForType] AuthRequiredGroup visible after creation: " + m.authRequiredGroup.visible.ToStr()
            print "DynamicContentScreen.brs - [loadContentForType] ShowingAuthRequired after creation: " + m.showingAuthRequired.ToStr()
            return
        else
            print "DynamicContentScreen.brs - [loadContentForType] *** USER AUTHENTICATED - PROCEEDING WITH CONTENT LOAD ***"
            print "DynamicContentScreen.brs - [loadContentForType] Clearing auth UI elements..."
            ' Clear any previous auth state since user is now authenticated
            m.showingAuthRequired = false
            
            ' Ensure auth UI is hidden
            if m.authRequiredGroup <> invalid
                m.authRequiredGroup.visible = false
                print "DynamicContentScreen.brs - [loadContentForType] authRequiredGroup hidden"
            end if
            
            ' Ensure content list is visible
            if m.contentRowList <> invalid
                m.contentRowList.visible = true
                print "DynamicContentScreen.brs - [loadContentForType] contentRowList set to visible"
            end if
            
            print "DynamicContentScreen.brs - [loadContentForType] *** WILL NOW PROCEED TO API CALL ***"
        end if
    end if
    
    ' Handle Account page (contentTypeId = 6) - show authentication like User Channels
    if contentTypeId = 6
        print "DynamicContentScreen.brs - [loadContentForType] *** ACCOUNT PAGE LOGIC REACHED ***"
        print "DynamicContentScreen.brs - [loadContentForType] Screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
        print "DynamicContentScreen.brs - [loadContentForType] Showing Account page with regular content"
        
        ' Show simple account page
        showSimpleAccountPage()
        print "DynamicContentScreen.brs - [loadContentForType] *** ACCOUNT PAGE LOGIC COMPLETED ***"
        
        ' Debug: Check main screen state after Account page creation
        print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Main screen children: " + m.top.getChildCount().ToStr()
        print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Main screen visible: " + m.top.visible.ToStr()
        print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Main screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
        
        ' Check if Account page group is still attached and visible
        if m.accountPageGroup <> invalid
            print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Account page still exists"
            print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Account page visible: " + m.accountPageGroup.visible.ToStr()
            print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Account page attached: " + (m.accountPageGroup.getParent() <> invalid).ToStr()
        else
            print "DynamicContentScreen.brs - [loadContentForType] POST-ACCOUNT DEBUG: Account page is INVALID!"
        end if
        return
    end if
    
    print "DynamicContentScreen.brs - [loadContentForType] Loading content for type ID: " + contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [loadContentForType] Screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    print "DynamicContentScreen.brs - [loadContentForType] This should load different content for different IDs"
    
    ' Show global loading state
    parentScene = m.top.getParent()
    if parentScene <> invalid
        parentScene.callFunc("showGlobalLoader", "Loading Content...")
    end if
    
    ' Show loading state
    showLoadingState()
    
    ' Initialize content API
    if m.contentApi <> invalid
        m.contentApi.unobserveField("responseData")
        m.contentApi.unobserveField("contentItems")
        m.contentApi = invalid
    end if
    
    m.contentApi = createObject("roSGNode", "DynamicContentApi")
    m.contentApi.observeField("responseData", "handleContentResponse")
    m.contentApi.observeField("contentItems", "handleContentItems")
    m.contentApi.contentTypeId = contentTypeId
    print "DynamicContentScreen.brs - [loadContentForType] Created DynamicContentApi with contentTypeId: " + contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [loadContentForType] Starting API call..."
    m.contentApi.control = "RUN"
end sub

sub showLoadingState()
    print "DynamicContentScreen.brs - [showLoadingState] Showing loading indicator"
    
    m.top.isLoading = true
    m.loadingGroup.visible = true
    m.contentRowList.visible = false
    m.noContentGroup.visible = false
end sub

sub hideLoadingState()
    print "DynamicContentScreen.brs - [hideLoadingState] Hiding loading indicator"
    
    m.top.isLoading = false
    m.loadingGroup.visible = false
end sub

sub handleContentResponse()
    print "DynamicContentScreen.brs - [handleContentResponse] Content response received for contentTypeId: " + m.top.contentTypeId.ToStr()
    
    responseData = m.contentApi.responseData
    if responseData <> invalid and responseData <> ""
        print "DynamicContentScreen.brs - [handleContentResponse] Raw response length: " + responseData.Len().ToStr()
        print "DynamicContentScreen.brs - [handleContentResponse] Raw response: " + responseData
    else
        print "DynamicContentScreen.brs - [handleContentResponse] Empty or invalid response"
        showNoContentState()
    end if
end sub

sub handleContentItems()
    print "DynamicContentScreen.brs - [handleContentItems] Content items received for contentTypeId: " + m.top.contentTypeId.ToStr()
    
    contentItems = m.contentApi.contentItems
    
    ' Extra logging for User Channels (contentTypeId = 14)
    if m.top.contentTypeId = 14
        print "=============================================="
        print "DynamicContentScreen.brs - [handleContentItems] *** USER CHANNELS DATA RECEIVED ***"
        print "=============================================="
        if contentItems = invalid
            print "DynamicContentScreen.brs - [handleContentItems] *** USER CHANNELS: contentItems is INVALID ***"
        else if contentItems.Count() = 0
            print "DynamicContentScreen.brs - [handleContentItems] *** USER CHANNELS: contentItems is EMPTY (0 items) ***"
        else
            print "DynamicContentScreen.brs - [handleContentItems] *** USER CHANNELS: " + contentItems.Count().ToStr() + " items/categories received ***"
            print "----------------------------------------------"
            
            ' Iterate through each category/item
            for i = 0 to contentItems.Count() - 1
                item = contentItems[i]
                print "DynamicContentScreen.brs - [handleContentItems] *** USER CHANNELS CATEGORY " + i.ToStr() + " ***"
                
                if item <> invalid
                    ' Print all keys in this category
                    print "DynamicContentScreen.brs - [handleContentItems] Keys in category:"
                    for each key in item.Keys()
                        keyValue = item[key]
                        if Type(keyValue) = "roArray"
                            print "DynamicContentScreen.brs - [handleContentItems]   " + key + ": [Array with " + keyValue.Count().ToStr() + " items]"
                        else if Type(keyValue) = "roAssociativeArray"
                            print "DynamicContentScreen.brs - [handleContentItems]   " + key + ": [AssociativeArray]"
                        else if keyValue <> invalid
                            print "DynamicContentScreen.brs - [handleContentItems]   " + key + ": " + keyValue.ToStr()
                        else
                            print "DynamicContentScreen.brs - [handleContentItems]   " + key + ": <invalid>"
                        end if
                    end for
                    
                    ' Check for common data fields
                    if item.DoesExist("title")
                        print "DynamicContentScreen.brs - [handleContentItems]   -> Title: " + item.title
                    end if
                    if item.DoesExist("name")
                        print "DynamicContentScreen.brs - [handleContentItems]   -> Name: " + item.name
                    end if
                    if item.DoesExist("id")
                        print "DynamicContentScreen.brs - [handleContentItems]   -> ID: " + item.id.ToStr()
                    end if
                    
                    ' Check for VodEntityData (common in GiaTV API)
                    if item.DoesExist("VodEntityData") and item.VodEntityData <> invalid
                        print "DynamicContentScreen.brs - [handleContentItems]   -> VodEntityData: " + item.VodEntityData.Count().ToStr() + " items"
                        ' Print first 3 VodEntityData items
                        maxItems = 3
                        if item.VodEntityData.Count() < maxItems then maxItems = item.VodEntityData.Count()
                        for j = 0 to maxItems - 1
                            vodItem = item.VodEntityData[j]
                            if vodItem <> invalid
                                print "DynamicContentScreen.brs - [handleContentItems]     VodEntity " + j.ToStr() + ":"
                                for each vodKey in vodItem.Keys()
                                    vodValue = vodItem[vodKey]
                                    if Type(vodValue) = "roArray" or Type(vodValue) = "roAssociativeArray"
                                        print "DynamicContentScreen.brs - [handleContentItems]       " + vodKey + ": [" + Type(vodValue) + "]"
                                    else if vodValue <> invalid
                                        vodValueStr = vodValue.ToStr()
                                        if vodValueStr.Len() > 100 then vodValueStr = Left(vodValueStr, 100) + "..."
                                        print "DynamicContentScreen.brs - [handleContentItems]       " + vodKey + ": " + vodValueStr
                                    end if
                                end for
                            end if
                        end for
                    end if
                    
                    ' Check for contents (another common field)
                    if item.DoesExist("contents") and item.contents <> invalid
                        print "DynamicContentScreen.brs - [handleContentItems]   -> contents: " + item.contents.Count().ToStr() + " items"
                    end if
                    
                    ' Check for channels (possible for User Channels)
                    if item.DoesExist("channels") and item.channels <> invalid
                        print "DynamicContentScreen.brs - [handleContentItems]   -> channels: " + item.channels.Count().ToStr() + " items"
                    end if
                    
                    ' Check for streams
                    if item.DoesExist("streams") and item.streams <> invalid
                        print "DynamicContentScreen.brs - [handleContentItems]   -> streams: " + item.streams.Count().ToStr() + " items"
                    end if
                else
                    print "DynamicContentScreen.brs - [handleContentItems] Category " + i.ToStr() + " is INVALID"
                end if
                print "----------------------------------------------"
            end for
            
            print "DynamicContentScreen.brs - [handleContentItems] *** FULL USER CHANNELS JSON DUMP: ***"
            print FormatJson(contentItems)
        end if
        print "=============================================="
    end if
    
    if contentItems <> invalid and contentItems.Count() > 0
        print "DynamicContentScreen.brs - [handleContentItems] Processing " + contentItems.Count().ToStr() + " content items"
        print "DynamicContentScreen.brs - [handleContentItems] Content items structure: " + FormatJson(contentItems)
        
        ' Debug: Check what type of content we're actually getting
        if contentItems.Count() > 0 and contentItems[0] <> invalid
            firstCategory = contentItems[0]
            if firstCategory.DoesExist("VodEntityData") and firstCategory.VodEntityData <> invalid and firstCategory.VodEntityData.Count() > 0
                firstItem = firstCategory.VodEntityData[0]
                print "DynamicContentScreen.brs - [handleContentItems] CONTENT TYPE DEBUG:"
                print "DynamicContentScreen.brs - [handleContentItems] Expected contentTypeId: " + m.top.contentTypeId.ToStr()
                print "DynamicContentScreen.brs - [handleContentItems] First item title: " + firstItem.title
                if firstItem.DoesExist("live")
                    print "DynamicContentScreen.brs - [handleContentItems] First item live: " + firstItem.live.ToStr()
                end if
                if firstItem.DoesExist("typeId")
                    print "DynamicContentScreen.brs - [handleContentItems] First item typeId: " + firstItem.typeId.ToStr()
                end if
                if firstItem.DoesExist("type")
                    print "DynamicContentScreen.brs - [handleContentItems] First item type: " + firstItem.type
                end if
            end if
        end if
        
        m.top.contentData = contentItems
        buildContentDisplay(contentItems)
    else
        print "DynamicContentScreen.brs - [handleContentItems] No content items received or empty array"
        if contentItems <> invalid
            print "DynamicContentScreen.brs - [handleContentItems] Content items count: " + contentItems.Count().ToStr()
        else
            print "DynamicContentScreen.brs - [handleContentItems] Content items is invalid"
        end if
        showNoContentState()
    end if
end sub

sub buildContentDisplay(contentItems as object)
    print "DynamicContentScreen.brs - [buildContentDisplay] Building RowList content with " + contentItems.Count().ToStr() + " categories"
    
    hideLoadingState()
    
    ' Hide global loader
    print "DynamicContentScreen.brs - [buildContentDisplay] Attempting to hide global loader"
    parentScene = m.top.getParent()
    if parentScene <> invalid
        print "DynamicContentScreen.brs - [buildContentDisplay] Parent scene found, calling hideGlobalLoader"
        parentScene.callFunc("hideGlobalLoader")
        print "DynamicContentScreen.brs - [buildContentDisplay] hideGlobalLoader called successfully"
    else
        print "DynamicContentScreen.brs - [buildContentDisplay] ERROR: Parent scene not found!"
    end if
    
    ' Content items are already grouped by category from the API
    if contentItems.Count() = 0
        showNoContentState()
        return
    end if
    
    ' ========== USER CHANNELS DEBUG LOGGING ==========
    if m.top.contentTypeId = 14
        print "=============================================="
        print "USER CHANNELS DATA DEBUG - contentTypeId: 14"
        print "=============================================="
        print "Total categories/rows: " + contentItems.Count().ToStr()
        
        for catIdx = 0 to contentItems.Count() - 1
            catData = contentItems[catIdx]
            print "----------------------------------------------"
            print "CATEGORY " + catIdx.ToStr() + " KEYS:"
            
            ' Print all keys in the category
            if GetInterface(catData, "ifAssociativeArray") <> invalid
                for each key in catData.Keys()
                    keyValue = catData[key]
                    if keyValue = invalid
                        print "  " + key + ": invalid"
                    else if Type(keyValue) = "roArray"
                        print "  " + key + ": [Array with " + keyValue.Count().ToStr() + " items]"
                    else if Type(keyValue) = "roAssociativeArray"
                        print "  " + key + ": [AssociativeArray]"
                    else
                        print "  " + key + ": " + keyValue.ToStr() + " (" + Type(keyValue) + ")"
                    end if
                end for
            else
                print "  Category data is NOT an AssociativeArray, Type: " + Type(catData)
            end if
        end for
        print "=============================================="
    end if
    
    ' ========== TV GUIDE DEBUG LOGGING ==========
    if m.top.contentTypeId = 17
        print "=============================================="
        print "TV GUIDE DATA DEBUG - contentTypeId: 17"
        print "=============================================="
        print "Total categories/rows: " + contentItems.Count().ToStr()
        
        for catIdx = 0 to contentItems.Count() - 1
            catData = contentItems[catIdx]
            print "----------------------------------------------"
            print "CATEGORY " + catIdx.ToStr() + " KEYS:"
            
            ' Print all keys in the category
            if GetInterface(catData, "ifAssociativeArray") <> invalid
                for each key in catData.Keys()
                    keyValue = catData[key]
                    if keyValue = invalid
                        print "  " + key + ": invalid"
                    else if Type(keyValue) = "roArray"
                        print "  " + key + ": [Array with " + keyValue.Count().ToStr() + " items]"
                    else if Type(keyValue) = "roAssociativeArray"
                        print "  " + key + ": [AssociativeArray]"
                    else
                        print "  " + key + ": " + keyValue.ToStr() + " (" + Type(keyValue) + ")"
                    end if
                end for
            else
                print "  Category data is NOT an AssociativeArray, Type: " + Type(catData)
            end if
            
            ' Print first 3 content items details
            if catData.contents <> invalid and GetInterface(catData.contents, "ifArray") <> invalid
                print "  CONTENTS SAMPLE (first 3 of " + catData.contents.Count().ToStr() + "):"
                maxItems = 3
                if catData.contents.Count() < maxItems then maxItems = catData.contents.Count()
                
                for itemIdx = 0 to maxItems - 1
                    item = catData.contents[itemIdx]
                    if item <> invalid and GetInterface(item, "ifAssociativeArray") <> invalid
                        print "    Item " + itemIdx.ToStr() + " keys:"
                        for each itemKey in item.Keys()
                            itemValue = item[itemKey]
                            if itemValue = invalid
                                print "      " + itemKey + ": invalid"
                            else if Type(itemValue) = "roArray"
                                print "      " + itemKey + ": [Array with " + itemValue.Count().ToStr() + " items]"
                            else if Type(itemValue) = "roAssociativeArray"
                                print "      " + itemKey + ": [AssociativeArray]"
                            else if Type(itemValue) = "roString" or Type(itemValue) = "String"
                                if Len(itemValue) > 50
                                    print "      " + itemKey + ": " + Left(itemValue, 50) + "..."
                                else
                                    print "      " + itemKey + ": " + itemValue
                                end if
                            else
                                print "      " + itemKey + ": " + itemValue.ToStr() + " (" + Type(itemValue) + ")"
                            end if
                        end for
                    end if
                end for
            end if
        end for
        print "=============================================="
        print "END TV GUIDE DATA DEBUG"
        print "=============================================="
    end if
    ' ========== END TV GUIDE DEBUG LOGGING ==========
    
    ' Create ContentNode structure for RowList
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Create a row for each category
    for each categoryData in contentItems
        if categoryData.contents <> invalid and categoryData.contents.Count() > 0
         
            ' Safely get category name
            categoryName = "Unknown"
            categoryField = categoryData["category"]
            if categoryField <> invalid
                if Type(categoryField) = "roString" or Type(categoryField) = "String"
                    categoryName = categoryField
                else
                    categoryName = categoryField.ToStr()
                end if
            end if
            
            ' Create row node for this category
            rowNode = CreateObject("roSGNode", "ContentNode")
            rowNode.title = categoryName
            
            ' Add content items to this row
            itemCount = 0
            for each contentItem in categoryData.contents
                itemNode = createContentNodeFromApiData(contentItem)
                if itemNode <> invalid
                    rowNode.appendChild(itemNode)
                    itemCount = itemCount + 1
                    print "DynamicContentScreen.brs - [buildContentDisplay] Added item " + itemCount.ToStr() + " to row: " + itemNode.title
                else
                    print "DynamicContentScreen.brs - [buildContentDisplay] ERROR: Failed to create item node for content item"
                end if
            end for
            
            print "DynamicContentScreen.brs - [buildContentDisplay] Row '" + categoryName + "' has " + rowNode.getChildCount().ToStr() + " items"
            
            ' Add row to main content node
            contentNode.appendChild(rowNode)
        end if
    end for
    
    ' Set content to RowList
    print "DynamicContentScreen.brs - [buildContentDisplay] Setting content to RowList, contentNode children: " + contentNode.getChildCount().ToStr()
    
    ' Set dynamic RowList properties based on content type
    rowItemSizes = []
    rowHeights = []
    rowItemSpacings = []
    
    ' HOME SCREEN (contentTypeId = 13) - Dynamic layout based on row titles
    if m.top.contentTypeId = 13
        print "DynamicContentScreen.brs - [buildContentDisplay] HOME SCREEN - Using dynamic per-row layout based on category titles"
        
        ' Use flexible component that can handle both layouts
        m.contentRowList.itemComponentName = "HomeRowItemComponent"
        
        ' Iterate through each row and set dimensions based on category title
        ' Sized to fit 7 items per row with 8th peeking
        for i = 0 to contentNode.getChildCount() - 1
            rowNode = contentNode.getChild(i)
            rowTitle = ""
            if rowNode <> invalid and rowNode.title <> invalid
                rowTitle = LCase(rowNode.title)
            end if
            
            ' Check if this row should use Portrait (Movies) or Landscape (everything else)
            if Instr(1, rowTitle, "movie") > 0
                ' Movies - Portrait layout (220x330 image + 40 title = 370 total) - 7 items per row
                rowItemSizes.Push([220, 375])
                rowHeights.Push(400.0)
                rowItemSpacings.Push([20, 10])
                print "DynamicContentScreen.brs - [buildContentDisplay] Row " + i.ToStr() + " '" + rowNode.title + "' -> PORTRAIT (220x375)"
            else
                ' Series, Live TV, User Channels, etc. - Landscape layout (350x197 image + 48 title = 245 total) - 4 items + half peek
                rowItemSizes.Push([350, 245])
                rowHeights.Push(270.0)
                rowItemSpacings.Push([25, 15])
                print "DynamicContentScreen.brs - [buildContentDisplay] Row " + i.ToStr() + " '" + rowNode.title + "' -> LANDSCAPE (350x245)"
            end if
            
            ' Mark items in this row with their layout type for the component to use
            for j = 0 to rowNode.getChildCount() - 1
                itemNode = rowNode.getChild(j)
                if itemNode <> invalid
                    if not itemNode.hasField("layoutType")
                        itemNode.addField("layoutType", "string", false)
                    end if
                    if Instr(1, rowTitle, "movie") > 0
                        itemNode.layoutType = "portrait"
                    else
                        itemNode.layoutType = "landscape"
                    end if
                end if
            end for
        end for
        
        m.contentRowList.rowItemSize = rowItemSizes
        m.contentRowList.rowHeights = rowHeights
        m.contentRowList.rowItemSpacing = rowItemSpacings
        m.contentRowList.itemSize = [1920, 420]  ' Max row height
        m.contentRowList.rowLabelOffset = [[0, 8]]  ' Bring titles closer to items
        
    ' Series (2), Live TV (3), User Channels (14), Age Restricted (15), Personal (16), TV Guide (17) - Landscape cards (4 per row + half peek)
    else if m.top.contentTypeId = 2 or m.top.contentTypeId = 3 or m.top.contentTypeId = 14 or m.top.contentTypeId = 15 or m.top.contentTypeId = 16 or m.top.contentTypeId = 17
        if m.top.contentTypeId = 2
            print "DynamicContentScreen.brs - [buildContentDisplay] Series content detected, using SeriesItemComponent"
        else if m.top.contentTypeId = 3
            print "DynamicContentScreen.brs - [buildContentDisplay] Live TV content detected, using SeriesItemComponent"
        else if m.top.contentTypeId = 14
            print "DynamicContentScreen.brs - [buildContentDisplay] User Channels content detected, using SeriesItemComponent"
        else if m.top.contentTypeId = 15
            print "DynamicContentScreen.brs - [buildContentDisplay] Age Restricted content detected, using SeriesItemComponent"
        else if m.top.contentTypeId = 16
            print "DynamicContentScreen.brs - [buildContentDisplay] Personal content detected, using SeriesItemComponent"
        else if m.top.contentTypeId = 17
            print "DynamicContentScreen.brs - [buildContentDisplay] TV Guide content detected, using SeriesItemComponent"
        end if
        m.contentRowList.itemComponentName = "SeriesItemComponent"
        
        ' Size for 4 items per row + half peek of 5th: 350px width, 197px image (16:9) + 48px title area = 245px height
        for i = 0 to contentNode.getChildCount() - 1
            rowItemSizes.Push([350, 245])
            rowHeights.Push(270.0)
        end for
        m.contentRowList.rowItemSize = rowItemSizes
        m.contentRowList.rowHeights = rowHeights
        m.contentRowList.rowItemSpacing = [[25, 15]]
        m.contentRowList.itemSize = [1920, 290]
        m.contentRowList.rowLabelOffset = [[0, 10]]
        
    ' Movies (contentTypeId = 1) - Portrait cards (7 per row) using HomeRowItemComponent
    else if m.top.contentTypeId = 1
        print "DynamicContentScreen.brs - [buildContentDisplay] Movies content detected, using HomeRowItemComponent (Portrait)"
        m.contentRowList.itemComponentName = "HomeRowItemComponent"
        
        ' Mark items with portrait layout type
        for i = 0 to contentNode.getChildCount() - 1
            rowNode = contentNode.getChild(i)
            if rowNode <> invalid
                for j = 0 to rowNode.getChildCount() - 1
                    itemNode = rowNode.getChild(j)
                    if itemNode <> invalid
                        if not itemNode.hasField("layoutType")
                            itemNode.addField("layoutType", "string", false)
                        end if
                        itemNode.layoutType = "portrait"
                    end if
                end for
            end if
            rowItemSizes.Push([220, 375])
            rowHeights.Push(400.0)
        end for
        m.contentRowList.rowItemSize = rowItemSizes
        m.contentRowList.rowHeights = rowHeights
        m.contentRowList.rowItemSpacing = [[20, 10]]
        m.contentRowList.itemSize = [1920, 420]
        m.contentRowList.rowLabelOffset = [[0, 8]]
        
    ' Other VOD content - Portrait (fallback)
    else
        print "DynamicContentScreen.brs - [buildContentDisplay] Other VOD content detected, using RowListItemComponent (Portrait)"
        m.contentRowList.itemComponentName = "RowListItemComponent"
        
        for i = 0 to contentNode.getChildCount() - 1
            rowItemSizes.Push([280, 420])
            rowHeights.Push(450.0)
        end for
        m.contentRowList.rowItemSize = rowItemSizes
        m.contentRowList.rowHeights = rowHeights
        m.contentRowList.rowItemSpacing = [[20, 15]]
        m.contentRowList.itemSize = [1920, 450]
    end if
    
    m.contentRowList.content = contentNode
    
    ' Improve row title styling
    m.contentRowList.rowTitleColor = "#ffffff"
    m.contentRowList.rowSubtitleColor = "#cccccc"
    
    ' Try to set row title font (if supported) - Bold
    titleFont = CreateObject("roSGNode", "Font")
    titleFont.uri = "pkg:/images/UrbanistBold.ttf"
    titleFont.size = 28
    if m.contentRowList.hasField("rowTitleFont")
        m.contentRowList.rowTitleFont = titleFont
    end if
    
    ' Show content RowList
    m.contentRowList.visible = true
    m.noContentGroup.visible = false
    
    print "DynamicContentScreen.brs - [buildContentDisplay] RowList visible: " + m.contentRowList.visible.ToStr()
    print "DynamicContentScreen.brs - [buildContentDisplay] RowList translation: [" + m.contentRowList.translation[0].ToStr() + ", " + m.contentRowList.translation[1].ToStr() + "]"
    
    ' Hide auth required message if it was showing
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
    end if
    m.showingAuthRequired = false
    
    ' After content loads successfully, return focus to navigation bar
    ' This allows users to continue navigating between different content types
    print "DynamicContentScreen.brs - [buildContentDisplay] Content loaded successfully, returning focus to navigation"
    returnFocusToNavigation()
    
    print "DynamicContentScreen.brs - [buildContentDisplay] RowList has focus: " + m.contentRowList.hasFocus().ToStr()
    
    ' Debug: Check if content was set properly
    if m.contentRowList.content <> invalid
        print "DynamicContentScreen.brs - [buildContentDisplay] RowList content rows: " + m.contentRowList.content.getChildCount().ToStr()
    else
        print "DynamicContentScreen.brs - [buildContentDisplay] ERROR: RowList content is invalid!"
    end if
end sub

sub onItemSelected()
    print "DynamicContentScreen.brs - [onItemSelected] Item selected"
    print "DynamicContentScreen.brs - [onItemSelected] RowList rowItemSelected: " + FormatJson(m.contentRowList.rowItemSelected)
    
    ' Get selected item details
    if m.contentRowList.rowItemSelected <> invalid and m.contentRowList.rowItemSelected.Count() >= 2
        rowIndex = m.contentRowList.rowItemSelected[0]
        itemIndex = m.contentRowList.rowItemSelected[1]
        
        print "DynamicContentScreen.brs - [onItemSelected] Row: " + rowIndex.ToStr() + ", Item: " + itemIndex.ToStr()
        
        ' Get the selected content item
        if m.contentRowList.content <> invalid and rowIndex < m.contentRowList.content.getChildCount()
            rowContent = m.contentRowList.content.getChild(rowIndex)
            print "DynamicContentScreen.brs - [onItemSelected] Row content found: " + (rowContent <> invalid).ToStr()
            
            if rowContent <> invalid and itemIndex < rowContent.getChildCount()
                selectedItem = rowContent.getChild(itemIndex)
                print "DynamicContentScreen.brs - [onItemSelected] Selected item found: " + (selectedItem <> invalid).ToStr()
                
                if selectedItem <> invalid
                    print "DynamicContentScreen.brs - [onItemSelected] Selected item: " + selectedItem.title
                    print "DynamicContentScreen.brs - [onItemSelected] Item type: " + Type(selectedItem)
                    
                    ' Check if this is a SERIES - should navigate to SeasonScreen
                    itemContentType = ""
                    itemTypeId = -1
                    
                    ' Get type from the item's stored data
                    if selectedItem.contentType <> invalid
                        itemContentType = LCase(selectedItem.contentType)
                    end if
                    if selectedItem.typeId <> invalid
                        itemTypeId = selectedItem.typeId
                    end if
                    
                    print "DynamicContentScreen.brs - [onItemSelected] Content type: " + itemContentType + ", typeId: " + itemTypeId.ToStr()
                    
                    ' Check if this is a Series (typeId = 2 or type = "series")
                    if itemContentType = "series" or itemTypeId = 2
                        print "DynamicContentScreen.brs - [onItemSelected] *** SERIES DETECTED - Navigating to SeasonScreen ***"
                        
                        ' Navigate to SeasonScreen for series content
                        navigateToSeasonScreen(selectedItem)
                        return
                    end if
                    
                    ' Check if this item has DVR content
                    if selectedItem.dvr_url <> invalid and selectedItem.dvr_url <> ""
                        print "DynamicContentScreen.brs - [onItemSelected] DVR content detected, requesting DVR screen"
                        print "DynamicContentScreen.brs - [onItemSelected] DVR URL: " + selectedItem.dvr_url
                        
                        ' Create DVR request data
                        dvrData = {
                            dvrUrl: selectedItem.dvr_url,
                            channelTitle: selectedItem.title
                        }
                        
                        ' Trigger DVR request event to parent (home scene)
                        m.top.dvrRequested = dvrData
                        print "DynamicContentScreen.brs - [onItemSelected] DVR request sent to parent"
                        
                        return
                    else
                        print "DynamicContentScreen.brs - [onItemSelected] Regular content - should play directly"
                        
                        ' Try to find content URL from multiple possible fields
                        contentUrl = ""
                        
                        ' PRIORITY 1: Check apiData field first (User Channels stores original API data here)
                        if selectedItem.apiData <> invalid
                            print "DynamicContentScreen.brs - [onItemSelected] Checking apiData for stream URL"
                            
                            ' Check apiData.sources
                            if selectedItem.apiData.sources <> invalid
                                if selectedItem.apiData.sources.primary <> invalid and selectedItem.apiData.sources.primary <> ""
                                    contentUrl = selectedItem.apiData.sources.primary
                                    print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'apiData.sources.primary': " + contentUrl
                                else if selectedItem.apiData.sources.hls <> invalid and selectedItem.apiData.sources.hls <> ""
                                    contentUrl = selectedItem.apiData.sources.hls
                                    print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'apiData.sources.hls': " + contentUrl
                                else if selectedItem.apiData.sources.secondary <> invalid and selectedItem.apiData.sources.secondary <> ""
                                    contentUrl = selectedItem.apiData.sources.secondary
                                    print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'apiData.sources.secondary': " + contentUrl
                                end if
                            end if
                            
                            ' Check apiData direct URL fields
                            if contentUrl = "" and selectedItem.apiData.url <> invalid and selectedItem.apiData.url <> ""
                                contentUrl = selectedItem.apiData.url
                                print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'apiData.url': " + contentUrl
                            end if
                            
                            if contentUrl = "" and selectedItem.apiData.stream_url <> invalid and selectedItem.apiData.stream_url <> ""
                                contentUrl = selectedItem.apiData.stream_url
                                print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'apiData.stream_url': " + contentUrl
                            end if
                        end if
                        
                        ' PRIORITY 2: Check direct url field
                        if contentUrl = "" and selectedItem.url <> invalid and selectedItem.url <> ""
                            contentUrl = selectedItem.url
                            print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'url' field"
                        end if
                        
                        ' PRIORITY 3: Check hls field (common for streaming)
                        if contentUrl = "" and selectedItem.hls <> invalid and selectedItem.hls <> ""
                            contentUrl = selectedItem.hls
                            print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'hls' field"
                        end if
                        
                        ' PRIORITY 4: Check stream_url field
                        if contentUrl = "" and selectedItem.stream_url <> invalid and selectedItem.stream_url <> ""
                            contentUrl = selectedItem.stream_url
                            print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'stream_url' field"
                        end if
                        
                        ' PRIORITY 5: Check sources object
                        if contentUrl = "" and selectedItem.sources <> invalid
                            if selectedItem.sources.hls <> invalid and selectedItem.sources.hls <> ""
                                contentUrl = selectedItem.sources.hls
                                print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'sources.hls' field"
                            else if selectedItem.sources.primary <> invalid and selectedItem.sources.primary <> ""
                                contentUrl = selectedItem.sources.primary
                                print "DynamicContentScreen.brs - [onItemSelected] Found URL in 'sources.primary' field"
                            end if
                        end if
                        
                        ' Debug: Print all available fields on the item
                        print "DynamicContentScreen.brs - [onItemSelected] *** ITEM FIELDS DEBUG ***"
                        if selectedItem.url <> invalid then print "DynamicContentScreen.brs - [onItemSelected]   url: " + selectedItem.url
                        if selectedItem.hls <> invalid then print "DynamicContentScreen.brs - [onItemSelected]   hls: " + selectedItem.hls
                        if selectedItem.stream_url <> invalid then print "DynamicContentScreen.brs - [onItemSelected]   stream_url: " + selectedItem.stream_url
                        if selectedItem.sources <> invalid then print "DynamicContentScreen.brs - [onItemSelected]   sources: [object]"
                        
                        ' Extra comprehensive logging for User Channels (contentTypeId = 14)
                        if m.top.contentTypeId = 14
                            print "=============================================="
                            print "*** USER CHANNELS ITEM SELECTED - FULL DATA DUMP ***"
                            print "=============================================="
                            print "Row Index: " + rowIndex.ToStr()
                            print "Item Index: " + itemIndex.ToStr()
                            print ""
                            print "---------- ALL ITEM FIELDS ----------"
                            
                            ' Get the item interface to iterate through all fields
                            itemInterface = GetInterface(selectedItem, "ifAssociativeArray")
                            if itemInterface <> invalid
                                allKeys = selectedItem.Keys()
                                print "Total fields: " + allKeys.Count().ToStr()
                                print ""
                                
                                for each key in allKeys
                                    fieldValue = selectedItem[key]
                                    
                                    if fieldValue = invalid
                                        print "  " + key + ": <invalid>"
                                    else if Type(fieldValue) = "roString" or Type(fieldValue) = "String"
                                        if fieldValue = ""
                                            print "  " + key + ": """" (empty string)"
                                        else
                                            print "  " + key + ": """ + fieldValue + """"
                                        end if
                                    else if Type(fieldValue) = "roInt" or Type(fieldValue) = "Integer" or Type(fieldValue) = "roFloat" or Type(fieldValue) = "Float"
                                        print "  " + key + ": " + fieldValue.ToStr()
                                    else if Type(fieldValue) = "roBoolean" or Type(fieldValue) = "Boolean"
                                        print "  " + key + ": " + fieldValue.ToStr()
                                    else if Type(fieldValue) = "roAssociativeArray"
                                        print "  " + key + ": [AssociativeArray]"
                                        ' Print nested keys
                                        nestedInterface = GetInterface(fieldValue, "ifAssociativeArray")
                                        if nestedInterface <> invalid
                                            nestedKeys = fieldValue.Keys()
                                            for each nestedKey in nestedKeys
                                                nestedValue = fieldValue[nestedKey]
                                                if nestedValue = invalid
                                                    print "      " + nestedKey + ": <invalid>"
                                                else if Type(nestedValue) = "roString" or Type(nestedValue) = "String"
                                                    if nestedValue = ""
                                                        print "      " + nestedKey + ": """" (empty)"
                                                    else
                                                        valueStr = nestedValue
                                                        if valueStr.Len() > 100 then valueStr = Left(valueStr, 100) + "..."
                                                        print "      " + nestedKey + ": """ + valueStr + """"
                                                    end if
                                                else if Type(nestedValue) = "roAssociativeArray"
                                                    print "      " + nestedKey + ": [AssociativeArray - nested]"
                                                    ' Print 3rd level keys for apiData
                                                    if key = "apiData"
                                                        thirdLevelInterface = GetInterface(nestedValue, "ifAssociativeArray")
                                                        if thirdLevelInterface <> invalid
                                                            for each thirdKey in nestedValue.Keys()
                                                                thirdValue = nestedValue[thirdKey]
                                                                if thirdValue = invalid
                                                                    print "          " + thirdKey + ": <invalid>"
                                                                else if Type(thirdValue) = "roString" or Type(thirdValue) = "String"
                                                                    if thirdValue = ""
                                                                        print "          " + thirdKey + ": """" (empty)"
                                                                    else
                                                                        thirdStr = thirdValue
                                                                        if thirdStr.Len() > 80 then thirdStr = Left(thirdStr, 80) + "..."
                                                                        print "          " + thirdKey + ": """ + thirdStr + """"
                                                                    end if
                                                                else
                                                                    print "          " + thirdKey + ": " + thirdValue.ToStr() + " [" + Type(thirdValue) + "]"
                                                                end if
                                                            end for
                                                        end if
                                                    end if
                                                else if Type(nestedValue) = "roArray"
                                                    print "      " + nestedKey + ": [Array with " + nestedValue.Count().ToStr() + " items]"
                                                else
                                                    print "      " + nestedKey + ": " + nestedValue.ToStr() + " [" + Type(nestedValue) + "]"
                                                end if
                                            end for
                                        end if
                                    else if Type(fieldValue) = "roArray"
                                        print "  " + key + ": [Array with " + fieldValue.Count().ToStr() + " items]"
                                        ' Print first few array items if they exist
                                        if fieldValue.Count() > 0
                                            maxShow = 3
                                            if fieldValue.Count() < maxShow then maxShow = fieldValue.Count()
                                            for i = 0 to maxShow - 1
                                                arrayItem = fieldValue[i]
                                                if arrayItem <> invalid
                                                    print "      [" + i.ToStr() + "]: " + Type(arrayItem)
                                                end if
                                            end for
                                        end if
                                    else
                                        print "  " + key + ": [" + Type(fieldValue) + "]"
                                    end if
                                end for
                            else
                                print "  ERROR: Cannot get interface for selected item"
                            end if
                            
                   
                            print "---------- RAW API DATA (JSON) ----------"
                            if selectedItem.apiData <> invalid
                                apiDataJson = FormatJson(selectedItem.apiData)
                                print apiDataJson
                            else
                                print "  apiData field is invalid"
                            end if
                            
                            print ""
                            print "---------- RAW SOURCES DATA (JSON) ----------"
                            if selectedItem.sources <> invalid
                                sourcesJson = FormatJson(selectedItem.sources)
                                print sourcesJson
                            else
                                print "  sources field is invalid"
                            end if
                            
                            print "=============================================="
                        end if
                        
                        if contentUrl = ""
                            print "DynamicContentScreen.brs - [onItemSelected] Content URL: No URL found"
                        else
                            print "DynamicContentScreen.brs - [onItemSelected] Content URL: " + contentUrl
                        end if
                        
                        ' Trigger video playback for regular content
                        if contentUrl <> "" and contentUrl <> invalid
                            print "DynamicContentScreen.brs - [onItemSelected] Triggering video playback for: " + selectedItem.title
                            
                            ' Get metadata - prefer apiData if available (User Channels)
                            itemTitle = selectedItem.title
                            itemDescription = ""
                            itemThumbnail = ""
                            itemIsLive = false
                            
                            if selectedItem.apiData <> invalid
                                print "DynamicContentScreen.brs - [onItemSelected] Using apiData for metadata"
                                if selectedItem.apiData.title <> invalid then itemTitle = selectedItem.apiData.title
                                if selectedItem.apiData.description <> invalid then itemDescription = selectedItem.apiData.description
                                if selectedItem.apiData.live <> invalid then itemIsLive = selectedItem.apiData.live
                                
                                ' Get thumbnail from apiData.images
                                if selectedItem.apiData.images <> invalid
                                    if selectedItem.apiData.images.poster <> invalid and selectedItem.apiData.images.poster <> ""
                                        itemThumbnail = selectedItem.apiData.images.poster
                                    else if selectedItem.apiData.images.thumbnail <> invalid and selectedItem.apiData.images.thumbnail <> ""
                                        itemThumbnail = selectedItem.apiData.images.thumbnail
                                    end if
                                end if
                            else
                                print "DynamicContentScreen.brs - [onItemSelected] Using direct item fields for metadata"
                                if selectedItem.description <> invalid then itemDescription = selectedItem.description
                                if selectedItem.hdPosterUrl <> invalid then itemThumbnail = selectedItem.hdPosterUrl
                                if selectedItem.live <> invalid then itemIsLive = selectedItem.live
                            end if
                            
                            ' Create video play request data
                            videoData = {
                                contentUrl: contentUrl,
                                title: itemTitle,
                                description: itemDescription,
                                thumbnail: itemThumbnail,
                                isLive: itemIsLive
                            }
                            
                            print "DynamicContentScreen.brs - [onItemSelected] Video data prepared:"
                            print "DynamicContentScreen.brs - [onItemSelected]   Title: " + videoData.title
                            print "DynamicContentScreen.brs - [onItemSelected]   URL: " + videoData.contentUrl
                            print "DynamicContentScreen.brs - [onItemSelected]   IsLive: " + videoData.isLive.ToStr()
                            
                            ' Trigger video play request event to parent (home scene)
                            m.top.videoPlayRequested = videoData
                            print "DynamicContentScreen.brs - [onItemSelected] Video play request sent to parent"
                        else
                            print "DynamicContentScreen.brs - [onItemSelected] ERROR: No valid URL for content playback"
                        end if
                    end if
                else
                    print "DynamicContentScreen.brs - [onItemSelected] ERROR: Selected item is invalid"
                end if
            else
                print "DynamicContentScreen.brs - [onItemSelected] ERROR: Item index out of bounds or row content invalid"
                if rowContent <> invalid
                    print "DynamicContentScreen.brs - [onItemSelected] Row has " + rowContent.getChildCount().ToStr() + " items, requested index: " + itemIndex.ToStr()
                end if
            end if
        else
            print "DynamicContentScreen.brs - [onItemSelected] ERROR: Row index out of bounds or content invalid"
            if m.contentRowList.content <> invalid
                print "DynamicContentScreen.brs - [onItemSelected] Content has " + m.contentRowList.content.getChildCount().ToStr() + " rows, requested index: " + rowIndex.ToStr()
            end if
        end if
    else
        print "DynamicContentScreen.brs - [onItemSelected] ERROR: rowItemSelected is invalid or has wrong format"
        if m.contentRowList.rowItemSelected <> invalid
            print "DynamicContentScreen.brs - [onItemSelected] rowItemSelected count: " + m.contentRowList.rowItemSelected.Count().ToStr()
        end if
    end if
    
    print "DynamicContentScreen.brs - [onItemSelected] Item selection handling complete"
end sub

sub onItemFocused()
    ' Simple logging for item focus - RowList handles focus automatically
    print "DynamicContentScreen.brs - [onItemFocused] Item focus changed"
end sub

' Navigate to SeasonScreen for series content
sub navigateToSeasonScreen(selectedItem as object)
    print "DynamicContentScreen.brs - [navigateToSeasonScreen] *** NAVIGATING TO SEASON SCREEN ***"
    
    if selectedItem = invalid
        print "DynamicContentScreen.brs - [navigateToSeasonScreen] ERROR: selectedItem is invalid"
        return
    end if
    
    ' Get series ID - check multiple possible fields
    seriesId = 0
    if selectedItem.contentId <> invalid
        seriesId = selectedItem.contentId
    else if selectedItem.id <> invalid
        ' Try to convert string ID to integer
        if Type(selectedItem.id) = "roString" or Type(selectedItem.id) = "String"
            seriesId = Val(selectedItem.id)
        else
            seriesId = selectedItem.id
        end if
    else if selectedItem.apiData <> invalid and selectedItem.apiData.id <> invalid
        seriesId = selectedItem.apiData.id
    end if
    
    ' Get typeId - default to 2 for series
    typeId = 2
    if selectedItem.typeId <> invalid
        if Type(selectedItem.typeId) = "roString" or Type(selectedItem.typeId) = "String"
            typeId = Val(selectedItem.typeId)
        else
            typeId = selectedItem.typeId
        end if
    end if
    
    print "DynamicContentScreen.brs - [navigateToSeasonScreen] Series ID: " + seriesId.ToStr()
    print "DynamicContentScreen.brs - [navigateToSeasonScreen] Type ID: " + typeId.ToStr()
    print "DynamicContentScreen.brs - [navigateToSeasonScreen] Series Title: " + selectedItem.title
    
    ' Find the SeasonScreen component
    parentScene = m.top.getParent()
    while parentScene <> invalid
        seasonScreen = parentScene.findNode("SeasonScreen")
        if seasonScreen <> invalid
            print "DynamicContentScreen.brs - [navigateToSeasonScreen] Found SeasonScreen"
            
            ' DON'T hide current screen yet - wait until data is loaded
            ' The screen will be hidden in processSeriesData after successful load
            
            ' Set series data on SeasonScreen
            ' The existing SeasonScreen expects arrayDVRs with season data
            ' We need to fetch the series details first
            
            ' Create a task to fetch series details with seasons/episodes
            fetchSeriesData(seriesId, typeId, selectedItem, seasonScreen)
            
            return
        end if
        parentScene = parentScene.getParent()
    end while
    
    print "DynamicContentScreen.brs - [navigateToSeasonScreen] ERROR: Could not find SeasonScreen"
end sub

' Fetch series data with seasons and episodes using SeriesApi Task
sub fetchSeriesData(seriesId as integer, typeId as integer, seriesItem as object, seasonScreen as object)
    print "DynamicContentScreen.brs - [fetchSeriesData] Fetching series data for ID: " + seriesId.ToStr() + ", TypeID: " + typeId.ToStr()
    
    ' Store references for callback
    m.pendingSeasonScreen = seasonScreen
    m.pendingSeriesItem = seriesItem
    
    ' Show global loader while fetching data
    showGlobalLoader(true)
    
    ' Create SeriesApi task to fetch data (runs on TASK thread, not RENDER thread)
    m.seriesApiTask = CreateObject("roSGNode", "SeriesApi")
    m.seriesApiTask.seriesId = seriesId
    m.seriesApiTask.typeId = typeId
    
    ' Observe for when data is ready
    m.seriesApiTask.observeField("seriesData", "onSeriesDataReceived")
    m.seriesApiTask.observeField("errorMessage", "onSeriesApiError")
    
    ' Start the task
    m.seriesApiTask.control = "RUN"
    
    print "DynamicContentScreen.brs - [fetchSeriesData] SeriesApi task started"
end sub

' Show or hide the global loading indicator
sub showGlobalLoader(show as boolean)
    globalLoader = m.global.findNode("globalLoader")
    if globalLoader <> invalid
        globalLoader.visible = show
        print "DynamicContentScreen.brs - [showGlobalLoader] Loader visible: " + show.ToStr()
    else
        print "DynamicContentScreen.brs - [showGlobalLoader] Global loader not found"
    end if
end sub

' Callback when series data is received from SeriesApi task
sub onSeriesDataReceived()
    print "DynamicContentScreen.brs - [onSeriesDataReceived] Series data received from task"
    
    ' Hide loader
    showGlobalLoader(false)
    
    if m.seriesApiTask <> invalid and m.seriesApiTask.seriesData <> invalid
        seriesData = m.seriesApiTask.seriesData
        processSeriesData(seriesData)
    else
        print "DynamicContentScreen.brs - [onSeriesDataReceived] ERROR: No series data in response"
        showSeasonScreenWithBasicInfo()
    end if
end sub

' Callback when series API returns an error
sub onSeriesApiError()
    print "DynamicContentScreen.brs - [onSeriesApiError] Series API error"
    
    ' Hide loader
    showGlobalLoader(false)
    
    if m.seriesApiTask <> invalid and m.seriesApiTask.errorMessage <> invalid
        print "DynamicContentScreen.brs - [onSeriesApiError] Error: " + m.seriesApiTask.errorMessage
    end if
    
    ' Show season screen with basic info as fallback
    showSeasonScreenWithBasicInfo()
end sub

' Process series data object (already parsed from API response)
sub processSeriesData(seriesData as object)
    print "DynamicContentScreen.brs - [processSeriesData] Processing series data object"
    
    if seriesData = invalid
        print "DynamicContentScreen.brs - [processSeriesData] ERROR: Series data is invalid"
        showSeasonScreenWithBasicInfo()
        return
    end if
    
    print "DynamicContentScreen.brs - [processSeriesData] Series title: " + seriesData.title
    
    ' Convert to format expected by SeasonScreen
    ' SeasonScreen expects arrayDVRs with format: [{dvrtitle: "seasonNum", data: {"episodeNum": episodeObject}}]
    ' API returns seasons as object: {"01": [episodes], "02": [episodes], ...}
    seasonsArray = []
    
    if seriesData.seasons <> invalid
        print "DynamicContentScreen.brs - [processSeriesData] Processing seasons object"
        
        ' Seasons is an object with season numbers as keys (e.g., "01", "02", "03")
        seasonKeys = []
        
        ' Collect all season keys
        for each seasonKey in seriesData.seasons
            seasonKeys.Push(seasonKey)
        end for
        
        ' Sort season keys to display in order
        seasonKeys.Sort()
        
        print "DynamicContentScreen.brs - [processSeriesData] Found " + seasonKeys.Count().ToStr() + " seasons"
        
        for each seasonKey in seasonKeys
            seasonEpisodes = seriesData.seasons[seasonKey]
            
            print "DynamicContentScreen.brs - [processSeriesData] Processing Season " + seasonKey + " with " + seasonEpisodes.Count().ToStr() + " episodes"
            
            ' Build episodes data map - key is episode number, value is episode data object
            episodesData = {}
            
            if seasonEpisodes <> invalid and Type(seasonEpisodes) = "roArray"
                for each episode in seasonEpisodes
                    ' Get episode number - convert "01" to "1" for proper key matching
                    episodeNum = "1"
                    if episode.episode <> invalid
                        episodeStr = episode.episode.ToStr()
                        episodeInt = Val(episodeStr)
                        if episodeInt > 0
                            episodeNum = episodeInt.ToStr()
                        else
                            episodeNum = episodeStr
                        end if
                    end if
                    
                    ' Store the episode data as an object
                    episodesData[episodeNum] = episode
                end for
            end if
            
            ' Create season entry - convert "01" to "1" for display
            displaySeasonNum = seasonKey
            if displaySeasonNum.Left(1) = "0" and displaySeasonNum.Len() > 1
                displaySeasonNum = displaySeasonNum.Mid(1)
            end if
            
            seasonEntry = {
                dvrtitle: displaySeasonNum,
                data: episodesData
            }
            seasonsArray.Push(seasonEntry)
            
            print "DynamicContentScreen.brs - [processSeriesData] Added Season " + displaySeasonNum + " with " + episodesData.Count().ToStr() + " episodes"
        end for
    else
        print "DynamicContentScreen.brs - [processSeriesData] No seasons found, creating default"
        seasonEntry = {
            dvrtitle: "1",
            data: {}
        }
        seasonsArray.Push(seasonEntry)
    end if
    
    print "DynamicContentScreen.brs - [processSeriesData] Total seasons prepared: " + seasonsArray.Count().ToStr()
    
    ' Show the SeasonScreen
    if m.pendingSeasonScreen <> invalid
        print "DynamicContentScreen.brs - [processSeriesData] Setting up SeasonScreen"
        
        ' Hide current screen and navigation bar AFTER data is loaded
        m.top.visible = false
        
        dynamicNavBar = m.global.findNode("dynamic_navigation_bar")
        if dynamicNavBar <> invalid
            dynamicNavBar.visible = false
        end if
        
        ' Set the parent series info
        parentNode = CreateObject("roSGNode", "ContentNode")
        
        if seriesData.title <> invalid and seriesData.title <> ""
            parentNode.title = seriesData.title
        else if m.pendingSeriesItem <> invalid and m.pendingSeriesItem.title <> invalid
            parentNode.title = m.pendingSeriesItem.title
        else
            parentNode.title = "Unknown Series"
        end if
        
        if seriesData.images <> invalid and seriesData.images.poster <> invalid
            parentNode.hdPosterUrl = seriesData.images.poster
        else if m.pendingSeriesItem <> invalid and m.pendingSeriesItem.hdPosterUrl <> invalid
            parentNode.hdPosterUrl = m.pendingSeriesItem.hdPosterUrl
        end if
        
        m.pendingSeasonScreen.DVRParent = parentNode
        m.pendingSeasonScreen.arrayDVRs = seasonsArray
        m.pendingSeasonScreen.navigatedFrom = "SERIES"
        m.pendingSeasonScreen.visible = true
        m.pendingSeasonScreen.setFocus(true)
        
        print "DynamicContentScreen.brs - [processSeriesData] SeasonScreen displayed with " + seasonsArray.Count().ToStr() + " seasons"
    end if
end sub

' Show SeasonScreen with basic info when API fails
sub showSeasonScreenWithBasicInfo()
    print "DynamicContentScreen.brs - [showSeasonScreenWithBasicInfo] Using basic info"
    
    if m.pendingSeasonScreen <> invalid and m.pendingSeriesItem <> invalid
        ' Hide current screen and navigation bar
        m.top.visible = false
        
        dynamicNavBar = m.global.findNode("dynamic_navigation_bar")
        if dynamicNavBar <> invalid
            dynamicNavBar.visible = false
        end if
        
        ' Create basic season data
        seasonEntry = {
            dvrtitle: "1",
            data: {}
        }
        
        parentNode = CreateObject("roSGNode", "ContentNode")
        parentNode.title = m.pendingSeriesItem.title
        
        m.pendingSeasonScreen.DVRParent = parentNode
        m.pendingSeasonScreen.arrayDVRs = [seasonEntry]
        m.pendingSeasonScreen.navigatedFrom = "SERIES"
        m.pendingSeasonScreen.visible = true
        m.pendingSeasonScreen.setFocus(true)
    end if
end sub

function createContentNodeFromApiData(apiItem as object) as object
    ' Convert API content item to Roku ContentNode format
    if apiItem = invalid
        return invalid
    end if
    
    contentNode = CreateObject("roSGNode", "ContentNode")
    
    ' Set basic properties (both direct and in data object for compatibility)
    if apiItem.title <> invalid
        contentNode.title = apiItem.title
    else
        contentNode.title = "Unknown Title"
    end if
    
    if apiItem.description <> invalid
        contentNode.description = apiItem.description
    else
        contentNode.description = ""
    end if
    
    ' Note: RowListItemComponent will use contentNode.title and contentNode.description directly
    ' since contentNode.data is not available on ContentNode
    
    if apiItem.id <> invalid
        contentNode.id = apiItem.id.ToStr()
    end if
    
    ' Set additional fields that RowList might expect
    contentNode.shortDescriptionLine1 = contentNode.title
    contentNode.shortDescriptionLine2 = contentNode.description
    
    ' Set images
    if apiItem.images <> invalid
        if apiItem.images.poster <> invalid and apiItem.images.poster <> ""
            contentNode.hdPosterUrl = apiItem.images.poster
            contentNode.sdPosterUrl = apiItem.images.poster
            ' Also set standard poster fields for RowList compatibility
            contentNode.hdGridPosterUrl = apiItem.images.poster
            contentNode.sdGridPosterUrl = apiItem.images.poster
        end if
        
        if apiItem.images.banner <> invalid and apiItem.images.banner <> ""
            contentNode.hdBackgroundImageUrl = apiItem.images.banner
        end if
    end if
    
    ' Set video source (if available)
    if apiItem.sources <> invalid
        if apiItem.sources.primary <> invalid and apiItem.sources.primary <> ""
            contentNode.url = apiItem.sources.primary
        else if apiItem.sources.hls <> invalid and apiItem.sources.hls <> ""
            contentNode.url = apiItem.sources.hls
        end if
    end if
    
    ' Set content type
    if apiItem.type <> invalid
        contentNode.addField("contentType", "string", false)
        contentNode.contentType = apiItem.type
    end if
    
    ' Set type ID (important for series detection - typeId = 2 means series)
    if apiItem.typeId <> invalid
        contentNode.addField("typeId", "integer", false)
        contentNode.typeId = apiItem.typeId
    end if
    
    ' Store the numeric ID for series lookup
    if apiItem.id <> invalid
        contentNode.addField("contentId", "integer", false)
        contentNode.contentId = apiItem.id
    end if
    
    ' Set live flag
    if apiItem.live <> invalid
        contentNode.live = apiItem.live
    else
        contentNode.live = false
    end if
    
    ' Store original API data for reference
    contentNode.addField("apiData", "assocarray", false)
    contentNode.apiData = apiItem
    
    print "DynamicContentScreen.brs - [createContentNodeFromApiData] Created ContentNode:"
    print "  - Title: " + contentNode.title
    print "  - hdPosterUrl: " + FormatJson(contentNode.hdPosterUrl)
    print "  - Description: " + FormatJson(contentNode.description)
    
    return contentNode
end function

sub createContentRow(category as object, yPosition as integer, rowIndex as integer)
    print "DynamicContentScreen.brs - [createContentRow] Creating row for category: " + category.name
    
    ' Create row group
    rowGroup = CreateObject("roSGNode", "Group")
    rowGroup.id = "contentRow_" + rowIndex.ToStr()
    rowGroup.translation = [0, yPosition]
    
    ' Create category header
    categoryLabel = CreateObject("roSGNode", "Label")
    categoryLabel.text = category.name
    categoryLabel.color = "#ffffff"
    categoryLabel.font = "font:UrbanistBold"
    categoryLabel.translation = [0, 0]
    categoryLabel.width = 1760
    
    ' Set header font
    headerFont = CreateObject("roSGNode", "Font")
    headerFont.role = "font"
    headerFont.uri = "pkg:/images/UrbanistBold.ttf"
    headerFont.size = 28
    categoryLabel.font = headerFont
    
    rowGroup.appendChild(categoryLabel)
    
    ' Create horizontal scrolling group for content items
    contentScrollGroup = CreateObject("roSGNode", "Group")
    contentScrollGroup.id = "contentScroll_" + rowIndex.ToStr()
    contentScrollGroup.translation = [0, 50]
    
    ' Create individual content item components
    xPosition = 0
    itemIndex = 0
    
    for each item in category.items
        ' Create ContentItemComponent for each item
        contentItemComp = CreateObject("roSGNode", "ContentItemComponent")
        contentItemComp.id = "contentItem_" + rowIndex.ToStr() + "_" + itemIndex.ToStr()
        contentItemComp.translation = [xPosition, 0]
        contentItemComp.itemContent = item
        contentItemComp.focusable = true
        
        contentScrollGroup.appendChild(contentItemComp)
        
        xPosition = xPosition + 220 ' 200 width + 20 spacing
        itemIndex = itemIndex + 1
    end for
    
    rowGroup.appendChild(contentScrollGroup)
    
    ' Add row to content container
    m.contentContainer.appendChild(rowGroup)
    
    ' Store row reference
    rowInfo = CreateObject("roAssociativeArray")
    rowInfo.group = rowGroup
    rowInfo.scrollGroup = contentScrollGroup
    rowInfo.category = category.name
    rowInfo.itemCount = category.items.Count()
    
    m.contentRows.Push(rowInfo)
end sub

sub clearContentDisplay()
    print "DynamicContentScreen.brs - [clearContentDisplay] Clearing existing content"
    
    ' Remove all children from content container
    m.contentContainer.removeChildrenIndex(m.contentContainer.getChildCount(), 0)
    
    ' Clear row references
    m.contentRows = []
    m.currentRowIndex = 0
    m.currentItemIndex = 0
    m.focusedContentNode = invalid
end sub

sub setInitialFocus()
    print "DynamicContentScreen.brs - [setInitialFocus] Setting initial focus"
    
    ' Check if we're showing auth required message - this needs user interaction
    if m.showingAuthRequired = true
        print "DynamicContentScreen.brs - [setInitialFocus] Auth required state detected"
        
        ' Check for prettier auth dialog first (Account screen)
        if m.prettierAuthGroup <> invalid and m.prettierAuthGroup.visible = true
            print "DynamicContentScreen.brs - [setInitialFocus] Prettier auth dialog visible, setting focus"
            m.prettierAuthGroup.setFocus(true)
            return
        ' Check for regular auth dialog (User Channels)
        else if m.authRequiredGroup <> invalid
            print "DynamicContentScreen.brs - [setInitialFocus] Regular auth group exists, making it visible and setting focus"
            m.authRequiredGroup.visible = true  ' Ensure it's visible
            
            ' Set focus on the login button inside the auth group, not the group itself
            if m.userChannelsLoginCard <> invalid
                m.userChannelsLoginCard.setFocus(true)
                print "DynamicContentScreen.brs - [setInitialFocus] Focus set on User Channels login button"
            else
                m.authRequiredGroup.setFocus(true)
                print "DynamicContentScreen.brs - [setInitialFocus] Focus set on auth group (login button not found)"
            end if
            return
        else
            print "DynamicContentScreen.brs - [setInitialFocus] No auth group exists, creating auth dialog"
            ' Auth dialog doesn't exist, create it based on content type
            if m.top.contentTypeId = 6
                showPrettierAuthorizationMessage()
            else
                showAuthorizationRequiredMessage()
            end if
            return
        end if
    end if
    
    ' Check if we're showing Account page - handle focus on login button if needed
    if m.accountPageGroup <> invalid and m.accountPageGroup.visible = true
        print "DynamicContentScreen.brs - [setInitialFocus] Account page visible"
        if m.top.explicitContentFocusRequested = true and m.accountLoginButton <> invalid and m.accountLoginButton.visible = true
            print "DynamicContentScreen.brs - [setInitialFocus] Setting focus on Account login button"
            m.accountLoginButton.setFocus(true)
            m.top.explicitContentFocusRequested = false ' Reset the flag
        else
            print "DynamicContentScreen.brs - [setInitialFocus] Account page - returning focus to navigation"
            returnFocusToNavigation()
        end if
        return
    end if
    
    ' Only focus content if explicitly requested (e.g., user pressed RIGHT from navigation)
    ' We'll add a flag to indicate when content focus is actually wanted
    if m.top.explicitContentFocusRequested = true and m.contentRowList <> invalid and m.contentRowList.visible = true and m.contentRowList.content <> invalid and m.contentRowList.content.getChildCount() > 0
        print "DynamicContentScreen.brs - [setInitialFocus] Explicit content focus requested, setting focus on RowList"
        m.contentRowList.setFocus(true)
        m.top.explicitContentFocusRequested = false ' Reset the flag
        print "DynamicContentScreen.brs - [setInitialFocus] RowList focus after setFocus: " + m.contentRowList.hasFocus().ToStr()
        return
    end if
    
    ' For all other cases (initial screen load, tab switching), return focus to navigation
    print "DynamicContentScreen.brs - [setInitialFocus] Returning focus to navigation for tab switching"
    returnFocusToNavigation()
end sub

sub showNoContentState()
    print "DynamicContentScreen.brs - [showNoContentState] Showing no content message for contentTypeId: " + m.top.contentTypeId.ToStr()
    
    hideLoadingState()
    m.contentRowList.visible = false
    m.noContentGroup.visible = true
    
    ' Set dynamic message based on content type
    noContentLabel = m.top.findNode("noContentLabel")
    noContentSubLabel = m.top.findNode("noContentSubLabel")
    
    ' Content IDs from API: Home=13, Movies=1, Series=2, Live TV=3, User Channels=14
    if m.top.contentTypeId = 13
        noContentLabel.text = "Home content not available"
        noContentSubLabel.text = "Check back later for featured content"
    else if m.top.contentTypeId = 1
        noContentLabel.text = "Movies not available"
        noContentSubLabel.text = "Check back later for new movie releases"
    else if m.top.contentTypeId = 2
        noContentLabel.text = "Series not available for now"
        noContentSubLabel.text = "Check back later for new series content"
    else if m.top.contentTypeId = 3
        noContentLabel.text = "Live TV & DVR not available"
        noContentSubLabel.text = "Check your connection or try again later"
    else if m.top.contentTypeId = 14
        noContentLabel.text = "User Channels"
        noContentSubLabel.text = "Press RIGHT to login and access premium content"
    else
        noContentLabel.text = "Content not available for now"
        noContentSubLabel.text = "Check back later for updates"
    end if
    
    ' Make no content group focusable but don't set focus on it
    ' Focus should remain on navigation bar for continued navigation
    m.noContentGroup.focusable = true
    print "DynamicContentScreen.brs - [showNoContentState] No content state shown with message: " + noContentLabel.text
end sub

sub scrollToRow(rowIndex as integer)
    print "DynamicContentScreen.brs - [scrollToRow] Scrolling to row: " + rowIndex.ToStr()
    
    if m.contentContainer <> invalid and rowIndex >= 0 and rowIndex < m.contentRows.Count()
        ' Calculate the Y position to scroll to
        ' Each row is approximately 350 pixels apart
        targetY = -rowIndex * 350
        
        ' Animate scroll to the target position
        scrollAnimation = CreateObject("roSGNode", "Animation")
        scrollAnimation.duration = 0.3
        scrollAnimation.easeFunction = "outQuad"
        
        scrollInterpolator = CreateObject("roSGNode", "Vector2DFieldInterpolator")
        scrollInterpolator.key = [0.0, 1.0]
        scrollInterpolator.keyValue = [m.contentContainer.translation, [0, targetY]]
        scrollInterpolator.fieldToInterp = "contentContainer.translation"
        
        scrollAnimation.appendChild(scrollInterpolator)
        m.contentContainer.appendChild(scrollAnimation)
        scrollAnimation.control = "start"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "DynamicContentScreen.brs - [onKeyEvent] Key: " + key + ", Press: " + press.ToStr() + ", hasFocus: " + m.top.hasFocus().ToStr()
    if press
        ' Handle authentication required state
        if m.showingAuthRequired = true
            if key = "right"
                ' User wants to focus login button directly
                print "DynamicContentScreen.brs - [onKeyEvent] RIGHT key pressed - focusing login button"
                if m.userChannelsLoginCard <> invalid
                    m.userChannelsLoginCard.setFocus(true)
                    print "DynamicContentScreen.brs - [onKeyEvent] User Channels login card focused"
                else if m.authRequiredGroup <> invalid
                    m.authRequiredGroup.setFocus(true)
                    print "DynamicContentScreen.brs - [onKeyEvent] Auth required group focused"
                end if
                return true
            else if key = "OK"
                ' User wants to login
                print "DynamicContentScreen.brs - [onKeyEvent] User selected login from auth required screen"
                ' Check if we're using prettier auth dialog (Account) or regular auth dialog (User Channels)
                if m.prettierAuthGroup <> invalid and m.prettierAuthGroup.visible = true
                    print "DynamicContentScreen.brs - [onKeyEvent] Using prettier auth dialog for Account"
                else
                    print "DynamicContentScreen.brs - [onKeyEvent] Using regular auth dialog for User Channels"
                end if
                showLoginFromUserChannels()
                return true
            else if key = "back" or key = "left"
                ' User wants to return focus to navigation - DO NOT hide the content!
                ' The screen content should stay visible, only focus moves to navigation
                print "DynamicContentScreen.brs - [onKeyEvent] LEFT/BACK from auth screen - returning FOCUS to navigation (content stays visible)"
                
                ' DO NOT hide the auth dialog - it should remain visible!
                ' Only move focus to navigation bar
                returnFocusToNavigation()
                return true
            else if key = "up" or key = "down"
                ' Allow navigation between tabs even when showing auth required
                ' DO NOT intercept navigation keys - let navigation bar handle them completely
                print "DynamicContentScreen.brs - [onKeyEvent] Navigation key on auth required screen - NOT intercepting"
                print "DynamicContentScreen.brs - [onKeyEvent] Current contentTypeId: " + m.top.contentTypeId.ToStr()
                print "DynamicContentScreen.brs - [onKeyEvent] Letting navigation bar handle UP/DOWN key without interference"
                
                ' DO NOT hide the auth dialog! Content should stay visible, only navigation changes
                print "DynamicContentScreen.brs - [onKeyEvent] Auth dialog stays visible during tab navigation"
                
                ' Let navigation bar handle the key completely
                return false
            end if
            return true ' Consume all other keys when showing auth required
        end if
        
        ' Handle Account page state
        if m.accountPageGroup <> invalid and m.accountPageGroup.visible = true
            if key = "OK" and m.accountLoginButton <> invalid and m.accountLoginButton.visible = true and m.accountLoginButton.hasFocus()
                ' User wants to login from Account page
                print "DynamicContentScreen.brs - [onKeyEvent] User selected login from Account page"
                ' TODO: Add login functionality here
                return true
            else if key = "back" or key = "left"
                ' User wants to go back from Account page
                print "DynamicContentScreen.brs - [onKeyEvent] User selected back from Account page"
                returnFocusToNavigation()
                return true
            else if key = "up" or key = "down"
                ' Allow navigation between tabs from Account page
                print "DynamicContentScreen.brs - [onKeyEvent] Navigation key on Account page, returning focus to navigation"
                returnFocusToNavigation()
                return false ' Let navigation bar handle the key
            end if
            return false ' Don't consume other keys - let Account page handle them
        end if
        
        ' Handle no content state - allow navigation to continue
        if m.noContentGroup <> invalid and m.noContentGroup.visible = true
            if key = "back" or key = "left"
                ' User wants to go back from no content screen
                print "DynamicContentScreen.brs - [onKeyEvent] User selected back from no content screen"
                returnFocusToNavigation()
                return true
            else if key = "right" and m.top.contentTypeId = 14
                ' User wants to login for User Channels from no content screen
                print "DynamicContentScreen.brs - [onKeyEvent] RIGHT key on User Channels no content - showing auth dialog"
                showAuthorizationRequiredMessage()
                return true
            else if key = "up" or key = "down"
                ' Allow navigation between tabs even when showing no content
                print "DynamicContentScreen.brs - [onKeyEvent] Navigation key on no content screen, returning focus to navigation"
                returnFocusToNavigation()
                return false ' Let navigation bar handle the key
            end if
            return false ' Don't consume other keys - let navigation handle them
        end if
        
        if key = "back" then
            ' Return focus to navigation bar
            returnFocusToNavigation()
            return true
        else if key = "left" and m.contentRowList.hasFocus()
            ' Check if we're at the leftmost item, then return to navigation
            itemFocused = m.contentRowList.itemFocused
            print "DynamicContentScreen.brs - [onKeyEvent] LEFT key pressed, itemFocused: " + FormatJson(itemFocused)
            if itemFocused <> invalid and Type(itemFocused) = "roArray" and itemFocused.Count() >= 2
                if itemFocused[1] = 0 ' First item in row (leftmost)
                    print "DynamicContentScreen.brs - [onKeyEvent] At leftmost item (column 0), returning to navigation"
                    returnFocusToNavigation()
                    return true
                else
                    print "DynamicContentScreen.brs - [onKeyEvent] Not at leftmost item (column " + itemFocused[1].ToStr() + "), allowing RowList to handle LEFT"
                    return false ' Let RowList handle LEFT navigation within content
                end if
            else
                ' If no valid item focus, always return to navigation on left
                print "DynamicContentScreen.brs - [onKeyEvent] Cannot determine item position, returning to navigation as fallback"
                returnFocusToNavigation()
                return true
            end if
        else if key = "right"
            ' User wants to enter content from navigation
            if m.contentRowList <> invalid and m.contentRowList.visible = true
                print "DynamicContentScreen.brs - [onKeyEvent] User entering content from navigation"
                print "DynamicContentScreen.brs - [onKeyEvent] RowList current focus: " + m.contentRowList.hasFocus().ToStr()
                m.explicitContentFocusRequested = true
                m.contentRowList.setFocus(true)
                print "DynamicContentScreen.brs - [onKeyEvent] RowList focus after setFocus: " + m.contentRowList.hasFocus().ToStr()
                return true
            else
                print "DynamicContentScreen.brs - [onKeyEvent] RowList not available for focus - visible: " + m.contentRowList.visible.ToStr()
            end if
        end if
    end if
    ' Let RowList handle other navigation automatically
    return false
end function

sub showLoginFromUserChannels()
    ' Go directly to login flow (no signup option)
    print "DynamicContentScreen.brs - [showLoginFromUserChannels] Starting login flow directly"
    showUserChannelsLoginFlow()
end sub

sub onUserChannelsAuthDialogSelected()
    ' This function is kept for compatibility but simplified
    print "DynamicContentScreen.brs - [onUserChannelsAuthDialogSelected] Button selected: " + m.userChannelsAuthDialog.buttonSelected.ToStr()
    
    if m.userChannelsAuthDialog.buttonSelected = 0
        ' Login button pressed
        print "DynamicContentScreen.brs - [onUserChannelsAuthDialogSelected] Login selected"
        closeUserChannelsAuthDialog()
        showUserChannelsLoginFlow()
    else
        ' Cancel button pressed
        print "DynamicContentScreen.brs - [onUserChannelsAuthDialogSelected] Cancel selected"
        closeUserChannelsAuthDialog()
    end if
end sub

sub closeUserChannelsAuthDialog()
    if m.top.GetScene().dialog <> invalid
        m.top.GetScene().dialog.close = true
        m.top.GetScene().dialog = invalid
    end if
    print "DynamicContentScreen.brs - [closeUserChannelsAuthDialog] Authorization dialog closed"
end sub

sub showUserChannelsSignupFlow()
    print "DynamicContentScreen.brs - [showUserChannelsSignupFlow] Starting signup flow"
    
    ' Show username dialog first
    m.userChannelsUsernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.userChannelsUsernameDialog.title = "Create Account - Username"
    m.userChannelsUsernameDialog.text = ""
    m.userChannelsUsernameDialog.buttons = ["Next", "Cancel"]
    m.userChannelsUsernameDialog.observeField("buttonSelected", "onUserChannelsSignupUsernameSelected")
    m.userChannelsUsernameDialog.observeField("wasClosed", "onUserChannelsSignupDialogClosed")
    
    m.top.GetScene().dialog = m.userChannelsUsernameDialog
    m.top.GetScene().dialog.setFocus(true)
    
    print "DynamicContentScreen.brs - [showUserChannelsSignupFlow] Username dialog displayed"
end sub

sub showUserChannelsLoginFlow()
    print "DynamicContentScreen.brs - [showUserChannelsLoginFlow] Starting login flow"
    
    ' Show username dialog first
    m.userChannelsUsernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.userChannelsUsernameDialog.title = "Login - Username"
    m.userChannelsUsernameDialog.text = ""
    m.userChannelsUsernameDialog.buttons = ["Next", "Cancel"]
    m.userChannelsUsernameDialog.observeField("buttonSelected", "onUserChannelsLoginUsernameSelected")
    m.userChannelsUsernameDialog.observeField("wasClosed", "onUserChannelsLoginDialogClosed")
    
    m.top.GetScene().dialog = m.userChannelsUsernameDialog
    m.top.GetScene().dialog.setFocus(true)
    
    print "DynamicContentScreen.brs - [showUserChannelsLoginFlow] Username dialog displayed"
end sub

sub onUserChannelsSignupUsernameSelected()
    print "DynamicContentScreen.brs - [onUserChannelsSignupUsernameSelected] Button: " + m.userChannelsUsernameDialog.buttonSelected.ToStr()
    
    if m.userChannelsUsernameDialog.buttonSelected = 0 and m.userChannelsUsernameDialog.text.Len() > 0
        ' Next button with valid username
        m.userChannelsSignupUsername = m.userChannelsUsernameDialog.text
        m.userChannelsUsernameDialog.close = true
        showUserChannelsSignupPasswordDialog()
    else if m.userChannelsUsernameDialog.buttonSelected = 1
        ' Cancel button
        m.userChannelsUsernameDialog.close = true
        returnToUserChannelsAuth()
    else
        ' Invalid input
        m.userChannelsUsernameDialog.keyboard.textEditBox.hintText = "Please enter a valid username"
    end if
end sub

sub onUserChannelsLoginUsernameSelected()
    print "DynamicContentScreen.brs - [onUserChannelsLoginUsernameSelected] Button: " + m.userChannelsUsernameDialog.buttonSelected.ToStr()
    
    if m.userChannelsUsernameDialog.buttonSelected = 0 and m.userChannelsUsernameDialog.text.Len() > 0
        ' Next button with valid username
        m.userChannelsLoginUsername = m.userChannelsUsernameDialog.text
        m.userChannelsUsernameDialog.close = true
        showUserChannelsLoginPasswordDialog()
    else if m.userChannelsUsernameDialog.buttonSelected = 1
        ' Cancel button
        m.userChannelsUsernameDialog.close = true
        returnToUserChannelsAuth()
    else
        ' Invalid input
        m.userChannelsUsernameDialog.keyboard.textEditBox.hintText = "Please enter a valid username"
    end if
end sub

sub showUserChannelsSignupPasswordDialog()
    print "DynamicContentScreen.brs - [showUserChannelsSignupPasswordDialog] Showing password dialog for signup"
    
    m.userChannelsPasswordDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.userChannelsPasswordDialog.title = "Create Account - Password"
    m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = true
    m.userChannelsPasswordDialog.buttons = ["Create Account", "Show Password", "Hide Password", "Back"]
    m.userChannelsPasswordDialog.observeField("buttonSelected", "onUserChannelsSignupPasswordSelected")
    m.userChannelsPasswordDialog.observeField("wasClosed", "onUserChannelsSignupDialogClosed")
    
    m.top.GetScene().dialog = m.userChannelsPasswordDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub showUserChannelsLoginPasswordDialog()
    print "DynamicContentScreen.brs - [showUserChannelsLoginPasswordDialog] Showing password dialog for login"
    
    m.userChannelsPasswordDialog = CreateObject("roSGNode", "KeyboardDialog")
    m.userChannelsPasswordDialog.title = "Login - Password"
    m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = true
    m.userChannelsPasswordDialog.buttons = ["Login", "Show Password", "Hide Password", "Back"]
    m.userChannelsPasswordDialog.observeField("buttonSelected", "onUserChannelsLoginPasswordSelected")
    m.userChannelsPasswordDialog.observeField("wasClosed", "onUserChannelsLoginDialogClosed")
    
    m.top.GetScene().dialog = m.userChannelsPasswordDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onUserChannelsSignupPasswordSelected()
    buttonIndex = m.userChannelsPasswordDialog.buttonSelected
    
    if buttonIndex = 0 and m.userChannelsPasswordDialog.text.Len() > 0
        ' Create Account button
        m.userChannelsSignupPassword = m.userChannelsPasswordDialog.text
        m.userChannelsPasswordDialog.close = true
        processUserChannelsSignup()
    else if buttonIndex = 1
        ' Show Password
        m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = false
    else if buttonIndex = 2
        ' Hide Password
        m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = true
    else if buttonIndex = 3
        ' Back button
        m.userChannelsPasswordDialog.close = true
        showUserChannelsSignupFlow()
    else
        ' Invalid input
        m.userChannelsPasswordDialog.keyboard.textEditBox.hintText = "Please enter a valid password"
    end if
end sub

sub onUserChannelsLoginPasswordSelected()
    buttonIndex = m.userChannelsPasswordDialog.buttonSelected
    
    if buttonIndex = 0 and m.userChannelsPasswordDialog.text.Len() > 0
        ' Login button
        m.userChannelsLoginPassword = m.userChannelsPasswordDialog.text
        m.userChannelsPasswordDialog.close = true
        processUserChannelsLogin()
    else if buttonIndex = 1
        ' Show Password
        m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = false
    else if buttonIndex = 2
        ' Hide Password
        m.userChannelsPasswordDialog.keyboard.textEditBox.secureMode = true
    else if buttonIndex = 3
        ' Back button
        m.userChannelsPasswordDialog.close = true
        showUserChannelsLoginFlow()
    else
        ' Invalid input
        m.userChannelsPasswordDialog.keyboard.textEditBox.hintText = "Please enter a valid password"
    end if
end sub

sub processUserChannelsSignup()
    print "DynamicContentScreen.brs - [processUserChannelsSignup] Processing signup for: " + m.userChannelsSignupUsername
    
    ' Show progress dialog
    m.userChannelsProgressDialog = CreateObject("roSGNode", "ProgressDialog")
    m.userChannelsProgressDialog.title = "Creating Account..."
    m.top.GetScene().dialog = m.userChannelsProgressDialog
    
    ' Use actual SignUpApi to perform signup
    m.userChannelsSignupApi = CreateObject("roSGNode", "SignUpApi")
    m.userChannelsSignupApi.email = m.userChannelsSignupUsername
    m.userChannelsSignupApi.password = m.userChannelsSignupPassword
    m.userChannelsSignupApi.repeatPassword = m.userChannelsSignupPassword  ' Use same password for repeat
    m.userChannelsSignupApi.observeField("responseData", "onUserChannelsSignupResponse")
    m.userChannelsSignupApi.control = "RUN"
    
    print "DynamicContentScreen.brs - [processUserChannelsSignup] Signup API request sent"
end sub

sub onUserChannelsSignupResponse()
    print "DynamicContentScreen.brs - [onUserChannelsSignupResponse] Signup API response received"
    
    ' Close progress dialog
    if m.userChannelsProgressDialog <> invalid
        m.userChannelsProgressDialog.close = true
    end if
    
    if m.userChannelsSignupApi <> invalid
        response = m.userChannelsSignupApi.responseData
        print "DynamicContentScreen.brs - [onUserChannelsSignupResponse] Response: " + response
        
        if response = "Success"
            print "DynamicContentScreen.brs - [onUserChannelsSignupResponse] Signup successful!"
            showUserChannelsSignupSuccess()
        else
            print "DynamicContentScreen.brs - [onUserChannelsSignupResponse] Signup failed - " + response
            showUserChannelsSignupError("Signup failed. Please try again with a different email.")
        end if
    end if
end sub

sub showUserChannelsSignupError(errorMessage as string)
    print "DynamicContentScreen.brs - [showUserChannelsSignupError] Showing error: " + errorMessage
    
    m.userChannelsErrorDialog = CreateObject("roSGNode", "BackDialog")
    m.userChannelsErrorDialog.title = "Signup Failed"
    m.userChannelsErrorDialog.message = errorMessage
    m.userChannelsErrorDialog.buttons = ["Try Again", "Cancel"]
    m.userChannelsErrorDialog.observeField("buttonSelected", "onUserChannelsSignupErrorSelected")
    
    m.top.GetScene().dialog = m.userChannelsErrorDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onUserChannelsSignupErrorSelected()
    buttonIndex = m.userChannelsErrorDialog.buttonSelected
    m.userChannelsErrorDialog.close = true
    
    if buttonIndex = 0
        ' Try Again - show signup flow again
        showUserChannelsSignupFlow()
    else
        ' Cancel - return to auth required screen
        returnToUserChannelsAuth()
    end if
end sub

sub processUserChannelsLogin()
    print "DynamicContentScreen.brs - [processUserChannelsLogin] Processing login for: " + m.userChannelsLoginUsername
    
    ' Show progress dialog
    m.userChannelsProgressDialog = CreateObject("roSGNode", "ProgressDialog")
    m.userChannelsProgressDialog.title = "Logging in..."
    m.top.GetScene().dialog = m.userChannelsProgressDialog
    
    ' Use actual LoginScreenApi to perform login
    m.userChannelsLoginApi = CreateObject("roSGNode", "LoginScreenApi")
    m.userChannelsLoginApi.email = m.userChannelsLoginUsername
    m.userChannelsLoginApi.password = m.userChannelsLoginPassword
    m.userChannelsLoginApi.observeField("responseData", "onUserChannelsLoginResponse")
    m.userChannelsLoginApi.control = "RUN"
    
    print "DynamicContentScreen.brs - [processUserChannelsLogin] Login API request sent"
end sub

sub onUserChannelsLoginResponse()
    print "DynamicContentScreen.brs - [onUserChannelsLoginResponse] Login API response received"
    
    ' Close progress dialog
    if m.userChannelsProgressDialog <> invalid
        m.userChannelsProgressDialog.close = true
    end if
    
    if m.userChannelsLoginApi <> invalid
        response = m.userChannelsLoginApi.responseData
        print "DynamicContentScreen.brs - [onUserChannelsLoginResponse] Response: " + response
        
        if response = "Success"
            print "DynamicContentScreen.brs - [onUserChannelsLoginResponse] Login successful!"
            showUserChannelsLoginSuccess()
        else if response = "405"
            print "DynamicContentScreen.brs - [onUserChannelsLoginResponse] Login failed - method not allowed"
            showUserChannelsLoginError("Login failed. Please try again later.")
        else
            print "DynamicContentScreen.brs - [onUserChannelsLoginResponse] Login failed - " + response
            showUserChannelsLoginError("Invalid email or password. Please try again.")
        end if
    end if
end sub

sub showUserChannelsLoginError(errorMessage as string)
    print "DynamicContentScreen.brs - [showUserChannelsLoginError] Showing error: " + errorMessage
    
    m.userChannelsErrorDialog = CreateObject("roSGNode", "BackDialog")
    m.userChannelsErrorDialog.title = "Login Failed"
    m.userChannelsErrorDialog.message = errorMessage
    m.userChannelsErrorDialog.buttons = ["Try Again", "Cancel"]
    m.userChannelsErrorDialog.observeField("buttonSelected", "onUserChannelsLoginErrorSelected")
    
    m.top.GetScene().dialog = m.userChannelsErrorDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onUserChannelsLoginErrorSelected()
    buttonIndex = m.userChannelsErrorDialog.buttonSelected
    m.userChannelsErrorDialog.close = true
    
    if buttonIndex = 0
        ' Try Again - show login flow again
        showUserChannelsLoginFlow()
    else
        ' Cancel - return to auth required screen
        returnToUserChannelsAuth()
    end if
end sub

sub showUserChannelsSignupSuccess()
    m.userChannelsSuccessDialog = CreateObject("roSGNode", "BackDialog")
    m.userChannelsSuccessDialog.title = "Account Created!"
    m.userChannelsSuccessDialog.message = "Your account has been created successfully. You now have access to User Channels."
    m.userChannelsSuccessDialog.buttons = ["OK"]
    m.userChannelsSuccessDialog.observeField("buttonSelected", "onUserChannelsSuccessDialogSelected")
    
    m.top.GetScene().dialog = m.userChannelsSuccessDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub showUserChannelsLoginSuccess()
    m.userChannelsSuccessDialog = CreateObject("roSGNode", "BackDialog")
    m.userChannelsSuccessDialog.title = "Login Successful!"
    m.userChannelsSuccessDialog.message = "You have been logged in successfully. Welcome back to User Channels!"
    m.userChannelsSuccessDialog.buttons = ["OK"]
    m.userChannelsSuccessDialog.observeField("buttonSelected", "onUserChannelsSuccessDialogSelected")
    
    m.top.GetScene().dialog = m.userChannelsSuccessDialog
    m.top.GetScene().dialog.setFocus(true)
end sub

sub onUserChannelsSuccessDialogSelected()
    m.userChannelsSuccessDialog.close = true
    ' Clear auth required state and reload User Channels content
    m.showingAuthRequired = false
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
    end if
    ' Reload User Channels content
    m.top.contentTypeId = 14  ' Set to User Channels
    loadContentForType()  ' Reload content
end sub

sub onUserChannelsSignupDialogClosed()
    returnToUserChannelsAuth()
end sub

sub onUserChannelsLoginDialogClosed()
    returnToUserChannelsAuth()
end sub

sub returnToUserChannelsAuth()
    print "DynamicContentScreen.brs - [returnToUserChannelsAuth] Returning to User Channels auth screen"
    if m.userChannelsLoginCard <> invalid
        m.userChannelsLoginCard.setFocus(true)
    else if m.authRequiredGroup <> invalid
        m.authRequiredGroup.setFocus(true)
    end if
end sub

sub onLoginDialogButtonSelected()
    scene = m.top.getScene()
    if scene <> invalid and scene.dialog <> invalid
        dialog = scene.dialog
        buttonIndex = dialog.buttonSelected
        
        print "DynamicContentScreen.brs - [onLoginDialogButtonSelected] Button selected: " + buttonIndex.ToStr()
        
        if buttonIndex = 0
            ' Login button selected
            print "DynamicContentScreen.brs - [onLoginDialogButtonSelected] User selected Login"
            dialog.close = true
            showUsernamePasswordDialog()
        else if buttonIndex = 1
            ' Sign Up button selected
            print "DynamicContentScreen.brs - [onLoginDialogButtonSelected] User selected Sign Up"
            dialog.close = true
            showSignUpDialog()
        else if buttonIndex = 2
            ' Cancel button selected
            print "DynamicContentScreen.brs - [onLoginDialogButtonSelected] User selected Cancel"
            dialog.close = true
            ' Stay on current screen with auth required message
        end if
    end if
end sub

sub showUsernamePasswordDialog()
    ' Show username/password login dialog
    print "DynamicContentScreen.brs - [showUsernamePasswordDialog] Showing username dialog"
    
    ' Create keyboard dialog for username
    usernameDialog = CreateObject("roSGNode", "KeyboardDialog")
    usernameDialog.title = "Enter Username"
    usernameDialog.text = ""
    usernameDialog.buttons = ["Next", "Cancel"]
    
    scene = m.top.getScene()
    if scene <> invalid
        scene.dialog = usernameDialog
        usernameDialog.observeField("buttonSelected", "onUsernameDialogButtonSelected")
        usernameDialog.setFocus(true)
    end if
end sub

sub onUsernameDialogButtonSelected()
    scene = m.top.getScene()
    if scene <> invalid and scene.dialog <> invalid
        dialog = scene.dialog
        buttonIndex = dialog.buttonSelected
        
        if buttonIndex = 0 and dialog.text.Len() > 0
            ' Next button with valid username
            m.loginUsername = dialog.text
            dialog.close = true
            showPasswordDialog()
        else if buttonIndex = 1
            ' Cancel button
            dialog.close = true
        end if
    end if
end sub

sub showPasswordDialog()
    ' Show password dialog
    print "DynamicContentScreen.brs - [showPasswordDialog] Showing password dialog"
    
    passwordDialog = CreateObject("roSGNode", "KeyboardDialog")
    passwordDialog.title = "Enter Password"
    passwordDialog.text = ""
    passwordDialog.secure = true
    passwordDialog.buttons = ["Login", "Cancel"]
    
    scene = m.top.getScene()
    if scene <> invalid
        scene.dialog = passwordDialog
        passwordDialog.observeField("buttonSelected", "onPasswordDialogButtonSelected")
        passwordDialog.setFocus(true)
    end if
end sub

sub onPasswordDialogButtonSelected()
    scene = m.top.getScene()
    if scene <> invalid and scene.dialog <> invalid
        dialog = scene.dialog
        buttonIndex = dialog.buttonSelected
        
        if buttonIndex = 0 and dialog.text.Len() > 0
            ' Login button with valid password
            m.loginPassword = dialog.text
            dialog.close = true
            performLogin(m.loginUsername, m.loginPassword)
        else if buttonIndex = 1
            ' Cancel button
            dialog.close = true
        end if
    end if
end sub

sub showSignUpDialog()
    ' TODO: Implement sign up dialog
    print "DynamicContentScreen.brs - [showSignUpDialog] Sign up not implemented yet"
end sub

sub performLogin(username as string, password as string)
    ' TODO: Implement actual login API call
    print "DynamicContentScreen.brs - [performLogin] Performing login for user: " + username
    
    ' For now, just show a success message and reload content
    ' In real implementation, this would call the login API
    print "DynamicContentScreen.brs - [performLogin] Login successful (mock), reloading content"
    
    ' Hide auth required message and reload content
    m.showingAuthRequired = false
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
    end if
    
    ' Reload content for User Channels
    loadContentForType()
end sub

function handleUpKey() as boolean
    if m.contentRows.Count() > 0 and m.currentRowIndex > 0
        ' Move to previous row
        m.currentRowIndex = m.currentRowIndex - 1
        newRow = m.contentRows[m.currentRowIndex]
        if newRow.scrollGroup <> invalid and newRow.scrollGroup.getChildCount() > 0
            ' Focus on the same item index in the new row, or last item if row is shorter
            itemIndex = m.currentItemIndex
            if itemIndex >= newRow.scrollGroup.getChildCount()
                itemIndex = newRow.scrollGroup.getChildCount() - 1
            end if
            
            newContentItem = newRow.scrollGroup.getChild(itemIndex)
            if newContentItem <> invalid
                newContentItem.setFocus(true)
                m.focusedContentNode = newContentItem
                m.currentItemIndex = itemIndex
                return true
            end if
        end if
    end if
    return false
end function

function handleDownKey() as boolean
    if m.contentRows.Count() > 0 and m.currentRowIndex < m.contentRows.Count() - 1
        ' Move to next row
        m.currentRowIndex = m.currentRowIndex + 1
        newRow = m.contentRows[m.currentRowIndex]
        if newRow.scrollGroup <> invalid and newRow.scrollGroup.getChildCount() > 0
            ' Focus on the same item index in the new row, or last item if row is shorter
            itemIndex = m.currentItemIndex
            if itemIndex >= newRow.scrollGroup.getChildCount()
                itemIndex = newRow.scrollGroup.getChildCount() - 1
            end if
            
            newContentItem = newRow.scrollGroup.getChild(itemIndex)
            if newContentItem <> invalid
                newContentItem.setFocus(true)
                m.focusedContentNode = newContentItem
                m.currentItemIndex = itemIndex
                return true
            end if
        end if
    end if
    return false
end function

function handleLeftKey() as boolean
    if m.contentRows.Count() > 0 and m.currentItemIndex > 0
        ' Move to previous item in current row
        currentRow = m.contentRows[m.currentRowIndex]
        if currentRow.scrollGroup <> invalid
            m.currentItemIndex = m.currentItemIndex - 1
            newContentItem = currentRow.scrollGroup.getChild(m.currentItemIndex)
            if newContentItem <> invalid
                newContentItem.setFocus(true)
                m.focusedContentNode = newContentItem
                return true
            end if
        end if
    else if m.currentItemIndex = 0
        ' At the leftmost item, return focus to navigation bar
        returnFocusToNavigation()
        return true
    end if
    return false
end function

sub returnFocusToNavigation()
    print "DynamicContentScreen.brs - [returnFocusToNavigation] Returning focus to navigation bar"
    print "DynamicContentScreen.brs - [returnFocusToNavigation] Current screen has focus: " + m.top.hasFocus().ToStr()
    
    ' Get parent scene using a working approach
    parentScene = m.top.getParent()
    
    ' Navigate up the hierarchy to find the scene
    while parentScene <> invalid
        print "DynamicContentScreen.brs - [returnFocusToNavigation] Checking parent: " + Type(parentScene).ToStr()
        ' Check if this node has the navigation bar (indicating it's the scene)
        navBar = parentScene.findNode("dynamic_navigation_bar")
        if navBar <> invalid
            ' Found the scene with navigation bar
            print "DynamicContentScreen.brs - [returnFocusToNavigation] Found navigation bar, setting focus"
            print "DynamicContentScreen.brs - [returnFocusToNavigation] NavBar current focus state: " + navBar.hasFocus().ToStr()
            print "DynamicContentScreen.brs - [returnFocusToNavigation] NavBar navHasFocus: " + navBar.navHasFocus.ToStr()
            
            ' Don't clear auth state when returning to navigation during temporary navigation
            ' Auth state should only be cleared when user explicitly cancels or authenticates
            ' if m.authRequiredGroup <> invalid
            '     m.authRequiredGroup.visible = false
            ' end if
            
            ' Ensure this content screen releases focus completely
            m.top.setFocus(false)
            if m.contentRowList <> invalid
                m.contentRowList.setFocus(false)
            end if
            if m.noContentGroup <> invalid
                m.noContentGroup.setFocus(false)
            end if
            if m.loadingGroup <> invalid
                m.loadingGroup.setFocus(false)
            end if
            
            ' Check if we're in initial load phase to prevent index changes during app startup
            isInitialLoad = false
            if parentScene.callFunc <> invalid
                isInitialLoad = parentScene.callFunc("isInitialLoadPhase")
            end if
            
            if isInitialLoad = true
                print "DynamicContentScreen.brs - [returnFocusToNavigation] In initial load phase, skipping selectedIndex changes"
            else
                ' IMPORTANT: Do NOT try to "correct" selectedIndex based on contentTypeId
                ' The navigation index depends on the dynamic order of items from the API,
                ' which can vary (especially when authenticated with Age Restricted/Personal tabs)
                ' Trust that selectedIndex was set correctly when the user navigated to this screen
                currentNavIndex = navBar.selectedIndex
                print "DynamicContentScreen.brs - [returnFocusToNavigation] Current navBar.selectedIndex: " + currentNavIndex.ToStr()
                print "DynamicContentScreen.brs - [returnFocusToNavigation] ContentTypeId: " + m.top.contentTypeId.ToStr()
                print "DynamicContentScreen.brs - [returnFocusToNavigation] Keeping current selectedIndex - not attempting correction (dynamic navigation order)"
            end if
            
            ' Set navigation bar state and focus
            navBar.navHasFocus = true
            navBar.setFocus(true)
            
            ' Force focus update to ensure proper visual state
            navBar.callFunc("focusUpdated")
            
            ' If navigation bar still doesn't have focus, force it
            if not navBar.hasFocus()
                print "DynamicContentScreen.brs - [returnFocusToNavigation] Navigation bar still no focus, calling forceFocus"
                navBar.callFunc("forceFocus")
            end if
            
            print "DynamicContentScreen.brs - [returnFocusToNavigation] After setting focus - NavBar has focus: " + navBar.hasFocus().ToStr()
            print "DynamicContentScreen.brs - [returnFocusToNavigation] After setting focus - NavBar navHasFocus: " + navBar.navHasFocus.ToStr()
            print "DynamicContentScreen.brs - [returnFocusToNavigation] Focus returned to navigation bar successfully"
            return
        end if
        parentScene = parentScene.getParent()
    end while
    
    print "DynamicContentScreen.brs - [returnFocusToNavigation] ERROR: Could not find navigation bar"
end sub

function handleRightKey() as boolean
    if m.contentRows.Count() > 0
        currentRow = m.contentRows[m.currentRowIndex]
        if currentRow.scrollGroup <> invalid and m.currentItemIndex < currentRow.scrollGroup.getChildCount() - 1
            ' Move to next item in current row
            m.currentItemIndex = m.currentItemIndex + 1
            newContentItem = currentRow.scrollGroup.getChild(m.currentItemIndex)
            if newContentItem <> invalid
                newContentItem.setFocus(true)
                m.focusedContentNode = newContentItem
                return true
            end if
        end if
    end if
    return false
end function

function handleOKKey() as boolean
    print "DynamicContentScreen.brs - [handleOKKey] Content item selected"
    
    if m.focusedContentNode <> invalid and m.focusedContentNode.itemFocused <> invalid
        selectedIndex = m.focusedContentNode.itemFocused
        print "DynamicContentScreen.brs - [handleOKKey] Selected item index: " + selectedIndex.ToStr()
        
        ' Get the selected content item
        if m.currentRowIndex < m.contentRows.Count()
            currentRow = m.contentRows[m.currentRowIndex]
            if currentRow.category <> invalid and selectedIndex >= 0
                ' TODO: Handle content playback
                print "DynamicContentScreen.brs - [handleOKKey] Playing content from category: " + currentRow.category
                return true
            end if
        end if
    end if
    
    return false
end function

function checkAuthenticationForUserChannels() as boolean
    ' Check if user is authenticated for User Channels access
    print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] ========== CHECKING AUTH =========="
    authData = RetrieveAuthData()
    
    if authData = invalid
        print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData is INVALID"
        return false
    end if
    
    print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData exists, checking fields..."
    print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData type: " + Type(authData)
    
    ' Log all available fields in authData
    authDataInterface = GetInterface(authData, "ifAssociativeArray")
    if authDataInterface <> invalid
        print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData keys:"
        for each key in authData.Keys()
            print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels]   - " + key + ": " + Type(authData[key])
        end for
    end if
    
    ' Check isauth field
    if authData.isauth <> invalid
        print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData.isauth = " + authData.isauth.ToStr()
        print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] authData.isauth type: " + Type(authData.isauth)
        
        if authData.isauth = 1
            print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] ✓ User IS authenticated (isauth = 1)"
            return true
        else if authData.isauth = true
            print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] ✓ User IS authenticated (isauth = true)"
            return true
        else
            print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] ✗ User NOT authenticated (isauth = " + authData.isauth.ToStr() + ")"
            return false
        end if
    else
        print "DynamicContentScreen.brs - [checkAuthenticationForUserChannels] ✗ authData.isauth field is INVALID"
        return false
    end if
end function

sub showAuthorizationRequiredMessage()
    ' Show modern authorization UI similar to Account screen
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] *** SHOWING MODERN AUTH UI ***"
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] ContentTypeId: " + m.top.contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Current showingAuthRequired: " + m.showingAuthRequired.ToStr()
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] AuthRequiredGroup exists: " + (m.authRequiredGroup <> invalid).ToStr()
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Screen visible: " + m.top.visible.ToStr()
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    
    hideLoadingState()
    m.contentRowList.visible = false
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Hidden content list and loading"
    
    ' Create modern authorization UI
    if m.authRequiredGroup = invalid
        m.authRequiredGroup = CreateObject("roSGNode", "Group")
        m.authRequiredGroup.id = "authRequiredGroup"
        m.authRequiredGroup.translation = [40, 60]  ' Adjust for dynamic content screen padding (20px base + 20px margin)
        m.authRequiredGroup.focusable = true
        
        ' Header section
        headerGroup = CreateObject("roSGNode", "Group")
        headerGroup.translation = [0, 0]
        
        ' Main title
        titleLabel = CreateObject("roSGNode", "Label")
        titleLabel.text = "User Channels"
        titleLabel.color = "#4FC3F7"
        titleLabel.font = "font:UrbanistBold"
        titleLabel.translation = [0, 0]
        
        titleFont = CreateObject("roSGNode", "Font")
        titleFont.role = "font"
        titleFont.uri = "pkg:/images/UrbanistBold.ttf"
        titleFont.size = 56
        titleLabel.font = titleFont
        
        headerGroup.appendChild(titleLabel)
        
        ' Subtitle
        subtitleLabel = CreateObject("roSGNode", "Label")
        subtitleLabel.text = "Access premium channels and exclusive content"
        subtitleLabel.color = "#CCCCCC"
        subtitleLabel.font = "font:UrbanistMedium"
        subtitleLabel.translation = [0, 70]
        
        subtitleFont = CreateObject("roSGNode", "Font")
        subtitleFont.role = "font"
        subtitleFont.uri = "pkg:/images/UrbanistMedium.ttf"
        subtitleFont.size = 28
        subtitleLabel.font = subtitleFont
        
        headerGroup.appendChild(subtitleLabel)
        m.authRequiredGroup.appendChild(headerGroup)
        
        ' Authentication status card
        statusCard = CreateObject("roSGNode", "Group")
        statusCard.translation = [0, 120]  ' Match Account screen: 180 - 60 = 120 relative
        
        ' Card background
        statusCardBg = CreateObject("roSGNode", "Rectangle")
        statusCardBg.width = 600
        statusCardBg.height = 120
        statusCardBg.color = "#1a1f2e"
        statusCardBg.translation = [0, 0]
        statusCard.appendChild(statusCardBg)
        
        ' Status indicator
        statusIndicator = CreateObject("roSGNode", "Rectangle")
        statusIndicator.width = 8
        statusIndicator.height = 120
        statusIndicator.color = "#FF5722"  ' Red for not authenticated
        statusIndicator.translation = [0, 0]
        statusCard.appendChild(statusIndicator)
        
        ' Status content
        statusContent = CreateObject("roSGNode", "Group")
        statusContent.translation = [30, 20]
        
        statusTitleLabel = CreateObject("roSGNode", "Label")
        statusTitleLabel.text = "Authentication Required"
        statusTitleLabel.color = "#FFFFFF"
        statusTitleLabel.font = "font:UrbanistBold"
        statusTitleLabel.translation = [0, 0]
        
        statusTitleFont = CreateObject("roSGNode", "Font")
        statusTitleFont.role = "font"
        statusTitleFont.uri = "pkg:/images/UrbanistBold.ttf"
        statusTitleFont.size = 28
        statusTitleLabel.font = statusTitleFont
        
        statusContent.appendChild(statusTitleLabel)
        
        statusValueLabel = CreateObject("roSGNode", "Label")
        statusValueLabel.text = "Please log in to access User Channels"
        statusValueLabel.color = "#CCCCCC"
        statusValueLabel.font = "font:UrbanistMedium"
        statusValueLabel.translation = [0, 40]
        
        statusValueFont = CreateObject("roSGNode", "Font")
        statusValueFont.role = "font"
        statusValueFont.uri = "pkg:/images/UrbanistMedium.ttf"
        statusValueFont.size = 24
        statusValueLabel.font = statusValueFont
        
        statusContent.appendChild(statusValueLabel)
        
        statusHintLabel = CreateObject("roSGNode", "Label")
        statusHintLabel.text = "Select login button below to continue"
        statusHintLabel.color = "#888888"
        statusHintLabel.font = "font:UrbanistMedium"
        statusHintLabel.translation = [0, 70]
        
        statusHintFont = CreateObject("roSGNode", "Font")
        statusHintFont.role = "font"
        statusHintFont.uri = "pkg:/images/UrbanistMedium.ttf"
        statusHintFont.size = 18
        statusHintLabel.font = statusHintFont
        
        statusContent.appendChild(statusHintLabel)
        statusCard.appendChild(statusContent)
        m.authRequiredGroup.appendChild(statusCard)
        
        ' Login action card
        loginCard = CreateObject("roSGNode", "Group")
        loginCard.translation = [0, 270]  ' Match Account screen: 330 - 60 = 270 relative
        loginCard.focusable = true
        
        ' Card background
        loginCardBg = CreateObject("roSGNode", "Rectangle")
        loginCardBg.width = 600
        loginCardBg.height = 100
        loginCardBg.color = "#1a1f2e"
        loginCardBg.translation = [0, 0]
        loginCard.appendChild(loginCardBg)
        
        ' Focus border
        m.userChannelsLoginFocusBorder = CreateObject("roSGNode", "Poster")
        m.userChannelsLoginFocusBorder.uri = "pkg:/images/png/button_focused_2px.9.png"
        m.userChannelsLoginFocusBorder.blendColor = "0x6366f1FF"
        m.userChannelsLoginFocusBorder.width = 600
        m.userChannelsLoginFocusBorder.height = 100
        m.userChannelsLoginFocusBorder.translation = [0, 0]
        m.userChannelsLoginFocusBorder.visible = false
        loginCard.appendChild(m.userChannelsLoginFocusBorder)
        
        ' Action content
        loginContent = CreateObject("roSGNode", "Group")
        loginContent.translation = [30, 20]
        
        loginIcon = CreateObject("roSGNode", "Poster")
        loginIcon.uri = "pkg:/images/png/login.png"
        loginIcon.width = 60
        loginIcon.height = 60
        loginIcon.translation = [0, 0]
        loginIcon.loadDisplayMode = "scaleToZoom"
        loginContent.appendChild(loginIcon)
        
        loginTextLabel = CreateObject("roSGNode", "Label")
        loginTextLabel.text = "Log In"
        loginTextLabel.color = "#FFFFFF"
        loginTextLabel.font = "font:UrbanistBold"
        loginTextLabel.translation = [80, 8]
        
        loginTextFont = CreateObject("roSGNode", "Font")
        loginTextFont.role = "font"
        loginTextFont.uri = "pkg:/images/UrbanistBold.ttf"
        loginTextFont.size = 32
        loginTextLabel.font = loginTextFont
        
        loginContent.appendChild(loginTextLabel)
        
        loginDescLabel = CreateObject("roSGNode", "Label")
        loginDescLabel.text = "Access your premium channels"
        loginDescLabel.color = "#CCCCCC"
        loginDescLabel.font = "font:UrbanistMedium"
        loginDescLabel.translation = [80, 45]
        
        loginDescFont = CreateObject("roSGNode", "Font")
        loginDescFont.role = "font"
        loginDescFont.uri = "pkg:/images/UrbanistMedium.ttf"
        loginDescFont.size = 20
        loginDescLabel.font = loginDescFont
        
        loginContent.appendChild(loginDescLabel)
        loginCard.appendChild(loginContent)
        
        ' Set up focus handling for login card
        loginCard.observeField("focusedChild", "onUserChannelsLoginFocusChanged")
        
        m.authRequiredGroup.appendChild(loginCard)
        m.userChannelsLoginCard = loginCard
        
        ' Add to main screen
        m.top.appendChild(m.authRequiredGroup)
    end if
    
    m.authRequiredGroup.visible = true
    m.noContentGroup.visible = false
    
    ' Set flag to handle OK key for login
    m.showingAuthRequired = true
    
    ' Set focus on the login card so user can interact with it
    if m.userChannelsLoginCard <> invalid
        m.userChannelsLoginCard.setFocus(true)
        print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Focus set on login card"
    else
        m.authRequiredGroup.setFocus(true)
        print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] Focus set on auth required group"
    end if
    
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] *** MODERN AUTH UI SETUP COMPLETE ***"
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] AuthRequiredGroup visible: " + m.authRequiredGroup.visible.ToStr()
    print "DynamicContentScreen.brs - [showAuthorizationRequiredMessage] ShowingAuthRequired: " + m.showingAuthRequired.ToStr()
end sub

function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        currentTime = CreateObject("roDateTime").asSeconds()
        ' Check if the data is expired
        if currentTime <= data.expiry
            ' Data is valid
            return data
        else
            ' Data is expired
            return invalid
        end if
    else
        ' No valid data found
        return invalid
    end if
end function

function RegRead(key, section = invalid)
    if section = invalid section = "Default"
    sec = CreateObject("roRegistrySection", section)
    if sec.Exists(key) return sec.Read(key)
    return sec.Read(key)
end function

sub showAccountPage()
    print "DynamicContentScreen.brs - [showAccountPage] *** SHOWING ACCOUNT PAGE ***"
    print "DynamicContentScreen.brs - [showAccountPage] ContentTypeId: " + m.top.contentTypeId.ToStr()
    print "DynamicContentScreen.brs - [showAccountPage] Screen visible: " + m.top.visible.ToStr()
    print "DynamicContentScreen.brs - [showAccountPage] Screen children count: " + m.top.getChildCount().ToStr()
    
    ' Hide other content AND the main background
    print "DynamicContentScreen.brs - [showAccountPage] Hiding other content elements"
    hideLoadingState()
    m.contentRowList.visible = false
    m.noContentGroup.visible = false
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
        print "DynamicContentScreen.brs - [showAccountPage] Hidden auth required group"
    end if
    
    ' Hide the main XML background rectangle that's covering our content
    backgroundRect = m.top.findNode("backgroundRect")
    print "DynamicContentScreen.brs - [showAccountPage] Background rect found: " + (backgroundRect <> invalid).ToStr()
    if backgroundRect <> invalid
        backgroundRect.visible = false
        print "DynamicContentScreen.brs - [showAccountPage] Hidden main background rectangle"
        print "DynamicContentScreen.brs - [showAccountPage] Background rect visible now: " + backgroundRect.visible.ToStr()
    else
        print "DynamicContentScreen.brs - [showAccountPage] ERROR: Could not find backgroundRect node"
    end if
    
    ' Force recreation of account page for debugging
    if m.accountPageGroup <> invalid
        print "DynamicContentScreen.brs - [showAccountPage] Removing existing account page"
        m.top.removeChild(m.accountPageGroup)
        m.accountPageGroup = invalid
    end if
    
    ' Create account page
    print "DynamicContentScreen.brs - [showAccountPage] Creating new account page"
    createAccountPageUI()
    
    ' Update account status
    updateAccountStatus()
    
    ' Show account page
    m.accountPageGroup.visible = true
    print "DynamicContentScreen.brs - [showAccountPage] Account page displayed"
    print "DynamicContentScreen.brs - [showAccountPage] Account page visible: " + m.accountPageGroup.visible.ToStr()
    print "DynamicContentScreen.brs - [showAccountPage] Account page translation: [" + m.accountPageGroup.translation[0].ToStr() + ", " + m.accountPageGroup.translation[1].ToStr() + "]"
    print "DynamicContentScreen.brs - [showAccountPage] Account page opacity: " + m.accountPageGroup.opacity.ToStr()
    print "DynamicContentScreen.brs - [showAccountPage] Main screen translation: [" + m.top.translation[0].ToStr() + ", " + m.top.translation[1].ToStr() + "]"
    
    ' Final verification - check if Account page is still there and visible
    if m.accountPageGroup <> invalid
        print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: Account page exists"
        print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: Account page children: " + m.accountPageGroup.getChildCount().ToStr()
        print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: Account page parent: " + (m.accountPageGroup.getParent() <> invalid).ToStr()
        if m.accountPageGroup.getChildCount() > 0
            firstChild = m.accountPageGroup.getChild(0)
            if firstChild <> invalid
                print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: First child type: " + firstChild.subtype()
                print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: First child visible: " + firstChild.visible.ToStr()
            end if
        end if
    else
        print "DynamicContentScreen.brs - [showAccountPage] FINAL CHECK: Account page is INVALID!"
    end if
end sub

sub createAccountPageUI()
    print "DynamicContentScreen.brs - [createAccountPageUI] Creating Account page UI"
    
    ' Create main account group
    m.accountPageGroup = CreateObject("roSGNode", "Group")
    m.accountPageGroup.id = "accountPageGroup"
    m.accountPageGroup.translation = [0, 0]  ' Absolute top-left corner for maximum visibility
    m.accountPageGroup.focusable = true
    m.accountPageGroup.visible = true  ' Ensure it's visible from creation
    
    ' Create background that will be visible above the main screen background
    accountBg = CreateObject("roSGNode", "Rectangle")
    accountBg.width = 1740  ' Adjusted for wider 240px nav bar
    accountBg.height = 1080  ' Full screen height
    accountBg.color = "#2a3441"  ' Distinct color to ensure visibility
    accountBg.opacity = 1.0  ' Full opacity
    accountBg.translation = [-50, -50]  ' Offset to cover main background
    m.accountPageGroup.appendChild(accountBg)
    print "DynamicContentScreen.brs - [createAccountPageUI] Full-screen background created: " + accountBg.width.ToStr() + "x" + accountBg.height.ToStr()
    
    ' Create title
    titleLabel = CreateObject("roSGNode", "Label")
    titleLabel.id = "accountTitle"
    titleLabel.text = "Account Settings"
    titleLabel.color = "#4FC3F7"  ' Light blue
    titleLabel.font = CreateObject("roSGNode", "Font")
    titleLabel.font.uri = "pkg:/images/UrbanistBold.ttf"
    titleLabel.font.size = 48  ' Larger font
    titleLabel.translation = [50, 50]
    titleLabel.width = 600  ' Wider
    titleLabel.height = 70  ' Taller
    titleLabel.visible = true
    m.accountPageGroup.appendChild(titleLabel)
    print "DynamicContentScreen.brs - [createAccountPageUI] Title created: '" + titleLabel.text + "'"
    
    ' Create status label
    m.accountStatusLabel = CreateObject("roSGNode", "Label")
    m.accountStatusLabel.id = "accountStatus"
    m.accountStatusLabel.text = "Checking authentication status..."
    m.accountStatusLabel.color = "#ffffff"
    m.accountStatusLabel.font = CreateObject("roSGNode", "Font")
    m.accountStatusLabel.font.uri = "pkg:/images/UrbanistMedium.ttf"
    m.accountStatusLabel.font.size = 28
    m.accountStatusLabel.translation = [50, 150]
    m.accountStatusLabel.width = 800
    m.accountStatusLabel.height = 40
    m.accountPageGroup.appendChild(m.accountStatusLabel)
    
    ' Create login button (initially hidden)
    m.accountLoginButton = CreateObject("roSGNode", "Group")
    m.accountLoginButton.id = "accountLoginButton"
    m.accountLoginButton.translation = [50, 250]
    m.accountLoginButton.focusable = true
    m.accountLoginButton.visible = false
    
    ' Login button background
    loginBg = CreateObject("roSGNode", "Rectangle")
    loginBg.width = 200
    loginBg.height = 60
    loginBg.color = "#4FC3F7"
    loginBg.translation = [0, 0]
    m.accountLoginButton.appendChild(loginBg)
    
    ' Login button text
    loginText = CreateObject("roSGNode", "Label")
    loginText.text = "Login"
    loginText.color = "#ffffff"
    loginText.font = CreateObject("roSGNode", "Font")
    loginText.font.uri = "pkg:/images/UrbanistBold.ttf"
    loginText.font.size = 24
    loginText.translation = [0, 0]
    loginText.width = 200
    loginText.height = 60
    loginText.horizAlign = "center"
    loginText.vertAlign = "center"
    m.accountLoginButton.appendChild(loginText)
    
    m.accountPageGroup.appendChild(m.accountLoginButton)
    
    ' Add a very visible test rectangle to ensure visibility
    ' Create modern Account Settings layout matching your app's design
    
    ' Main content container
    contentContainer = CreateObject("roSGNode", "Group")
    contentContainer.translation = [100, 80]  ' Proper margins
    
    ' Account Settings Header
    headerLabel = CreateObject("roSGNode", "Label")
    headerLabel.text = "Account Settings"
    headerLabel.color = "#FFFFFF"
    headerLabel.font = "font:UrbanistBold"
    headerLabel.fontSize = 42
    headerLabel.translation = [0, 0]
    contentContainer.appendChild(headerLabel)
    
    ' User Profile Card
    profileCard = CreateObject("roSGNode", "Rectangle")
    profileCard.width = 600
    profileCard.height = 120
    profileCard.color = "#1a1f2e"
    profileCard.translation = [0, 80]
    contentContainer.appendChild(profileCard)
    
    ' Profile Avatar (placeholder)
    avatar = CreateObject("roSGNode", "Rectangle")
    avatar.width = 80
    avatar.height = 80
    avatar.color = "#6366f1"  ' Purple accent
    avatar.translation = [20, 20]
    profileCard.appendChild(avatar)
    
    ' User Info
    userNameLabel = CreateObject("roSGNode", "Label")
    userNameLabel.text = "Guest User"
    userNameLabel.color = "#FFFFFF"
    userNameLabel.font = "font:UrbanistMedium"
    userNameLabel.fontSize = 24
    userNameLabel.translation = [120, 25]
    profileCard.appendChild(userNameLabel)
    
    statusLabel = CreateObject("roSGNode", "Label")
    statusLabel.text = "Not signed in"
    statusLabel.color = "#9CA3AF"
    statusLabel.font = "font:UrbanistRegular"
    statusLabel.fontSize = 18
    statusLabel.translation = [120, 55]
    profileCard.appendChild(statusLabel)
    
    ' Sign In Button
    signInButton = CreateObject("roSGNode", "Rectangle")
    signInButton.width = 200
    signInButton.height = 50
    signInButton.color = "#6366f1"  ' Purple brand color
    signInButton.translation = [0, 240]
    contentContainer.appendChild(signInButton)
    
    signInText = CreateObject("roSGNode", "Label")
    signInText.text = "Sign In"
    signInText.color = "#FFFFFF"
    signInText.font = "font:UrbanistMedium"
    signInText.fontSize = 20
    signInText.horizAlign = "center"
    signInText.translation = [100, 15]
    signInButton.appendChild(signInText)
    
    ' Settings Options
    settingsTitle = CreateObject("roSGNode", "Label")
    settingsTitle.text = "Settings"
    settingsTitle.color = "#FFFFFF"
    settingsTitle.font = "font:UrbanistMedium"
    settingsTitle.fontSize = 28
    settingsTitle.translation = [0, 340]
    contentContainer.appendChild(settingsTitle)
    
    ' Settings Items
    settingsItems = [
        "Playback Quality",
        "Parental Controls", 
        "Language & Region",
        "Privacy Settings",
        "Help & Support"
    ]
    
    for i = 0 to settingsItems.Count() - 1
        itemContainer = CreateObject("roSGNode", "Rectangle")
        itemContainer.width = 600
        itemContainer.height = 60
        itemContainer.color = "#0f1419"
        itemContainer.translation = [0, 390 + (i * 70)]
        contentContainer.appendChild(itemContainer)
        
        itemLabel = CreateObject("roSGNode", "Label")
        itemLabel.text = settingsItems[i]
        itemLabel.color = "#FFFFFF"
        itemLabel.font = "font:UrbanistRegular"
        itemLabel.fontSize = 20
        itemLabel.translation = [20, 20]
        itemContainer.appendChild(itemLabel)
        
        ' Arrow indicator
        arrow = CreateObject("roSGNode", "Label")
        arrow.text = ">"
        arrow.color = "#9CA3AF"
        arrow.font = "font:UrbanistRegular"
        arrow.fontSize = 20
        arrow.translation = [560, 20]
        itemContainer.appendChild(arrow)
    end for
    
    m.accountPageGroup.appendChild(contentContainer)
    print "DynamicContentScreen.brs - [createAccountPageUI] Created modern Account Settings UI"
    
    ' Add to main screen - ensure it's on top by adding it last
    m.top.appendChild(m.accountPageGroup)
    
    ' Move Account page to front to ensure it's visible above background
    m.top.removeChild(m.accountPageGroup)
    m.top.appendChild(m.accountPageGroup)
    print "DynamicContentScreen.brs - [createAccountPageUI] Account page moved to front for visibility"
    
    print "DynamicContentScreen.brs - [createAccountPageUI] Account page UI created"
    print "DynamicContentScreen.brs - [createAccountPageUI] Account page added to screen, children count: " + m.top.getChildCount().ToStr()
    print "DynamicContentScreen.brs - [createAccountPageUI] Account page group visible: " + m.accountPageGroup.visible.ToStr()
end sub

sub updateAccountStatus()
    print "DynamicContentScreen.brs - [updateAccountStatus] Updating account status"
    
    if m.accountStatusLabel = invalid
        print "DynamicContentScreen.brs - [updateAccountStatus] Account status label not found"
        return
    end if
    
    ' Check authentication status
    authData = RetrieveAuthData()
    if authData <> invalid and authData.isauth = 1
        ' User is authenticated
        print "DynamicContentScreen.brs - [updateAccountStatus] User is authenticated"
        m.accountStatusLabel.text = "✓ You are logged in"
        m.accountStatusLabel.color = "#4FC3F7"
        if m.accountLoginButton <> invalid
            m.accountLoginButton.visible = false
        end if
    else
        ' User is not authenticated
        print "DynamicContentScreen.brs - [updateAccountStatus] User is not authenticated"
        m.accountStatusLabel.text = "⚠ You are not authorized"
        m.accountStatusLabel.color = "#f16667"
        if m.accountLoginButton <> invalid
            m.accountLoginButton.visible = true
        end if
    end if
    
    print "DynamicContentScreen.brs - [updateAccountStatus] Account status updated"
end sub

sub showSimpleAccountPage()
    print "DynamicContentScreen.brs - [showSimpleAccountPage] Creating simple Account page"
    
    ' Hide all other content
    hideLoadingState()
    m.contentRowList.visible = false
    m.noContentGroup.visible = false
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
    end if
    
    ' Hide the main background
    backgroundRect = m.top.findNode("backgroundRect")
    if backgroundRect <> invalid
        backgroundRect.visible = false
    end if
    
    ' Remove any existing account content
    if m.simpleAccountGroup <> invalid
        m.top.removeChild(m.simpleAccountGroup)
        m.simpleAccountGroup = invalid
    end if
    
    ' Create simple account group
    m.simpleAccountGroup = CreateObject("roSGNode", "Group")
    m.simpleAccountGroup.id = "simpleAccountGroup"
    m.simpleAccountGroup.translation = [0, 0]
    
    ' Create background
    accountBg = CreateObject("roSGNode", "Rectangle")
    accountBg.width = 1740  ' Adjusted for wider 240px nav bar
    accountBg.height = 1080
    accountBg.color = "#1a1f2e"
    accountBg.translation = [0, 0]
    m.simpleAccountGroup.appendChild(accountBg)
    
    ' Create title
    titleLabel = CreateObject("roSGNode", "Label")
    titleLabel.text = "Account Settings"
    titleLabel.color = "#4FC3F7"
    titleLabel.font = CreateObject("roSGNode", "Font")
    titleLabel.font.uri = "pkg:/images/UrbanistBold.ttf"
    titleLabel.font.size = 48
    titleLabel.translation = [60, 60]
    titleLabel.width = 600
    titleLabel.height = 60
    m.simpleAccountGroup.appendChild(titleLabel)
    
    ' Create status message
    statusLabel = CreateObject("roSGNode", "Label")
    statusLabel.text = "User is not authenticated"
    statusLabel.color = "#ffffff"
    statusLabel.font = CreateObject("roSGNode", "Font")
    statusLabel.font.uri = "pkg:/images/UrbanistMedium.ttf"
    statusLabel.font.size = 32
    statusLabel.translation = [60, 160]
    statusLabel.width = 800
    statusLabel.height = 50
    m.simpleAccountGroup.appendChild(statusLabel)
    
    ' Create login button
    loginButton = CreateObject("roSGNode", "Rectangle")
    loginButton.width = 200
    loginButton.height = 60
    loginButton.color = "#6366f1"
    loginButton.translation = [60, 240]
    m.simpleAccountGroup.appendChild(loginButton)
    
    ' Login button text
    loginText = CreateObject("roSGNode", "Label")
    loginText.text = "Login"
    loginText.color = "#ffffff"
    loginText.font = CreateObject("roSGNode", "Font")
    loginText.font.uri = "pkg:/images/UrbanistBold.ttf"
    loginText.font.size = 24
    loginText.translation = [75, 15]
    loginText.width = 100
    loginText.height = 30
    loginText.horizAlign = "center"
    loginText.vertAlign = "center"
    loginButton.appendChild(loginText)
    
    ' Create info text
    infoLabel = CreateObject("roSGNode", "Label")
    infoLabel.text = "Press right arrow to activate login (functionality not implemented yet)"
    infoLabel.color = "#cccccc"
    infoLabel.font = CreateObject("roSGNode", "Font")
    infoLabel.font.uri = "pkg:/images/UrbanistMedium.ttf"
    infoLabel.font.size = 20
    infoLabel.translation = [60, 340]
    infoLabel.width = 1000
    infoLabel.height = 30
    m.simpleAccountGroup.appendChild(infoLabel)
    
    ' Add to screen
    m.top.appendChild(m.simpleAccountGroup)
    
    print "DynamicContentScreen.brs - [showSimpleAccountPage] Simple Account page created and displayed"
end sub

sub onUserChannelsLoginFocusChanged()
    if m.userChannelsLoginCard <> invalid and m.userChannelsLoginFocusBorder <> invalid
        if m.userChannelsLoginCard.hasFocus() or m.userChannelsLoginCard.isInFocusChain()
            m.userChannelsLoginFocusBorder.visible = true
            print "DynamicContentScreen.brs - [onUserChannelsLoginFocusChanged] User Channels login focused - showing border"
        else
            m.userChannelsLoginFocusBorder.visible = false
            print "DynamicContentScreen.brs - [onUserChannelsLoginFocusChanged] User Channels login unfocused - hiding border"
        end if
    end if
end sub

sub showPrettierAuthorizationMessage()
    print "DynamicContentScreen.brs - [showPrettierAuthorizationMessage] *** SHOWING PRETTIER AUTH DIALOG ***"
    
    ' Hide other content
    hideLoadingState()
    m.contentRowList.visible = false
    m.noContentGroup.visible = false
    if m.authRequiredGroup <> invalid
        m.authRequiredGroup.visible = false
    end if
    
    ' Create prettier authorization dialog
    if m.prettierAuthGroup = invalid
        createPrettierAuthDialog()
    end if
    
    ' Set flag to handle OK key for login
    m.showingAuthRequired = true
    
    ' Show prettier auth dialog
    m.prettierAuthGroup.visible = true
    m.prettierAuthGroup.focusable = true
    m.prettierAuthGroup.setFocus(true)
    
    print "DynamicContentScreen.brs - [showPrettierAuthorizationMessage] Prettier auth dialog displayed"
end sub

sub createPrettierAuthDialog()
    print "DynamicContentScreen.brs - [createPrettierAuthDialog] Creating prettier auth dialog"
    
    ' Create main group
    m.prettierAuthGroup = CreateObject("roSGNode", "Group")
    m.prettierAuthGroup.id = "prettierAuthGroup"
    m.prettierAuthGroup.translation = [960, 540]  ' Center of screen (1920/2, 1080/2)
    m.prettierAuthGroup.focusable = true
    
    ' Create modern background with rounded corners effect
    authBg = CreateObject("roSGNode", "Rectangle")
    authBg.width = 800
    authBg.height = 450
    authBg.color = "#1a1f2e"  ' Dark blue-gray
    authBg.translation = [-400, -225]  ' Center the background
    m.prettierAuthGroup.appendChild(authBg)
    
    ' Create accent border
    accentBorder = CreateObject("roSGNode", "Rectangle")
    accentBorder.width = 800
    accentBorder.height = 6
    accentBorder.color = "#4FC3F7"  ' Light blue accent
    accentBorder.translation = [-400, -225]
    m.prettierAuthGroup.appendChild(accentBorder)
    
    ' Create icon background circle
    iconBg = CreateObject("roSGNode", "Rectangle")
    iconBg.width = 120
    iconBg.height = 120
    iconBg.color = "#4FC3F7"
    iconBg.translation = [-60, -180]
    m.prettierAuthGroup.appendChild(iconBg)
    
    ' Create lock icon (using text)
    lockIcon = CreateObject("roSGNode", "Label")
    lockIcon.text = "🔒"
    lockIcon.color = "#ffffff"
    lockIcon.font = CreateObject("roSGNode", "Font")
    lockIcon.font.size = 48
    lockIcon.translation = [-24, -160]
    lockIcon.width = 48
    lockIcon.height = 48
    lockIcon.horizAlign = "center"
    lockIcon.vertAlign = "center"
    m.prettierAuthGroup.appendChild(lockIcon)
    
    ' Create main title
    titleLabel = CreateObject("roSGNode", "Label")
    titleLabel.text = "Authentication Required"
    titleLabel.color = "#ffffff"
    titleLabel.font = CreateObject("roSGNode", "Font")
    titleLabel.font.uri = "pkg:/images/UrbanistBold.ttf"
    titleLabel.font.size = 36
    titleLabel.translation = [-300, -80]
    titleLabel.width = 600
    titleLabel.height = 50
    titleLabel.horizAlign = "center"
    m.prettierAuthGroup.appendChild(titleLabel)
    
    ' Create description
    descLabel = CreateObject("roSGNode", "Label")
    descLabel.text = "Please sign in to access your account and premium features"
    descLabel.color = "#b0b0b0"
    descLabel.font = CreateObject("roSGNode", "Font")
    descLabel.font.uri = "pkg:/images/UrbanistMedium.ttf"
    descLabel.font.size = 24
    descLabel.translation = [-350, -20]
    descLabel.width = 700
    descLabel.height = 60
    descLabel.horizAlign = "center"
    descLabel.wrap = true
    m.prettierAuthGroup.appendChild(descLabel)
    
    ' Create login button
    loginButton = CreateObject("roSGNode", "Group")
    loginButton.id = "prettierLoginButton"
    loginButton.translation = [-150, 80]
    loginButton.focusable = true
    
    ' Login button background
    loginBg = CreateObject("roSGNode", "Rectangle")
    loginBg.width = 300
    loginBg.height = 60
    loginBg.color = "#4FC3F7"
    loginBg.translation = [0, 0]
    loginButton.appendChild(loginBg)
    
    ' Login button text
    loginText = CreateObject("roSGNode", "Label")
    loginText.text = "Sign In"
    loginText.color = "#ffffff"
    loginText.font = CreateObject("roSGNode", "Font")
    loginText.font.uri = "pkg:/images/UrbanistBold.ttf"
    loginText.font.size = 28
    loginText.translation = [0, 0]
    loginText.width = 300
    loginText.height = 60
    loginText.horizAlign = "center"
    loginText.vertAlign = "center"
    loginButton.appendChild(loginText)
    
    m.prettierAuthGroup.appendChild(loginButton)
    
    ' Create help text
    helpLabel = CreateObject("roSGNode", "Label")
    helpLabel.text = "Press OK to sign in • Press Back to return"
    helpLabel.color = "#808080"
    helpLabel.font = CreateObject("roSGNode", "Font")
    helpLabel.font.uri = "pkg:/images/UrbanistRegular.ttf"
    helpLabel.font.size = 18
    helpLabel.translation = [-300, 180]
    helpLabel.width = 600
    helpLabel.height = 30
    helpLabel.horizAlign = "center"
    m.prettierAuthGroup.appendChild(helpLabel)
    
    ' Add to main screen
    m.top.appendChild(m.prettierAuthGroup)
    
    print "DynamicContentScreen.brs - [createPrettierAuthDialog] Prettier auth dialog created"
end sub
