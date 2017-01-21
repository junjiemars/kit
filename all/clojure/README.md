# Clojure

* [REPL](#repl)


## REPL
[REPL](https://en.wikipedia.org/wiki/REPL) is the heart of **Clojure Programming**, 
but what exactly is it?
```clj
(loop [input (read-line-from)]
    (-> input
        eval-str
        print)
    (recur (read-line-from)))
```

The most easy way to install [Clojure](https://clojure.org/) is call one line code in your shell
```sh
# install and setup clojure
PREFIX=<install-dir> HAS_CLOJURE=1 bash <(curl https:/raw.githubusercontent.com/junjiemars/kit/master/ul/install-java-kits.sh)

# just run it, we are in REPL
clojure
```

### Network REPL

