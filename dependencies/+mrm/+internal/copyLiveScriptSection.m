function copyLiveScriptSection( json )

% Copyright 2019 MathWorks Inc.

sc = java.awt.Toolkit.getDefaultToolkit().getSystemClipboard();
mime = 'application/matlab_json; class=java.lang.String';
transferData = javax.activation.DataHandler( json, mime );
sc.setContents(transferData,[])

end