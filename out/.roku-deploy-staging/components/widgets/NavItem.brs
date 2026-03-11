sub init()
    print "NavItem.brs - [init] Initializing nav item"
    
    m.background = m.top.findNode("background")
    m.focusBackground = m.top.findNode("focusBackground")
    m.focusBorder = m.top.findNode("focusBorder")
    m.selectedBackground = m.top.findNode("selectedBackground")
    m.selectedIndicator = m.top.findNode("selectedIndicator")
    m.title = m.top.findNode("title")
    
    ' Set up observers
    m.top.observeField("focused", "onFocusChanged")
    m.top.observeField("selected", "onSelectedChanged")
    
    ' Make sure the component is focusable
    m.top.focusable = true
    
    print "NavItem.brs - [init] NavItem initialized, focusable: " + m.top.focusable.ToStr()
end sub

sub onFocusedChildChanged()
    print "NavItem.brs - [onFocusedChildChanged] FocusedChild changed: " + Type(m.top.focusedChild)
end sub

sub OnContentSet()
    print "NavItem.brs - [OnContentSet] Called"
    
    content = m.top.itemContent
    if content <> invalid
        ' Set title
        if content.title <> invalid and content.title <> ""
            m.title.text = content.title
            print "NavItem.brs - [OnContentSet] Set title: " + content.title
        else
            m.title.text = "Nav Item"
        end if
        
        ' Observe the focused field from content
        if content.hasField("focused")
            content.observeField("focused", "onContentFocusChanged")
            print "NavItem.brs - [OnContentSet] Observing content focused field for: " + content.title
        else
            print "NavItem.brs - [OnContentSet] WARNING: Content does not have focused field for: " + content.title
        end if
        
        ' Observe the selected field from content
        if content.hasField("selected")
            content.observeField("selected", "onContentSelectedChanged")
            print "NavItem.brs - [OnContentSet] Observing content selected field for: " + content.title
        else
            print "NavItem.brs - [OnContentSet] WARNING: Content does not have selected field for: " + content.title
        end if
    else
        m.title.text = "Invalid Content"
    end if
end sub

sub onContentFocusChanged()
    print "NavItem.brs - [onContentFocusChanged] Content focus changed"
    content = m.top.itemContent
    if content <> invalid and content.hasField("focused")
        m.top.focused = content.focused
        print "NavItem.brs - [onContentFocusChanged] Set NavItem focused to: " + content.focused.ToStr() + " for item: " + m.title.text
    else
        print "NavItem.brs - [onContentFocusChanged] Content invalid or no focused field"
    end if
end sub

sub onContentSelectedChanged()
    print "NavItem.brs - [onContentSelectedChanged] Content selected changed"
    content = m.top.itemContent
    if content <> invalid and content.hasField("selected")
        m.top.selected = content.selected
        print "NavItem.brs - [onContentSelectedChanged] Set NavItem selected to: " + content.selected.ToStr()
    end if
end sub

sub onFocusChanged()
    print "NavItem.brs - [onFocusChanged] Focus changed - focused: " + m.top.focused.ToStr() + ", item: " + m.title.text
    updateVisualState()
end sub

sub onSelectedChanged()
    print "NavItem.brs - [onSelectedChanged] Selected changed - selected: " + m.top.selected.ToStr() + ", item: " + m.title.text
    updateVisualState()
end sub

sub updateVisualState()
    print "NavItem.brs - [updateVisualState] Updating visual state for: " + m.title.text + " - focused: " + m.top.focused.ToStr() + ", selected: " + m.top.selected.ToStr()
    
    ' Handle both states independently - they can coexist
    ' FOCUSED state (navigation cursor) - highest priority visual
    if m.top.focused
        print "NavItem.brs - [updateVisualState] Item has FOCUS (navigation cursor): " + m.title.text
        
        ' Show bright focus indicators
        if m.focusBackground <> invalid then m.focusBackground.visible = true
        if m.focusBorder <> invalid then m.focusBorder.visible = true
        
        ' Focus text styling - dark text on bright background
        if m.title <> invalid
            m.title.color = "#000000"  ' Dark text on bright white background
            m.title.font.size = 24
        end if
        
    else
        ' Hide focus indicators when not focused
        if m.focusBackground <> invalid then m.focusBackground.visible = false
        if m.focusBorder <> invalid then m.focusBorder.visible = false
    end if
    
    ' SELECTED state (active tab) - persistent indicator
    if m.top.selected
        print "NavItem.brs - [updateVisualState] Item is SELECTED (active tab): " + m.title.text
        
        ' Show selected indicators (subtle, persistent)
        if m.selectedBackground <> invalid then m.selectedBackground.visible = true
        if m.selectedIndicator <> invalid then m.selectedIndicator.visible = true
        if m.background <> invalid then m.background.visible = false
        
        ' Selected text styling (if not focused)
        if not m.top.focused and m.title <> invalid
            m.title.color = "#ffffff"
            m.title.font.size = 22
        end if
        
    else
        ' Hide selected indicators when not selected
        if m.selectedBackground <> invalid then m.selectedBackground.visible = false
        if m.selectedIndicator <> invalid then m.selectedIndicator.visible = false
        
        ' Show normal background if not selected and not focused
        if not m.top.focused
            if m.background <> invalid then m.background.visible = true
            
            ' Normal text styling
            if m.title <> invalid
                m.title.color = "#cccccc"
                m.title.font.size = 22
            end if
        else
            ' Hide normal background when focused
            if m.background <> invalid then m.background.visible = false
        end if
    end if
    
    print "NavItem.brs - [updateVisualState] Final state - focus: " + m.focusBackground.visible.ToStr() + ", selected: " + m.selectedBackground.visible.ToStr() + ", normal: " + m.background.visible.ToStr()
end sub