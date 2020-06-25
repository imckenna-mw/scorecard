function insertLiveScriptSection( json )

% Copyright 2019 MathWorks Inc.

richEditorApplication = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
client = richEditorApplication.getLastActiveLiveEditorClient;
if isempty( client )
    return % no Live Editor client
end
rtc = client.getRichTextComponent;
htmlComponent = rtc.getLightWeightBrowser();
command = "rtcInstance.getDocument().insertContentAtCurrentPosition(" + json + ")";
htmlComponent.executeScript( command );

end