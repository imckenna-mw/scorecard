function json = regenerateJson( mlxPath, jsonPath )

% Copyright 2019 MathWorks Inc.
edit( mlxPath )
richEditorApplication = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
client = richEditorApplication.getLastActiveLiveEditorClient;
le = client.getLiveEditor;
disp(le.getLongName)
rtc = client.getRichTextComponent;
htmlComponent = rtc.getLightWeightBrowser();
command = 'rtcInstance.actionDataService.executeAction("rtc_select_all");rtcInstance.actionDataService.executeAction("rtc_copy")';

subscription = message.subscribe( '/clipboardservice/setClipboardDataRequest', @receiveClipboard );
htmlComponent.executeScript(command);

    function receiveClipboard( src )

        flavorIndex = {src.contents.flavor} == "application/matlab_json";
        json = src.contents(flavorIndex).content;
        % beautify somewhat
        json = strrep(json,'{"className":',[newline '{"className":']);
               
        [~,~] = mkdir( fileparts( jsonPath ) );
        fid = fopen( jsonPath, 'w' );
        fprintf( fid, '%s\n', json );
        fclose( fid );
        edit( jsonPath )
        
        message.unsubscribe( subscription )
    end

end

