classdef ScriptletSelector < handle
    
    % Copyright 2019 MathWorks Inc.
    
    properties
        ToolGroup
        Window
        WorkspaceSelector
        Tree
        Subscription
        ScriptletLoader
    end
    
    methods
        function obj = ScriptletSelector()
        
        obj.ScriptletLoader = mrm.internal.JSONloader;        
        
        obj.ToolGroup = matlab.ui.internal.desktop.ToolGroup('Scriptlets');
        % Discard the Data-browser left panel
        obj.ToolGroup.disableDataBrowser();
        obj.ToolGroup.setDockable();        
        
        import matlab.ui.internal.toolstrip.*
        
        hTabGroup = matlab.ui.internal.toolstrip.TabGroup();
        hTab = Tab('Scriptlets');
        
        hSection = Section('Insert');
        hColumn = Column('HorizontalAlignment','center', 'Width',150);
        hSection.add(hColumn);
        
        hButton = Button('Insert');
        hButton.ButtonPushedFcn = @obj.insertCallback;
        hButton.Icon = Icon.IMPORT_24; % matlab.ui.internal.toolstrip.Icon.showStandardIcons
        hColumn.add(hButton);
        
        hButton = Button('Clipboard');
        hButton.ButtonPushedFcn = @obj.clipboardCallback;
        hButton.Icon = Icon.COPY_24;
        hColumn.add(hButton);
        
        hTab.add(hSection);
        
        hSection = Section('Run');
        hColumn = Column('HorizontalAlignment','center', 'Width',150);
        hSection.add(hColumn);
        
        hButton = Button('Insert & Run');
        hButton.ButtonPushedFcn = @obj.insertRunCallback;
        hButton.Icon = Icon.RUN_24; % matlab.ui.internal.toolstrip.Icon.showStandardIcons
        hColumn.add(hButton);        
        
        hTab.add(hSection);
        
        hSection = Section('Author');
        hColumn = Column('HorizontalAlignment','center', 'Width',150);
        hSection.add(hColumn);
        
        hButton = Button('Edit');
        hButton.ButtonPushedFcn = @obj.editCallback;
        hButton.Icon = Icon.BROWSE_24;
        hColumn.add(hButton);
        
        hButton = Button('Commit');
        hButton.ButtonPushedFcn = @obj.commitCallback;
        hButton.Icon = Icon.SAVE_24;
        hColumn.add(hButton);
        
        hTab.add(hSection);
        
        hTabGroup.add(hTab);
        
        % Add the tab group to the built-in toolstrip
        obj.ToolGroup.addTabGroup(hTabGroup);
        
        obj.ToolGroup.open();
        dockToolgroup(obj)
        
        % Create a figure and dock it into the tool-group
        obj.Window = figure('Name','Credit Scorecard');
        
        % create workspace dropdown
        obj.WorkspaceSelector = uicontrol( 'Parent', obj.Window, ...
            'Style', 'popupmenu', 'String', '<empty workspace>', ...
            'Units', 'normalized', 'Position', [0.0 0.95 1 0.05], ...
            'Callback', @obj.onWorkspaceVariableSelected);
        obj.populateWorkspaceSelector([],[]);
        obj.Subscription(1) = message.subscribe( '/embeddedOutputs/regionsComplete/*', @obj.populateWorkspaceSelector );
        obj.Subscription(2) = message.subscribe( '/liveapps/initializeRequest/*', @obj.liveAppInserted );
        
        obj.ToolGroup.addFigure(obj.Window);                       
        
        end
        
        function delete(obj)
        message.unsubscribe(obj.Subscription(1));
        message.unsubscribe(obj.Subscription(2));
        end 
        
        function [mlxPath,jsonPath] = getSelectedPath(obj)
        nodes = obj.Tree.getSelectedNodes;
        if ~isscalar(nodes)
            mlxPath = '';
            jsonPath = '';
            return
        end
        value = nodes(1).getValue;
        if value(end) == '\'
            value(end) = [];
        end
        
        mlxPath = value;
        % relocate JSON version
        jsonPath = replace( mlxPath, ".mlx", ".json" );
        jsonPath = replace( jsonPath, fullfile( obj.getResourceRoot, 'scriptlets' ), ...
            fullfile( obj.getResourceRoot, 'json' ) );
        
        end
        
        function buildTree(obj,root)
                
        warning off MATLAB:uitreenode:DeprecatedFunction
        warning off MATLAB:uitree:DeprecatedFunction
        
        % Cannot pass a file filter to select on mlx files
        [obj.Tree, container] = uitree('v0', 'Root', ...
            char(fullfile( obj.getResourceRoot, 'scriptlets', root )) );
        obj.Tree.Root.setName( root );
        
        warning on MATLAB:uitree:DeprecatedFunction
        
        set( handle( container ), 'Parent', obj.Window, ...
            'Units', 'normalized', 'Position', [0 0 1 0.95] );
        
        % expand the root note to see the contents
        obj.Tree.expand(obj.Tree.Root)
        end   

        
    end
    
    methods ( Access = private )
        
        function insertCallback(obj,~,~)
        obj.ScriptletLoader.OldIDs = {};
        [mlxPath,jsonPath] = obj.getSelectedPath;
        json = obj.ScriptletLoader.loadFromTemplate( mlxPath,jsonPath );
        mrm.internal.insertLiveScriptSection( json );
        end
        
        function insertRunCallback(obj,~,~)
        insertCallback(obj,[],[])

        richEditorApplication = com.mathworks.mde.liveeditor.LiveEditorApplication.getInstance;
        client = richEditorApplication.getLastActiveLiveEditorClient;        
        rtc = client.getRichTextComponent;
        htmlComponent = rtc.getLightWeightBrowser();
        command = 'rtcInstance.actionDataService.executeAction("rtc_navigate_previous_section")';         
        htmlComponent.executeScript( command );
        command = 'rtcInstance.actionDataService.executeAction("rtc_navigate_previous_section")';         
        htmlComponent.executeScript( command );
        command = 'rtcInstance.actionDataService.executeAction("rtc_run_section_advance")';
        htmlComponent.executeScript( command );
        end        
        
        function clipboardCallback(obj,~,~)
        obj.ScriptletLoader.OldIDs = {};
        [mlxPath,jsonPath] = obj.getSelectedPath;
        json = obj.ScriptletLoader.loadFromTemplate( mlxPath,jsonPath );
        mrm.internal.copyLiveScriptSection( json );
        end
        
        function editCallback(obj,~,~)
        edit( obj.getSelectedPath );
        end
        
        function commitCallback(obj,~,~)
        [mlxPath,jsonPath] = obj.getSelectedPath;
        mrm.internal.regenerateJson(mlxPath,jsonPath);
        end
        
        function dockToolgroup(obj)
        robot = java.awt.Robot;
        robot.keyPress(java.awt.event.KeyEvent.VK_CONTROL)
        robot.keyPress(java.awt.event.KeyEvent.VK_SHIFT)
        robot.keyPress(java.awt.event.KeyEvent.VK_D)
        robot.keyRelease(java.awt.event.KeyEvent.VK_D)
        robot.keyRelease(java.awt.event.KeyEvent.VK_SHIFT)
        robot.keyRelease(java.awt.event.KeyEvent.VK_CONTROL)
        end
        
        function populateWorkspaceSelector(obj,~,~)
        w = evalin('base','whos');
        w = w( ismember( {w.class}, {'table','creditscorecard'} ) );
        if isempty( w )
            buildTree(obj,'data\');
            obj.WorkspaceSelector.Value = 1;
            obj.WorkspaceSelector.String = '<no valid objects in workspace>';            
            obj.ScriptletLoader.OldIDs = {};
            obj.ScriptletLoader.NewIDs = {};            
        else
            obj.WorkspaceSelector.String = {w.name};
            onWorkspaceVariableSelected(obj,[],[])
        end
        end
        
        function onWorkspaceVariableSelected(obj,~,~)
        wsvName = obj.WorkspaceSelector.String{obj.WorkspaceSelector.Value};
        ws = evalin('base',wsvName);
        buildTree(obj,[class(ws) '\']);
        obj.ScriptletLoader.OldIDs = {};
        obj.ScriptletLoader.NewIDs = {wsvName};
        end
        
        function liveAppInserted(obj,src)
        for retry = 1:10
            app = matlab.internal.editor.LiveAppManager.getApp(src.editorId,src.appId);
            if ~isempty( app )
                break
            end
            pause(0.5)
        end
        if isa( app, 'BaseFilterReviewerTask' )
            app.WorkspaceDropDown.populateVariables;
            app.WorkspaceDropDown.Value = obj.WorkspaceSelector.String{obj.WorkspaceSelector.Value};
            doUpdate(app)
        end
        end
        
        function folder = getResourceRoot(~)
        p = currentProject;
        folder = fullfile( p.RootFolder, 'resources' );
        end
        
    end
    
end
