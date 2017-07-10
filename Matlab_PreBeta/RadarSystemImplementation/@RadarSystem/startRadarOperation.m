function startRadarOperation(obj)

    obj.m_uFrameCounter = 1;

    if obj.m_uNumFrames==1
        obj.setAutomaticFrameTrigger(0);
    else
        obj.setAutomaticFrameTrigger
    end

    for n=1:obj.m_uNumFrames
        obj.getFrameData;
    end

end

