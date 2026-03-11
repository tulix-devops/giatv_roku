sub init()
    m.bg = m.top.findNode("bg")
    m.label = m.top.findNode("label")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid
        m.label.text = ""
        return
    end if
    if content.title <> invalid
        m.label.text = content.title
    else
        m.label.text = ""
    end if
end sub

sub onFocusPercentChanged()
    fp = m.top.focusPercent
    if fp > 0.5
        m.bg.color = "#3498DB"
        m.label.color = "#FFFFFF"
        m.top.scale = [1.02, 1.02]
    else
        m.bg.color = "#1F3B5C"
        m.label.color = "#FFFFFF"
        m.top.scale = [1.0, 1.0]
    end if
end sub

