function init()


    m.searchBox = m.top.FindNode("searchBox")
    ' m.searchBox.observeField("text", "initiateSearch")
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.keyboard = m.top.findNode("keyboard")
    m.keyboard.observeField("text", "updateTextBox")

    m.top.observeField("focusedChild", "handleFocus")
    m.top.observeField("visible", "onVisibilityChanged")
    m.top.searchDataEntity = m.top.findNode("searchDataEntity")
    m.top.observeField("searchDataEntity", "searchDataUpdated")
    m.searchContainer = m.top.findNode("searchContainer")
    m.rowList = m.top.findNode("searchList")


    m.applyButton = m.top.findNode("applyButton")

    m.buttonPoster = m.top.findNode("submit")
    m.buttonLabel = m.top.findNode("buttonLabel")


    m.activateKeyboard = m.top.findNode("activateKeyboard")
    m.deactivateKeyboard = m.top.findNode("deactivateKeyboard")


    m.lastFocusedItem = invalid
end function


sub activateKeyboard()
    m.activateKeyboard.control = "start"
    m.searchBox.active = true
end sub

sub deactivateKeyboard()
    m.deactivateKeyboard.control = "start"
    m.searchBox.active = false
end sub

sub updateTextBox()
    ' print m.keyboard.focusedChild
    m.searchBox.text = m.keyboard.text
    m.searchBox.cursorPosition = Len(m.searchBox.text)
end sub

sub handleFocus(event as object)
    field = event.getRoSGNode()
    print "SearchScreen.brs - [handleFocus] Search screen focus changed, hasFocus: " + m.top.hasFocus().ToStr()
    print "SearchScreen.brs - [handleFocus] Search screen visible: " + m.top.visible.ToStr()
    
    ' Only activate keyboard if search screen is actually visible and should be active
    if m.top.hasFocus() and m.top.visible = true
        print "SearchScreen.brs - [handleFocus] Activating search keyboard"
        m.keyboard.visible = true
        m.keyboard.setFocus(true)
        print m.keyboard.focusedChild
        print "FocusedChild is here"
        activateKeyboard()
    else
        print "SearchScreen.brs - [handleFocus] Search screen not active, skipping keyboard activation"
        ' Hide keyboard when search screen loses focus or is not visible
        if m.keyboard <> invalid
            m.keyboard.visible = false
            deactivateKeyboard()
        end if
    end if
end sub

sub onVisibilityChanged()
    print "SearchScreen.brs - [onVisibilityChanged] Search screen visibility changed to: " + m.top.visible.ToStr()
    
    ' Hide keyboard when search screen becomes invisible
    if m.top.visible = false and m.keyboard <> invalid
        print "SearchScreen.brs - [onVisibilityChanged] Hiding keyboard as search screen is not visible"
        m.keyboard.visible = false
        m.keyboard.setFocus(false)
        deactivateKeyboard()
    end if
end sub

sub initiateSearch()
    m.searchedData = createObject("roSGNode", "SearchScreenApi")
    m.searchedData.observeField("responseData", "handleResponseData")
    m.searchedData.keyword = m.searchBox.text
    if len(m.searchBox.text) <> 0
        showLoadingDialog("Loading")

    end if
    ' ShowSpinner(true)
    ' m.relatedData.control = "RUN"
end sub



sub handleResponseData()
    data = m.searchedData.responseData

    m.top.searchDataEntity = parseVodScreenEntity(data, 8)
    TopDialogClose()
end sub

sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub

sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub searchDataUpdated()
    if m.top.searchDataEntity <> invalid

        m.searchContainer.visible = true
        hvc = CreateObject("roSGNode", "HomeVodContent")
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 42

        m.rowList.focusable = true
        m.rowList.rowLabelFont = defaultFont
        content = CreateObject("roSGNode", "ContentNode")
        ' m.rowList.numColumns = vodCat.VodEntityData.count()
        ' m.rowList.numRows = 4


        ' For truly mixed content, we'll use the largest dimensions to accommodate all items
        ' This allows each item to size itself appropriately while maintaining row consistency
        m.rowList.rowItemSize = [[320, 420]] ' Max width for Live/TV, Max height for Movies
        m.rowList.rowHeights = [440.0]

        content.title = "Search results for '" + m.searchBox.text + "'"
        for each vodData in m.top.searchDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            
            ' Determine content type based on typeId
            ' typeId 3 = Live, typeId 1 = VOD (Movie), typeId 2 = TV Show (Series)
            isLiveChannel = (vodData.typeId = 3) or (vodData.typeId = 2)
            
            item.addfields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: isLiveChannel,
                typeId: vodData.typeId
            })
            item.focusable = true
            
            ' Image selection based on content type
            if vodData.images <> invalid
                if isLiveChannel and vodData.images["poster"] <> invalid
                    ' Live channels and TV Shows use poster image
                    item.hdPosterUrl = encodeUrl(vodData.images["poster"])
                else if vodData.typeId = 2 and vodData.images["thumbnail"] <> invalid
                    ' TV Shows can also use thumbnail if poster not available
                    item.hdPosterUrl = encodeUrl(vodData.images["thumbnail"])
                else if vodData.images["banner"] <> invalid
                    ' VOD Movies use banner image
                    item.hdPosterUrl = encodeUrl(vodData.images["banner"])
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            else
                item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
            end if

            content.appendChild(item)
        end for
        hvc.appendChild(content)
        ' m.rowList.content = content
        ' m.rowList.content = content

        ' m.rowList.content = CreateObject("roSGNode", "RowListContent")

        m.rowList.content = hvc
        m.searchContainer.appendChild(m.rowList)
        m.rowList.observeField("rowItemFocused", "onRowItemFocused")


    end if

    ' ShowSpinner(false)
end sub

function encodeUrl(url as string) as string
    ' Replace spaces with %20
    url = url.Replace(" ", "%20")
    ' Add more replacements if necessary
    ' url = url.Replace("<character>", "<encoded_value>")
    return url
end function

sub activateButton()

    m.buttonLabel.color = "#000000"
    m.buttonPoster.uri = "pkg:/images/png/shapes/active_button.png"

    ' active_button
end sub


sub deactivateButton()
    m.buttonLabel.color = "0xFFFFFF"
    m.buttonPoster.uri = "pkg:/images/png/shapes/grey_rounded.png"
end sub


function onKeyEvent(key as string, press as boolean) as boolean
    searchScreen = m.global.findNode("search_screen")
    vodListRow = m.top.findNode("exampleRowList")

    print press
    print key

    print "KeyPress Above"

    if press = false and key = "right"
        if searchScreen.hasFocus()
            return true
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            m.rowList.setFocus(true)
            m.rowList.rowItemFocused = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        deactivateButton()
        deactivateKeyboard()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        return true
    else if key = "right" and press = true
    else if key = "down" and press = true
        if m.applyButton.hasFocus() then
            deactivateButton()
            m.rowList.setFocus(true)
        else if m.rowList.hasFocus() then
            activateKeyboard()
            m.keyboard.setFocus(true)
        end if
    else if key = "up" and press = true
        if m.rowList.hasFocus() then
            m.applyButton.setFocus(true)
            activateButton()
            return true
        end if
        deactivateKeyboard()
        m.applyButton.setFocus(true)
        activateButton()
        return true
        if m.keyboard.hasFocus() then
            print "Do we get here?"
            m.applyButton.setFocus(true)
            return true
        end if
        ' if vodListRow.hasFocus()
        '     getVodActiveRowIndex = getActiveVODRowIndex()[0]
        '     if getVodActiveRowIndex = 0
        '         unFocusActiveVODRowItem()

        '     end if
        ' end if
    else if key = "back" and press = true then
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        return true
    else if key = "left" and press = true
        ' if vodListRow.hasFocus()
        '     getVodActiveRowIndex = getActiveVODRowIndex()[1]
        '     if getVodActiveRowIndex = 0
        '         unFocusActiveVODRowItem()
        '         m.navBar = m.global.findNode("navigation_bar")
        '         m.navBar.setFocus(true)
        '         m.navBar.navHasFocus = true
        '         m.navBar.navHasFocus = true
        '         deactivateRow()
        '     end if
        ' end if

    else if key = "OK"
        print "SearchScreen.brs - [onKeyEvent] OK key pressed in search screen"
        if m.applyButton.hasFocus() then
            initiateSearch()
            return true
        else if m.rowList.hasFocus() then
            print "Search screen: OK pressed on content item"
            selectionData = getActiveEntityDetails()
            m.lastFocusedItem = m.rowList.rowItemFocused
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

                m.SeasonScreen.navigatedFrom = "SEARCH"
                m.SeasonScreen.DVRParent = progNodeToPlay
                m.SeasonScreen.arrayDVRs = convertToSimpleArray(selectionData.data.seasons)
                m.SeasonScreen.setFocus(true)
                m.SeasonScreen.visible = true

                m.global.findNode("navigation_bar").visible = false
                m.global.findNode("search_screen").visible = false
            else
                ' Handle Live channels and VOD Movies - navigate to video player
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
                if selectionData.isLiveChannel = true and selectionData.data.sources["dvr"] <> invalid then
                    ' Live channel with DVR - navigate to DVRListingScreen
                    progNodeToPlay.addFields({
                        isdvr: "1",
                    })
                    m.DVRListingScreen.DVRParent = progNodeToPlay
                    m.DVRListingScreen.arrayDVRs = convertToSimpleArray(selectionData.data.sources["dvr"])
                    print "Search Screen.brs [forDVR]"
                    print m.DVRListingScreen.arrayDVRs
                    m.DVRListingScreen.setFocus(true)
                    m.DVRListingScreen.visible = true
                else
                    ' Live channel without DVR or VOD Movie - navigate to video player
                    if selectionData.isLiveChannel = true 
                        ' Live channel without DVR
                    else 
                        ' VOD Movie
                        progNodeToPlay.playDuration = selectionData.data.duration * 60
                    end if
                    
                    m.DVRVideoPlayerScreen.navigatedFrom = "Search"
                    m.DVRVideoPlayerScreen.content = progNodeToPlay
                    m.DVRVideoPlayerScreen.setFocus(true)
                    m.DVRVideoPlayerScreen.visible = true
                end if

                m.global.findNode("navigation_bar").visible = false
                m.global.findNode("search_screen").visible = false
            end if
        end if
        ' detailScreen = m.global.findNode("detailScene")
        ' ' selectionData = getActiveVODEntity()
        ' selectionData = getActiveEntityDetails()
        ' detailScreen.detailScreenData = []
        ' tmpData = []
        ' tmpData.push(selectionData)
        ' detailScreen.detailScreenData = tmpData
        ' detailScreen.setFocus(true)
        ' detailScreen.visible = true
        ' m.isDetailScreenPushed = true
        ' m.global.findNode("navigation_bar").visible = false
        ' m.global.findNode("home_screen").visible = false

    end if

    return false
end function



sub unFocusActiveVODRowItem()
    if m.searchContainer.visible = true and m.rowList.hasFocus()
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
    end if

end sub

' Helper function to find the index of the currently focused child
function getFocusedChildIndex(container as object) as integer
    for i = 0 to container.getChildCount() - 1
        if container.getChild(i).hasFocus()
            return i
        end if
    end for
    return -1 ' In case no child has focus
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
    m.simpleArray = simpleArray
    return m.simpleArray
end function



