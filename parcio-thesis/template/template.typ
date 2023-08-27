#import "@preview/tablex:0.0.5": *
#import "@preview/codelst:1.0.0": *

#let ovgu-blue = rgb("#0068B4")
#let ovgu-darkgray = rgb("#606060")
#let ovgu-lightgray = rgb("#C0C0C0")
#let ovgu-orange = rgb("#F39100")
#let ovgu-purple = rgb("#7A003F")
#let ovgu-red = rgb("#D13F58")

#let large = 14.4pt
#let Large = 17.28pt 
#let LARGE = 20.74pt
#let huge = 24.88pt

// Typst has its own `#lorem()` function but I wanted to make this comparable
// to the LaTeX template which uses a different variant of this placeholder text.
#let ipsum = [
  Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Ut purus elit, vestibulum ut, placerat ac, adipiscing vitae, felis. Curabitur dictum gravida mauris. Nam
  arcu libero, nonummy eget, consectetuer id, vulputate a, magna. Donec vehicula augue eu neque. Pellentesque habitant morbi tristique senectus et netus et
  malesuada fames ac turpis egestas. Mauris ut leo. Cras viverra metus rhoncus
  sem. Nulla et lectus vestibulum urna fringilla ultrices. Phasellus eu tellus sit amet
  tortor gravida placerat. Integer sapien est, iaculis in, pretium quis, viverra ac, nunc.
  Praesent eget sem vel leo ultrices bibendum. Aenean faucibus. Morbi dolor nulla,
  malesuada eu, pulvinar at, mollis ac, nulla. Curabitur auctor semper nulla. Donec
  varius orci eget risus. Duis nibh mi, congue eu, accumsan eleifend, sagittis quis,
  diam. Duis eget orci sit amet orci dignissim rutrum.
]

// TODO box.
#let todo(text) = rect(
  fill: ovgu-orange,
  stroke: black + 0.5pt,
  radius: 0.25em,
  width: 100%
)[#text]

// Like \section* (unnumbered level 2 heading, does not appear in ToC).
#let section(title) = heading(level: 2, outlined: false, numbering: none)[#title]

// ----------------------
//   CUSTOM PARCIO TABLE
//  (uses tablex & nested tables)
// ----------------------
#let parcio-table(columns, rows, ..tablec) = {
  let header-data = tablec.pos().slice(0, columns)
  let rest = tablec.pos().slice(columns)
  
  table(columns: 1, stroke: none,
    style(styles => {
      let header = table(columns: columns, rows: 1, stroke: 0.5pt, align: center,
        ..header-data
      )
      let hw = measure(header, styles).width / columns

      header
      v(-1em)
      tablex(columns: (hw,) * columns, rows: rows - 1, stroke: 0.5pt, align: (x, y) => 
          (left, center, right).at(x),
          auto-hlines: false,
          hlinex(),
          ..rest,
          hlinex()
        )
    })
  )
}

// ----------------------
//   ACTUAL TEMPLATE
// ----------------------
#let project(title, author, abstract, body) = {
  set document(title: title, author: author.name)
  set page("a4", margin: 2.5cm, number-align: right)
  set text(font: "Libertinus Serif", 12pt, lang: "en")
  set heading(numbering: "1.1.")
  set par(justify: true)
  set math.equation(numbering: "(1)")

  // Make URLs use monospaced font.
  show link: l => {
    if type(l.dest) == "string" {
      set text(font: "Inconsolata", 12pt * 0.95)
      l
    } else {
      l
    }
  }

  // Create the "Chapter X." heading for every level 1 heading that is numbered.
  // Also resets figure counters so they stay chapter-specific.
  show heading.where(level: 1): h => {
    set text(huge)
    if h.numbering != none {
      pagebreak(weak: true, to: "odd")
      if h.body == [Appendix] {
        counter(heading.where(level: 1)).update(1)
        [Appendix #counter(heading.where(level: 1)).display(h.numbering)]
      } else {
        [Chapter ] + counter(heading.where(level: 1)).display()
      }
      [\ #v(0.2em) #h.body]
    } else {
      h
    }

    counter(figure.where(kind: image)).update(0)
    counter(figure.where(kind: table)).update(0)
    counter(figure.where(kind: raw)).update(0)
  }

  show heading.where(level: 2): h => {
    if h.numbering != none {
      [#counter(heading).display()~~#h.body]
    } else {
      h
    }
  }

  // Make figures use "<chapter>.<num>." numbering.
  set figure(numbering: n => locate(loc => {
    let headings = query(heading.where(level: 1).before(loc), loc).last()
    let chapter = counter(heading.where(level: 1)).display(headings.numbering)
    [#chapter#n.]
  }))

  // Make references to figures use "<chapter>.<num>" numbering.
  // (without period at the end, will be easier in the future)
  show ref: r => {
    let elem = r.element
    if elem != none and elem.func() == figure {
      if elem.kind == image or elem.kind == table or elem.kind == raw {
         return [#elem.supplement #elem.counter.display(n => {
          let chapter = counter(heading.where(level: 1)).display()
          link(elem.location())[#chapter#n]
         })]     
      }
    }

    r
  }

  // Make @heading automatically say "Chapter XYZ" instead of "Section XYZ",
  // unless we want to manually specify it.
  set ref(supplement: it => {
    if it.func() == heading.where(supplement: none) {
      "Chapter"
    } else {
      it.supplement
    }
  })

  // Changes every citation that has (...et al.) in it to use square brackets.
  // TODO.
  show cite: c => {
    show regex("[(].*(et al.).*[)]"): r => {
      r.text.replace("(", "[").replace(")", "]").replace(".", ".,")
    }

    c
  }

  // Customize ToC to look like template.
  set outline(fill: repeat[~~.], indent: none)
  show outline: o => {
    show heading: pad.with(bottom: 1em)
    o
  }

  // Level 2 and deeper.
  show outline.entry: it => {
    let cc = it.body.children.first().text
    
    box(
      grid(columns: (auto, 1fr, auto),
        h(1.5em) + link(it.element.location())[#cc#h(1em)#it.element.body],
        it.fill,
        box(width: 1.5em) + it.page
      )
    )
  }

  // Level 1 chapters get bold and no dots.
  show outline.entry.where(level: 1): it => {
    set text(font: "Libertinus Sans")
    let cc = if it.element.body == [Appendix] {
      "A." // hotfix
    } else if it.body.has("children") {
      it.body.children.first()
    } else {
      h(-0.5em)
    }
    
    v(0.1em)
    box(
      grid(columns: 3,
        strong(link(it.element.location())[#cc #h(0.5em) #it.element.body]),
        h(1fr),
        strong(it.page)
      )
    )
  }

  // Applies a similar theme with the ovgu colors using the tmTheme format.
  // It is very limited; using Typst's own highlighting might be more expressive.
  set raw(theme: "ovgu.tmTheme")
  show raw: set text(font: "Inconsolata")
  
  // Custom line numbering, not native yet.
  // Packages exist that implement this.
  show raw.where(block: true): r => [
    #grid(columns: 2, column-gutter: -1em)[
      #v(1em)
      #set text(fill: ovgu-darkgray, font: "Inconsolata", 0.95 * 12pt)
      #set par(leading: 0.65em)
      #move(dx: -1.5em, dy: -0.5em)[
        #for (i, l) in r.text.split("\n").enumerate() [
          #box[#align(right)[#{i + 1}]]
          #linebreak()
        ]
      ]
    ][    
      #block(stroke: 0.5pt + gray, inset: (x: 0.5em, y: 0.5em), width: 100%)[
        #align(left)[#r]
      ]
    ]
  ]

  // TODO (make better): Custom subfigure counter ((a), (b), ...).
  show figure.where(kind: "sub"): f => {
    f.body
    v(-0.65em)
    counter(figure.where(kind: "sub")).display("(a)") + " " + f.caption
  }
  
  show heading: set text(font: "Libertinus Sans", Large)
  show heading: it => it + v(1em)

  set footnote.entry(separator: line(length: 40%, stroke: 0.5pt))

  // Can't import pdf yet (svg works).
  align(center)[
    #image(alt: "Blue OVGU logo", width: 66%, "ovgu.svg")  
  ]

  v(4.75em)

  align(center)[
    #text(Large, font: "Libertinus Serif")[*Bachelor/Master Thesis*]
    #v(2.5em)
    #text(huge, font: "Libertinus Sans")[*#title*]
    #v(1.25em)

    #set text(Large)
    #show raw: set text(large * 0.95)
    #align(center)[
      #author.name\
      #v(0.75em, weak: true)#link("mailto:" + author.mail)[#raw(author.mail)]
    ]

    #v(0.5em)
    #text(Large)[#datetime.today().display("[month repr:long] [day], [year]")]
    #v(5.35em)

    First Reviewer:\
    Prof. Dr. Musterfrau\ \
    #v(-1.5em)

    Second Reviewer:\
    Prof. Dr. Mustermann\ \
    #v(-1.5em)

    Supervisor:\
    Dr. Evil
  ]
  
  show raw: set text(12pt * 0.95)
  pagebreak(to: "odd")

  v(-8.5em)
  align(center + horizon)[
    #text(font: "Libertinus Sans", [*Abstract*])\ \
    #align(left, abstract)
  ]
  
  pagebreak(to: "odd")
  body
}