classdef JSONloader < handle
    
    % Copyright 2019 MathWorks Inc.
    
    properties
        OldIDs = {}
        NewIDs = {}
        IsOutput = []
    end
    
    methods
        
        function json = loadFromTemplate( obj, mlxPath, jsonPath )
               
        if isempty( obj.OldIDs )
            populateOldIDs( obj, jsonPath )
        end
        
        json = fileread( jsonPath );
        json = strrep( json, newline, '' );
        json = strrep( json, char(13), '' );
        o = mtree( mlxPath, '-file' );
        
        % replace if output and already in workspace
        w = evalin('base','who');
        newIDs = matlab.lang.makeUniqueStrings([obj.OldIDs(:);w], find(obj.IsOutput) ); %#ok<FNDSB>
        obj.NewIDs(obj.IsOutput) = newIDs(obj.IsOutput);
                   
        f = mtfind(o,'Kind','ID','String',obj.OldIDs);
        linenos = lineno(f);
        charnos = charno(f);
        strs = strings(f);
        % won't work with line content after a live control
        linestart = '{"className":"LineNode","children":[{"className":"PlainTextNode","text":"';
        linestart = strfind(json,linestart) + length( linestart );
        for n = length( linenos ):-1:1
            pos = linestart(linenos(n))+charnos(n)-1;
            str = strs{n};
            newid = obj.NewIDs{strcmp(obj.OldIDs,str)};
            assert(strcmp(json(pos:(pos+length(str)-1)),str));
            json = [json(1:pos-1) newid json(pos+length(str):end)];
        end
        
        end
              
        function populateOldIDs( obj, jsonPath )
        [folder,script] = fileparts(jsonPath);
        signatureFile = fullfile( folder, 'functionSignatures.json' );
        if ~exist( signatureFile, 'file' )
            obj.OldIDs = {};
            obj.IsOutput = [];
            return
        end
        signature = jsondecode( fileread( signatureFile ) );
        if ~isfield( signature, script )
            obj.OldIDs = {};
            obj.IsOutput = [];
            return
        end
        if isfield( signature.(script), 'outputs' ) && ~isempty( signature.(script).outputs )
            obj.OldIDs = [{signature.(script).inputs.name} {signature.(script).outputs.name}];
            obj.IsOutput = [false(size(signature.(script).inputs)); true(size(signature.(script).outputs))];
        elseif isfield( signature.(script), 'inputs' ) && ~isempty( signature.(script).inputs )
            obj.OldIDs = {signature.(script).inputs.name};
            obj.IsOutput = false(size(signature.(script).inputs));
        else
            obj.OldIDs = {};
            obj.IsOutput = false(0,0);
        end
        end
        
    end
    
end