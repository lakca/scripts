#! /usr/bin/env bash

node -e 'let text="";process.stdin.on("data", e => text += e.toString()).on("end", () => {const url=new URL(text);console.log(`url=\x27${url.origin}${url.pathname}\x27\n` + [...url.searchParams.entries()].map(e => `curlparams+=(--data-urlencode ${e[0]}=${e[1]})`).join("\n"))})' | tee | pbcopy
