sub init()
    m.background = m.top.findNode("cardBg")
    m.titleLabel = m.top.findNode("programTitle")
    m.timeLabel = m.top.findNode("programTime")
    m.descLabel = m.top.findNode("programDesc")
end sub

sub onContentChanged()
    content = m.top.itemContent
    if content = invalid then return
    
    ' Program title
    if content.title <> invalid and content.title <> ""
        m.titleLabel.text = content.title
    else
        m.titleLabel.text = "Program"
    end if
    
    ' Program time
    if content.startTime <> invalid and content.endTime <> invalid
        m.timeLabel.text = content.startTime + " - " + content.endTime
    else
        m.timeLabel.text = ""
    end if
    
    ' Program description
    if content.description <> invalid and content.description <> ""
        m.descLabel.text = content.description
    else
        m.descLabel.text = ""
    end if
end sub
