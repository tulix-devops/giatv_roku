sub init()
    m.progressWell = m.top.FindNode("progressWell")
    m.progress = m.top.FindNode("progress")
    m.seekProgress = m.top.FindNode("seekProgress")
    m.top.ObserveFieldScoped("position", "OnPlayerPositionChanged")
    m.top.ObserveFieldScoped("seekPosition", "OnPlayerSeekPositionChanged")

    m.progressWell.width = m.top.barWidth
    m.progressWell.height = m.top.barHeight
end sub

sub setProgressWellHeight()
    m.progressWell.height = m.top.barHeight
end sub

sub setProgressWellWidth()
    m.progressWell.width = m.top.barWidth
end sub

sub OnPlayerPositionChanged()
    d = m.top.duration
    if d > 0
        p = m.top.position
        progress = p / d
        if progress >= 1 then progress = 1
        w = m.progressWell.width * progress
        if w < 2 then w = 2 'make sure width is at least couple pixels so 9patch image is rendered properly
        m.progress.width = w
    end if
end sub

sub OnPlayerSeekPositionChanged()
    d = m.top.duration
    if d > 0
        p = m.top.seekPosition
        seekProgress = p / d
        if seekProgress >= 1 then seekProgress = 1
        w = m.progressWell.width * seekProgress
        if w < 2 then w = 2 'make sure width is at least couple pixels so 9patch image is rendered properly
        m.seekProgress.width = w
    end if
end sub