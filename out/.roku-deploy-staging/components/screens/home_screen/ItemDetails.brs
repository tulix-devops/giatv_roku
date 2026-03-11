sub init()
    m.top.itemDetailsData = m.top.findNode("itemDetailsData")
    m.titleLabel = m.top.findNode("titleLabel")
    m.descriptionLabel = m.top.findNode("descriptionLabel")
    m.top.observeField("itemDetailsData", "itemDetailsDataChanged")
    m.ratingGroup = m.top.findNode("ratingGroup")
    m.castGroup = m.top.findNode("castGroup")
    m.descrGroup = m.top.findNode("descriptionGroup")

    m.castList = m.top.findNode("castList")
    m.tagList = m.top.findNode("tagList")

    m.directorList = m.top.findNode("directorList")
    m.productionYearList = m.top.findNode("productionYearList")
end sub




sub itemDetailsDataChanged()

    if m.top.itemDetailsData <> invalid

        if m.top.itemDetailsData[0] <> invalid
            if m.top.itemDetailsData[0].isLiveChannel = true
                m.ratingGroup.visible = false
                m.castGroup.visible = false
                m.descrGroup.translation = [13, 140]
                ' m.descrGroup.translation = [0, 280]
                m.top.findNode("layoutTitleGroup").visible = false
                m.titleLabel.text = m.top.itemDetailsData[0].title
                m.descriptionLabel.text = m.top.itemDetailsData[0].data.description

                m.titleLabel.translation = [13, 25]
                m.titleLabel.font.size = 42

            else
                ' m.descrGroup.translation = [0, 300]
                m.top.findNode("layoutTitleGroup").visible = true
                m.descrGroup.translation = [13, 310]
                m.ratingGroup.visible = true
                m.castGroup.visible = true
                m.titleLabel.text = m.top.itemDetailsData[0].title
                m.descriptionLabel.text = m.top.itemDetailsData[0].data.description


                m.titleLabel.translation = [13, 255]
                m.titleLabel.font.size = 24

                generateCastGroup()
                generateTagGroup()
                generateDirectorGroup()
                generateProductionYearGroup()
            end if


        end if
    end if
end sub


sub generateDirectorGroup()
    if m.top.itemDetailsData[0].data.attributes["Director"] <> invalid
        director = m.top.itemDetailsData[0].data.attributes["Director"]
        directorArray = []
        directorArray.push(director)
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 16

        childrenToRemove = []
        for i = 0 to m.directorList.getChildCount() - 1
            childrenToRemove.push(m.directorList.getChild(i))
        end for
        m.directorList.removeChildren(childrenToRemove)

        currentX = 0
        currentY = 0
        spacingX = 10 ' Horizontal spacing between cast items
        spacingY = 10 ' Vertical spacing between rows
        maxColumns = 20 ' Max number of items per row
        itemHeight = 36 ' Height of each item
        loopLimit = min(directorArray.count(), 20)


        for i = 0 to loopLimit - 1
            year = directorArray[i]
            directorListGroup = CreateObject("roSGNode", "Group")

            ' If we exceed maxColumns, move to the next row
            if i mod maxColumns = 0 and i <> 0
                currentX = 0
                currentY = currentY + itemHeight + spacingY
            end if

            directorListGroup.translation = [currentX, currentY] ' Adjust translation for each entry

            ' Create and append Poster
            castPoster = CreateObject("roSGNode", "Poster")
            ' castPoster.uri = "pkg:/images/png/shapes/tag_outline_black.9.png"
            castPoster.uri = "pkg:/images/png/shapes/pink_cat_outline.9.png"
            castPoster.loadDisplayMode = "scaleToZoom"
            castPoster.width = 75 + len(year) * 4 ' Adjust width based on text length
            castPoster.height = itemHeight
            castPoster.translation = [0, 0]

            ' Create and append Label
            castLabel = CreateObject("roSGNode", "Label")
            castLabel.text = year
            castLabel.font = defaultFont
            castLabel.translation = [0, 0]
            castLabel.color = "#FF4960"
            castLabel.width = castPoster.width
            castLabel.height = castPoster.height
            castLabel.horizAlign = "center"
            castLabel.vertAlign = "center"

            castPoster.appendChild(castLabel)
            directorListGroup.appendChild(castPoster)

            ' Append the cast entry to the castList
            m.directorList.appendChild(directorListGroup)

            ' Update currentX for the next item
            currentX = currentX + castPoster.width + spacingX
        end for
    end if


end sub


sub generateProductionYearGroup()
    if m.top.itemDetailsData[0].data.attributes["Production Year"] <> invalid
        productionYear = m.top.itemDetailsData[0].data.attributes["Production Year"]
        productionYearArray = []
        productionYearArray.push(productionYear)
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 16

        childrenToRemove = []
        for i = 0 to m.productionYearList.getChildCount() - 1
            childrenToRemove.push(m.productionYearList.getChild(i))
        end for
        m.productionYearList.removeChildren(childrenToRemove)

        currentX = 0
        currentY = 0
        spacingX = 10 ' Horizontal spacing between cast items
        spacingY = 10 ' Vertical spacing between rows
        maxColumns = 20 ' Max number of items per row
        itemHeight = 36 ' Height of each item
        loopLimit = min(productionYearArray.count(), 20)


        for i = 0 to loopLimit - 1
            year = productionYearArray[i]
            productionYearGroup = CreateObject("roSGNode", "Group")

            ' If we exceed maxColumns, move to the next row
            if i mod maxColumns = 0 and i <> 0
                currentX = 0
                currentY = currentY + itemHeight + spacingY
            end if

            productionYearGroup.translation = [currentX, currentY] ' Adjust translation for each entry

            ' Create and append Poster
            castPoster = CreateObject("roSGNode", "Poster")
            ' castPoster.uri = "pkg:/images/png/shapes/tag_outline_black.9.png"
            castPoster.uri = "pkg:/images/png/shapes/pink_cat_outline.9.png"
            castPoster.loadDisplayMode = "scaleToZoom"
            castPoster.width = 75 + len(year) * 4 ' Adjust width based on text length
            castPoster.height = itemHeight
            castPoster.translation = [0, 0]

            ' Create and append Label
            castLabel = CreateObject("roSGNode", "Label")
            castLabel.text = year
            castLabel.font = defaultFont
            castLabel.translation = [0, 0]
            castLabel.color = "#FF4960"
            castLabel.width = castPoster.width
            castLabel.height = castPoster.height
            castLabel.horizAlign = "center"
            castLabel.vertAlign = "center"

            castPoster.appendChild(castLabel)
            productionYearGroup.appendChild(castPoster)

            ' Append the cast entry to the castList
            m.productionYearList.appendChild(productionYearGroup)

            ' Update currentX for the next item
            currentX = currentX + castPoster.width + spacingX
        end for
    end if

end sub



sub generateCastGroup()
    if m.top.itemDetailsData[0].data.attributes["Actors"] <> invalid
        cast = m.top.itemDetailsData[0].data.attributes["Actors"]
        castArray = cast.split(",")
        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 16


        childrenToRemove = []
        for i = 0 to m.castList.getChildCount() - 1
            childrenToRemove.push(m.castList.getChild(i))
        end for
        m.castList.removeChildren(childrenToRemove)

        currentX = 0
        currentY = 0
        spacingX = 10 ' Horizontal spacing between cast items
        spacingY = 10 ' Vertical spacing between rows
        maxColumns = 20 ' Max number of items per row
        itemHeight = 36 ' Height of each item
        loopLimit = min(castArray.count(), 20)
        if castArray.count() > 10
            m.descrGroup.translation = [0, 350]
        end if

        for i = 0 to loopLimit - 1
            actor = castArray[i]
            castGroup = CreateObject("roSGNode", "Group")

            ' If we exceed maxColumns, move to the next row
            if i mod maxColumns = 0 and i <> 0
                currentX = 0
                currentY = currentY + itemHeight + spacingY
            end if

            castGroup.translation = [currentX, currentY] ' Adjust translation for each entry

            ' Create and append Poster
            castPoster = CreateObject("roSGNode", "Poster")
            ' castPoster.uri = "pkg:/images/png/shapes/tag_outline_black.9.png"
            castPoster.uri = "pkg:/images/png/shapes/pink_cat_outline.9.png"
            castPoster.loadDisplayMode = "scaleToZoom"
            castPoster.width = 75 + len(actor) * 4 ' Adjust width based on text length
            castPoster.height = itemHeight
            castPoster.translation = [0, 0]

            ' Create and append Label
            castLabel = CreateObject("roSGNode", "Label")
            castLabel.text = actor
            castLabel.font = defaultFont
            castLabel.translation = [0, 0]
            castLabel.color = "#FF4960"
            castLabel.width = castPoster.width
            castLabel.height = castPoster.height
            castLabel.horizAlign = "center"
            castLabel.vertAlign = "center"

            castPoster.appendChild(castLabel)
            castGroup.appendChild(castPoster)

            ' Append the cast entry to the castList
            m.castList.appendChild(castGroup)

            ' Update currentX for the next item
            currentX = currentX + castPoster.width + spacingX
        end for
    end if

end sub


sub generateTagGroup()
    if m.top.itemDetailsData[0].data.attributes["Genre"] <> invalid
        tags = m.top.itemDetailsData[0].data.attributes["Genre"]
        tagsArray = tags.split(",")

        defaultFont = CreateObject("roSGNode", "Font")
        defaultFont.uri = "pkg:/images/UrbanistSemiBold.ttf"
        defaultFont.size = 15

        childrenToRemove = []
        for i = 0 to m.tagList.getChildCount() - 1
            childrenToRemove.push(m.tagList.getChild(i))
        end for
        m.tagList.removeChildren(childrenToRemove)

        currentX = 0
        currentY = 0
        spacingX = 10 ' Horizontal spacing between cast items
        spacingY = 10 ' Vertical spacing between rows
        maxColumns = 20 ' Max number of items per row
        itemHeight = 36 ' Height of each item

        for i = 0 to tagsArray.count() - 1
            tag = tagsArray[i]
            tagsGroup = CreateObject("roSGNode", "Group")

            ' If we exceed maxColumns, move to the next row
            if i mod maxColumns = 0 and i <> 0
                currentX = 0
                currentY = currentY + itemHeight + spacingY
            end if

            tagsGroup.translation = [currentX, currentY] ' Adjust translation for each entry

            ' Create and append Poster
            tagsPoster = CreateObject("roSGNode", "Poster")
            tagsPoster.uri = "pkg:/images/png/shapes/pink_cat_outline.9.png"
            tagsPoster.width = 60 + len(tag) * 4 ' Adjust width based on text length
            tagsPoster.height = itemHeight
            tagsPoster.translation = [0, 0]

            ' Create and append Label
            tagsLabel = CreateObject("roSGNode", "Label")
            tagsLabel.text = tag
            tagsLabel.font = defaultFont
            tagsLabel.translation = [0, 0]
            tagsLabel.color = "#FF4960"
            tagsLabel.width = tagsPoster.width
            tagsLabel.height = tagsPoster.height
            tagsLabel.horizAlign = "center"
            tagsLabel.vertAlign = "center"

            tagsPoster.appendChild(tagsLabel)
            tagsGroup.appendChild(tagsPoster)

            ' Append the cast entry to the castList
            m.tagList.appendChild(tagsGroup)

            ' Update currentX for the next item
            currentX = currentX + tagsPoster.width + spacingX
        end for
    end if



end sub


function min(a as integer, b as integer) as integer
    if a < b then
        return a
    else
        return b
    end if
end function