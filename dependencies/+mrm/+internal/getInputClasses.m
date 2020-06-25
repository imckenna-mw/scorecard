function types = getInputClasses( resourceFolder )

% parse function signatures
signatures = mrm.internal.recursiveDir(fullfile(resourceFolder,'json'),'functionSignatures.json');

types = string.empty;

for n = 1:length(signatures)
    signature = jsondecode(fileread(fullfile(signatures(n).folder,signatures(n).name)));
    entries = fields(signature);
    for i = 1:length(entries)
        if entries{i} == "x_schemaVersion"
            continue
        end
        entry = signature.(entries{i});
        if isfield( entry, 'inputs' )
            if ~isempty( entry.inputs )
                types = [types; entry.inputs(1).type]; %#ok<AGROW>
            end
        end
    end    
end

types = unique(types);

end
