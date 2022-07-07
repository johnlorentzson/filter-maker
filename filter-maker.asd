(asdf:defsystem #:filter-maker
  :description "CLIM program for letting users make filters out of predicates and keys."
  :author "John Lorentzson (Duuqnd)"
  :license  "BSD 2-Clause"
  :version "1.0.0"
  :serial t
  :depends-on (#:mcclim)
  :components ((:file "package")
               (:file "filter-maker")))
