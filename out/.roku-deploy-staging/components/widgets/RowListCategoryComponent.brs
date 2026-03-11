sub init()
    m.categoryTitle = m.top.findNode("categoryTitle")
    m.placeholderRectangle = m.top.findNode("placeholderRectangle")
end sub

sub OnContentSet()
    print "CATEGORY SSET"
    content = m.top.itemContent
    content.observeField("keyPressed", "onKeyPressed")
    if content <> invalid
        setCategoryText(content)
        onSelectedChanged(content)

        if content.isdvr = true then
            ' m.placeholderRectangle.width = 400
            ' m.placeholderRectangle.height = 120
            ' m.categoryTitle.width = 400
            ' m.categoryTitle.height = 120
            ' m.categoryTitle.font.size = 38
            m.placeholderRectangle.width = 250
            m.placeholderRectangle.height = 100
            m.categoryTitle.width = 250
            m.categoryTitle.height = 100
            m.categoryTitle.font.size = 26
        else
            m.placeholderRectangle.width = 250
            m.placeholderRectangle.height = 100
            m.categoryTitle.width = 250
            m.categoryTitle.height = 100
            m.categoryTitle.font.size = 26
        end if
    end if
end sub

sub setCategoryText(content)
    print content
    print content.data
    print "Here is content Of Category Text"

    if content.categoryName <> invalid
        title = content.categoryName
        if len(title) > 40
            title = left(title, 37) + "...."
        end if
        m.categoryTitle.text = title
    else
        if content.data.name <> invalid
            title = content.data.name
            if len(title) > 40
                title = left(title, 37) + "...."
            end if
            m.categoryTitle.text = title
        else 
            m.categoryTitle.text = ""
        end if
    end if
end sub

sub onSelectedChanged(content)
    if content.isSelected <> invalid
        if content.isSelected = true then
            m.placeholderRectangle.color = "0xFFFFFFFF"
            m.categoryTitle.color = "0x000000"
        else
            m.placeholderRectangle.color = "#9E9E9E26"
            m.categoryTitle.color = "0xFFFFFF"
        end if
    end if
end sub



