# SDML Mode for Emacs

![SDML Logo Text](https://raw.githubusercontent.com/sdm-lang/.github/main/profile/horizontal-text.svg)

This package provides support for SDML (the [Simple Domain Modeling Language](https://github.com/johnstonskj/tree-sitter-sdml)) in
[Org-Babel](https://orgmode.org/worg/org-contrib/babel/) blocks.

## Installing

Install is easiest from MELPA, here's how with `use-package`. Note the hook clause
to ensure this minor mode is always enabled for SDML source files.

```elisp
(use-package ob-sdml
  :after (ob sdml-mode)
  :init (ob-sdml-setup))
```

Or, interactively; `M-x package-install RET sdml-ispell RET` and then
run `M-x ob-sdml-setup RET` to add SDML to the Babel list of languages.

You will also need to install the SDML command-line tool to execute commands
against source blocks.

```sh
〉cargo install sdml-cli
```

## Usage

For example, the following source block calls the CLI to draw a concept diagram
for the enclosed module.

```org
#+NAME: lst:rentals-example
#+CAPTION: Rentals Concepts
#+BEGIN_SRC sdml :cmdline draw --diagram concepts :file ./rentals-concepts.svg :exports both
module rentals is

  entity Vehicle

  entity Location

  entity Customer

  entity Booking

end
#+END_SRC
```

The results block then references the resulting image.

```
#+NAME: fig:rentals-example-concepts
#+CAPTION: Rentals Concepts
#+RESULTS: lst:rentals-example
[[file:./rentals-concepts.svg]]
```

To simply show the source in a document the following does not require the
command-line tool at all.

```org
#+BEGIN_SRC sdml :exports code :eval never
module rentals is
  ;; ...
end
#+END_SRC
```

But, what if we want to produce more than one diagram from the same source? By
using the built-in /[noweb](https://orgmode.org/manual/Noweb-Reference-Syntax.html)/ syntax we can create a new source block, but
reference the original content. This source block has different command-line
parameters and has it's own results block as well.

```org
#+NAME: fig:rentals-example-erd
#+BEGIN_SRC sdml :cmdline draw --diagram concepts :file ./rentals-erd.svg :exports results :noweb yes
<<lst:rentals-example>>
#+END_SRC
```

## Contributing

This package includes an [Eldev](https://github.com/emacs-eldev/eldev) file and the following MUST be run before
creating any PR.

- `eldev lint`
- `eldev doctor`
- `eldev package --load-before-compiling --stop-on-failure --warnings-as-errors`
- `eldev test`
- `eldev test --undercover auto,coveralls,merge,dontsent -U simplecov.json`
- `eldev release -nU 9.9.9`

The script [eldev-check.sh](https://gist.github.com/johnstonskj/6af5ef6866bfb1288f4962a6ba3ef418) may be useful to you if you do not have your own Eldev workflow.

## License

This package is released under the Apache License, Version 2.0. See the LICENSE
file in this repository for details.

## Changes

The `0.1.x` series are all pre-release and do not appear in ELPA/MELPA.
