MXMLC = PLATFORM == "win" ? "mxmlc.exe" : "mxmlc"
COMPC = PLATFORM == "win" ? "compc.exe" : "compc"
ASDOC = PLATFORM == "win" ? "asdoc.exe" : "asdoc"

task :doc do
     sh "#{ASDOC} -output doc -source-path src -doc-sources src/org/zozuar/volumetrics/"
end

task :clean do
     rm_r "doc"
end