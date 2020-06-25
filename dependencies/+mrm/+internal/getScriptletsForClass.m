function [names,paths] = getScriptletsForClass( resourceFolder, inputType )

% parse function signatures
signatures = mrm.internal.recursiveDir(fullfile(resourceFolder,'json'),'functionSignatures.json');

names = string.empty;
paths = string.empty;

for n = 1:length(signatures)
    signature = jsondecode(fileread(fullfile(signatures(n).folder,signatures(n).name)));
    entries = fields(signature);
    for i = 1:length(entries)
        if entries{i} == "x_schemaVersion"
            continue
        end
        entry = signature.(entries{i});
        match = false;
        if ~isfield( entry, 'inputs' )
            match = isempty( inputType );            
        elseif isempty( entry.inputs )
            match = isempty( inputType );
        else
            if strcmp(entry.inputs(1).type{1},inputType)
                match = true;
            end
        end
        if match
            names(end+1) = entries{i} + ".mlx";
            paths(end+1) = fullfile( replace( signatures(n).folder, "json", "scriptlets" ), entries{i} + ".mlx" );
            
        end
    end
    
end

end