function file = getCurrentFolderBrowserSelectedFile

% Copyright 2018, MathWorks Inc.

desktop = com.mathworks.mde.desk.MLDesktop.getInstance;
cfb = desktop.getClient('Current Folder');
if isempty( cfb )
    file = "";
    return
end
dv = cfb.getDetailViewer;
file = dv.getFile;
if isempty( file )
    file = "";
    return
end
file = string( file.toString );
end
