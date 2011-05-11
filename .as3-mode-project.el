(setq as3-flymake-build-command
      (list "wget" (list "http://localhost:2001/compile" "-O-" "-q")))

(setq as3-project-source-paths `("."))

(setq as3-build-and-run-command "wget http://localhost:2001/compile_and_show -O- -q")