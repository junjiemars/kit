;;;;
;; sample-self-env-spec.el: specify the private environment specs or yourself
;; 
;;;;


(def-self-env-spec
  :theme (list :name 'atom-one-dark
               :path (emacs-home* "theme/")
               :allowed t)
  :font (list :name "Monaco-11"
              :allowed t)
  :cjk-font (list :name "Microsoft Yahei"
                  :size 12
                  :allowed t)
  :shell (list :env-vars '("LD_LIBRARY_PATH" "JAVA_HOME")
               :interactive-shell t
               :exec-path t
               :bin-path (comment `,(bin-path "bash"))
               :allowed t)
  :desktop (list :files-not-to-save "\.el\.gz\\|\.desktop\\|~$"
                 :buffers-not-to-save "^TAGS\\|\\.log"
                 :modes-not-to-save
                 '(dired-mode fundamental-mode rmail-mode)
                 :restore-eager 8
                 :allowed t)

  :socks (list :port 11032
               :server "127.0.0.1"
               :version 5
               :allowed nil))
