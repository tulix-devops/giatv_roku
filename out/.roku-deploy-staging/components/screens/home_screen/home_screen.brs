function init()
    m.spinLoader = false
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")
    
    ' Add visibility trigger
    m.isFirstVisibilityTrigger = 0
    
    ' Remove fetchHomeScreenData() from here
    m.prevFocusedHomeRowIndex = invalid
    m.prevFocusedHomeItemIndex = invalid

    m.isDetailScreenPushed = false
    m.top.mainGroup = m.top.findNode("mainGroup")
    m.lastFocusedItem = invalid
end function

sub onScreenVisibilityChanged()
    if m.top.visible = true
        ' Only fetch data on first visibility (when trigger is 0)
        if m.isFirstVisibilityTrigger = 0
            m.isFirstVisibilityTrigger = 1
            ' Show loading dialog BEFORE fetching data
            fetchHomeScreenData()
        end if
        
        ' Remove the duplicate loading dialog logic
        ' if m.top.homeScreenDataEntity = invalid
        '     m.top.GetScene().dialog = m.progressdialog
        ' else if m.isDetailScreenPushed = true then
        if m.isDetailScreenPushed = true then
            m.isDetailScreenPushed = false
            m.top.findNode("exampleRowList").setFocus(true)
        end if
    else if m.top.visible = false
        TopDialogClose()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print key
    print press
    print "Main Screen Brs OnKeyEvent"

    homeScreen = m.global.findNode("home_screen")
    vodListRow = m.top.findNode("exampleRowList")

    if press = false and key = "right"
        if homeScreen.hasFocus()
            vodListRow.setFocus(true)
            return true
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.rowItemFocused = m.lastFocusedItem
            return true
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        return true
    else if key = "left" and press = true
        if vodListRow.hasFocus()
            getVodActiveRowIndex = getActiveVODRowIndex()[1]
            if getVodActiveRowIndex = 0
                unFocusActiveVODRowItem()
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
            end if
        end if
    else if press = false and key = "OK" then
        vodListRow.setFocus(true)
        return true    
    else if key = "OK"
        ' Navigation is now handled by onRowItemSelected
        return false
    end if

    return false
end function


function associativeToArray(assocArray as object) as object
    result = CreateObject("roArray", assocArray.count(), true)
    for each key in assocArray.keys()
        result.push({ key: key, value: assocArray[key] })
    end for
    return result
end function


function getFocusedChildIndex(container as object) as integer
    for i = 0 to container.getChildCount() - 1
        if container.getChild(i).hasFocus()
            return i
        end if
    end for
    return -1 ' In case no child has focus
end function


sub fetchHomeScreenData()
    showLoadingDialog("Loading, please wait...")
    m.homeScreenData = createObject("roSGNode", "HomeScreenData")
    m.homeScreenData.observeField("responseData", "handleResponseData")
    m.homeScreenData.control = "RUN"
end sub

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub


sub handleLiveChannelsUpdate()
end sub



sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub handleResponseData()
    data = m.homeScreenData.responseData

    m.top.homeScreenDataEntity = parseHomeVodEntity(data)
end sub


sub updateHomeScreen()
    initializeHomeScreen()
    TopDialogClose()
end sub


function initializeLiveChannelData()
    m.liveChannelData = createObject("roSGNode", "LiveScreenApi")
    m.liveChannelData.observeField("responseData", "handleLiveChannelResponseData")
    m.liveChannelData.control = "RUN"

end function


sub handleLiveChannelResponseData()
    data = m.liveChannelData.responseData

    m.top.liveChannelsEntity = parseChannelEntity(data)

end sub


sub fetchLiveScreenData()
    ' m.liveContentContainer = m.top.findNode("liveListContainer")
    ' hvc = CreateObject("roSGNode", "HomeVodContent")
    ' if m.top.liveChannelsEntity <> invalid
    '     content = CreateObject("roSGNode", "ContentNode")
    '     content.title = "Live channels"
    '     for each channel in m.top.liveChannelsEntity
    '         item = CreateObject("roSGNode", "ContentNode")
    '         item.title = channel.title
    '         item.isChannel = true
    '         item.focusable = true
    '         item.addfields({
    '             rowItemFocus: false
    '             data: channel
    '         })
    '         item.hdPosterUrl = "https://183.bozztv.com/storage/movies/" + channel.storageRecord["thumb"]
    '         content.appendChild(item)
    '     end for
    '     hvc.appendChild(content)
    ' end if
    ' m.liveRowList = m.top.findNode("liveListRow")
    ' ' content = CreateObject("roSGNode", "ContentNode")
    ' m.liveRowList.focusable = true
    ' ' hvc.appendChild(content)
    ' m.liveRowList.content = hvc
    ' m.liveContentContainer.appendChild(m.liveRowList)
    ' m.liveRowList.observeField("rowItemFocused", "onLiveRowItemFocused")

end sub


sub initializeHomeScreen()
    print "=== initializeHomeScreen DEBUG ==="
    print "m.top.homeScreenDataEntity type: " + Type(m.top.homeScreenDataEntity)
    print "m.top.homeScreenDataEntity count: " + Str(m.top.homeScreenDataEntity.Count())

    m.contentContainer = m.top.findNode("contentContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 48

    if m.rowList = invalid
        m.rowList = m.top.findNode("exampleRowList")
        m.rowList.focusable = true
        m.contentContainer.appendChild(m.rowList)
    end if

    hvc = CreateObject("roSGNode", "ContentNode")
    hvc.title = "Home"

    rowItemSizes = []
    rowHeights = []

    for each vodCat in m.top.homeScreenDataEntity

        print "Processing category: " + vodCat.categoryName
        print "Category type: " + Type(vodCat)
        print "VodEntityData type: " + Type(vodCat.VodEntityData)
        print "VodEntityData count: " + Str(vodCat.VodEntityData.Count())
        ' Check if this is a live section or TV shows section
        isLiveSection = false
        isTvShowSection = false

        if vodCat.isLiveSection <> invalid and vodCat.isLiveSection = true
            isLiveSection = true
            rowItemSizes.Push([320, 180])
            rowHeights.Push(200.0)
        else 
            ' Check if this category contains TV shows (typeId = 2)
            for each vodData in vodCat.VodEntityData
                if vodData.typeId = 2
                    isTvShowSection = true
                    exit for
                end if
            end for
            
            if isTvShowSection
                ' TV Shows use same dimensions as Live channels
                rowItemSizes.Push([320, 180])
                rowHeights.Push(200.0)
            else
                ' VOD Movies use larger dimensions
                rowItemSizes.Push([300, 420])
                rowHeights.Push(440.0)
            end if
        end if
        
        content = CreateObject("roSGNode", "ContentNode")
        
        ' Set proper category titles based on content type
        if isLiveSection = true
            content.title = "Live"
        else if isTvShowSection
            content.title = "TV Series"
        else
            content.title = "Movies"
        end if
        
     
        
        
        for each vodData in vodCat.VodEntityData
     
            if vodData.images <> invalid
            end if

            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            print 
            ' Determine if this item should use Live channel layout
            isLiveChannel = isLiveSection or vodData.typeId = 2
            
            item.addfields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: isLiveChannel,
                isLiveSection: isLiveSection,
                typeId: vodData.typeId
            })
            item.focusable = true

            if vodData.images <> invalid
                if isLiveChannel and vodData.images["poster"] <> invalid
                    
                        item.hdPosterUrl = vodData.images["poster"]
                    
                else if vodData.images["banner"] <> invalid
                    ' VOD Movies use banner image
                    item.hdPosterUrl = vodData.images["banner"]
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            else
                item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
            end if

            if vodData.typeId = 2
                if vodData.images["thumbnail"] <> invalid
                    ' VOD Movies use banner image
                    item.hdPosterUrl = encodeUrl(vodData.images["thumbnail"])
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if

            content.appendChild(item)
        end for
        hvc.appendChild(content)
    end for
    
    m.rowList.content = hvc
    m.rowList.rowItemSize = rowItemSizes
    m.rowList.rowHeights = rowHeights
    m.rowList.itemSpacing = [0, 80]
    m.rowList.itemSize = [1920, 520]
    m.rowList.rowLabelFont = defaultFont
    m.contentContainer.appendChild(m.rowList)
    m.rowList.observeField("rowItemFocused", "onRowItemFocused")
    m.rowList.observeField("itemSelected", "onRowItemSelected")
end sub



function encodeUrl(url as string) as string
    ' Replace spaces with %20
    url = url.Replace(" ", "%20")
    ' Add more replacements if necessary
    ' url = url.Replace("<character>", "<encoded_value>")
    return url
end function



sub onLiveRowItemFocused()
    rowItemFocusedInfo = m.liveRowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]

        ' Handle the previously focused item
        if m.prevFocusedLiveRowIndex <> invalid and m.prevFocusedLiveItemIndex <> invalid
            prevFocusedRow = m.liveRowList.content.getChild(m.prevFocusedLiveRowIndex)
            if prevFocusedRow <> invalid
                prevFocusedItem = prevFocusedRow.getChild(m.prevFocusedLiveItemIndex)
                if prevFocusedItem <> invalid
                    prevFocusedItem.rowItemFocus = false ' Reset the previous focus
                end if
            end if
        end if

        ' Retrieve the currently focused row and item
        focusedRow = m.liveRowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = true ' Set the new focus
                print "New Focus: Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex)
            end if
        end if

        ' Update the previous focus indices
        m.prevFocusedLiveRowIndex = focusedRowIndex
        m.prevFocusedLiveItemIndex = focusedItemIndex
    end if
end sub


sub unFocusActiveVODRowItem()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = false
            end if
        end if
    end if
end sub


function getActiveVODEntity()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem.data
            end if
        end if
    end if
end function

function getActiveEntityDetails()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid

                return focusedItem
            end if
        end if
    end if
end function


sub onRowItemFocused()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]

        ' Handle the previously focused item
        if m.prevFocusedHomeRowIndex <> invalid and m.prevFocusedHomeItemIndex <> invalid
            prevFocusedRow = m.rowList.content.getChild(m.prevFocusedHomeRowIndex)
            if prevFocusedRow <> invalid
                prevFocusedItem = prevFocusedRow.getChild(m.prevFocusedHomeItemIndex)
                if prevFocusedItem <> invalid
                    prevFocusedItem.rowItemFocus = false ' Reset the previous focus
                end if
            end if
        end if

        ' Retrieve the currently focused row and item
        focusedRow = m.rowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                focusedItem.rowItemFocus = true ' Set the new focus
                subscription = validateSubscription()

                if focusedItem.isLiveChannel = true
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("homePlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storageRecord["source"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.source
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "640"
                    end if

                    ' m.itemDetails = m.global.findNode("itemDetailLayout")
                    ' selectionData = getActiveEntityDetails()
                    ' m.itemDetails.itemDetailsData = []
                    ' tmpData = []
                    ' tmpData.push(selectionData)
                    ' m.itemDetails.itemDetailsData = tmpData
                else
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("homePlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storage["record"]["trailer"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.sources["trailer"]
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "640"
                    end if

                    m.itemDetails = m.global.findNode("itemDetailLayout")
                    selectionData = getActiveEntityDetails()
                    ' m.itemDetails.itemDetailsData = []
                    ' tmpData = []
                    ' tmpData.push(selectionData)
                    ' m.itemDetails.itemDetailsData = tmpData
                end if

                print "New Focus: Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex)
            end if
        end if

        ' Update the previous focus indices
        m.prevFocusedHomeRowIndex = focusedRowIndex
        m.prevFocusedHomeItemIndex = focusedItemIndex
    end if
end sub


sub onRowItemSelected()
    selectionData = getActiveEntityDetails()
    m.isDetailScreenPushed = true
    
    ' Check content type using typeId
    ' typeId 3 = Live, typeId 1 = VOD (Movie), typeId 2 = TV Show (Series)
    if selectionData.typeId = 2
        ' Handle TV Series - navigate to SeasonScreen
        m.SeasonScreen = m.global.findNode("SeasonScreen")
        
        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = selectionData.data.sources["primary"]
        progNodeToPlay.title = selectionData.data.title
        progNodeToPlay.description = selectionData.data.description
        progNodeToPlay.hdposterurl = selectionData.data["images"]["thumbnail"]
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "JoyGo"
        })

        m.SeasonScreen.navigatedFrom = "HOME"
        m.SeasonScreen.DVRParent = progNodeToPlay
        m.SeasonScreen.arrayDVRs = convertToSimpleArray(selectionData.data.seasons)
        m.SeasonScreen.setFocus(true)
        m.SeasonScreen.visible = true

        m.global.findNode("navigation_bar").visible = false
        m.global.findNode("home_screen").visible = false
    else
        ' Handle Live channels and VOD content
        m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")
        m.DVRListingScreen = m.global.findNode("DVRListingScreen")
        
        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = selectionData.data.sources["primary"]
        progNodeToPlay.title = selectionData.data.title
        progNodeToPlay.description = selectionData.data.description
        
        ' Fix image handling like in live_screen.brs
        if selectionData.data.images <> invalid
            if selectionData.data.images["poster"] <> invalid
                progNodeToPlay.hdposterurl = selectionData.data.images["poster"]
            else
                progNodeToPlay.hdposterurl = "pkg:/images/png/no-poster-found.png"
            end if
        else
            progNodeToPlay.hdposterurl = "pkg:/images/png/no-poster-found.png"
        end if
        
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "JoyGo"
        })

        ' Check if live channel has DVR data
        if selectionData.isLiveSection = true and selectionData.data.sources["dvr"] <> invalid then
            ' Live channel with DVR - navigate to DVRListingScreen
            progNodeToPlay.addFields({
                isdvr: "1",
            })
            m.DVRListingScreen.DVRParent = progNodeToPlay
            m.DVRListingScreen.arrayDVRs = convertToSimpleArray(selectionData.data.sources["dvr"])
            m.DVRListingScreen.navigatedFrom = "HOME"  
            print "Home Screen.brs [forDVR]"
            print m.DVRListingScreen.arrayDVRs
            m.DVRListingScreen.setFocus(true)
            m.DVRListingScreen.visible = true
        else
            ' Live channel without DVR or VOD Movie - navigate to video player
            m.DVRVideoPlayerScreen.navigatedFrom = "HOME"
            if selectionData.isLiveSection = true  
                ' progNodeToPlay.playDuration = selectionData.data.duration * 60
                ' Live channel without DVR
            else 
                ' VOD Movie
                progNodeToPlay.playDuration = selectionData.data.duration * 60
            end if
            ' progNodeToPlay.playDuration = selectionData.data.duration * 60
            m.DVRVideoPlayerScreen.content = progNodeToPlay
            m.DVRVideoPlayerScreen.visible = true
            m.DVRVideoPlayerScreen.setFocus(true)
        end if

        m.global.findNode("navigation_bar").visible = false
        m.global.findNode("home_screen").visible = false
    end if
end sub


function getActiveVODRowIndex()
    rowItemFocusedInfo = m.rowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function




sub validateSubscription() as boolean
    authData = RetrieveAuthData()
    print authData
    if authData <> invalid
        if authData.subscribed = 1
            return true
        else

            return false
        end if
    else
        return false
    end if
end sub


function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    print jsonData
    print "Here is JSON DATA??????"
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        print data
        print "we are Here?"
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
    ' return invalid
    return sec.Read(key)
end function

function convertToSimpleArray(dvrData as object)
    ' Initialize an empty array to store the simple array values
    simpleArray = []

    ' Iterate over the keys in the roAssociativeArray
    for each key in dvrData
        ' Get the value corresponding to the key (which is an array of DVR data)
        dayDVRs = dvrData[key]

        ' Create an associative array to hold the day's DVRs and the title
        item = {
            dvrTitle: key, ' Add the title corresponding to the key
            data: dayDVRs ' Store the DVR data
        }

        ' Push the object to the simple array
        simpleArray.Push(item)
    end for

    ' Now simpleArray contains the DVR arrays for each day along with their titles
    return simpleArray
end function




