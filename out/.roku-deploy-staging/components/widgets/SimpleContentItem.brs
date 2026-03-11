sub init()
    print "SimpleContentItem.brs - [init] Initializing simple content item"
    
    m.contentPoster = m.top.findNode("contentPoster")
    m.contentTitle = m.top.findNode("contentTitle")
    m.focusIndicator = m.top.findNode("focusIndicator")
    
    ' Set up focus handling
    m.top.observeField("focusedChild", "onFocusChanged")
end sub

sub onContentSet()
    content = m.top.itemContent
    print "SimpleContentItem.brs - [onContentSet] Content set: " + Type(content).ToStr()
    
    if content <> invalid
        ' Set poster image
        if content.hdPosterUrl <> invalid and content.hdPosterUrl <> ""
            print "SimpleContentItem.brs - [onContentSet] Setting poster: " + content.hdPosterUrl
            m.contentPoster.uri = content.hdPosterUrl
        else
            print "SimpleContentItem.brs - [onContentSet] No poster URL, using placeholder"
            m.contentPoster.uri = "pkg:/images/png/poster_not_found_220x375.png"
        end if
        
        ' Set title
        if content.title <> invalid and content.title <> ""
            print "SimpleContentItem.brs - [onContentSet] Setting title: " + content.title
            m.contentTitle.text = content.title
        else
            print "SimpleContentItem.brs - [onContentSet] No title available"
            m.contentTitle.text = "No Title"
        end if
    else
        print "SimpleContentItem.brs - [onContentSet] Content is invalid"
    end if
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        ' Show focus indicator
        m.focusIndicator.opacity = 0.3
        print "SimpleContentItem.brs - [onFocusChanged] Item gained focus"
    else
        ' Hide focus indicator
        m.focusIndicator.opacity = 0
    end if
end sub
