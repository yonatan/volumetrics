MXMLC = PLATFORM == "win" ? "mxmlc.exe" : "mxmlc"
COMPC = PLATFORM == "win" ? "compc.exe" : "compc"
ASDOC = PLATFORM == "win" ? "asdoc.exe" : "asdoc"

VOLUMETRICS_SRC_FILES = FileList["./src/org/zozuar/volumetrics/**/*.as"]
# convert filenames to AS3 class names (probably fails on windows)
VOLUMETRICS_CLASSES = VOLUMETRICS_SRC_FILES.map {|p| p[6..-4].gsub("/", ".")}

SWC_TARGET = "./bin/Volumetrics.swc"

EXAMPLES_LIB = [SWC_TARGET, "./examples/lib/MinimalComps.swc"]
EXAMPLES_NAMES = ["EffectExplorer"]
EXAMPLES_SRC_FILES = EXAMPLES_NAMES.map {|name| "./examples/#{name}.as"}

MXMLC_OPTIONS = [
                 "-compiler.source-path ./examples ./src",
                 "-optimize",
                 "-include-libraries #{EXAMPLES_LIB.join(" ")}",
                ]

SWC_OPTIONS = [
               "-output #{SWC_TARGET}",
               "-source-path ./src",
               "-include-classes #{VOLUMETRICS_CLASSES}",
              ]

task :doc => VOLUMETRICS_SRC_FILES do
  rm_r "./doc" rescue nil
  sh "#{ASDOC} -output doc -source-path src -doc-sources src/org/zozuar/volumetrics/"
end

file SWC_TARGET => VOLUMETRICS_SRC_FILES do
  sh "#{COMPC} #{SWC_OPTIONS.join(" ")}"
end

task :swc => [SWC_TARGET] do
end

task :examples => [SWC_TARGET] do
  EXAMPLES_NAMES.each do|name|
    sh "#{MXMLC} -output ./bin/#{name}.swf #{MXMLC_OPTIONS.join(" ")} -- ./examples/#{name}.as"
  end
end

task :clean do
  rm_r "./doc" rescue nil
  rm "./bin/*" rescue nil
end
