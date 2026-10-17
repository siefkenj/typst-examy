#import "../template.typ": IMPORT, reference_index

Every name examy exports, each with a page of every argument it takes. All of
them are imported by

#raw(IMPORT, lang: "typ", block: true)

The guide pages show them in use; the reference is generated from the
package's own declarations, the same ones that check the arguments of every
call, so it always matches the version it documents.

#reference_index()
