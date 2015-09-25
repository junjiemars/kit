{:user {:plugins [[cider/cider-nrepl "0.9.1"]
                  [lein-try "0.4.3"]
                  [lein-kibit "0.1.2"]]
        :dependencies ;;^:replace
        [[org.clojure/clojure "1.7.0"]
         [org.clojure/tools.nrepl "0.2.10"]
         [org.clojure/tools.trace "0.7.8"]
         ]
        ;;:repl-options {:timeout 40000}
        }}

