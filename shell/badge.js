#! /usr/bin/env node

/**
 * https://img.shields.io/crates/d/:crate
**/
const { spawnSync, execSync } = require("child_process")
const fs = require('fs')

if (`${process.ppid}` !== process.env.NODE_PARENT_PID) {
  // Say our original entrance script is `app.js`
  let cmd = `NODE_PARENT_PID=${process.pid} node --no-warnings ${process.argv.slice(1).join(' ')}`;

  if (process.argv.includes('-p')) {
    const tmp = __filename + '.tmp'
    const writable = fs.createWriteStream(tmp)
    writable.on('open', () => {
      execSync(cmd, { stdio: ['inherit', writable, 'inherit'] })
    })
    const readable = fs.createReadStream(tmp)
    readable.on('open', () => {
      execSync('pbcopy', { stdio: [readable, 'inherit', 'inherit'] })
      fs.unlinkSync(tmp)
    })
  } else {
    execSync(cmd, { stdio: ['inherit', 'inherit', 'inherit'] })
  }
} else {
  async function github(owner, repo, file) {
    file = file || 'package.json'
    const res = await fetch(`https://api.gitHub.com/repos/${owner}/${repo}/contents/${file}`, {
      headers: {
        'content-type': 'application/json',
        'user-agent': '',
      }
    })
    if (res.status === 200) {
      const body = await res.json()
      if (Array.isArray(body)) return body.map(e => ({ path: e.path, type: e.type, url: e.html_url }))
      const text = Buffer.from(body.content, 'base64').toString()
      if (file.endsWith('.json')) {
        return JSON.parse(text)
      } else {
        return text
      }
    }
  }

  async function npm(pkg) {
    const json = await fetch(`https://api.npms.io/v2/package/${encodeURIComponent(pkg)}`).then(r => r.json())
    const info = { json }
    info.github = json.collected.metadata.links.repository
    const r = new URL(info.github).pathname.split('/')
    info.owner = r[1]
    info.repo = r[2]
    info.npm = json.collected.metadata.links.npm
    info.home = json.collected.metadata.links.homepage
    info.description = json.collected.metadata.description
    info.license = json.collected.metadata.license
    info.shields = json.collected.source?.badges?.map(e => e.urls.shields) || []
    return info
  }

  function nextArgv(...args) {
    for (const arg of process.argv) {
      if (!args.length) {
        return arg
      }
      if (arg === args[0]) {
        args.shift()
      }
    }
  }

  function dependency(pkgInfo, name) {
    return pkgInfo?.dependencies?.[name] || pkgInfo?.devDependencies?.[name] || pkgInfo?.peerDependencies?.[name]
  }

  let text = process.argv[2]
  let pkg, owner, repo

  if (/^[^/]+\/[^/]+$/.test(text)) {
    if (text.startsWith('@')) {
      pkg = text
    } else {
      [owner, repo] = text.split('/')
    }
  } else if (/github\.com/.test(text)) {
    [, owner, repo] = new URL(text).pathname.split('/')
  } else if (/npmjs\.com/.test(text)) {
    pkg = new URL(text).pathname.replace('/package/', '')
  } else {
    pkg = text
  }

  async function run() {
    if (!pkg) {
      const data = await github(owner, repo)
      if (dependency(data, 'turbo') || dependency(data, 'lerna')) {
        const packages = await github(owner, repo, 'packages')
        packages.forEach(e => e.package = e.path + '/package.json')
        console.log(packages)
        return
      } else {
        ({ name: pkg } = data)
      }
    }
    const npminfo = await npm(pkg)
    if (!owner) owner = npminfo.owner
    if (!repo) repo = npminfo.repo
    const pkg2 = encodeURIComponent(pkg)

    console.log(
      [
        `[![GitHub stars](https://img.shields.io/github/stars/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo})`,
        `[![GitHub issues](https://img.shields.io/github/issues/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo}/issues)`,
        `[![GitHub issues-closed](https://img.shields.io/github/issues-closed/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo}/issues)`,
        `[![GitHub license](https://img.shields.io/github/license/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo})`,
        `[![GitHub release](https://img.shields.io/github/release/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo}/releases/)`,
        `[![GitHub tag](https://img.shields.io/github/tag/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo}/tags/)`,
        `[![GitHub commit-activity](https://img.shields.io/github/commit-activity/m/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo})`,
        `[![GitHub last-commit](https://img.shields.io/github/last-commit/${owner}/${repo}?logo=github)](https://github.com/${owner}/${repo})`,
        `[![GitHub release-date](https://img.shields.io/github/release-date/${owner}/${repo}?logo=github)](https://github.com/${owner}/releases/)`,
        `[![GitHub contributors-anon](https://img.shields.io/github/contributors-anon/${owner}/${repo}?logo=github)](https://github.com/${owner}/graphs/contributors/)`,
        `[![GitHub languages/top](https://img.shields.io/github/languages/top/${owner}/${repo}?logo=github)](https://github.com/${owner}/graphs/contributors/)`,
        `[![NPM version](https://img.shields.io/npm/v/${pkg2}?logo=npm)](${npminfo.npm})`,
        `[![NPM downloads](https://img.shields.io/npm/dw/${pkg2}?logo=npm)](${npminfo.npm})`,
        `[![NPM types](https://img.shields.io/npm/types/${pkg2}?logo=npm)](${npminfo.npm})`,
        `[![NPM license](https://img.shields.io/npm/l/${pkg2}?logo=npm)](${npminfo.npm})`,
        ...npminfo.shields.map(e => `![e](${e})`),
      ].join('\n')
    )
  }

  if (process.argv.includes('-g')) {
    github(owner, repo, nextArgv('--')).then(console.log)
  } else if (process.argv.includes('-n')) {
    npm(pkg).then(console.log)
  } else {
    run()
  }
}
