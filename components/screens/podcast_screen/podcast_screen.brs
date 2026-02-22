
function init()
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")
    fetchVodScreenData()

    m.activateRow = m.top.findNode("activateRow")
    m.deactivateRow = m.top.findNode("deactivateRow")
    m.activateItemDetails = m.top.findNode("activateItemDetails")
    m.deactivateItemDetails = m.top.findNode("deactivateItemDetails")
    m.page = 1


    m.totalItems = 0
    m.lastFocusedItem = invalid
end function


sub fetchVodScreenData()
    showLoadingDialog("Loading, please wait...")
    ' if m.vodScreenData <> invalid
    '     m.vodScreenData.removeObserver("responseData")
    ' end if
    m.vodScreenData = createObject("roSGNode", "VodScreenData")
    m.vodScreenData.observeField("responseData", "handleResponseData")
    m.vodScreenData.page = m.page
    m.vodScreenData.vodType = 4
    m.vodScreenData.control = "RUN"
    print "ss"
    print "Do we have data Here"
end sub

sub handleResponseData()
    data = m.vodScreenData.responseData
    m.page = m.page + 1
    m.top.vodDataEntity = parseVodScreenEntity(data, 0)
    print m.top.vodDataEntity.count()

end sub

sub onScreenVisibilityChanged()
    if m.top.visible = true
        if m.top.vodDataEntity = invalid
            m.top.GetScene().dialog = m.progressdialog
        end if
    else if m.top.visible = false
        TopDialogClose()
    end if
end sub


sub showLoadingDialog(textToShow as string)
    m.progressdialog.busySpinner.uri = "pkg:/images/png/loader.png"
    m.progressdialog.backgroundUri = "pkg:/images/png/shapes/final_transparent_mask.png"
    m.progressdialog.width = 500

    if m.top.visible = true
        m.top.GetScene().dialog = m.progressdialog
    end if



end sub





sub initializeVodScreen()
    m.contentContainer = m.top.findNode("vodContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    if m.rowList = invalid
        m.rowList = m.top.findNode("vodRowList")
        m.rowList.focusable = true
        m.contentContainer.appendChild(m.rowList)
        m.rowList.observeField("itemFocused", "onItemFocused")
    end if

    ' currentFocusedIndex = m.rowList.itemFocused
    m.lastFocusedItem = m.rowList.itemFocused
    content = m.rowList.content
    if content = invalid
        content = CreateObject("roSGNode", "ContentNode")
        content.itemComponentName = "Videos"
    end if

    if m.top.vodDataEntity <> invalid
        for each vodData in m.top.vodDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            ' item.title = vodData.title
            ' item.title = "Podcasts"
            item.hdPosterUrl = ""

            ' if vodData.storage <> invalid
            '     if vodData.storage["record"] <> invalid
            '         if vodData.storage["record"]["banner"] <> invalid
            '             item.hdPosterUrl = vodData.storage["record"]["banner"]
            '         end if
            '     end if
            ' end if
            print vodData.images
            if vodData.images <> invalid
                if vodData.images["thumbnail"] <> invalid
                    item.hdPosterUrl = vodData.images["thumbnail"]
                else item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if 
            end if

            item.addFields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: false,
                focusable: true
            })
            m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for


        ' m.rowList.itemContent = content
        m.rowList.content = content
        m.rowList.itemFocused = m.lastFocusedItem
        m.rowList.jumptoitem = m.lastFocusedItem

    end if


end sub

sub onItemFocused()
    itemFocusedInfo = m.rowList.itemFocused
    print itemFocusedInfo
    print "Hello Item Focused info is Here"

    if itemFocusedInfo <> invalid


        focusedItemIndex = itemFocusedInfo

        ' Handle the previously focused item
        if m.prevFocusedItemIndex <> invalid
            prevFocusedItem = m.rowList.content.getChild(m.prevFocusedItemIndex)
            if prevFocusedItem <> invalid
                prevFocusedItem.rowItemFocus = false ' Reset the previous focus
            end if
        end if

        ' Retrieve the currently focused item
        focusedItem = m.rowList.content.getChild(focusedItemIndex)
        if focusedItem <> invalid
            focusedItem.rowItemFocus = true ' Set the new focus

            if focusedItem.isLiveChannel = true
                m.videoPlayerScreen = m.global.findNode("podcastPlayer")
                m.videoPlayerScreen.contentURL = focusedItem.data.source
                m.itemDetails = m.global.findNode("podcastItemDetails")
                selectionData = getActiveEntityDetails()
                print selectionData
                print "Here is Selection Data"
                m.itemDetails.itemDetailsData = []
                tmpData = []
                tmpData.push(selectionData)
                m.itemDetails.itemDetailsData = tmpData
            else
                m.videoPlayerScreen = m.global.findNode("podcastPlayer")
                m.videoPlayerScreen.contentURL = focusedItem.data.sources["trailer"]
                m.videoPlayerScreen.width = "1280"
                m.videoPlayerScreen.height = "800"
                m.itemDetails = m.global.findNode("podcastItemDetails")
                print m.itemDetails
                print "Here is ItemDetails"
                selectionData = getActiveEntityDetails()
                print selectionData.data
                print "Selection Data we are looking For"
                m.itemDetails.itemDetailsData = []
                tmpData = []
                tmpData.push(selectionData)
                m.itemDetails.itemDetailsData = tmpData
            end if

            print "New Focus: Item " + str(focusedItemIndex)
            print focusedItemIndex
            if focusedItemIndex >= m.totalItems - 7
                ' Focused item is one of the last 7 items
                fetchVodScreenData()
                print "The focused item is one of the last 7 items."
                ' You can add any specific logic you want to execute when one of the last 7 items is focused
            end if

            ' Update the previous focus indices
            m.prevFocusedItemIndex = focusedItemIndex
            ' m.prevFocusedRowIndex = lastRowIndex
        end if
    end if
end sub

sub onRowItemFocused()
    rowItemFocusedInfo = m.rowList.rowItemFocused
    print rowItemFocusedInfo
    print "Hello Row Item Focused info is Here"
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
                        m.videoPlayerScreen = m.global.findNode("podcastPlayer")
                        ' m.videoPlayerScreen.contentURL = focusedItem.data.storageRecord["source"]
                        m.videoPlayerScreen.contentURL = focusedItem.data.source
                    end if
                    m.itemDetails = m.global.findNode("podcastItemDetails")
                    selectionData = getActiveEntityDetails()
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                else
                    if subscription = true
                        m.videoPlayerScreen = m.global.findNode("podcastPlayer")

                        m.videoPlayerScreen.contentURL = focusedItem.data.storage["record"]["trailer"]
                        m.videoPlayerScreen.width = "1280"
                        m.videoPlayerScreen.height = "800"
                    end if
                    m.itemDetails = m.global.findNode("podcastItemDetails")
                    print m.itemDetails
                    print "here is ItemDetails"
                    selectionData = getActiveEntityDetails()
                    print selectionData
                    print "Selection Data we are looking For"
                    m.itemDetails.itemDetailsData = []
                    tmpData = []
                    tmpData.push(selectionData)
                    m.itemDetails.itemDetailsData = tmpData
                end if

                print "New Focus: Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex)
            end if
        end if

        ' Update the previous focus indices
        m.prevFocusedHomeRowIndex = focusedRowIndex
        m.prevFocusedHomeItemIndex = focusedItemIndex
    end if
end sub


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

function getActiveEntityDetails()
    itemFocusedInfo = m.rowList.itemFocused
    if itemFocusedInfo <> invalid
        focusedItemIndex = itemFocusedInfo
        focusedItem = m.rowList.content.getChild(focusedItemIndex)
        if focusedItem <> invalid
            return focusedItem
        end if
    end if
    return invalid
end function



sub updateVodScreen()
    initializeVodScreen()
    TopDialogClose()
    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.itemSelected = m.lastFocusedItem
end sub


sub TopDialogClose()
    if m.top.GetScene().dialog <> invalid then
        m.top.GetScene().dialog.close = true
    end if
end sub


sub activateRow()

    ' Start the translation animation
    m.activateRow.control = "start"
    m.activateItemDetails.control = "start"
end sub

sub deactivateRow()
    m.deactivateItemDetails.control = "start"

    ' Start the translation animation
    m.deactivateRow.control = "start"
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    vodScreen = m.global.findNode("podcast_screen")
    vodListRow = m.top.findNode("vodRowList")
    print key
    print press
    print "What Happened in VOD SCREEN"
    if press = false and key = "right"
        if vodScreen.hasFocus()
            vodListRow.setFocus(true)
            activateRow()
        end if
    else if key = "back" and press = false
        if m.lastFocusedItem <> invalid
            vodListRow.setFocus(true)
            m.rowList.itemFocused = m.lastFocusedItem
            m.rowList.itemSelected = m.lastFocusedItem
        end if
    else if (press = false or press = true) and key = "back" then
        unFocusActiveVODRowItem()
        m.navBar = m.global.findNode("navigation_bar")
        m.navBar.setFocus(true)
        m.navBar.navHasFocus = true
        deactivateRow()
        m.videoPlayerScreen = m.global.findNode("podcastPlayer")
        m.videoPlayerScreen.contentURL = ""
        return true
    else if key = "left" and press = true
        if m.rowList.hasFocus()
            if m.rowList.itemFocused mod 5 = 0 then
                ' Perform actions when the focused item index matches the condition
                unFocusActiveVODRowItem()
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
                deactivateRow()
                m.videoPlayerScreen = m.global.findNode("podcastPlayer")
                m.videoPlayerScreen.contentURL = ""
            end if
        end if
    else if key = "OK"
        m.videoPlayerScreen = m.global.findNode("podcastPlayer")
        m.videoPlayerScreen.contentURL = ""
        ' detailScreen =
        detailScreen = m.global.findNode("detailScene")
        ' selectionData = getActiveVODEntity()
        selectionData = getActiveEntityDetails()
        detailScreen.detailScreenData = []
        detailScreen.navigatedFrom = "VOD"
        tmpData = []
        tmpData.push(selectionData)
        detailScreen.detailScreenData = tmpData
        detailScreen.setFocus(true)
        detailScreen.visible = true
        ' m.lastFocusedItem = m.rowList.rowItemFocused
        m.lastFocusedItem = m.rowList.itemFocused
        m.isDetailScreenPushed = true
        m.global.detailEntity = tmpData
        print m.global.detailEntity
        m.global.setField("detailEntity", tmpData)
        m.global.findNode("navigation_bar").visible = false
        m.global.findNode("podcast_screen").visible = false
    end if
end function

function getActiveLiveRowIndex()
    rowItemFocusedInfo = m.rowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function

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

