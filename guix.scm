; SPDX-License-Identifier: MPL-2.0
;; guix.scm — GNU Guix package definition for preference-injector
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "preference-injector")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "preference-injector")
  (description "preference-injector — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/preference-injector")
  (license mpl2.0))
