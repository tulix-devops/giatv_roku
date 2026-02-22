
function init()
    m.progressdialog = createObject("roSGNode", "ProgressDialog")
    m.top.observeField("visible", "onScreenVisibilityChanged")

    m.vodDataCache = {}
    m.page = 1
    m.totalItems = 0
    m.lastFocusedItem = invalid
    m.selectedCategory = 0
    m.lastFocuedCategoryItem = invalid
    m.firstCategoryInitialization = false
    m.vodAnimationInitialized = false

    m.activateRow = m.top.findNode("activateRow")
    m.deactivateRow = m.top.findNode("deactivateRow")
    m.activateItemDetails = m.top.findNode("activateItemDetails")
    m.deactivateItemDetails = m.top.findNode("deactivateItemDetails")
end function

sub onScreenVisibilityChanged()
    if m.top.visible = true
        ' Check authentication before showing content
        if not isUserAuthenticated()
            print "VODScreen: User not authenticated, redirecting to login"
            redirectToLogin()
            return
        end if
        
        ' Only fetch data when screen becomes visible AND user is authenticated
        if m.top.vodDataEntity = invalid and m.top.categoryDataEntity = invalid
            print "VODScreen: Screen visible and authenticated, fetching category data"
            fetchCategoryData()
        end if
    else if m.top.visible = false
        TopDialogClose()
    end if
end sub

function isUserAuthenticated() as boolean
    authData = RetrieveAuthData()
    if authData <> invalid
        if authData.accessToken <> invalid and authData.accessToken <> ""
            return true
        else if authData.accesstoken <> invalid and authData.accesstoken <> ""
            return true
        end if
    end if
    return false
end function

sub redirectToLogin()
    ' Hide current screen
    m.top.visible = false
    ' Show login screen
    ' Skip login screen - continue with content
    print "VodScreen.brs - Skipping login screen, showing content"
end sub

sub fetchCategoryData()
    ' Double-check authentication before making API call
    if not isUserAuthenticated()
        print "VODScreen: Cannot fetch categories - user not authenticated"
        redirectToLogin()
        return
    end if
    
    showLoadingDialog("Loading, please wait...")
    m.categoryData = createObject("roSGNode", "CategoriesData")
    m.categoryData.observeField("responseData", "handleCategoryResponseData")
    m.categoryData.typeID = 1  ' VOD type
    m.categoryData.control = "RUN"
end sub

sub handleCategoryResponseData()
    data = m.categoryData.responseData
    m.top.categoryDataEntity = parseCategoryEntity(data)
    print "LiveScreen: Categories loaded: " + m.top.categoryDataEntity.count().ToStr()
end sub

sub fetchVodScreenData(categoryId as integer)
    ' Check authentication before making API call
    if not isUserAuthenticated()
        print "VODScreen: Cannot fetch VOD data - user not authenticated"
        redirectToLogin()
        return
    end if
    
    m.selectedCategory = categoryId
    print "VODScreen: Fetching VOD data for category: " + categoryId.ToStr()
    
    if m.vodDataCache.doesExist(categoryId.ToStr()) then
        initializeCachedVodScreenData()
        return
    end if

    showLoadingDialog("Loading, please wait...")
    m.vodScreenData = createObject("roSGNode", "VodScreenData")
    m.vodScreenData.observeField("responseData", "handleResponseData")
    m.vodScreenData.page = m.page
    m.vodScreenData.vodType = 1  ' Reverted back to 3 for VOD content
    m.vodScreenData.categoryType = categoryId
    m.vodScreenData.control = "RUN"
end sub

sub handleResponseData()
    print "We got here inside VOD_SCREEN handleResponseData"
    data = m.vodScreenData.responseData
    m.page = m.page + 1
    m.top.vodDataEntity = parseVodScreenEntity(data, 0)
    print "VODScreen: VOD data loaded: " + m.top.vodDataEntity.count().ToStr()
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

sub initializeCachedVodScreenData()
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

    m.lastFocusedItem = m.rowList.itemFocused

    content = m.rowList.content
    if content <> invalid
        childrenToRemove = []
        for i = 0 to content.getChildCount() - 1
            childrenToRemove.push(content.getChild(i))
        end for
        content.removeChildren(childrenToRemove)
    else
        content = CreateObject("roSGNode", "ContentNode")
        content.title = "VOD"
    end if

    for each vodData in m.vodDataCache[m.selectedCategory.ToStr()]
        item = CreateObject("roSGNode", "ContentNode")
        item.title = vodData.title
        item.hdPosterUrl = ""

        if vodData.images <> invalid
            if vodData.images["banner"] <> invalid
                item.hdPosterUrl = vodData.images["banner"]
            else
                item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
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

    m.rowList.content = content
    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.jumptoitem = m.lastFocusedItem

    m.contentContainer.appendChild(m.rowList)
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

    m.lastFocusedItem = m.rowList.itemFocused

    content = m.rowList.content
    if content <> invalid
        childrenToRemove = []
        for i = 0 to content.getChildCount() - 1
            childrenToRemove.push(content.getChild(i))
        end for
        content.removeChildren(childrenToRemove)
    else
        content = CreateObject("roSGNode", "ContentNode")
        content.title = "VOD"
    end if

    if m.top.vodDataEntity <> invalid
        m.vodDataCache[m.selectedCategory.ToStr()] = m.top.vodDataEntity
        for each vodData in m.top.vodDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = vodData.title
            item.hdPosterUrl = ""

            if vodData.images <> invalid
                if vodData.images["banner"] <> invalid
                    item.hdPosterUrl = vodData.images["banner"]
                else
                    item.hdPosterUrl = "pkg:/images/png/no-poster-found.png"
                end if
            end if

            item.addFields({
                rowItemFocus: false,
                data: vodData,
                isLiveChannel: false,
                focusable: true,
                isVodLayout: true,
                itemWidth: 400,
                itemHeight: 225
            })
            m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for
    end if

    m.rowList.content = content
    m.rowList.itemFocused = m.lastFocusedItem
    m.rowList.jumptoitem = m.lastFocusedItem

    m.contentContainer.appendChild(m.rowList)
end sub

function RetrieveAuthData() as object
    section = "AUTH"
    jsonData = RegRead("authData", section)
    
    ' Check if the JSON data is valid
    if jsonData <> invalid and jsonData <> ""
        ' Deserialize the JSON string back into an associative array
        data = ParseJson(jsonData)
        if data <> invalid
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
    
    ' Add null safety checks
    if m.rowList <> invalid then
        if m.lastFocusedItem <> invalid then
            m.rowList.itemFocused = m.lastFocusedItem
            m.rowList.itemSelected = m.lastFocusedItem
        end if
    end if
end sub


sub updateVodCategoryScreen()
    initializeCategories()

end sub


sub initializeCategories()
    m.contentContainer = m.top.findNode("vodContainer")
    defaultFont = CreateObject("roSGNode", "Font")
    defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
    defaultFont.size = 42

    hvc = CreateObject("roSGNode", "HomeVodContent")

    m.categoryRowList = m.top.findNode("categoryRowList")
    m.categoryRowList.focusable = true
    m.contentContainer.appendChild(m.categoryRowList)
    m.categoryRowList.rowLabelFont = defaultFont

    ' currentFocusedIndex = m.rowList.itemFocused
    ' m.lastFocusedItem = m.categoryRowList.itemFocused

    content = CreateObject("roSGNode", "ContentNode")
    content.title = "Categories"



    if m.top.categoryDataEntity <> invalid
        fetchVodScreenData(m.top.categoryDataEntity[0].id)
        m.firstCategoryInitialization = true
        for each categoryData in m.top.categoryDataEntity
            item = CreateObject("roSGNode", "ContentNode")
            item.title = categoryData.title
            print categoryData.name


            item.addFields({
                rowItemFocus: false,
                data: categoryData,
                isLiveChannel: false,
                focusable: true,
                isSelected: false,
                isLandscape: true
            })
            ' m.totalItems = m.totalItems + 1
            content.appendChild(item)
        end for

        hvc.appendChild(content)
        ' m.rowList.itemContent = content
        m.categoryRowList.content = hvc
        m.contentContainer.appendChild(m.categoryRowList)
        m.categoryRowList.observeField("rowItemFocused", "onCategoryItemFocused")

        ' m.categoryRowList.itemFocused = m.lastFocusedItem
        ' m.categoryRowList.jumptoitem = m.lastFocusedItem

    end if

end sub




sub onCategoryItemFocused()
    rowItemFocusedInfo = m.categoryRowList.rowItemFocused
    print "Is Category Item Being Focused"
    if rowItemFocusedInfo <> invalid
        print rowItemFocusedInfo
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]



        ' Retrieve the currently focused item
        focusedRow = m.categoryRowList.content.getChild(focusedRowIndex)
        if focusedRow <> invalid
            focusedItem = focusedRow.getChild(focusedItemIndex)
            if focusedItem <> invalid
                if m.lastFocusedCategoryItem <> invalid
                    m.lastFocusedCategoryItem.isSelected = false
                end if

                m.lastFocusedCategoryItem = focusedItem
                focusedItem.rowItemFocus = true ' Set the new focus
                print focusedItem
                print "CATEGORY FOCUSED ITEM"
                focusedItem.isSelected = true
                if focusedItemIndex <> 0 then
                    m.selectedCategory = focusedItem.data.id
                    fetchVodScreenData(focusedItem.data.id)
                else if focusedItemIndex = 0 and m.firstCategoryInitialization = true
                    m.selectedCategory = focusedItem.data.id
                    fetchVodScreenData(focusedItem.data.id)
                end if

            end if

        end if
    end if
end sub


sub activateRow()

    ' Start the translation animation
    ' m.activateRow.control = "start"
    ' m.activateItemDetails.control = "start"
end sub

sub deactivateRow()
    ' m.deactivateItemDetails.control = "start"

    ' Start the translation animation
    ' m.deactivateRow.control = "start"
end sub



function onKeyEvent(key as string, press as boolean) as boolean
    vodScreen = m.global.findNode("vod_screen")
    vodListRow = m.top.findNode("vodRowList")
    categoryRowList = m.top.findNode("categoryRowList")
    print key
    print press
    print "What Happened in VOD SCREEN"
    if press = false and key = "right"
        if vodScreen.hasFocus()
            ' vodListRow.setFocus(true)
            categoryRowList.setFocus(true)
            ' activateRow()
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
        m.videoPlayerScreen = m.global.findNode("vodPlayer")
        m.videoPlayerScreen.contentURL = ""
        m.vodAnimationInitialized = false
        return true
    else if key = "left" and press = true
        if m.rowList <> invalid and m.rowList.hasFocus()
            if m.rowList.itemFocused <> invalid and m.rowList.itemFocused mod 5 = 0 then
                ' Perform actions when the focused item index matches the condition
                unFocusActiveVODRowItem()
                m.navBar = m.global.findNode("navigation_bar")
                if m.navBar <> invalid then
                    m.navBar.setFocus(true)
                    m.navBar.navHasFocus = true
                end if
                deactivateRow()
                m.videoPlayerScreen = m.global.findNode("vodPlayer")
                if m.videoPlayerScreen <> invalid then
                    m.videoPlayerScreen.contentURL = ""
                end if
                m.vodAnimationInitialized = false
            end if
        end if
        if categoryRowList.hasFocus()
            if getActiveCategoryRowIndex()[1] = 0
                m.navBar = m.global.findNode("navigation_bar")
                m.navBar.setFocus(true)
                m.navBar.navHasFocus = true
                ' deactivateRow()
                m.videoPlayerScreen = m.global.findNode("vodPlayer")
                m.videoPlayerScreen.contentURL = ""
                m.vodAnimationInitialized = false
            end if

        end if

    else if key = "down" and press = true
        if categoryRowList.hasFocus()
            if m.vodAnimationInitialized = false
                activateRow()
                m.vodAnimationInitialized = true
            end if
            vodListRow.setFocus(true)
            return true
        end if
    else if key = "up" and press = true
        if vodListRow.hasFocus() and vodListRow.itemFocused <= 5 then
            deactivateRow()
            m.vodAnimationInitialized = false
            categoryRowList.setFocus(true)
            return true
        end if
    else if key = "OK" and vodListRow.hasFocus()
        m.videoPlayerScreen = m.global.findNode("vodPlayer")
        m.videoPlayerScreen.contentURL = ""
        ' detailScreen = m.global.findNode("detailScene")
        selectionData = getActiveEntityDetails()
        ' detailScreen.detailScreenData = []
        ' detailScreen.navigatedFrom = "VOD"
        ' tmpData = []
        ' tmpData.push(selectionData)
        ' detailScreen.detailScreenData = tmpData
        ' detailScreen.setFocus(true)
        ' detailScreen.visible = true
        ' m.lastFocusedItem = m.rowList.rowItemFocused
        m.lastFocusedItem = m.rowList.itemFocused
        m.isDetailScreenPushed = true

        ' m.DVRVideoPlayerScreen = m.global.findNode("videoPlayerScreen")
        m.DVRVideoPlayerScreen = m.global.findNode("videoDVRScreen")

        progNodeToPlay = CreateObject("roSGNode", "ContentNode")
        progNodeToPlay.url = selectionData.data.sources["primary"]
        progNodeToPlay.title = selectionData.data.title
        progNodeToPlay.description = selectionData.data.description
        if selectionData.data.attributes["Production Year"] <> invalid
            progNodeToPlay.addFields({
                productionyear: selectionData.data.attributes["Production Year"],
            })
        end if

        progNodeToPlay.hdposterurl = selectionData.data["images"]["banner"]
        ' progNodeToPlay.playStart = "00"duration
        progNodeToPlay.playDuration = selectionData.data.duration * 60
        progNodeToPlay.addFields({
            isCC: "false",
            isHD: "true",
            channelTitle: "JoyGo"
        })

        m.DVRVideoPlayerScreen.navigatedFrom = "VOD"


        ' m.DVRVideoPlayerScreen.contentProgram = progNodeToPlay
        m.DVRVideoPlayerScreen.content = progNodeToPlay
        m.global.findNode("navigation_bar").visible = false
        m.global.findNode("vod_screen").visible = false
        m.DVRVideoPlayerScreen.setFocus(true)
        m.DVRVideoPlayerScreen.visible = true
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

function getActiveCategoryRowIndex()
    rowItemFocusedInfo = m.categoryRowList.focusedChild.rowItemFocused
    focusedRowIndex = -1
    if rowItemFocusedInfo <> invalid
        focusedRowIndex = rowItemFocusedInfo[0]
        focusedItemIndex = rowItemFocusedInfo[1]
        print "Row " + str(focusedRowIndex) + " Item " + str(focusedItemIndex) + " is focused."
    end if

    return [focusedRowIndex, focusedItemIndex]
end function

