sub init()
    print "SimpleNavigationItem.brs - [init] Initializing simple navigation item"
    
    m.background = m.top.findNode("background")
    m.focusIndicator = m.top.findNode("focusIndicator")
    m.title = m.top.findNode("title")
    
    m.top.observeField("focused", "onFocusChanged")
    m.top.focusable = true
end sub

sub OnContentSet()
    print "SimpleNavigationItem.brs - [OnContentSet] Called"
    
    content = m.top.itemContent
    if content <> invalid and content.title <> invalid
        m.title.text = content.title
        print "SimpleNavigationItem.brs - [OnContentSet] Set title: " + content.title
    else
        m.title.text = "Nav Item"
        print "SimpleNavigationItem.brs - [OnContentSet] Using default title"
    end if
end sub

sub onFocusChanged()
    if m.top.focused
        print "SimpleNavigationItem.brs - [onFocusChanged] Item gained focus: " + m.title.text
        m.focusIndicator.visible = true
        m.title.color = "#f16667"
    else
        print "SimpleNavigationItem.brs - [onFocusChanged] Item lost focus: " + m.title.text
        m.focusIndicator.visible = false
        m.title.color = "#ffffff"
    end if
end sub