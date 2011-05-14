MXMLC = PLATFORM == "win" ? "mxmlc.exe" : "mxmlc"
COMPC = PLATFORM == "win" ? "compc.exe" : "compc"
ASDOC = PLATFORM == "win" ? "asdoc.exe" : "asdoc"

VOLUMETRICS_SRC_FILES = FileList["./src/org/zozuar/volumetrics/**/*.as"]
# convert filenames to AS3 class names (probably fails on windows)
VOLUMETRICS_CLASSES = VOLUMETRICS_SRC_FILES.map {|p| p[6..-4].gsub("/", ".")}

SWC_TARGET = "./bin/Volumetrics.swc"

EXAMPLES_LIBS = [SWC_TARGET, "./examples/lib/MinimalComps.swc"]

MXMLC_OPTIONS = [
                 "-compiler.source-path ./examples ./src",
                 "-optimize",
                 "-include-libraries #{EXAMPLES_LIBS.join(" ")}",
                ]

SWC_OPTIONS = [
               "-output #{SWC_TARGET}",
               "-optimize",
               "-source-path ./src",
               "-include-classes #{VOLUMETRICS_CLASSES}",
              ]

# doc
file "./doc/index.html" => VOLUMETRICS_SRC_FILES do
  rm_r Dir.glob("./doc/*")
  sh "#{ASDOC} -output doc -source-path src -doc-sources src/org/zozuar/volumetrics/"
end
task :doc => "./doc/index.html" do
end

# swc
file SWC_TARGET => VOLUMETRICS_SRC_FILES do
  sh "#{COMPC} #{SWC_OPTIONS.join(" ")}"
end
task :swc => [SWC_TARGET] do
end

# examples
file "./bin/EffectExplorer.swf" => ["./examples/EffectExplorer.as", SWC_TARGET] do
  sh "#{MXMLC} -output ./bin/EffectExplorer.swf #{MXMLC_OPTIONS.join(" ")} -- ./examples/EffectExplorer.as"
end
file "./bin/PointLightDemo.swf" => ["./examples/PointLightDemo.as", SWC_TARGET] do
  sh "#{MXMLC} -output ./bin/PointLightDemo.swf #{MXMLC_OPTIONS.join(" ")} -- ./examples/PointLightDemo.as"
end
task :examples => ["./bin/EffectExplorer.swf", "./bin/PointLightDemo.swf"] do
end

# clean
task :clean do
  rm_r Dir.glob("./doc/*")
  rm Dir.glob("./bin/*.swf")
  rm SWC_TARGET
end

task :all => [:swc, :examples, :doc] do
end

task :default => [:all]
