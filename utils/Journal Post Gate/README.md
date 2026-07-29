# 🚧 Journal Post Gate

A deterministic guard that decides whether a generated post is safe to publish.

If you let an LLM turn a private work journal into public posts, the model writes the prose —
but **the model must not be the one deciding what is confidential**. This script does that,
with regexes, the same way every time.

---

### 📋 What Does It Do?

Scans text (a file or stdin) and **exits non-zero** if it finds anything that would identify an
employer, an account, a system or a person:

**Built-in rules** — generic, useful to anyone:

| Rule | Catches |
|------|---------|
| AWS account | any bare 12-digit number |
| Private repo hosts | `bitbucket.org`, `atlassian.net`, self-hosted GitLab |
| AWS ARNs | `arn:aws:` |
| IP addresses | dotted quads |
| Secrets | `AKIA…`, `ghp_…`, `sbp_…`, `xox…` and similar vendor prefixes |
| Local absolute paths | `/Users/<name>/…` |
| Credentials in a URL | `scheme://user:pass@host` |

**What is deliberately NOT in this file:** your employer's name, internal repo prefixes,
ticket-ID prefixes, cloud profile names. A public script that enumerates a company's private
identifiers *is* the leak it claims to prevent. Those live in your private config (below).

Every match is printed with its line so you know exactly what to rewrite.

---

### ⚙️ Usage

```bash
./journal-post-gate.sh post.html        # check a file
cat post.html | ./journal-post-gate.sh  # check stdin
./journal-post-gate.sh --patterns       # print the active ruleset
```

Exit codes: `0` clean · `1` blocked · `2` usage error.

```
  ✘ cuenta AWS (12 dígitos)
      1:574228278861
      1:910332525012

BLOQUEADO — post.html no se publica.
Reescribe el post en términos genéricos: qué tipo de sistema y qué aprendiste,
sin nombrar la cuenta, el repo, el ticket ni a la persona.
```

---

### 🔒 Private rules

Everything specific to you lives in `~/.config/journal-post-gate/`, outside any repo:

`patterns.txt` — your own regex rules, same `label|regex` format as the built-ins:

```
ID de ticket interno|\b(ABC|XYZ)-[0-9]+\b
repo interno|\b(acme|foo)-[a-z0-9-]+
identificador del empleador|(acmecorp|acme-inc)
```

`denylist.txt` — literal terms, one per line, case-insensitive. Names of colleagues and
clients go here:

```
# colleagues mentioned in the journal
Firstname Lastname
```

Both take `#` comments. Override the directory with `JOURNAL_GATE_CONFIG=/path`.
Run `./journal-post-gate.sh --patterns` to see the built-ins plus how many private rules loaded.

> The script flags itself when scanned — its own ruleset contains the literal strings it looks
> for. That is expected and harmless; those are public vendor prefixes, not secrets.

---

### 🤖 Where it fits

Used by the `journal-a-post` skill, which turns a daily journal entry into a post for a public
site. The skill runs the gate **before** opening the pull request, and again on the full page
after inserting the post. The publish step is a PR, never a direct push — a leak that reaches a
public site cannot be unpublished.

---

### 📦 Requirements

Bash and `grep` with ERE support. No dependencies.

> ⚠️ The ruleset is tuned to one person's environment. Fork the `RULES` array before reusing it.
